# Sistema multiplataforma de inventario para una tienda con base de datos en la nube

**Aplicación web publicada:** https://melodic-melomakarona-8b8ae7.netlify.app

## Documentación del proyecto

- [Alcance, usuarios y requisitos](docs/01-alcance-y-requisitos.md)
- [Diseño y diccionario de la base de datos](docs/02-base-de-datos.md)
- [Pantallas y flujos del sistema](docs/03-pantallas-y-flujos.md)
- [Plan de trabajo del equipo](docs/04-plan-de-trabajo.md)
- [Plan de pruebas y demostración](docs/05-pruebas-y-demostracion.md)

Toda la propuesta está limitada a tecnologías gratuitas: Flutter, Supabase Free, PostgreSQL, Visual Studio Code, Android Studio y GitHub Free. No se requiere publicar la aplicación en una tienda ni contratar infraestructura de pago.

## Planteamiento del problema

Muchas tiendas pequeñas y medianas administran su inventario mediante libretas, hojas de cálculo o archivos almacenados en una sola computadora. Estos métodos pueden provocar información desactualizada, registros duplicados, errores al capturar datos y pérdida de información. Además, dificultan conocer en tiempo real la cantidad disponible de cada producto.

La falta de un control centralizado también puede ocasionar que algunos productos se agoten sin que el responsable lo detecte a tiempo, mientras que otros se compren en exceso. Asimismo, consultar el historial de entradas y ventas o identificar a los proveedores relacionados con cada producto puede convertirse en una tarea lenta y poco confiable.

Por esta razón, se propone desarrollar un sistema multiplataforma de inventario conectado a una base de datos en la nube. El sistema permitirá almacenar y consultar de forma centralizada la información de productos, categorías, proveedores, existencias, entradas y ventas. También generará alertas cuando un producto alcance un nivel mínimo de existencias.

Los empleados y administradores podrán utilizar el sistema desde celulares y computadoras. En ambos casos se abrirá como una aplicación web desde el navegador, sin instalar nada. La base de datos en la nube permitirá que la información permanezca sincronizada entre todos los dispositivos autorizados y ofrecerá mejores opciones de seguridad, respaldo y disponibilidad.

## Objetivo general

Desarrollar un sistema multiplataforma de inventario para una tienda, accesible desde celulares Android y computadoras, conectado mediante una API a una base de datos en la nube, que permita registrar, organizar y consultar productos, categorías, proveedores, existencias, entradas y ventas, con el propósito de mejorar el control del inventario, reducir errores y facilitar el acceso sincronizado a la información desde diferentes dispositivos.

## Objetivos específicos

- Diseñar una base de datos relacional que permita almacenar la información de productos, categorías, proveedores, existencias y movimientos de inventario.
- Diseñar una interfaz adaptable que pueda utilizarse desde teléfonos celulares y computadoras.
- Implementar las funciones necesarias para registrar, consultar, actualizar y eliminar información del sistema.
- Registrar las entradas de mercancía y las ventas realizadas para mantener actualizadas las existencias de cada producto.
- Generar alertas cuando la cantidad disponible de un producto sea igual o menor que el nivel mínimo establecido.
- Mantener un historial de movimientos que permita conocer cuándo y por qué aumentaron o disminuyeron las existencias.
- Alojar la base de datos en un servicio de nube para permitir el acceso remoto y centralizado a la información.
- Sincronizar los cambios realizados desde celulares y computadoras mediante una única base de datos en la nube.
- Aplicar medidas básicas de seguridad, como autenticación de usuarios, control de acceso y protección de las credenciales de conexión.
- Configurar mecanismos de respaldo y recuperación para disminuir el riesgo de pérdida de información.
- Realizar pruebas que permitan comprobar el funcionamiento, la disponibilidad y la integridad de los datos almacenados.

## Propuesta de solución

La solución consistirá en una aplicación multiplataforma mediante la cual los usuarios autorizados podrán administrar el inventario desde un celular o una computadora. El sistema funcionará como una aplicación web que se abre desde el navegador de cualquier dispositivo.

La aplicación se desarrollará con Flutter y se comunicarán con una API alojada en la nube. La API será responsable de validar las solicitudes y acceder a la base de datos PostgreSQL.

La aplicación no se conectará directamente a la base de datos. El uso de una API evitará exponer las credenciales en celulares o computadoras y permitirá controlar qué operaciones puede realizar cada usuario.

El sistema incluirá los siguientes módulos principales:

- Administración de productos y categorías.
- Registro y consulta de proveedores.
- Control de existencias.
- Registro de entradas de mercancía.
- Registro de ventas y reducción automática de existencias.
- Alertas de bajo stock.
- Búsqueda de productos y lectura de códigos de barras con la cámara del celular.
- Consulta del historial de movimientos.
- Inicio de sesión y gestión básica de usuarios.

