# Plan de pruebas y demostración

## Casos de prueba principales

| Código | Prueba | Resultado esperado |
|---|---|---|
| CP-01 | Iniciar sesión con credenciales válidas | Se abre el panel correspondiente al rol |
| CP-02 | Iniciar sesión con contraseña incorrecta | Se informa que las credenciales no son válidas |
| CP-03 | Empleado intenta administrar usuarios | El acceso es rechazado |
| CP-04 | Registrar un producto con código nuevo | El producto se guarda correctamente |
| CP-05 | Registrar un código de producto repetido | El sistema rechaza el registro |
| CP-06 | Registrar una entrada de 10 unidades | El stock aumenta exactamente 10 unidades |
| CP-07 | Vender 2 unidades disponibles | Se guarda la venta y el stock disminuye 2 |
| CP-08 | Intentar vender más unidades de las disponibles | La venta se rechaza y el stock no cambia |
| CP-09 | Dejar el stock igual al mínimo | El producto aparece en bajo stock |
| CP-10 | Consultar el historial después de una venta | Aparece el producto, cantidad, usuario y fecha |
| CP-11 | Registrar una venta desde Android y consultar desde PC | La computadora muestra el stock actualizado |
| CP-12 | Enviar un formulario con datos incompletos | Se muestran los campos que deben corregirse |
| CP-13 | Perder temporalmente la conexión | Se muestra un error y no se duplica la operación |
| CP-14 | Desactivar un producto | Ya no se ofrece para nuevas ventas |

## Evidencias que se deben guardar

- Capturas de las tablas y relaciones en Supabase.
- Capturas del inicio de sesión con ambos roles.
- Evidencia de funcionamiento en celular y computadora.
- Resultado de cada caso de prueba.
- Capturas antes y después de una entrada y una venta.
- Evidencia de una operación rechazada por stock insuficiente.
- Archivo APK final.
- Respaldo manual del esquema y datos ficticios.

## Datos para la demostración

Preparar antes de exponer:

- Un usuario administrador y un empleado.
- Tres categorías.
- Dos proveedores.
- Al menos diez productos.
- Un producto con stock suficiente.
- Un producto cerca de su stock mínimo.
- Entradas, ventas y movimientos históricos ficticios.

Nunca se deben utilizar contraseñas personales ni información real de clientes o proveedores.

## Guion de demostración

1. Abrir la aplicación web en una computadora e iniciar sesión como administrador.
2. Mostrar productos, categorías, proveedores y existencias actuales.
3. Registrar una entrada de mercancía y comprobar que el stock aumenta.
4. Abrir la aplicación Android e iniciar sesión como empleado.
5. Registrar una venta desde el celular.
6. Actualizar la consulta en la computadora y mostrar que el stock se sincronizó.
7. Realizar otra venta para que el producto alcance el stock mínimo.
8. Mostrar la alerta de bajo stock.
9. Intentar vender más unidades que las disponibles y demostrar que el sistema lo impide.
10. Consultar el historial y señalar usuario, fecha, cantidad y tipo de movimiento.
11. Explicar brevemente que Flutter, Supabase Free y PostgreSQL permiten realizar el prototipo con costo cero.

## Lista previa a la exposición

- Confirmar que el proyecto gratuito de Supabase no esté pausado.
- Probar la conexión a Internet disponible.
- Instalar y abrir el APK antes de la presentación.
- Mantener abierta la versión web en la computadora.
- Verificar las cuentas y datos ficticios.
- Realizar un respaldo manual.
- Tener capturas o un video corto como alternativa ante fallas de Internet.
- No mostrar claves, contraseñas ni paneles con información sensible.

## Condición de aprobación del prototipo

El prototipo estará listo cuando todas las pruebas de prioridad alta funcionen, se demuestre la sincronización entre Android y PC, se protejan las operaciones por rol y no sea necesario contratar ningún servicio de pago.
