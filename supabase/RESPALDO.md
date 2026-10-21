# Respaldo y recuperación de la base de datos

El plan gratuito de Supabase **no** hace respaldos automáticos. Haz un respaldo manual **cada semana y antes de cada entrega**.

## Qué se respalda

- **Esquema:** ya está en Git (`supabase/migrations/`). Con eso se recrean las tablas, las funciones y la seguridad.
- **Datos:** se exportan con `pg_dump` y se guardan en `respaldos/`. Esa carpeta está en `.gitignore`: **no** se sube a GitHub.

## Requisito (una vez)

Instala las herramientas de cliente de PostgreSQL (incluyen `pg_dump` y `psql`) desde https://www.postgresql.org/download/. Usa una versión **igual o mayor** a la de tu proyecto, que ves en Supabase → Project Settings → Infrastructure.

Copia la cadena de conexión en Supabase → **Connect** → **Session pooler**. Tiene la forma:
`postgresql://postgres.<ref>:<CONTRASEÑA>@aws-0-<region>.pooler.supabase.com:5432/postgres`

No guardes esta cadena en ningún archivo del proyecto.

## Hacer el respaldo (Windows, PowerShell)

```powershell
cd D:\ComputNube\sistema-inventario-nube
mkdir respaldos -Force
$url = Read-Host "Cadena de conexion"
$fecha = Get-Date -Format "yyyy-MM-dd"
pg_dump $url --data-only --schema=public --column-inserts -f "respaldos\datos-$fecha.sql"
pg_dump $url --schema-only --schema=public -f "respaldos\esquema-$fecha.sql"
```

## Recuperar (prueba de la Fase 5)

1. Crea un **segundo proyecto** gratuito en Supabase.
2. En su SQL Editor ejecuta `001_tablas.sql`, `002_funciones.sql` y `003_seguridad_rls.sql`.
3. Crea los mismos usuarios en Authentication (los `id` deben coincidir con los del respaldo). Si no coinciden, carga solo categorías, proveedores y productos.
4. Carga los datos: `psql "<cadena del proyecto nuevo>" -f respaldos\datos-AAAA-MM-DD.sql`
5. Ejecuta `tests/pruebas.sql` y comprueba que todo sale **OK**. Luego compara la cantidad de productos y movimientos con el proyecto original.

Anota el resultado en `docs/resultados-pruebas.md`.
