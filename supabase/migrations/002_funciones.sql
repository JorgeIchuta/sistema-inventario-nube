-- 002: funciones, trigger de perfiles y vista de bajo stock
-- Todas las operaciones que cambian el stock pasan por estas funciones.

-- Ayudantes de permisos ------------------------------------------------------
create or replace function public.es_activo()
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.perfiles where id = auth.uid() and activo);
$$;

create or replace function public.es_admin()
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.perfiles
                 where id = auth.uid() and activo and rol = 'administrador');
$$;

-- Perfil automatico al crear un usuario en Supabase Auth --------------------
create or replace function public.crear_perfil()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.perfiles (id, nombre)
  values (new.id, coalesce(nullif(new.raw_user_meta_data->>'nombre', ''), split_part(new.email, '@', 1)));
  return new;
end;
$$;

drop trigger if exists al_crear_usuario on auth.users;
create trigger al_crear_usuario
  after insert on auth.users
  for each row execute function public.crear_perfil();

-- Vista de bajo stock (respeta RLS del usuario que consulta) -----------------
create or replace view public.productos_bajo_stock with (security_invoker = true) as
select p.id, p.codigo, p.nombre, p.stock_actual, p.stock_minimo,
       p.categoria_id, c.nombre as categoria
from public.productos p
join public.categorias c on c.id = p.categoria_id
where p.activo and p.stock_actual <= p.stock_minimo;

-- Registrar entrada de mercaderia (solo administrador) -----------------------
-- p_items: [{"producto_id":1,"cantidad":10,"costo_unitario":5.5}, ...]
create or replace function public.registrar_entrada(
  p_proveedor_id bigint, p_items jsonb, p_clave uuid, p_observaciones text default null)
returns bigint language plpgsql security definer set search_path = public as $$
declare
  v_usuario uuid := auth.uid();
  v_entrada bigint;
  v_item jsonb;
  v_prod public.productos%rowtype;
  v_cant integer;
  v_costo numeric(12,2);
  v_total numeric(12,2) := 0;
begin
  if not public.es_admin() then
    raise exception 'Solo el administrador puede registrar entradas' using errcode = '42501';
  end if;
  if p_items is null or jsonb_typeof(p_items) <> 'array' or jsonb_array_length(p_items) = 0 then
    raise exception 'La entrada no tiene productos';
  end if;

  select id into v_entrada from public.entradas where clave_operacion = p_clave;
  if found then return v_entrada; end if;

  if not exists (select 1 from public.proveedores where id = p_proveedor_id and activo) then
    raise exception 'Proveedor no disponible';
  end if;

  insert into public.entradas (proveedor_id, usuario_id, total, observaciones, clave_operacion)
  values (p_proveedor_id, v_usuario, 0, p_observaciones, p_clave) returning id into v_entrada;

  for v_item in select * from jsonb_array_elements(p_items) loop
    v_cant := (v_item->>'cantidad')::integer;
    v_costo := coalesce((v_item->>'costo_unitario')::numeric, 0);
    if v_cant is null or v_cant <= 0 then raise exception 'Cantidad inválida'; end if;
    if v_costo < 0 then raise exception 'Costo inválido'; end if;

    select * into v_prod from public.productos
     where id = (v_item->>'producto_id')::bigint for update;
    if not found or not v_prod.activo then raise exception 'Producto no disponible'; end if;

    insert into public.detalle_entradas (entrada_id, producto_id, cantidad, costo_unitario)
    values (v_entrada, v_prod.id, v_cant, v_costo);

    update public.productos set stock_actual = stock_actual + v_cant where id = v_prod.id;

    insert into public.movimientos_inventario
      (producto_id, usuario_id, tipo, cantidad, stock_anterior, stock_resultante, referencia_tipo, referencia_id)
    values (v_prod.id, v_usuario, 'entrada', v_cant, v_prod.stock_actual, v_prod.stock_actual + v_cant, 'entrada', v_entrada);

    v_total := v_total + v_cant * v_costo;
  end loop;

  update public.entradas set total = v_total where id = v_entrada;
  return v_entrada;
end;
$$;

-- Registrar venta (administrador y empleado) ---------------------------------
-- p_items: [{"producto_id":1,"cantidad":2}, ...]
create or replace function public.registrar_venta(
  p_items jsonb, p_clave uuid, p_observaciones text default null)