## Arquitectura propuesta

```text
Celular Android ──┐
                  ├── API de Supabase ── PostgreSQL en Supabase
PC / navegador ───┘
```

Las versiones móvil y web enviarán sus solicitudes a través de Internet a la API proporcionada por Supabase. Esta API permitirá realizar las operaciones autorizadas sobre PostgreSQL y devolverá los resultados al dispositivo correspondiente. Las reglas de seguridad de Supabase se configurarán para evitar que un usuario acceda o modifique información sin autorización.

Todos los dispositivos utilizarán la misma base de datos. Por ejemplo, si un empleado registra una venta desde un celular, las existencias actualizadas podrán consultarse inmediatamente desde una computadora conectada al sistema.

Esta arquitectura evita la necesidad de contratar y alojar un servidor independiente para la primera versión del proyecto. Si posteriormente se requiere una lógica de negocio más avanzada, se podrá incorporar una API propia desarrollada con Node.js.

## Tecnologías sugeridas

- **Aplicación multiplataforma:** Flutter, herramienta gratuita y de código abierto que permite desarrollar para Android y web utilizando un mismo código base.
- **Servicio en la nube:** Supabase en su plan gratuito.
- **Base de datos:** PostgreSQL incluida en Supabase.
- **Backend/API:** API proporcionada por Supabase, sin necesidad de pagar por un servidor independiente.
- **Autenticación:** servicio de autenticación incluido en Supabase.
- **Comunicación:** solicitudes mediante HTTPS y datos en formato JSON.
- **Herramientas de desarrollo:** Visual Studio Code y Android Studio, disponibles gratuitamente.

Para este prototipo académico se utilizará **Flutter + Supabase Free + PostgreSQL**, ya que esta combinación permite desarrollar y demostrar el sistema sin contratar servicios de pago.

Node.js con Express se considera una ampliación opcional. Ambas herramientas son gratuitas, pero alojar permanentemente una API propia podría requerir un servicio adicional. Por esta razón, no serán necesarias en la primera versión.

## Presupuesto y plan gratuito

El proyecto se diseñará para funcionar con un presupuesto de **$0**. Flutter, PostgreSQL, Visual Studio Code, Android Studio y Node.js son herramientas gratuitas. Supabase dispone de un plan gratuito adecuado para proyectos académicos y prototipos pequeños.

Al momento de definir esta propuesta, el plan gratuito de Supabase incluye:

- Hasta 500 MB de base de datos PostgreSQL por proyecto.
- API para acceder a la información.
- Servicio de autenticación de usuarios.
- Hasta dos proyectos activos.
- 1 GB de almacenamiento de archivos.
- 5 GB de transferencia de datos.

Estos recursos son suficientes para almacenar los productos, categorías, proveedores, usuarios, ventas y movimientos de inventario necesarios durante la demostración del proyecto.

### Limitaciones que deben considerarse

- Un proyecto gratuito de Supabase puede pausarse después de una semana sin actividad. Se deberá ingresar al sistema antes de la presentación para comprobar que esté activo.
- El plan gratuito no incluye respaldos automáticos. Para la demostración se realizarán respaldos manuales de la base de datos.
- Los límites y condiciones de los servicios gratuitos pueden cambiar. Se deberán revisar antes de crear la cuenta y desplegar el proyecto.
- No se contratarán funciones adicionales ni se cambiará a un plan de pago.
- AWS, Microsoft Azure y Google Cloud no se utilizarán en la primera versión, pues algunos de sus servicios pueden solicitar una tarjeta o generar cargos al superar sus límites gratuitos.

## Distribución de la aplicación

El sistema se usa como aplicación web, publicada gratis en Netlify: https://melodic-melomakarona-8b8ae7.netlify.app

- **Celular:** se abre desde el navegador del celular. La pantalla se acomoda con una barra de menú abajo.
- **Computadora:** se abre desde Chrome, Edge o Firefox, con un menú lateral.

No se genera una aplicación instalable (APK) ni se publica en Google Play o App Store. Así no hace falta instalar nada y todos usan la misma versión.

## Seguridad básica

- Autenticación mediante correo electrónico o nombre de usuario y contraseña.
- Roles de administrador y empleado.
- Contraseñas almacenadas de manera cifrada mediante hash.
- Comunicación segura mediante HTTPS.
- Credenciales de la base de datos almacenadas únicamente en el servidor.
- Validación de los datos recibidos antes de guardarlos.
- Copias de seguridad periódicas de la base de datos.

## Resultado esperado

Al finalizar el proyecto se espera contar con un prototipo multiplataforma funcional que permita controlar el inventario de una tienda desde celulares Android y computadoras autorizadas. El prototipo deberá demostrar que la información se almacena de forma centralizada en la nube, se mantiene actualizada después de cada entrada o venta y se sincroniza entre todos los dispositivos conectados.
