# Plan de implementación

Plan acordado el 21 de octubre de 2026 para implementar todo lo descrito en el README y en `docs/01` a `docs/05`. Versión completa (con diagramas): documento "Informe de planificación: Sistema de inventario multiplataforma en la nube" en Claude.

Estado: **pendiente de ejecutar**. Se avanza fase por fase; una fase termina solo cuando se cumple su criterio de salida.

## Decisiones tomadas

- Flutter (un solo código) para la web (celular y computadora desde el navegador); Supabase Free (Auth + API REST/RPC + PostgreSQL); costo $0.
- La app usa solo la URL y la clave pública (`anon`), pasadas con `--dart-define`. La clave `service_role` nunca va en la app ni en Git.
- El stock solo cambia mediante 3 funciones de PostgreSQL (`registrar_entrada`, `registrar_venta`, `registrar_ajuste`), cada una en una sola transacción.
- RLS activado en todas las tablas; la seguridad real está en la base.
- Sincronización: refrescar al abrir pantalla y al deslizar. Supabase Realtime queda como mejora opcional.
- Alta de usuarios en la v1: el administrador crea la cuenta desde el panel de Supabase y asigna el rol en la app. Opcional: Edge Function para crearlas desde la app.
- Web publicada en Netlify o Cloudflare Pages (GitHub Pages gratis solo sirve si el repositorio es público).

## Ajustes al diseño original de la base de datos

- Columna `clave_operacion uuid unique` en `entradas` y `ventas` (evita duplicados al reintentar; cubre CP-13).
- Revocar `UPDATE (stock_actual)` en `productos` al rol `authenticated`.
- Funciones `SECURITY DEFINER` con `search_path` fijo y validación de `auth.uid()` y del rol.
- `registrar_venta`: `SELECT ... FOR UPDATE` por producto, rechaza toda la venta si falta stock o el producto está inactivo, toma el precio de la tabla.
- Función auxiliar `es_admin()`; trigger que crea `perfiles` (rol `empleado`) al registrarse un usuario; vista `productos_bajo_stock` (`stock_actual <= stock_minimo`, solo activos).
- Índices: `productos.codigo`, `productos.nombre`, `creado_en` de entradas/ventas/movimientos y todas las FK.

## Políticas RLS

| Tabla | Leer | Crear | Modificar | Borrar |
| --- | --- | --- | --- | --- |
| perfiles | Propio; admin todos | Trigger | Admin (rol, activo) | Nadie |
| categorias, proveedores | Autenticados | Admin | Admin | Nadie (desactivar) |
| productos | Autenticados | Admin | Admin, excepto `stock_actual` | Nadie (desactivar) |
| entradas, detalle_entradas | Admin | Solo `registrar_entrada` | Nadie | Nadie |
| ventas, detalle_ventas | Admin todas; empleado las suyas | Solo `registrar_venta` | Nadie | Nadie |
| movimientos_inventario | Admin todos; empleado los suyos | Solo las 3 funciones | Nadie | Nadie |

Un perfil con `activo = false` no pasa ninguna política.

## Estructura del repositorio

```text
sistema-inventario-nube/
├─ README.md, docs/
├─ informe/              informe en LaTeX
├─ supabase/
│  ├─ migrations/        tablas, funciones, RLS (SQL)
│  └─ seed.sql           datos ficticios
└─ app/                  proyecto Flutter (android + web)
   └─ lib/
      ├─ main.dart
      ├─ core/           config, cliente Supabase, rutas, tema
      ├─ shared/         widgets, validadores, layout adaptable
      └─ features/       auth, panel, productos, categorias, proveedores,
                         entradas, ventas, bajo_stock, historial, usuarios
                         (cada uno con data/ y presentation/)
```

Paquetes: `supabase_flutter`, `go_router`, `flutter_riverpod`, `intl`, `uuid`. Opcionales: `mobile_scanner`, `image_picker`, `fl_chart`, `csv`, `pdf`.

## Fases

### Fase 0 · Preparación (semana 1)
- [ ] Aprobar alcance, roles, reglas y requisitos
- [ ] Repositorio GitHub con estructura, `.gitignore` (`.env`, claves, respaldos) y ramas por función
- [ ] Cuentas gratuitas: Supabase, GitHub, hosting web
- [ ] Instalar Flutter, Android Studio, VS Code; `flutter doctor` sin errores
- [ ] Bocetos de las 10 pantallas (celular y PC)

