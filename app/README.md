# App Flutter: Inventario Cloud

Aplicación **web** (se usa desde el navegador del celular o de la computadora).

## Primera vez

```bash
cd app
flutter create --platforms=android,web --org bo.umsa --project-name inventario_cloud .
flutter pub get
```

`flutter create .` solo agrega las carpetas `android/` y `web/`; no reemplaza los archivos de `lib/`.

## Configuración (no se sube a Git)

1. Copia `dart_defines.example.json` como `dart_defines.json`.
2. Llena `SUPABASE_URL` y `SUPABASE_ANON_KEY` (Supabase → Project Settings → API).
3. **Nunca** uses la clave `service_role`.

## Ejecutar

```bash
flutter run -d chrome  --dart-define-from-file=dart_defines.json   # web
flutter run -d android --dart-define-from-file=dart_defines.json   # celular o emulador
```

## Compilar

```bash
flutter build web --release --dart-define-from-file=dart_defines.json
```

Usuarios de prueba: los creados en `supabase/README.md`.

## Pruebas

```bash
flutter test
```

`test/widget_test.dart` contiene las pruebas unitarias: regla de stock, formato en Bs, folios, validadores y mensajes de error. Si `flutter create` generó otro `widget_test.dart`, reemplázalo por el de este repositorio.


## Publicar la versión web (gratis)

1. Pon en `dart_defines.json` el campo `WEB_URL` con la dirección final (puedes completarlo después del primer despliegue y volver a compilar).
2. `flutter build web --release --dart-define-from-file=dart_defines.json`
3. **Netlify:** entra a https://app.netlify.com/drop y arrastra la carpeta `build/web`. Tendrás una URL del tipo `https://nombre.netlify.app`.
   (Alternativa: Cloudflare Pages → "Upload assets" con la misma carpeta.)
4. En **Supabase → Authentication → URL Configuration**:
   - **Site URL:** la URL de Netlify.
   - **Redirect URLs:** agrega la URL de Netlify y `http://localhost:*` para las pruebas locales.
5. Abre la URL e inicia sesión. La app usa rutas con `#` (por ejemplo, `/#/productos`), así que no necesita reglas de redirección en el hosting.

Cada vez que cambies el código, vuelve a compilar y a arrastrar la carpeta `build/web`.
