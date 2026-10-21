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
