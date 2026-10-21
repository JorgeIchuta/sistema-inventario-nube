# Manual de usuario: Inventario Cloud

Inventario Cloud funciona igual en el **celular Android** (app instalada con el archivo APK) y en la **computadora** (navegador Chrome, Edge o Firefox). Los datos son los mismos en todos los dispositivos.

## 1. Ingresar

1. Abre la app o la página web.
2. Escribe tu **correo** y tu **contraseña**, y pulsa **Ingresar**.
3. Si olvidaste la contraseña, pulsa **¿Olvidaste tu contraseña?**: recibirás un correo con un enlace para crear una nueva.

Para salir, pulsa tu avatar (arriba a la derecha) → **Cerrar sesión**, o el ícono de salida en la tarjeta de usuario del menú.

## 2. Qué puede hacer cada rol

| Módulo | Administrador | Empleado |
| --- | --- | --- |
| Panel | Sí | Sí (con sus propias ventas) |
| Productos | Consultar, agregar, editar, desactivar y ajustar | Solo consultar |
| Categorías y Proveedores | Sí | No |
| Entradas | Sí | No |
| Ventas | Sí | Sí |
| Bajo stock | Sí, con el botón "Registrar entrada" | Solo consultar |
| Historial | Todos los movimientos | Solo los suyos |
| Usuarios | Sí | No |

## 3. Navegación

- **Computadora:** menú lateral a la izquierda y buscador de productos arriba.
- **Celular:** barra inferior con Panel, Productos y Ventas; **Más** abre el menú completo.
- Para **actualizar** los datos de una lista, desliza hacia abajo (celular) o vuelve a abrir la pantalla.

## 4. Tareas frecuentes

### Registrar un producto nuevo (administrador)
1. **Productos → Agregar producto.**
2. Llena el código (único), el nombre, la categoría, el precio de venta en Bs y el stock mínimo.
3. **Guardar.** El producto empieza con stock 0; para cargar existencias, registra una entrada.

### Registrar una entrada de mercadería (administrador)
1. **Entradas → Nueva entrada.**
2. Elige el proveedor.
3. Agrega cada producto con su cantidad y su costo unitario. **Agregar producto** suma más filas.
4. Revisa el total y pulsa **Confirmar entrada.** El stock sube automáticamente.

### Registrar una venta
1. **Ventas.**
2. Escribe el nombre o el código del producto y tócalo para agregarlo.
3. Ajusta la cantidad con **−** y **+** (no puede superar el stock).
4. Revisa el total y pulsa **Confirmar venta** → **Confirmar venta.**
5. Si no hay stock suficiente, el sistema rechaza la venta y te indica qué producto falta; el carrito se conserva.

### Atender productos con bajo stock
- El **Panel** muestra cuántos productos están en el mínimo o agotados.
- En **Bajo stock**, el administrador pulsa **Registrar entrada** junto al producto.

### Corregir el stock después de un conteo físico (administrador)
1. **Productos** → botón de ajuste (ícono de controles) en la fila del producto.
2. Escribe el stock real y el motivo (por ejemplo, "producto dañado").
3. **Registrar ajuste.** El cambio queda en el historial.

### Consultar el historial
- **Historial** muestra fecha, producto, tipo (Entrada, Venta o Ajuste), cantidad, stock final y usuario.
- Filtra por **Tipo** o por **rango de fechas**. **Cargar más** muestra los movimientos anteriores.

### Administrar usuarios (administrador)
1. Crea la cuenta en **Supabase → Authentication → Users → Add user**.
2. En la app, en **Usuarios**, la cuenta aparece como Empleado. Pulsa editar para cambiar su nombre o su rol.
3. Para quitar el acceso a alguien, desactívalo; no puedes desactivar tu propia cuenta.

## 5. Mensajes comunes

| Mensaje | Qué hacer |
| --- | --- |
| Correo o contraseña incorrectos | Revisa los datos o recupera la contraseña |
| Tu cuenta está desactivada | Pide al administrador que la active |
| Sin conexión a Internet | Revisa la conexión y vuelve a intentar; la operación no se duplica |
| Stock insuficiente para … | Reduce la cantidad o registra una entrada |
| Ya existe un registro con ese valor | El código o el nombre ya está en uso |
