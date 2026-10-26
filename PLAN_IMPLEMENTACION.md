# Inventario Cloud: plan de implementación por fases

Este documento es la guía completa para construir el sistema. Está escrito para que un asistente de IA (o una persona) lo ejecute **fase por fase**, sin necesitar otra conversación. Antes de empezar, lee también `README.md` y la carpeta `docs/`.

---

## 0. Instrucciones para el asistente de IA

1. Trabaja **una fase a la vez**, en orden. No empieces la siguiente hasta cumplir todos los **criterios de aceptación** de la actual y hasta que el usuario lo confirme.
2. Al terminar cada tarea, marca su casilla `- [x]` en este archivo y anota debajo cualquier decisión o desviación.
3. Todo el texto visible para el usuario va en **español** (Bolivia). La moneda es el **boliviano (Bs)**.
4. **Costo cero:** usa solo herramientas y planes gratuitos. No actives nada que pida tarjeta.
5. **Seguridad:**
   - La app Flutter solo usa la **URL del proyecto** y la **clave pública `anon`** de Supabase.
   - Nunca pongas la clave `service_role` ni la contraseña de la base en el código, en Git ni en este archivo.
   - Nunca subas a Git archivos `.env`, claves ni respaldos con datos.
6. Pide al usuario lo que no puedes obtener tú: la URL y la clave `anon` de Supabase, y los correos de las cuentas de prueba.
7. El diseño visual de referencia está en `diseno/`. Respétalo (ver sección 3).
8. Si algo de este plan es imposible o contradice la documentación oficial actual de Flutter o Supabase, sigue la documentación oficial y anota el cambio aquí.
9. Usa siempre la versión estable más reciente de Flutter y de cada paquete.

---

## 1. Resumen del sistema

| Aspecto | Decisión |
| --- | --- |
| Nombre | Inventario Cloud |
| Qué es | Sistema de inventario para **una** tienda: productos, categorías, proveedores, entradas, ventas, alertas de bajo stock e historial |
| Clientes | App **Android** (archivo APK, sin Google Play) y app **web** (navegador de PC), ambas con **un solo código Flutter** |
| Backend | **Supabase Free**: Auth + API REST/RPC + PostgreSQL. Sin servidor propio |
| Roles | `administrador` (todo) y `empleado` (consulta productos, registra ventas y ve sus propios movimientos) |
| Seguridad | RLS en todas las tablas; el stock solo cambia a través de 3 funciones de PostgreSQL |
| Sincronización | Cada pantalla vuelve a consultar al abrirse y al deslizar o pulsar "Actualizar". Realtime es opcional |
| Hosting web | Netlify o Cloudflare Pages, plan gratuito (GitHub Pages solo si el repositorio es público) |
| Presupuesto | Bs 0 |

### Fuera del alcance

- Google Play o App Store.
- App para iPhone.
- Facturación electrónica e impuestos.
- Pagos en línea.
- Varias sucursales.
- Integración contable.

---

## 2. Estructura del repositorio

```text
sistema-inventario-nube/
├─ README.md
├─ PLAN_IMPLEMENTACION.md        ← este archivo
├─ docs/                         ← requisitos, BD, pantallas, pruebas
├─ diseno/                       ← diseño de referencia (NO se despliega)
│  ├─ DESIGN.md                  ← sistema de diseño (colores, tipografía, componentes)
│  ├─ template/                  ← prototipo navegable HTML/CSS/JS (abrir index.html)
│  └─ pantallas/                 ← capturas: panel, productos, venta, logo
├─ informe/                      ← informe académico en LaTeX
├─ supabase/
│  ├─ migrations/
│  │  ├─ 001_tablas.sql
│  │  ├─ 002_funciones.sql
│  │  └─ 003_seguridad_rls.sql
│  ├─ seed.sql                   ← datos ficticios
│  └─ tests/pruebas.sql          ← pruebas manuales de stock y permisos
└─ app/                          ← proyecto Flutter (android + web)
   ├─ assets/
   │  ├─ fonts/                  ← HankenGrotesk y JetBrainsMono (.ttf)
   │  └─ images/logo.png         ← copiar de diseno/pantallas/logo_inventario_cloud.png
   └─ lib/
      ├─ main.dart
      ├─ core/
      │  ├─ config.dart           ← lee SUPABASE_URL y SUPABASE_ANON_KEY de --dart-define
      │  ├─ supabase.dart         ← inicialización del cliente
      │  ├─ router.dart           ← go_router + guardas por rol
      │  ├─ theme.dart            ← colores, tipografía, formas (sección 3)
      │  └─ formatters.dart       ← moneda Bs, fechas, folios
      ├─ shared/
      │  ├─ layout/app_shell.dart ← sidebar / drawer / bottom nav según ancho
      │  ├─ widgets/              ← StatCard, StatusBadge, DataTableCard, PageHeader,
      │  │                           SearchField, QuantityStepper, EmptyState, ConfirmDialog
      │  └─ validators.dart
      └─ features/
         ├─ auth/        (data/ + presentation/)
         ├─ panel/
         ├─ productos/
         ├─ categorias/
         ├─ proveedores/
         ├─ entradas/
         ├─ ventas/
         ├─ bajo_stock/
         ├─ historial/
         └─ usuarios/
```