Salida: todos compilan un Flutter de prueba en Android y web.

### Fase 1 · Base de datos y seguridad (semana 2)
- [ ] Crear proyecto Supabase Free
- [ ] Migración 1: 9 tablas, CHECK, UNIQUE, FK, índices, `clave_operacion`
- [ ] Migración 2: `es_admin()`, trigger de perfiles, vista `productos_bajo_stock`, `registrar_entrada`, `registrar_venta`, `registrar_ajuste`
- [ ] Migración 3: RLS + políticas; revocar edición de `stock_actual`
- [ ] `seed.sql`: 1 admin, 1 empleado, 3 categorías, 2 proveedores, 10 productos
- [ ] Probar en editor SQL: entrada, venta, venta sin stock, llamada como empleado
- [ ] Primer respaldo manual (`supabase db dump`)

Salida: pruebas SQL de stock y permisos pasan (CP-15 a CP-17).

### Fase 2 · Base de la aplicación (semana 3)
- [ ] `flutter create --platforms=android,web app`
- [ ] Configurar `supabase_flutter` con `--dart-define`, tema y layout adaptable (corte en 600 px)
- [ ] Login, logout y recuperación de contraseña
- [ ] Leer perfil y proteger rutas por rol con `go_router`
- [ ] Panel principal con total de productos y conteo de bajo stock

Salida: CP-01 a CP-03.

### Fase 3 · Catálogos y entradas (semana 4)
- [ ] Categorías y proveedores: lista, alta, edición, desactivación
- [ ] Productos: búsqueda por nombre o código, alta, edición, desactivación, validaciones
- [ ] Nueva entrada: proveedor, varios productos, cantidades, costos → `registrar_entrada`

Salida: CP-04 a CP-06, CP-12, CP-14.

### Fase 4 · Ventas, alertas, historial y usuarios (semana 5)
- [ ] Nueva venta: carrito, total, confirmación, `clave_operacion` → `registrar_venta`; mostrar qué producto no tiene stock
- [ ] Pantalla Bajo stock y aviso en el panel
- [ ] Historial con filtros por tipo y fecha (empleado solo lo suyo)
- [ ] Ajuste de inventario (admin)
- [ ] Pantalla Usuarios: rol y activo/inactivo
- [ ] Refrescar al abrir y al deslizar

Salida: CP-07 a CP-11 y CP-13.

### Fase 5 · Pruebas y entrega (semana 6)
- [ ] Ejecutar CP-01 a CP-17 y guardar evidencias
- [ ] Corregir errores y textos
- Sin APK (decisión del equipo): el celular usa la versión web.
- [ ] `flutter build web` y publicar
- [ ] Respaldo final y prueba de recuperación en un segundo proyecto
- [ ] Manual breve, diapositivas, ensayo del guion de demostración

### Fase opcional (solo si las fases 0–4 están listas)
1. Código de barras con `mobile_scanner`
2. Filtros avanzados por fecha
3. Exportar CSV o PDF
4. Gráfica de más vendidos
5. Fotos en Supabase Storage
6. Realtime y alta de usuarios con Edge Function

## Casos de prueba agregados (además de CP-01 a CP-14 de `docs/05`)

| Código | Prueba | Resultado esperado |
| --- | --- | --- |
| CP-15 | Empleado llama a `registrar_entrada` por la API | Rechazado |
| CP-16 | Usuario intenta editar `stock_actual` directamente | Rechazado por la base |
| CP-17 | Usuario desactivado intenta consultar datos | No recibe información |

## Riesgos principales

| Riesgo | Mitigación |
| --- | --- |
| Proyecto Supabase pausado tras 1 semana sin uso | Uso semanal; revisar el día antes de exponer |
| Sin respaldos automáticos en plan gratuito | Migraciones en Git + respaldo semanal + prueba de recuperación |
| Filtración de `service_role` | Nunca en Flutter ni Git; regenerar si se filtra |
| Ventas simultáneas del último producto | `FOR UPDATE` + `CHECK (stock_actual >= 0)` |
| Reintento por mala conexión | `clave_operacion` única |
| Retraso de una fase | Recortar opcionales primero |

Límites del plan gratuito de Supabase (consultados el 21/10/2026 en https://supabase.com/pricing): 500 MB de base de datos, 1 GB de archivos, 5 GB de transferencia, 2 proyectos activos, sin respaldos automáticos, pausa tras 1 semana inactivo.
