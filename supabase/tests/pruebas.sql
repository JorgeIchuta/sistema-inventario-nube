-- Pruebas de stock y permisos (CP-06, CP-07, CP-08, CP-13, CP-15, CP-16, CP-17).
-- Ejecutar en el SQL Editor DESPUES de seed.sql.
--
-- IMPORTANTE: el resultado se muestra como un "ERROR" a proposito.
-- Asi Supabase deshace todos los cambios de la prueba y no quedan datos alterados.
-- Debe decir "PRUEBAS TERMINADAS" y las 7 pruebas con OK.

do $$
declare
  r text := '';
  admin_id uuid := (select id from auth.users where email = 'admin@inventario.test');
  emp_id uuid := (select id from auth.users where email = 'empleado@inventario.test');
  p bigint; antes int; despues int; v1 bigint; v2 bigint; clave uuid := gen_random_uuid(); n int;
begin
  if admin_id is null or emp_id is null then
    raise exception 'Faltan los usuarios admin@inventario.test y/o empleado@inventario.test en Authentication.';
  end if;

  -- CP-06: entrada de 10 unidades (como administrador)
  perform set_config('request.jwt.claims', json_build_object('sub', admin_id, 'role', 'authenticated')::text, true);
  set local role authenticated;
  select id, stock_actual into p, antes from productos where codigo = 'ABA-001';
  perform registrar_entrada((select id from proveedores order by id limit 1),
    jsonb_build_array(jsonb_build_object('producto_id', p, 'cantidad', 10, 'costo_unitario', 7)), gen_random_uuid());
  select stock_actual into despues from productos where id = p;
  r := r || E'\nCP-06 entrada +10: ' || case when despues = antes + 10 then 'OK' else 'FALLA' end;
  reset role;

  -- Como empleado
  perform set_config('request.jwt.claims', json_build_object('sub', emp_id, 'role', 'authenticated')::text, true);
  set local role authenticated;
  select id, stock_actual into p, antes from productos where codigo = 'BEB-001';

  -- CP-07: venta de 2 unidades
  v1 := registrar_venta(jsonb_build_array(jsonb_build_object('producto_id', p, 'cantidad', 2)), clave);
  select stock_actual into despues from productos where id = p;
  r := r || E'\nCP-07 venta -2: ' || case when despues = antes - 2 then 'OK' else 'FALLA' end;

  -- CP-13: reintento con la misma clave no duplica
  v2 := registrar_venta(jsonb_build_array(jsonb_build_object('producto_id', p, 'cantidad', 2)), clave);
  select stock_actual into despues from productos where id = p;
  r := r || E'\nCP-13 reintento no duplica: ' || case when v1 = v2 and despues = antes - 2 then 'OK' else 'FALLA' end;

  -- CP-08: venta mayor al stock
  begin
    perform registrar_venta(jsonb_build_array(jsonb_build_object('producto_id', p, 'cantidad', 9999)), gen_random_uuid());
    r := r || E'\nCP-08 venta sin stock: FALLA (no se rechazo)';
  exception when others then
    select stock_actual into despues from productos where id = p;
    r := r || E'\nCP-08 venta sin stock: ' || case when despues = antes - 2 then 'OK' else 'FALLA' end;
  end;

  -- CP-15: empleado intenta registrar una entrada
  begin
    perform registrar_entrada(1, jsonb_build_array(jsonb_build_object('producto_id', p, 'cantidad', 5)), gen_random_uuid());
    r := r || E'\nCP-15 empleado sin entradas: FALLA';
  exception when others then
    r := r || E'\nCP-15 empleado sin entradas: OK';
  end;

  -- CP-16: editar el stock directamente
  begin
    update productos set stock_actual = 999 where id = p;
    r := r || E'\nCP-16 stock no editable: FALLA';
  exception when insufficient_privilege then
    r := r || E'\nCP-16 stock no editable: OK';
  end;
  reset role;

  -- CP-17: usuario desactivado no lee datos
  update perfiles set activo = false where id = emp_id;
  set local role authenticated;
  select count(*) into n from productos;
  r := r || E'\nCP-17 desactivado sin datos: ' || case when n = 0 then 'OK' else 'FALLA' end;
  reset role;

  raise exception 'PRUEBAS TERMINADAS (los cambios se deshicieron):%', r;
end $$;