Cada módulo de `features/` tiene `data/`, con un repositorio que habla con Supabase y sus modelos, y `presentation/`, con pantallas y widgets.

---

## 3. Guía de diseño (tomada de `diseno/`)

Abre `diseno/template/index.html` en un navegador: es la referencia visual y de navegación. Replica su aspecto en Flutter.

### 3.1 Colores (de `diseno/template/styles.css`)

| Token | Hex | Uso |
| --- | --- | --- |
| primary | `#12358B` | Ítem activo del menú, botón primario, íconos de estadística |
| primaryDark | `#08296F` | Hover del botón primario, marca |
| secondary | `#2F75E8` | Enlaces, foco de campos |
| brandCyan | `#1FAAC7` | Texto "Cloud" del logo y degradado de la marca |
| surface | `#F6F8FD` | Fondo de la app |
| card | `#FFFFFF` | Tarjetas y tablas |
| softBlue | `#EAF1FF` | Buscador, botón secundario, hover del menú, tarjeta de usuario |
| border | `#DDE5F2` | Divisores y bordes |
| text | `#122033` | Texto principal |
| muted | `#677386` | Texto secundario |
| success / successBg | `#087A55` / `#E1F6ED` | "En stock", entradas, confirmaciones |
| warning / warningBg | `#9A5B00` / `#FFF1CB` | "Stock bajo", ventas en el historial |
| danger / dangerBg | `#C3262E` / `#FFE4E4` | "Agotado", ajustes, errores |

### 3.2 Tipografía

- **Hanken Grotesk** (400/500/600/700) para todo el texto.
- **JetBrains Mono** (500) para códigos/SKU, cantidades, montos y folios.
- Empaqueta las fuentes como assets (`assets/fonts/`) para que el APK funcione sin descargarlas.
- Títulos de página: 26–34 px en negrita. Texto normal: 14–16 px.

### 3.3 Formas y espaciado

- Tarjetas: radio **16**, borde `#EDF0F6` y sombra suave `0 8 24 rgba(20,48,100,0.08)`.
- Botones: radio **10** y alto mínimo **42**.
- Buscador e insignias: forma de píldora (radio 999).
- Espaciado en múltiplos de **8**. Márgenes: 30 en escritorio y 16 en móvil.

### 3.4 Diseño adaptable (mismos cortes que el prototipo)

| Ancho | Navegación |
| --- | --- |
| ≥ 980 px | **Sidebar fijo de 264 px**: logo arriba, 9 ítems en el centro, tarjeta del usuario (iniciales, nombre y rol) abajo. Barra superior de 68 px con buscador global, campana y avatar |
| 680–979 px | Sidebar oculto en un `Drawer` con botón ☰ en la barra superior |
| < 680 px | **Barra inferior** con Panel, Productos y Ventas, más "Más", que abre el menú completo. Las tablas se muestran como **tarjetas** |

### 3.5 Menú (orden e íconos de Material sugeridos)