returns bigint language plpgsql security definer set search_path = public as $$
declare
  v_usuario uuid := auth.uid();
  v_venta bigint;
  v_item jsonb;
  v_prod public.productos%rowtype;
  v_cant integer;
  v_total numeric(12,2) := 0;
begin
  if not public.es_activo() then
    raise exception 'Usuario no autorizado' using errcode = '42501';
  end if;
  if p_items is null or jsonb_typeof(p_items) <> 'array' or jsonb_array_length(p_items) = 0 then
    raise exception 'La venta no tiene productos';
  end if;

  select id into v_venta from public.ventas where clave_operacion = p_clave;
  if found then return v_venta; end if;

  insert into public.ventas (usuario_id, total, observaciones, clave_operacion)
  values (v_usuario, 0, p_observaciones, p_clave) returning id into v_venta;

  for v_item in select * from jsonb_array_elements(p_items) loop
    v_cant := (v_item->>'cantidad')::integer;
    if v_cant is null or v_cant <= 0 then raise exception 'Cantidad inválida'; end if;

    select * into v_prod from public.productos
     where id = (v_item->>'producto_id')::bigint for update;
    if not found or not v_prod.activo then raise exception 'Producto no disponible'; end if;
    if v_prod.stock_actual < v_cant then
      raise exception 'Stock insuficiente para %: disponible %, solicitado %',
        v_prod.nombre, v_prod.stock_actual, v_cant;
    end if;

    insert into public.detalle_ventas (venta_id, producto_id, cantidad, precio_unitario, subtotal)
    values (v_venta, v_prod.id, v_cant, v_prod.precio_venta, v_prod.precio_venta * v_cant);

    update public.productos set stock_actual = stock_actual - v_cant where id = v_prod.id;

    insert into public.movimientos_inventario
      (producto_id, usuario_id, tipo, cantidad, stock_anterior, stock_resultante, referencia_tipo, referencia_id)
    values (v_prod.id, v_usuario, 'venta', v_cant, v_prod.stock_actual, v_prod.stock_actual - v_cant, 'venta', v_venta);

    v_total := v_total + v_prod.precio_venta * v_cant;
  end loop;

  update public.ventas set total = v_total where id = v_venta;
  return v_venta;
end;
$$;

-- Ajuste de inventario (solo administrador) ----------------------------------
create or replace function public.registrar_ajuste(
  p_producto_id bigint, p_stock_nuevo integer, p_motivo text)
returns bigint language plpgsql security definer set search_path = public as $$
declare
  v_usuario uuid := auth.uid();
  v_prod public.productos%rowtype;
  v_mov bigint;
begin
  if not public.es_admin() then
    raise exception 'Solo el administrador puede ajustar el inventario' using errcode = '42501';
  end if;
  if p_motivo is null or btrim(p_motivo) = '' then raise exception 'Indique el motivo del ajuste'; end if;
  if p_stock_nuevo is null or p_stock_nuevo < 0 then raise exception 'El stock no puede ser negativo'; end if;

  select * into v_prod from public.productos where id = p_producto_id for update;
  if not found then raise exception 'Producto no encontrado'; end if;
  if v_prod.stock_actual = p_stock_nuevo then raise exception 'El stock no cambió'; end if;

  update public.productos set stock_actual = p_stock_nuevo where id = v_prod.id;

  insert into public.movimientos_inventario
    (producto_id, usuario_id, tipo, cantidad, stock_anterior, stock_resultante, referencia_tipo, observaciones)
  values (v_prod.id, v_usuario, 'ajuste', abs(p_stock_nuevo - v_prod.stock_actual),
          v_prod.stock_actual, p_stock_nuevo, 'ajuste', btrim(p_motivo))
  returning id into v_mov;

  update public.movimientos_inventario set referencia_id = v_mov where id = v_mov;
  return v_mov;
end;
$$;

-- Permisos de ejecucion -------------------------------------------------------
revoke execute on function public.registrar_entrada(bigint, jsonb, uuid, text) from public, anon;
revoke execute on function public.registrar_venta(jsonb, uuid, text) from public, anon;
revoke execute on function public.registrar_ajuste(bigint, integer, text) from public, anon;
revoke execute on function public.crear_perfil() from public, anon, authenticated;
grant execute on function public.registrar_entrada(bigint, jsonb, uuid, text) to authenticated;
grant execute on function public.registrar_venta(jsonb, uuid, text) to authenticated;
grant execute on function public.registrar_ajuste(bigint, integer, text) to authenticated;
grant execute on function public.es_activo() to authenticated;
grant execute on function public.es_admin() to authenticated;
