# Pantallas y flujos del sistema

## Pantallas principales

| Pantalla | Contenido principal | Acceso |
|---|---|---|
| Inicio de sesión | Correo, contraseña y recuperación de acceso | Todos |
| Panel principal | Resumen de productos, bajo stock, entradas y ventas | Todos |
| Productos | Lista, búsqueda, alta y edición | Lectura para todos; cambios para administrador |
| Categorías | Lista, alta, edición y desactivación | Administrador |
| Proveedores | Lista, datos de contacto, alta y edición | Administrador |
| Nueva entrada | Proveedor, productos, cantidades y costos | Administrador |
| Nueva venta | Productos, cantidades, precios y total | Todos |
| Bajo stock | Productos que requieren reposición | Todos |
| Historial | Entradas, ventas y ajustes con usuario y fecha | Todos según permisos |
| Usuarios | Lista, roles y estado | Administrador |

## Adaptación por dispositivo

### Celular Android

- Navegación inferior o menú lateral compacto.
- Botones grandes y formularios en una sola columna.
- Posibilidad de utilizar la cámara para leer códigos de barras.
- Instalación mediante APK, sin tienda de aplicaciones.

### Computadora

- Acceso desde un navegador moderno.
- Menú lateral permanente.
- Tablas con más columnas, búsquedas y filtros.
- Formularios que aprovechen el ancho disponible.

## Flujo de inicio de sesión

```text
Abrir aplicación
      ↓
Escribir correo y contraseña
      ↓
Supabase Auth valida las credenciales
      ↓
Consultar perfil y rol
      ↓
Mostrar las funciones autorizadas
```

## Flujo de entrada de mercancía

```text
Seleccionar proveedor
      ↓
Agregar productos, cantidades y costos
      ↓
Validar los datos
      ↓
Confirmar entrada
      ↓
Guardar entrada y detalles
      ↓
Aumentar stock y registrar movimientos
```

## Flujo de venta

```text
Buscar o escanear producto
      ↓
Agregar cantidad
      ↓
Comprobar stock disponible
      ↓
Confirmar venta
      ↓
Guardar venta y detalles
      ↓
Reducir stock y registrar movimientos
      ↓
Actualizar alertas de bajo stock
```

## Flujo de sincronización

```text
Venta registrada desde Android
      ↓
Supabase actualiza PostgreSQL
      ↓
La versión web vuelve a consultar los datos
      ↓
La computadora muestra el nuevo stock
```

## Criterios básicos de interfaz

- Utilizar nombres y mensajes en español.
- Marcar con claridad los campos obligatorios.
- Solicitar confirmación antes de guardar una venta o entrada.
- Mostrar el resultado exitoso o el motivo del error.
- Usar colores con texto o iconos; no depender únicamente del color.
- Mantener el mismo estilo visual en Android y web.