| Ítem | Ruta | Ícono | Visible para |
| --- | --- | --- | --- |
| Panel | `/panel` | `dashboard` | Todos |
| Productos | `/productos` | `inventory_2` | Todos |
| Categorías | `/categorias` | `category` | Administrador |
| Proveedores | `/proveedores` | `local_shipping` | Administrador |
| Entradas | `/entradas` | `move_to_inbox` | Administrador |
| Ventas | `/ventas` | `shopping_cart` | Todos |
| Bajo stock | `/bajo-stock` | `warning_amber` | Todos |
| Historial | `/historial` | `history` | Todos (el empleado solo ve lo suyo) |
| Usuarios | `/usuarios` | `group` | Administrador |

### 3.6 Componentes

- **PageHeader:** título, descripción gris y botones de acción a la derecha (en móvil, debajo).
- **StatCard:** ícono en un cuadro `softBlue`, etiqueta gris y valor grande.
- **StatusBadge:** píldora de color según el estado del stock:
  - `stock_actual == 0` → **Agotado** (danger).
  - `stock_actual <= stock_minimo` → **Stock bajo** (warning).
  - Otro caso → **En stock** (success).
- **DataTableCard:**
  - Escritorio: tabla dentro de una tarjeta, con números alineados a la derecha y en JetBrains Mono.
  - Móvil: lista de tarjetas con el nombre, el código, la insignia de estado arriba a la derecha y el precio y las existencias abajo.
- **Formularios:** en un **diálogo modal** en escritorio y en una pantalla o hoja inferior en móvil. La etiqueta va siempre visible encima del campo y el foco tiene borde `secondary` de 2 px. Botones "Cancelar" (secundario) y "Guardar" (primario).
- **Mensajes:** `SnackBar` (el "toast" del prototipo) para éxito o error; los errores van en lenguaje claro.
- **Diferencias con el prototipo:**
  - Se quita la franja "PROTOTIPO VISUAL".
  - La moneda es **Bs**, no MXN.
  - No hay línea de "Impuestos".
  - Los datos salen de Supabase, no de `app.js`.

### 3.7 Contenido de cada pantalla (según el prototipo)

- **Panel:** encabezado "Resumen general" con los botones "Registrar entrada" (solo administrador) y "Registrar venta".
  - 4 StatCards: Total de productos (activos), Ventas del día (suma de las ventas de hoy), Entradas de hoy y Bajo stock.
  - Tarjeta "Ventas semanales": barras de los últimos 7 días.
  - Tarjeta "Alertas de stock": 3 primeras, con enlace "Ver todo".
  - Tarjeta "Movimientos recientes": 3 últimos, con enlace "Ver historial".
- **Productos:**
  - Barra de herramientas: búsqueda por código o nombre, filtro de categoría y filtro de estado.
  - Columnas: Código, Producto, Categoría, Precio, Stock, Mín., Estado y Acciones (editar o desactivar, solo administrador).
  - Botón "Agregar producto" (solo administrador).
- **Categorías:** Nombre, Descripción, Productos (conteo), Estado y Acciones.
- **Proveedores:** Nombre, Teléfono, Correo, Estado y Acciones.
- **Entradas:**
  - Lista con Folio (`ENT-0001`), Proveedor, Fecha, Total, Usuario y Estado.
  - Botón "Nueva entrada": formulario con proveedor y varias filas de producto, cantidad y costo unitario, el total calculado y la confirmación.
- **Ventas (registrar venta):**
  - Buscador de producto o SKU, más el botón "Escanear" (opcional, fase 6).
  - Carrito con el producto, su código, la insignia "En stock: N", el subtotal y un selector − / + limitado al stock.
  - Panel "Resumen de venta" (Productos, Subtotal, Total) con el botón "Confirmar venta" y un diálogo de confirmación.
- **Bajo stock:** Producto, Código, Existencias, Mínimo, Estado y la acción "Registrar entrada" (solo administrador).
- **Historial:**
  - Columnas: Fecha, Producto, Tipo (insignia: Entrada verde, Venta amarilla, Ajuste roja), Cantidad (+/−) y Usuario.
  - Filtros por tipo y por rango de fechas.
- **Usuarios:** Nombre, Correo, Rol y Estado, más una acción para editar el rol y activar o desactivar.
- **Inicio de sesión** (no está en el prototipo; diséñalo con el mismo estilo):
  - Tarjeta centrada sobre fondo `surface`, con el logo (`assets/images/logo.png`).
  - Campos de correo y contraseña, botón "Ingresar" y enlace "¿Olvidaste tu contraseña?".

---

