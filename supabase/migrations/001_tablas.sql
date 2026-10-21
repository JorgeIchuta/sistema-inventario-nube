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
