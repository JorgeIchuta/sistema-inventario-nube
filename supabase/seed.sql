-- Datos ficticios de demostracion. Ejecutar en el SQL Editor DESPUES de:
--   1) aplicar las migraciones 001, 002 y 003
--   2) crear en Authentication > Users: admin@inventario.test y empleado@inventario.test
-- Se puede ejecutar una sola vez (falla si los datos ya existen).

begin;

-- Roles y nombres
update public.perfiles set rol = 'administrador', nombre = 'Admin Usuario'
 where id = (select id from auth.users where email = 'admin@inventario.test');
update public.perfiles set rol = 'empleado', nombre = 'Ana López'
 where id = (select id from auth.users where email = 'empleado@inventario.test');

insert into public.categorias (nombre, descripcion) values
  ('Abarrotes', 'Arroz, azúcar, aceite, fideos y otros básicos'),
  ('Bebidas',   'Agua, gaseosas y jugos'),
  ('Limpieza',  'Productos de limpieza del hogar');

insert into public.proveedores (nombre, telefono, correo, direccion) values
  ('Distribuidora Illimani', '70000001', 'ventas@illimani.test', 'Av. Buenos Aires, La Paz'),
  ('Comercial El Alto',      '70000002', 'pedidos@comercialelalto.test', 'Av. 6 de Marzo, El Alto');

-- Productos: (codigo, nombre, categoria, precio Bs, stock inicial, stock minimo)
with datos(codigo, nombre, categoria, precio, stock, minimo) as (values
  ('ABA-001', 'Arroz 1 kg',              'Abarrotes', 9.50,  40, 10),
  ('ABA-002', 'Azúcar 1 kg',             'Abarrotes', 8.00,  35, 10),
  ('ABA-003', 'Aceite vegetal 900 ml',   'Abarrotes', 16.00, 12, 12),
  ('ABA-004', 'Fideo tallarín 400 g',    'Abarrotes', 6.50,  50, 15),
  ('ABA-005', 'Harina 1 kg',             'Abarrotes', 7.00,  0,  8),
  ('BEB-001', 'Agua sin gas 2 L',        'Bebidas',   7.00,  30, 10),
  ('BEB-002', 'Gaseosa 2 L',             'Bebidas',   12.00, 24, 8),
  ('BEB-003', 'Jugo de durazno 1 L',     'Bebidas',   10.00, 6,  8),
  ('LIM-001', 'Detergente en polvo 1 kg','Limpieza',  18.00, 20, 5),
  ('LIM-002', 'Lavandina 1 L',           'Limpieza',  8.50,  15, 5),
  ('LIM-003', 'Jabón de tocador',        'Limpieza',  4.50,  60, 20),
  ('LIM-004', 'Papel higiénico x4',      'Limpieza',  14.00, 3,  6)
), ins as (
  insert into public.productos (codigo, nombre, categoria_id, precio_venta, stock_actual, stock_minimo)
  select d.codigo, d.nombre, c.id, d.precio, d.stock, d.minimo
  from datos d join public.categorias c on c.nombre = d.categoria
  returning id, stock_actual
)
-- Movimiento "Inventario inicial" para que el historial cuadre con el stock
insert into public.movimientos_inventario
  (producto_id, usuario_id, tipo, cantidad, stock_anterior, stock_resultante, referencia_tipo, observaciones)
select ins.id, (select id from auth.users where email = 'admin@inventario.test'),
       'ajuste', ins.stock_actual, 0, ins.stock_actual, 'ajuste', 'Inventario inicial'
from ins where ins.stock_actual > 0;

commit;