## 4. Modelo de datos (referencia para la Fase 1)

Hay 9 tablas propias más `auth.users` de Supabase. Los nombres van en español y en `snake_case`.

```sql
-- 001_tablas.sql
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
```

### 4.1 Funciones (002_funciones.sql), comportamiento obligatorio

Todas las funciones de esta sección comparten estas reglas:
- Se declaran `security definer set search_path = public`.
- Se revoca el permiso de ejecución a `public` y a `anon`, y se otorga a `authenticated`.
- Cualquier error lanza una excepción con un mensaje en español y deshace toda la operación.

| Función | Qué hace |
| --- | --- |
| `es_activo() returns boolean` | `true` si `auth.uid()` tiene un perfil con `activo = true` |
| `es_admin() returns boolean` | `true` si además tiene `rol = 'administrador'` |
| `crear_perfil()` + trigger `after insert on auth.users` | Inserta el perfil con `nombre = raw_user_meta_data->>'nombre'` (o la parte del correo antes de la @) y `rol = 'empleado'` |
| vista `productos_bajo_stock` (`with (security_invoker = true)`) | Productos activos con `stock_actual <= stock_minimo`, con el nombre de su categoría |
| `registrar_entrada(p_proveedor_id bigint, p_items jsonb, p_clave uuid, p_observaciones text default null) returns bigint` | Ver los pasos abajo. `p_items` = `[{"producto_id":1,"cantidad":10,"costo_unitario":5.5}, ...]` |
| `registrar_venta(p_items jsonb, p_clave uuid, p_observaciones text default null) returns bigint` | Ver los pasos abajo. `p_items` = `[{"producto_id":1,"cantidad":2}, ...]` |
| `registrar_ajuste(p_producto_id bigint, p_stock_nuevo integer, p_motivo text) returns bigint` | Ver los pasos abajo |

**`registrar_entrada`:**
1. Exige `es_admin()`.
2. Si ya existe una entrada con `p_clave`, devuelve su `id` sin hacer nada más.
3. Valida que el proveedor esté activo y que haya al menos un ítem.
4. Por cada ítem: bloquea el producto con `select ... for update`, valida que esté activo y que la cantidad sea mayor que 0, inserta el detalle, suma el stock y crea un movimiento `entrada` con el stock anterior y el resultante.
5. Al final guarda el total (suma de cantidad × costo) y devuelve el `id`.

**`registrar_venta`:**
1. Exige `es_activo()`.
2. Si ya existe una venta con `p_clave`, devuelve su `id`.
3. Por cada ítem: bloquea el producto con `for update`. Si está inactivo o no tiene stock suficiente, lanza el error `'Stock insuficiente para <nombre>: disponible X, solicitado Y'` y **toda la venta se cancela**.
4. Toma el precio de la tabla `productos`, nunca del cliente.
5. Inserta el detalle, resta el stock, crea un movimiento `venta`, guarda el total y devuelve el `id`.

**`registrar_ajuste`:**
1. Exige `es_admin()`, un motivo no vacío, `p_stock_nuevo >= 0` y una diferencia distinta de 0.
2. Bloquea el producto y fija el stock.
3. Crea un movimiento `ajuste` con `cantidad = |diferencia|` y `observaciones = p_motivo`.

Implementación de referencia de `registrar_venta`. Las otras dos siguen el mismo patrón.

```sql
create or replace function public.registrar_venta(p_items jsonb, p_clave uuid, p_observaciones text default null)
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
  if found then return v_venta; end if;            -- reintento: no duplicar

  insert into public.ventas (usuario_id, total, observaciones, clave_operacion)
  values (v_usuario, 0, p_observaciones, p_clave) returning id into v_venta;

  for v_item in select * from jsonb_array_elements(p_items) loop
    v_cant := (v_item->>'cantidad')::integer;
    if v_cant is null or v_cant <= 0 then
      raise exception 'Cantidad inválida';
    end if;

    select * into v_prod from public.productos
     where id = (v_item->>'producto_id')::bigint for update;
    if not found or not v_prod.activo then
      raise exception 'Producto no disponible';
    end if;
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

revoke execute on function public.registrar_venta(jsonb, uuid, text) from public, anon;
grant execute on function public.registrar_venta(jsonb, uuid, text) to authenticated;
```

