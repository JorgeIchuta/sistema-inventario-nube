# Alcance, usuarios y requisitos

## Alcance de la primera versión

El sistema permitirá controlar el inventario de una sola tienda desde celulares Android y computadoras. La aplicación Android se instalará mediante un archivo APK y la versión para computadora se abrirá desde un navegador web. Ambas utilizarán la misma base de datos PostgreSQL alojada en Supabase Free.

### Funciones obligatorias

- Iniciar y cerrar sesión.
- Administrar usuarios y sus roles.
- Registrar, consultar y actualizar categorías.
- Registrar, consultar y actualizar proveedores.
- Registrar, consultar y actualizar productos.
- Registrar entradas de mercancía.
- Registrar ventas con uno o varios productos.
- Actualizar automáticamente las existencias.
- Impedir ventas sin existencias suficientes.
- Mostrar alertas de bajo stock.
- Consultar el historial de movimientos.
- Utilizar el sistema desde Android y desde un navegador de PC.

### Funciones opcionales

Estas funciones se desarrollarán únicamente si las obligatorias ya funcionan:

- Lectura de códigos de barras con la cámara del celular.
- Fotografía del producto.
- Gráficas de productos más vendidos.
- Exportación de reportes a CSV o PDF.
- Filtros avanzados por fechas.

### Fuera del alcance

- Publicación en Google Play o Apple App Store.
- Aplicación nativa para iPhone.
- Facturación electrónica.
- Pagos en línea.
- Administración de varias sucursales.
- Integración con sistemas contables.
- Uso de servicios de pago.

## Tipos de usuario

### Administrador

- Administra usuarios, productos, categorías y proveedores.
- Registra entradas y ventas.
- Consulta existencias, alertas e historial.
- Puede desactivar registros que ya no se utilicen.

### Empleado

- Consulta productos y existencias.
- Registra ventas.
- Consulta alertas de bajo stock.
- Consulta sus movimientos, pero no administra usuarios.

## Requisitos funcionales

| Código | Requisito | Prioridad |
|---|---|---|
| RF-01 | El usuario debe iniciar sesión con correo y contraseña. | Alta |
| RF-02 | El sistema debe restringir funciones de acuerdo con el rol. | Alta |
| RF-03 | El administrador debe gestionar categorías. | Alta |
| RF-04 | El administrador debe gestionar proveedores. | Alta |
| RF-05 | El administrador debe registrar y actualizar productos. | Alta |
| RF-06 | El sistema debe permitir buscar productos por nombre o código. | Alta |
| RF-07 | El administrador debe registrar entradas de mercancía. | Alta |
| RF-08 | El administrador y el empleado deben registrar ventas. | Alta |
| RF-09 | Una entrada debe aumentar las existencias automáticamente. | Alta |
| RF-10 | Una venta debe reducir las existencias automáticamente. | Alta |
| RF-11 | El sistema debe impedir existencias negativas. | Alta |
| RF-12 | El sistema debe mostrar productos cuyo stock sea igual o menor al mínimo. | Alta |
| RF-13 | El sistema debe conservar el historial de movimientos. | Alta |
| RF-14 | Los cambios deben estar disponibles desde los demás dispositivos conectados. | Alta |
| RF-15 | El administrador debe poder desactivar productos, categorías y proveedores. | Media |
| RF-16 | El celular podrá leer códigos de barras mediante su cámara. | Opcional |

## Requisitos no funcionales

| Código | Requisito |
|---|---|
| RNF-01 | La interfaz debe adaptarse a celular y computadora. |
| RNF-02 | La comunicación con Supabase debe realizarse mediante HTTPS. |
| RNF-03 | Las contraseñas serán administradas por Supabase Auth y no se guardarán en tablas propias. |
| RNF-04 | Las credenciales administrativas no deben incluirse en Flutter. |
| RNF-05 | Las tablas deben protegerse mediante Row Level Security (RLS). |
| RNF-06 | Las operaciones comunes deben responder en un tiempo razonable con conexión estable. |
| RNF-07 | Los formularios deben validar datos obligatorios y cantidades. |
| RNF-08 | Los errores deben mostrarse con mensajes comprensibles. |
| RNF-09 | La aplicación debe funcionar en Android y en navegadores modernos de PC. |
| RNF-10 | Se debe realizar un respaldo manual antes de cada entrega importante. |

## Reglas de negocio

1. Cada producto pertenece a una categoría.
2. Cada producto tiene un código único, precio de venta, stock actual y stock mínimo.
3. Las cantidades y precios no pueden ser negativos.
4. Una entrada confirmada aumenta las existencias.
5. Una venta confirmada reduce las existencias.
6. No se puede vender una cantidad mayor al stock disponible.
7. Cada entrada o salida genera un movimiento de inventario.
8. Cada movimiento conserva fecha, usuario, producto, cantidad, tipo y referencia.
9. Una alerta aparece cuando el stock actual es menor o igual al stock mínimo.
10. Los movimientos confirmados no se eliminan; una corrección se registra como un nuevo movimiento de ajuste.
11. Los registros utilizados en movimientos se desactivan en lugar de eliminarse.
12. Solo el administrador puede gestionar usuarios y registrar entradas.

## Criterios de aceptación generales

- Una venta realizada desde Android se refleja en la versión web.
- El sistema rechaza una venta sin stock suficiente.
- Una entrada incrementa correctamente las existencias.
- El panel identifica los productos con bajo stock.
- El historial muestra quién realizó cada operación.
- Un empleado no puede acceder a la administración de usuarios.
