-- INSTALAR TODO: tablas + funciones + seguridad. Pegar completo en el SQL Editor y pulsar Run (una sola vez).

-- 001: tablas, restricciones e indices
create table public.perfiles (
  id uuid primary key references auth.users(id) on delete cascade,
  nombre varchar(100) not null,
  rol varchar(20) not null default 'empleado' check (rol in ('administrador','empleado')),
  activo boolean not null default true,
  creado_en timestamptz not null default now()
);

create table public.categorias (
  id bigint generated always as identity primary key,
  nombre varchar(80) not null unique,
  descripcion text,
  activo boolean not null default true,
  creado_en timestamptz not null default now()
);

create table public.proveedores (
  id bigint generated always as identity primary key,
  nombre varchar(120) not null,
  telefono varchar(25),
  correo varchar(120),
  direccion text,
  activo boolean not null default true,
  creado_en timestamptz not null default now()
);

create table public.productos (
  id bigint generated always as identity primary key,
  codigo varchar(50) not null unique,
  nombre varchar(120) not null,
  descripcion text,
  categoria_id bigint not null references public.categorias(id),
  precio_venta numeric(12,2) not null check (precio_venta >= 0),
  stock_actual integer not null default 0 check (stock_actual >= 0),
  stock_minimo integer not null default 0 check (stock_minimo >= 0),
  activo boolean not null default true,
  creado_en timestamptz not null default now()
);

create table public.entradas (
  id bigint generated always as identity primary key,
  proveedor_id bigint not null references public.proveedores(id),
  usuario_id uuid not null references public.perfiles(id),
  total numeric(12,2) not null default 0 check (total >= 0),
  observaciones text,
  clave_operacion uuid not null unique,      -- evita duplicados al reintentar
  creado_en timestamptz not null default now()
);

create table public.detalle_entradas (
  id bigint generated always as identity primary key,
  entrada_id bigint not null references public.entradas(id) on delete cascade,
  producto_id bigint not null references public.productos(id),
  cantidad integer not null check (cantidad > 0),
  costo_unitario numeric(12,2) not null check (costo_unitario >= 0)
);

create table public.ventas (
  id bigint generated always as identity primary key,
  usuario_id uuid not null references public.perfiles(id),
  total numeric(12,2) not null default 0 check (total >= 0),
  observaciones text,
  clave_operacion uuid not null unique,
  creado_en timestamptz not null default now()
);

create table public.detalle_ventas (
  id bigint generated always as identity primary key,
  venta_id bigint not null references public.ventas(id) on delete cascade,
  producto_id bigint not null references public.productos(id),
  cantidad integer not null check (cantidad > 0),
  precio_unitario numeric(12,2) not null check (precio_unitario >= 0),
  subtotal numeric(12,2) not null check (subtotal >= 0)
);

create table public.movimientos_inventario (
  id bigint generated always as identity primary key,
  producto_id bigint not null references public.productos(id),
  usuario_id uuid not null references public.perfiles(id),
  tipo varchar(20) not null check (tipo in ('entrada','venta','ajuste')),
  cantidad integer not null check (cantidad > 0),   -- siempre positiva; el tipo y los stocks indican el efecto
  stock_anterior integer not null,
  stock_resultante integer not null check (stock_resultante >= 0),
  referencia_tipo varchar(20) not null check (referencia_tipo in ('entrada','venta','ajuste')),
  referencia_id bigint,
  observaciones text,
  creado_en timestamptz not null default now()
);

create index on public.productos (nombre);
create index on public.productos (categoria_id);
create index on public.entradas (creado_en);
create index on public.entradas (proveedor_id);
create index on public.detalle_entradas (entrada_id);
create index on public.ventas (creado_en);
create index on public.ventas (usuario_id);
create index on public.detalle_ventas (venta_id);
create index on public.movimientos_inventario (producto_id);
create index on public.movimientos_inventario (usuario_id);
create index on public.movimientos_inventario (creado_en);

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

-- 003: Row Level Security y permisos
-- Sin politica = operacion denegada. Las escrituras de stock solo ocurren
-- dentro de registrar_entrada, registrar_venta y registrar_ajuste.

alter table public.perfiles               enable row level security;
alter table public.categorias             enable row level security;
alter table public.proveedores            enable row level security;
alter table public.productos              enable row level security;
alter table public.entradas               enable row level security;
alter table public.detalle_entradas       enable row level security;
alter table public.ventas                 enable row level security;
alter table public.detalle_ventas         enable row level security;
alter table public.movimientos_inventario enable row level security;

-- El rol anonimo no toca ninguna tabla
revoke all on all tables in schema public from anon;

-- perfiles
create policy perfiles_leer on public.perfiles for select to authenticated
  using (id = auth.uid() or public.es_admin());
create policy perfiles_editar on public.perfiles for update to authenticated
  using (public.es_admin()) with check (public.es_admin());

-- categorias
create policy categorias_leer on public.categorias for select to authenticated
  using (public.es_activo());
create policy categorias_crear on public.categorias for insert to authenticated
  with check (public.es_admin());
create policy categorias_editar on public.categorias for update to authenticated
  using (public.es_admin()) with check (public.es_admin());

-- proveedores
create policy proveedores_leer on public.proveedores for select to authenticated
  using (public.es_activo());
create policy proveedores_crear on public.proveedores for insert to authenticated
  with check (public.es_admin());
create policy proveedores_editar on public.proveedores for update to authenticated
  using (public.es_admin()) with check (public.es_admin());

-- productos (el stock no se puede escribir directamente)
create policy productos_leer on public.productos for select to authenticated
  using (public.es_activo());
create policy productos_crear on public.productos for insert to authenticated
  with check (public.es_admin());
create policy productos_editar on public.productos for update to authenticated
  using (public.es_admin()) with check (public.es_admin());

revoke insert, update on public.productos from authenticated;
grant insert (codigo, nombre, descripcion, categoria_id, precio_venta, stock_minimo, activo)
  on public.productos to authenticated;
grant update (codigo, nombre, descripcion, categoria_id, precio_venta, stock_minimo, activo)
  on public.productos to authenticated;

-- perfiles: el administrador solo cambia nombre, rol y estado
revoke insert, update on public.perfiles from authenticated;
grant update (nombre, rol, activo) on public.perfiles to authenticated;

-- entradas (solo lectura para el administrador)
create policy entradas_leer on public.entradas for select to authenticated
  using (public.es_admin());
create policy detalle_entradas_leer on public.detalle_entradas for select to authenticated
  using (public.es_admin());

-- ventas (administrador todas; empleado las suyas)
create policy ventas_leer on public.ventas for select to authenticated
  using (public.es_admin() or (usuario_id = auth.uid() and public.es_activo()));
create policy detalle_ventas_leer on public.detalle_ventas for select to authenticated
  using (public.es_admin() or exists (
    select 1 from public.ventas v
    where v.id = venta_id and v.usuario_id = auth.uid() and public.es_activo()));

-- movimientos (administrador todos; empleado los suyos)
create policy movimientos_leer on public.movimientos_inventario for select to authenticated
  using (public.es_admin() or (usuario_id = auth.uid() and public.es_activo()));

-- Sin escrituras directas en tablas de operaciones
revoke insert, update, delete on public.entradas, public.detalle_entradas,
  public.ventas, public.detalle_ventas, public.movimientos_inventario from authenticated;
revoke delete on public.perfiles, public.categorias, public.proveedores, public.productos from authenticated;