### 4.2 Seguridad RLS (003_seguridad_rls.sql)

Activa RLS en las 9 tablas. Las políticas son `to authenticated`. Si no hay política, la operación queda denegada.

| Tabla | SELECT | INSERT | UPDATE | DELETE |
| --- | --- | --- | --- | --- |
| perfiles | `id = auth.uid() or es_admin()` | ninguna (trigger) | `es_admin()` | ninguna |
| categorias, proveedores | `es_activo()` | `es_admin()` | `es_admin()` | ninguna (se desactivan) |
| productos | `es_activo()` | `es_admin()` | `es_admin()` | ninguna |
| entradas, detalle_entradas | `es_admin()` | ninguna (solo la función) | ninguna | ninguna |
| ventas | `es_admin() or (usuario_id = auth.uid() and es_activo())` | ninguna | ninguna | ninguna |
| detalle_ventas | `es_admin()` o pertenece a una venta propia | ninguna | ninguna | ninguna |
| movimientos_inventario | `es_admin() or (usuario_id = auth.uid() and es_activo())` | ninguna | ninguna | ninguna |

El stock no se puede editar directamente. Para eso se cambian los permisos por columna:

```sql
revoke insert, update on public.productos from authenticated, anon;
grant insert (codigo, nombre, descripcion, categoria_id, precio_venta, stock_minimo, activo) on public.productos to authenticated;
grant update (codigo, nombre, descripcion, categoria_id, precio_venta, stock_minimo, activo) on public.productos to authenticated;
```

El stock inicial de un producto nuevo siempre es 0 y solo sube con una **entrada** o un **ajuste**.

---

## 5. Fases

Cada fase indica su objetivo, sus tareas y sus criterios de aceptación. Las pruebas `CP-xx` están en la sección 6.

### Fase 0 · Preparación del entorno

**Objetivo:** dejar el repositorio y las herramientas listos.

- [ ] Inicializar Git en `sistema-inventario-nube/`, crear `.gitignore` (Flutter + `.env`, `*.key`, `respaldos/`, `app/build/`) y subir a GitHub.
- [ ] Ramas: `main` estable y una rama por función (`feature/...`).
- [ ] Verificar `flutter doctor` sin errores para Android y web (Chrome).
- [ ] Crear la cuenta gratuita de Supabase y el proyecto `inventario-cloud`. Anotar la región. **El usuario** debe pasar la URL y la clave `anon`.
- [ ] Crear la cuenta gratuita del hosting web (Netlify o Cloudflare Pages).
- [ ] Revisar `diseno/template/index.html` en el navegador y las capturas de `diseno/pantallas/`.

**Aceptación:** el repositorio existe en GitHub con la estructura de carpetas, `flutter doctor` está en verde y la URL y la clave `anon` están disponibles (fuera de Git).

### Fase 1 · Base de datos y seguridad

**Objetivo:** tener la base completa y protegida antes de escribir la app.

- [x] `supabase/migrations/001_tablas.sql` con el SQL de la sección 4.
- [x] `supabase/migrations/002_funciones.sql`: `es_activo`, `es_admin`, `crear_perfil` + trigger, la vista `productos_bajo_stock`, `registrar_entrada`, `registrar_venta` y `registrar_ajuste`, con sus `revoke`/`grant`.
- [x] `supabase/migrations/003_seguridad_rls.sql`: RLS, políticas y permisos por columna de la sección 4.2.
- [x] Ejecutar las 3 migraciones en orden. Puede ser en el **SQL Editor** del panel de Supabase, o con `supabase link` + `supabase db push` desde la CLI.
- [x] Crear dos usuarios en *Authentication → Users*: `admin@inventario.test` y `empleado@inventario.test`, con contraseñas de prueba que **no sean personales**. Luego, en el SQL Editor: `update perfiles set rol = 'administrador', nombre = 'Admin Usuario' where id = (select id from auth.users where email = 'admin@inventario.test');`
- [x] `supabase/seed.sql`, con datos ficticios en Bolivia:
  - 3 categorías (p. ej. Abarrotes, Bebidas, Limpieza).
  - 2 proveedores.
  - Al menos 10 productos.
  - Stock inicial cargado con movimientos `ajuste` de motivo "Inventario inicial", usando el `id` del administrador.
  - Al menos 1 producto con stock igual al mínimo y 1 agotado.
  - Como el SQL Editor no tiene `auth.uid()`, en el seed se inserta directamente; las funciones se prueban desde la app o con `set local role authenticated` + `set local request.jwt.claims`.
