# Base de datos (Supabase)

## Cómo aplicarla (una sola vez)

1. En https://supabase.com crea el proyecto `inventario-cloud` (plan Free).
2. Abre **SQL Editor** y ejecuta, en este orden, el contenido de:
   1. `migrations/001_tablas.sql`
   2. `migrations/002_funciones.sql`
   3. `migrations/003_seguridad_rls.sql`
3. En **Authentication → Users → Add user** crea (con "Auto Confirm User"):
   - `admin@inventario.test`
   - `empleado@inventario.test`
   Usa contraseñas de prueba, nunca personales.
4. Ejecuta `seed.sql` (asigna roles y carga 3 categorías, 2 proveedores y 12 productos).
5. Ejecuta `tests/pruebas.sql`: sale un mensaje rojo "PRUEBAS TERMINADAS" con las 7 pruebas en **OK**. Es intencional: así se deshacen los cambios de la prueba.

## Datos que necesita la app

En **Project Settings → API** copia la **Project URL** y la clave **anon public**.
No copies la `service_role` a ningún archivo del proyecto.
