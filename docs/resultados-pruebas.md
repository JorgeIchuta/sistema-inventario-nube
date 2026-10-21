# Resultados de las pruebas

Completa una fila por prueba. En "Evidencia" va el nombre de la captura guardada en `docs/evidencias/`.

| Código | Prueba | Resultado esperado | Android | Web | Evidencia | Fecha / responsable |
| --- | --- | --- | --- | --- | --- | --- |
| CP-01 | Iniciar sesión con credenciales válidas | Panel según el rol |  |  |  |  |
| CP-02 | Contraseña incorrecta | "Correo o contraseña incorrectos" |  |  |  |  |
| CP-03 | Empleado intenta abrir Usuarios | Acceso rechazado (vuelve al Panel) |  |  |  |  |
| CP-04 | Registrar producto con código nuevo | Se guarda |  |  |  |  |
| CP-05 | Código de producto repetido | Se rechaza con mensaje claro |  |  |  |  |
| CP-06 | Entrada de 10 unidades | Stock sube exactamente 10 |  |  |  |  |
| CP-07 | Vender 2 unidades disponibles | Se guarda y el stock baja 2 |  |  |  |  |
| CP-08 | Vender más de lo disponible | Se rechaza y el stock no cambia |  |  |  |  |
| CP-09 | Stock igual al mínimo | Aparece en Bajo stock |  |  |  |  |
| CP-10 | Historial tras una venta | Producto, cantidad, usuario y fecha |  |  |  |  |
| CP-11 | Vender en Android y consultar en PC | PC muestra el stock actualizado |  |  |  |  |
| CP-12 | Formulario incompleto | Se señalan los campos |  |  |  |  |
| CP-13 | Cortar conexión y reintentar venta | Error claro, sin venta duplicada |  |  |  |  |
| CP-14 | Desactivar un producto | Ya no aparece para ventas |  |  |  |  |
| CP-15 | Empleado llama a `registrar_entrada` | Rechazado (ver `supabase/tests/pruebas.sql`) | — | — |  |  |
| CP-16 | Editar `stock_actual` directamente | Rechazado (ver `supabase/tests/pruebas.sql`) | — | — |  |  |
| CP-17 | Usuario desactivado intenta leer datos | Sin datos / no puede ingresar |  |  |  |  |

## Pruebas automáticas

| Prueba | Comando | Resultado | Fecha |
| --- | --- | --- | --- |
| Unitarias de la app | `cd app` → `flutter test` |  |  |
| Base de datos (7 casos) | `supabase/tests/pruebas.sql` en el SQL Editor | OK en local (21/10/2026) |  |
| Recuperación de respaldo | `supabase/RESPALDO.md` |  |  |