- [x] `supabase/tests/pruebas.sql`, con consultas para comprobar CP-06, CP-07, CP-08, CP-15, CP-16 y CP-17 simulando cada rol.
- [ ] Primer respaldo: `supabase db dump` (esquema) y `supabase db dump --data-only` en una carpeta `respaldos/` fuera de Git.

**Aceptación:**
- Las 9 tablas tienen RLS activo.
- Una venta mayor que el stock falla y no cambia nada.
- Un empleado no puede llamar a `registrar_entrada` ni modificar `stock_actual`.
- Un usuario inactivo no lee datos.

### Fase 2 · Base de la aplicación

**Objetivo:** app Flutter con inicio de sesión, roles, tema y navegación adaptable.

- [ ] `flutter create --platforms=android,web --org bo.umsa app`.
- [x] Paquetes: `supabase_flutter`, `go_router`, `intl`, `uuid`, `google_fonts`. (Decisión: sin `flutter_riverpod`; el estado de sesión usa `ChangeNotifier`, para mantenerse dentro de lo descrito en el informe.)
- [x] `core/config.dart`: leer `SUPABASE_URL` y `SUPABASE_ANON_KEY` con `String.fromEnvironment`. Para ejecutar: `flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`. Documentar el comando en `app/README.md` y crear un `app/dart_defines.example.json` sin valores reales.
- [x] `core/theme.dart` con los colores, las fuentes y las formas de la sección 3. Fuentes como assets.
- [x] `core/formatters.dart`:
  - Moneda: `NumberFormat.currency(locale: 'es', symbol: 'Bs ', decimalDigits: 2)`.
  - Fecha: `dd/MM/yyyy HH:mm`.
  - Folios: `ENT-0001` y `VEN-0001`.
- [x] `shared/layout/app_shell.dart` con los 3 diseños de la sección 3.4 y el menú de la 3.5, filtrado por rol.
- [x] Pantalla de inicio de sesión (sección 3.7), con errores claros ("Correo o contraseña incorrectos", "Sin conexión a Internet").
- [x] Al entrar: leer `perfiles` del usuario. Si `activo = false`, cerrar la sesión y avisar "Tu cuenta está desactivada".
- [x] Recuperación de contraseña con `resetPasswordForEmail`, redirigida a la URL web. En la web, al recibir el evento de recuperación, mostrar un formulario para la nueva contraseña.
- [x] Guardas de ruta en `go_router`: sin sesión → `/login`; empleado en una ruta de administrador → `/panel` con un aviso.
- [x] Panel con datos reales: las 4 StatCards. Los gráficos pueden quedar con un marcador hasta la Fase 4.
- [x] Cerrar sesión desde la tarjeta del usuario o el avatar.

**Aceptación:** CP-01, CP-02 y CP-03. La app corre en el emulador o celular Android y en Chrome, y se ve como el prototipo en los 3 anchos.

### Fase 3 · Catálogos y entradas

**Objetivo:** productos, categorías, proveedores y entradas funcionando.

- [x] Categorías: lista, alta, edición y desactivación (con confirmación). Validar el nombre obligatorio y único, mostrando el error de la base en español.
- [x] Proveedores: lista, alta, edición y desactivación. Validar el formato del correo.
- [x] Productos:
  - Tabla en escritorio y tarjetas en móvil, con búsqueda por código o nombre y filtros por categoría y estado.
  - Alta y edición sin campo de stock: el stock se muestra solo como lectura.
  - Desactivación.
  - Validaciones: código obligatorio y único, precio ≥ 0, mínimo ≥ 0 y categoría activa.
- [x] Buscador global de la barra superior: lleva a Productos con el texto ya aplicado.
- [x] Entradas:
  - Lista con folios.
  - "Nueva entrada" con proveedor, filas dinámicas de producto, cantidad y costo, el total calculado y la confirmación.
  - Generar un `uuid` como `p_clave` **al abrir el formulario** y llamar a `rpc('registrar_entrada')`.
  - Al terminar, mostrar un SnackBar y refrescar.
