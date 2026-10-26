# Plan de trabajo del equipo

## Organización sugerida

El siguiente plan está preparado para cuatro integrantes y seis semanas. Si el grupo tiene otro tamaño, las responsabilidades pueden combinarse sin cambiar los entregables.

| Rol | Responsabilidades |
|---|---|
| Integrante 1: coordinación y datos | Seguimiento, modelo de datos, tablas, funciones e integridad |
| Integrante 2: interfaz | Diseño adaptable y pantallas Flutter |
| Integrante 3: integración y seguridad | Supabase Auth, conexión, RLS y roles |
| Integrante 4: calidad y documentación | Pruebas, evidencias, manual y presentación |

Todos los integrantes deben revisar cambios, probar la aplicación y comprender la arquitectura para poder explicar el proyecto.

## Cronograma

| Semana | Actividades | Entregable |
|---|---|---|
| 1 | Revisar requisitos, alcance, roles, reglas y prototipos | Documento aprobado y bocetos |
| 2 | Crear proyecto Supabase, tablas, relaciones, datos de prueba y RLS inicial | Base de datos funcional |
| 3 | Crear proyecto Flutter, navegación, inicio de sesión y diseño adaptable | Acceso desde Android y web |
| 4 | Implementar productos, categorías, proveedores y entradas | Catálogos y entradas funcionales |
| 5 | Implementar ventas, stock, alertas e historial | Flujo principal completo |
| 6 | Ejecutar pruebas, corregir errores, publicar la web y preparar exposición | Prototipo y documentación final |

## Tablero mínimo de tareas

### Pendiente

- Crear cuentas gratuitas y repositorio privado o académico.
- Crear el proyecto de Supabase Free.
- Crear tablas, restricciones, funciones y políticas RLS.
- Preparar datos ficticios de demostración.
- Crear el proyecto Flutter para Android y web.
- Implementar autenticación y roles.
- Implementar cada pantalla y sus validaciones.
- Probar sincronización entre dispositivos.
- Exportar respaldo manual.
- Desplegar la web en una opción gratuita (Netlify).
- Preparar diapositivas y guion de demostración.

## Herramientas gratuitas acordadas

| Necesidad | Herramienta | Costo previsto |
|---|---|---|
| Aplicación Android y web | Flutter | $0 |
| Base de datos, API y autenticación | Supabase Free con PostgreSQL | $0 dentro de sus límites |
| Editor | Visual Studio Code | $0 |
| Emulador y compilación Android | Android Studio | $0 |
| Control de versiones | Git y GitHub Free | $0 |
| Pruebas web | Chrome, Edge o Firefox | $0 |
| Publicación web | Netlify | $0 |

No se utilizarán servicios que exijan un plan de pago. Antes de activar cualquier función adicional, el equipo deberá comprobar que está incluida en el plan gratuito. No se publicará la aplicación en tiendas.

## Control de versiones

- Utilizar una rama por función.
- Evitar subir contraseñas, archivos `.env` y claves privadas.
- Revisar los cambios antes de unirlos a la rama principal.
- Registrar en cada tarea quién la realizó y cómo fue probada.

## Definición de terminado

Una tarea se considera terminada cuando:

- Cumple el requisito correspondiente.
- Funciona en el dispositivo requerido.
- Incluye validaciones y manejo básico de errores.
- Fue probada por otra persona del equipo.
- No expone credenciales.
- Está documentada y guardada en el repositorio.