- [x] Ocultar los botones de administrador al empleado. RLS es la protección real; esto es solo visual.

**Aceptación:** CP-04, CP-05, CP-06, CP-12 y CP-14.

### Fase 4 · Ventas, alertas, historial, ajustes y usuarios

**Objetivo:** completar el flujo principal.

- [x] Registrar venta (diseño de `diseno/pantallas/registro_de_venta_m_vil.png`):
  - Buscar y agregar productos activos al carrito.
  - Selector de cantidad limitado al stock.
  - Resumen y confirmación.
  - `p_clave` generado al iniciar la venta y reutilizado en los reintentos. `rpc('registrar_venta')`.
  - Si falla por stock, mostrar el mensaje de la base y mantener el carrito.
  - Si la operación tiene éxito, vaciar el carrito y mostrar "Venta VEN-0001 registrada por Bs X".
- [x] Bajo stock: tabla a partir de la vista `productos_bajo_stock`, con el botón "Registrar entrada" (administrador), que abre el formulario con ese producto ya cargado.
- [x] Historial:
  - Tabla y tarjetas con filtros por tipo y por fechas.
  - Mostrar el nombre del usuario (join con `perfiles`) y la cantidad con signo: + entrada, − venta y, para el ajuste, el signo según `stock_resultante − stock_anterior`.
  - Paginación de 20 en 20.
- [x] Ajuste de inventario (administrador): desde el detalle del producto, con el stock real y el motivo → `rpc('registrar_ajuste')`.
- [x] Usuarios (administrador):
  - Lista de perfiles con la acción de cambiar el rol y activar o desactivar.
  - No permitir que el administrador se desactive a sí mismo.
  - Texto de ayuda: "Para crear una cuenta nueva, agrégala en Supabase → Authentication y luego asigna su rol aquí".
- [x] Panel completo:
  - Ventas semanales: suma por día de los últimos 7 días, en barras simples o con `fl_chart`.
  - Las 3 alertas de stock y los 3 movimientos recientes, con sus enlaces.
- [x] Sincronización: `RefreshIndicator` en móvil y botón "Actualizar" en escritorio en todas las listas, y recarga al volver a cada pantalla.

**Aceptación:** CP-07, CP-08, CP-09, CP-10, CP-11 y CP-13.

### Fase 5 · Pruebas, despliegue y entrega

**Objetivo:** dejar el prototipo listo para demostrar.

- [x] Pruebas unitarias (`flutter test`):
  - Regla de estado del stock.
  - Validadores.
  - Formato de moneda y folios.
  - Cálculo del total del carrito.
- [ ] Ejecutar CP-01 a CP-17 en Android y en web. Guardar evidencias (capturas) en `docs/evidencias/`.
- [ ] Revisar textos, mensajes de error, estados vacíos ("No se encontraron productos") y accesibilidad (insignias con texto, no solo color).
- [ ] `flutter build apk --release --dart-define=...` e instalar en al menos 2 celulares.
- [x] `flutter build web --release --dart-define=...` y publicar `app/build/web` en Netlify o Cloudflare Pages. Configurar la URL resultante en Supabase → Authentication → URL Configuration.
- [ ] Respaldo final y **prueba de recuperación**: crear un segundo proyecto gratuito, aplicar las migraciones, cargar el respaldo y verificar.
- [x] `app/README.md` con instrucciones para ejecutar, compilar y desplegar. Manual de usuario breve en `docs/manual-usuario.md`.
- [ ] Ensayar el guion de demostración (`docs/05-pruebas-y-demostracion.md`).

**Aceptación:**
- Todas las pruebas de prioridad alta pasan.
- Se demuestra la sincronización entre Android y PC.
- Hay un APK y una URL web funcionando.
- Ninguna clave está en Git.
- No se contrató nada de pago.

### Fase 6 · Mejoras opcionales (solo si las fases 0–5 están completas)

- [ ] Lectura de código de barras con `mobile_scanner` (botón "Escanear" en Ventas y en Productos).
- [ ] Exportar el historial o los productos a CSV y PDF.
- [ ] Gráfica de los productos más vendidos.
- [ ] Foto del producto en Supabase Storage (bucket con políticas RLS).
- [ ] Supabase Realtime en `productos`, para ver el stock en vivo.
- [ ] Edge Function para que el administrador cree cuentas desde la app (la `service_role` solo vive en la función).

---

## 6. Casos de prueba

| Código | Prueba | Resultado esperado | Fase |
| --- | --- | --- | --- |
| CP-01 | Iniciar sesión con credenciales válidas | Se abre el panel según el rol | 2 |
| CP-02 | Contraseña incorrecta | Mensaje "Correo o contraseña incorrectos" | 2 |
| CP-03 | Un empleado intenta abrir Usuarios | Acceso rechazado | 2 |
| CP-04 | Registrar un producto con código nuevo | Se guarda | 3 |
| CP-05 | Código de producto repetido | Se rechaza con un mensaje claro | 3 |
| CP-06 | Entrada de 10 unidades | El stock sube exactamente 10 | 3 |
| CP-07 | Vender 2 unidades disponibles | Se guarda y el stock baja 2 | 4 |
| CP-08 | Vender más de lo disponible | Se rechaza y el stock no cambia | 4 |
| CP-09 | Stock igual al mínimo | Aparece en Bajo stock | 4 |
| CP-10 | Historial después de una venta | Muestra el producto, la cantidad, el usuario y la fecha | 4 |
| CP-11 | Vender en Android y consultar en la PC | La PC muestra el stock actualizado al refrescar | 4 |
| CP-12 | Formulario incompleto | Se señalan los campos a corregir | 3 |
| CP-13 | Cortar la conexión y reintentar una venta | Error claro y sin venta duplicada | 4 |
| CP-14 | Desactivar un producto | Ya no se ofrece para ventas | 3 |
| CP-15 | Un empleado llama a `registrar_entrada` por la API | Rechazado | 1 |
| CP-16 | Editar `stock_actual` directamente por la API | Rechazado | 1 |
| CP-17 | Un usuario desactivado intenta leer datos | No recibe información | 1 |

---

## 7. Riesgos y cómo evitarlos

| Riesgo | Mitigación |
| --- | --- |
| Supabase Free pausa el proyecto tras 1 semana sin uso | Usarlo cada semana; entrar el día antes de la exposición |
| El plan gratuito no tiene respaldos automáticos | Migraciones en Git, respaldo semanal y una prueba de recuperación |
| Filtración de la clave `service_role` | Nunca en la app ni en Git; si se filtra, regenerarla en el panel |
| Dos ventas simultáneas del último producto | `for update` + `check (stock_actual >= 0)` |
| Venta duplicada por un reintento | `clave_operacion` única |
| Retraso de una fase | Recortar primero la Fase 6 |
| Falla de Internet en la demostración | Video y capturas de respaldo |

Límites del plan gratuito de Supabase (consultados el 21/10/2026 en https://supabase.com/pricing): 500 MB de base de datos, 1 GB de archivos, 5 GB de transferencia, 2 proyectos activos, sin respaldos automáticos y pausa tras 1 semana inactivo. Revísalos antes de empezar.

---

## 8. Registro de avance

Anota aquí al terminar cada fase: la fecha, quién la hizo, qué quedó pendiente y las decisiones tomadas.

| Fase | Fecha | Estado | Notas |
| --- | --- | --- | --- |
| 0 |  | Pendiente |  |
| 1 | 21/10/2026 | Aplicada en Supabase (ultbapzcumcwgdxamqwz) | 7/7 pruebas OK. Falta el primer respaldo |
| 2 | 21/10/2026 | Código escrito | Falta: `flutter create .` + `flutter pub get` y probar en Chrome y Android (no se pudo compilar en el entorno de Claude) |
| 3 | 21/10/2026 | Código escrito | Falta compilar y probar CP-04, 05, 06, 12 y 14 |
| 4 | 21/10/2026 | Código escrito | Falta compilar y probar CP-07 a CP-11 y CP-13. Gráfico semanal sin fl_chart (barras propias) |
| 5 | 21/10/2026 | Documentación y pruebas escritas | flutter test OK (15/15). Web publicada: https://melodic-melomakarona-8b8ae7.netlify.app (26/10/2026). Falta: ejecutar CP-01 a CP-17 (docs/resultados-pruebas.md), compilar APK, respaldo y prueba de recuperación (supabase/RESPALDO.md), ensayo |
| 6 |  | Opcional |  |
