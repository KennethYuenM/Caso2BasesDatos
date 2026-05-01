create extension if not exists pgcrypto;

/*Se necesita ejecutar primero el siguiente incert antes de los scripts, por eso lo pongo aca*/
insert into acciones (nombreaccion)
values 
('CREATE'),
('UPDATE'),
('DELETE'),
('ERROR')
on conflict do nothing;


/*Funciones base de log y checksum*/

create or replace function fn_generar_checksum(p_data jsonb)
returns text
language plpgsql
as $$
begin
    return encode(digest(p_data::text, 'sha256'), 'hex');
exception
    when others then
        raise;
end;
$$;

create or replace function fn_insert_log(
    p_usuario int,
    p_tabla text,
    p_accion text,
    p_objeto_id int,
    p_datos_viejos jsonb default null,
    p_datos_nuevos jsonb default null,
    p_error text default null
)
returns void
language plpgsql
as $$
declare
    v_tablaid int;
    v_accionid int;
    v_checksum text;
begin
    begin
        select t.tablaid, a.accionid
        into v_tablaid, v_accionid
        from tablassistema t
        join acciones a
          on upper(a.nombreaccion) = upper(p_accion)
        where lower(t.nombretabla) = lower(p_tabla)
        limit 1;

        if v_tablaid is null or v_accionid is null then
            return; -- evita romper operación por fallo de log
        end if;

        v_checksum := fn_generar_checksum(
            jsonb_build_object(
                'usuario', coalesce(p_usuario, 0),
                'tabla', p_tabla,
                'accion', p_accion,
                'objeto_id', coalesce(p_objeto_id, 0),
                'viejo', coalesce(p_datos_viejos, '{}'::jsonb),
                'nuevo', coalesce(p_datos_nuevos, '{}'::jsonb),
                'error', coalesce(p_error, '')
            )
        );

        insert into logs (
            usuariomodificacion,
            tablaid,
            accionid,
            objetoafectadoid,
            datosviejos,
            datosnuevos,
            error,
            checksum
        )
        values (
            p_usuario,
            v_tablaid,
            v_accionid,
            coalesce(p_objeto_id, 0),
            p_datos_viejos,
            p_datos_nuevos,
            p_error,
            v_checksum
        );

    exception
        when others then
            -- nunca romper por log
            null;
    end;
end;
$$;

create or replace function fn_trigger_log()
returns trigger
language plpgsql
as $$
declare
    v_usuario int;
    v_objeto_id int := 0;
    v_accion text;
    v_old jsonb;
    v_new jsonb;
begin
    begin
        if tg_op = 'INSERT' then
            v_accion := 'CREATE';
            v_new := to_jsonb(new);
        elsif tg_op = 'UPDATE' then
            v_accion := 'UPDATE';
            v_new := to_jsonb(new);
            v_old := to_jsonb(old);
        else
            v_accion := 'DELETE';
            v_old := to_jsonb(old);
        end if;

        begin
            v_usuario := (coalesce(v_new, v_old)->>'usuariomodificacion')::int;
        exception when others then
            v_usuario := null;
        end;

        if tg_nargs >= 1 then
            if tg_op = 'DELETE' then
                v_objeto_id := coalesce((to_jsonb(old)->>tg_argv[0])::int, 0);
            else
                v_objeto_id := coalesce((to_jsonb(new)->>tg_argv[0])::int, 0);
            end if;
        end if;

        perform fn_insert_log(
            v_usuario,
            tg_table_name,
            v_accion,
            v_objeto_id,
            v_old,
            v_new,
            null
        );

        return case when tg_op = 'DELETE' then old else new end;

    exception
        when others then
            perform fn_insert_log(
                v_usuario,
                tg_table_name,
                v_accion,
                coalesce(v_objeto_id, 0),
                v_old,
                v_new,
                sqlerrm
            );
            raise;
    end;
end;
$$;

/*Checksum automático*/

create or replace function fn_set_checksum()
returns trigger
language plpgsql
as $$
declare
    v_data jsonb;
    i int;
    v_usuario int;
begin
    begin
        v_data := to_jsonb(new) - 'checksum';

        if tg_nargs > 0 then
            for i in 0 .. tg_nargs - 1 loop
                v_data := v_data - tg_argv[i];
            end loop;
        end if;

        new.checksum := fn_generar_checksum(v_data);
        return new;

    exception
        when others then
            v_usuario := (to_jsonb(new)->>'usuariomodificacion')::int;

            perform fn_insert_log(
                v_usuario,
                tg_table_name,
                tg_op,
                0,
                null,
                to_jsonb(new),
                sqlerrm
            );

            raise;
    end;
end;
$$;

/*Ultimo Login automático*/

create or replace function fn_update_last_login()
returns trigger
language plpgsql
as $$
declare
    v_usuario int;
begin
    begin
        v_usuario := coalesce(
            (to_jsonb(new)->>'usuariomodificacion')::int,
            (to_jsonb(old)->>'usuariomodificacion')::int
        );

        if v_usuario is not null then
            update usuarios
            set ultimologin = current_timestamp
            where usuarioid = v_usuario;
        end if;

        return case when tg_op = 'DELETE' then old else new end;

    exception
        when others then
            perform fn_insert_log(
                v_usuario,
                tg_table_name,
                tg_op,
                0,
                to_jsonb(old),
                to_jsonb(new),
                sqlerrm
            );
            raise;
    end;
end;
$$;

/*Tablas Del sistema*/
create or replace procedure sp_cargar_tablas()
language plpgsql
as $$
begin
    begin
        insert into tablassistema (nombretabla)
        select table_name
        from information_schema.tables
        where table_schema = 'core'
          and table_type = 'BASE TABLE'
        on conflict (nombretabla) do nothing;
    exception
        when others then
            perform fn_insert_log(null, 'tablassistema', 'CREATE', 0, null, null, sqlerrm);
            raise;
    end;
end;
$$;

/*Validaciones y trigger de direcciones*/

create or replace function fn_validar_division()
returns trigger
language plpgsql
as $$
declare
    v_orden_division int;
    v_orden_max int;
begin
    begin
        select
            ng.orden,
            max(ng2.orden)
        into v_orden_division, v_orden_max
        from divisionesgeograficas dg
        join nivelesgeograficos ng
            on ng.nivelid = dg.nivelid
        join divisionesgeograficas dgp
            on dgp.paisid = dg.paisid
        join nivelesgeograficos ng2
            on ng2.nivelid = dgp.nivelid
        where dg.divisionid = new.divisionid
        group by ng.orden;

        if v_orden_division is null then
            raise exception 'La division % no existe', new.divisionid;
        end if;

        if v_orden_division <> v_orden_max then
            raise exception 'La division % no es el nivel más bajo del país', new.divisionid;
        end if;

        return new;

    exception
        when others then
            perform fn_insert_log(
                (to_jsonb(new)->>'usuariomodificacion')::int,
                'direcciones',
                tg_op,
                0,
                to_jsonb(old),
                to_jsonb(new),
                sqlerrm
            );
            raise;
    end;
end;
$$;

create or replace function fn_generar_direccion()
returns trigger
language plpgsql
as $$
declare
    v_ruta text;
begin
    begin
        with recursive ruta as (
            select dg.divisionid, dg.padreid, dg.nombre, ng.orden
            from divisionesgeograficas dg
            join nivelesgeograficos ng on ng.nivelid = dg.nivelid
            where dg.divisionid = new.divisionid

            union all

            select p.divisionid, p.padreid, p.nombre, ng.orden
            from divisionesgeograficas p
            join nivelesgeograficos ng on ng.nivelid = p.nivelid
            join ruta r on r.padreid = p.divisionid
        )
        select string_agg(nombre, ', ' order by orden)
        into v_ruta
        from ruta;

        new.direccioncompleta :=
            concat_ws(', ', new.calle, new.numero, new.referencia, v_ruta);

        return new;

    exception
        when others then
            perform fn_insert_log(
                (to_jsonb(new)->>'usuariomodificacion')::int,
                'direcciones',
                tg_op,
                0,
                to_jsonb(old),
                to_jsonb(new),
                sqlerrm
            );
            raise;
    end;
end;
$$;

/*Historial Cambio de monedas*/

create or replace function fn_historial_tipo_cambio()
returns trigger
language plpgsql
as $$
begin
    begin
        update historialcambiosmonedas
        set fechafin = current_timestamp
        where tipocambioid = old.tipocambioid
          and fechafin = '9999-12-31 23:59:59'::timestamp;

        insert into historialcambiosmonedas (
            moneda1id,
            moneda2id,
            tipocambioid,
            usuariomodificacion,
            fechainicio,
            fechafin,
            tipocambio,
            checksum,
            horacambio
        )
        values (
            new.moneda1id,
            new.moneda2id,
            new.tipocambioid,
            new.usuariomodificacion,
            current_timestamp,
            '9999-12-31 23:59:59'::timestamp,
            new.tipocambio,
            fn_generar_checksum(
                jsonb_build_object(
                    'moneda1id', new.moneda1id,
                    'moneda2id', new.moneda2id,
                    'tipocambioid', new.tipocambioid,
                    'tipocambio', new.tipocambio
                )
            ),
            current_timestamp
        );

        return new;
    exception
        when others then
            perform fn_insert_log(
                coalesce(new.usuariomodificacion, old.usuariomodificacion),
                'tiposcambio',
                'UPDATE',
                coalesce(new.tipocambioid, old.tipocambioid),
                to_jsonb(old),
                to_jsonb(new),
                sqlerrm
            );
            raise;
    end;
end;
$$;

/*Ordenes, balance, lote y recálculo de costos*/

create or replace procedure sp_crear_orden(
    in p_usuario int,
    in p_estado int,
    in p_tipo int,
    in p_direccion_envio int,
    in p_direccion_entrega int,
    in p_moneda int,
    in p_tipocambioid int,
    in p_tipocambio numeric(18,6),
    in p_numero_orden varchar(30),
    out p_orden_id int
)
language plpgsql
as $$
begin
    begin
        insert into ordenes (
            estadoid,
            tipoordenid,
            usuariomodificacion,
            direccionenvioid,
            direccionentregaid,
            monedaid,
            tipocambioid,
            tipocambio,
            numeroorden,
            preciofinal
        )
        values (
            p_estado,
            p_tipo,
            p_usuario,
            p_direccion_envio,
            p_direccion_entrega,
            p_moneda,
            p_tipocambioid,
            p_tipocambio,
            p_numero_orden,
            0
        )
        returning ordenid into p_orden_id;

        insert into estadoscuenta (
            ordenid,
            usuariomodificacion,
            tipomovimiento,
            estado,
            monedaid,
            tipocambioid,
            tipocambio,
            monto
        )
        values (
            p_orden_id,
            p_usuario,
            'Debito',
            'pendiente',
            p_moneda,
            p_tipocambioid,
            p_tipocambio,
            0
        );

        insert into transacciones (
            monedaid,
            usuariomodificacion,
            tipoid,
            estadotransaccionid,
            ordenid,
            tipocambioid,
            tipocambio,
            monto,
            descripcion
        )
        values (
            p_moneda,
            p_usuario,
            1,
            1,
            p_orden_id,
            p_tipocambioid,
            p_tipocambio,
            0,
            'Transacción generada automáticamente al crear la orden'
        );
    exception
        when others then
            perform fn_insert_log(
                p_usuario,
                'ordenes',
                'CREATE',
                coalesce(p_orden_id, 0),
                null,
                null,
                sqlerrm
            );
            raise;
    end;
end;
$$;

create or replace function fn_actualizar_balance()
returns trigger
language plpgsql
as $$
begin
    begin
        if new.estado = 'completado'
           and (tg_op = 'INSERT' or old.estado is distinct from new.estado) then

            update balanceneto
            set saldo = coalesce(saldo, 0) + coalesce(new.monto, 0),
                ultimaActualizacion = current_timestamp
            where balanceid = 1;

            if not found then
                insert into balanceneto (saldo, ultimaActualizacion)
                values (coalesce(new.monto, 0), current_timestamp);
            end if;
        end if;

        return new;
    exception
        when others then
            perform fn_insert_log(
                coalesce(new.usuariomodificacion, old.usuariomodificacion),
                'estadoscuenta',
                'UPDATE',
                coalesce(new.estadocuentaid, old.estadocuentaid),
                to_jsonb(old),
                to_jsonb(new),
                sqlerrm
            );
            raise;
    end;
end;
$$;

create or replace function fn_asignar_lote()
returns trigger
language plpgsql
as $$
declare
    v_loteid int;
begin
    begin
        select loteid
        into v_loteid
        from lotes
        where productoid = new.productoid
          and cantidadproductolotedisponible >= new.cantidad
        order by fechafabricacion asc, loteid asc
        limit 1
        for update skip locked;

        if v_loteid is null then
            raise exception 'No hay lotes suficientes para el producto % (cantidad solicitada: %)', 
                new.productoid, new.cantidad;
        end if;

        new.loteid := v_loteid;

        return new;

    exception
        when others then
            perform fn_insert_log(
                (to_jsonb(new)->>'usuariomodificacion')::int,
                'ordendetalles',
                'CREATE',
                0,
                null,
                to_jsonb(new),
                sqlerrm
            );
            raise;
    end;
end;
$$;

create or replace function fn_recalcular_orden()
returns trigger
language plpgsql
as $$
declare
    v_ordenid int;
begin
    begin
        if tg_table_name = 'ordendetalles' then
            if tg_op = 'DELETE' then
                v_ordenid := old.ordenid;
            else
                v_ordenid := new.ordenid;
            end if;
        elsif tg_table_name in ('ordendetalleimpuestos', 'ordendetallepermisos', 'ordendetalledescuentos') then
            select od.ordenid
            into v_ordenid
            from ordendetalles od
            where od.ordendetalleid = case when tg_op = 'DELETE' then old.ordendetalleid else new.ordendetalleid end;
        end if;

        update ordenes o
        set preciofinal = coalesce((
            select sum(coalesce(od.preciolotefinal, 0))
            from ordendetalles od
            where od.ordenid = v_ordenid
        ), 0)
        where o.ordenid = v_ordenid;

        return case when tg_op = 'DELETE' then old else new end;
    exception
        when others then
            perform fn_insert_log(
                coalesce((to_jsonb(new)->>'usuariomodificacion')::int, (to_jsonb(old)->>'usuariomodificacion')::int),
                tg_table_name,
                case when tg_op = 'INSERT' then 'CREATE' when tg_op = 'UPDATE' then 'UPDATE' else 'DELETE' end,
                coalesce(v_ordenid, 0),
                to_jsonb(old),
                to_jsonb(new),
                sqlerrm
            );
            raise;
    end;
end;
$$;

create or replace function fn_calcular_totales_detalle(p_ordendetalleid int)
returns void
language plpgsql
as $$
declare
    v_producto_id int;
    v_cantidad int;
    v_precio_unitario numeric(18,6);

    v_precio_base numeric(18,6) := 0;
    v_impuestos numeric(18,6) := 0;
    v_permisos numeric(18,6) := 0;
    v_descuentos numeric(18,6) := 0;
begin
    begin
        /* Obtener datos base */
        select od.productoid, od.cantidad, p.precio
        into v_producto_id, v_cantidad, v_precio_unitario
        from ordendetalles od
        join productos p on p.productoid = od.productoid
        where od.ordendetalleid = p_ordendetalleid;

        if v_producto_id is null then
            raise exception 'Detalle % no existe', p_ordendetalleid;
        end if;

        /* Precio base */
        v_precio_base := coalesce(v_precio_unitario,0) * coalesce(v_cantidad,0);

        /* Impuestos */
        select coalesce(sum(
            case 
                when ip.tipo = 'porcentaje' then (v_precio_base * ip.valor / 100)
                else ip.valor
            end
        ),0)
        into v_impuestos
        from ordendetalleimpuestos odi
        join impuestospais ip on ip.impuestoid = odi.impuestoid
        where odi.ordendetalleid = p_ordendetalleid;

        /* Permisos */
        select coalesce(sum(pi.costo),0)
        into v_permisos
        from ordendetallepermisos odp
        join permisosimportacion pi on pi.permisoid = odp.permisoid
        where odp.ordendetalleid = p_ordendetalleid;

        /* Descuentos */
        select coalesce(sum(monto),0)
        into v_descuentos
        from ordendetalledescuentos
        where ordendetalleid = p_ordendetalleid;

        /* Update final */
        update ordendetalles
        set 
            descuentofinal = v_descuentos,
            preciolotefinal = (v_precio_base + v_impuestos + v_permisos) - v_descuentos
        where ordendetalleid = p_ordendetalleid;

    exception
        when others then
            perform fn_insert_log(
                null,
                'ordendetalles',
                'UPDATE',
                p_ordendetalleid,
                null,
                null,
                sqlerrm
            );
            raise;
    end;
end;
$$;

create or replace function fn_trigger_recalculo_detalle()
returns trigger
language plpgsql
as $$
declare
    v_id int;
begin
    begin
        if tg_op = 'DELETE' then
            v_id := old.ordendetalleid;
        else
            v_id := new.ordendetalleid;
        end if;

        if tg_op <> 'DELETE' then
            perform fn_calcular_totales_detalle(v_id);
        end if;

        return case when tg_op = 'DELETE' then old else new end;

    exception
        when others then
            perform fn_insert_log(
                null,
                tg_table_name,
                tg_op,
                coalesce(v_id,0),
                to_jsonb(old),
                to_jsonb(new),
                sqlerrm
            );
            raise;
    end;
end;
$$;

/*Inventarios*/
create or replace function fn_actualizar_inventario()
returns trigger
language plpgsql
as $$
declare
    v_tipo int;
    v_stock numeric;
    v_usuario int;
begin
    begin
        /* Obtener usuario */
        v_usuario := coalesce(
            new.usuariomodificacion,
            old.usuariomodificacion
        );

        /* Obtener tipo de orden */
        select tipoordenid
        into v_tipo
        from ordenes
        where ordenid = new.ordenid;

        if v_tipo is null then
            raise exception 'No existe la orden %', new.ordenid;
        end if;

        /* Obtener stock actual del lote */
        select cantidadproductolotedisponible
        into v_stock
        from lotes
        where loteid = new.loteid
        for update;

        if v_stock is null then
            raise exception 'No existe el lote %', new.loteid;
        end if;

        if v_tipo = 1 then
            /* SALIDA (venta) */
            if v_stock < new.cantidad then
                raise exception 
                'Stock insuficiente en lote % (disponible: %, requerido: %)',
                new.loteid, v_stock, new.cantidad;
            end if;

            update lotes
            set cantidadproductolotedisponible = v_stock - new.cantidad
            where loteid = new.loteid;

        else
            /* ENTRADA (compra) */
            update lotes
            set cantidadproductolotedisponible = v_stock + new.cantidad
            where loteid = new.loteid;
        end if;

        return new;

    exception
        when others then
            perform fn_insert_log(
                v_usuario,
                'lotes',
                'UPDATE',
                coalesce(new.loteid, 0),
                null,
                to_jsonb(new),
                sqlerrm
            );
            raise;
    end;
end;
$$;

/*Creación de triggers*/

drop trigger if exists trg_direcciones_validar_division on direcciones;
create trigger trg_direcciones_validar_division
before insert or update on direcciones
for each row
execute function fn_validar_division();

drop trigger if exists trg_direcciones_generar_completa on direcciones;
create trigger trg_direcciones_generar_completa
before insert or update on direcciones
for each row
execute function fn_generar_direccion();

drop trigger if exists trg_tiposcambio_historial on tiposcambio;
create trigger trg_tiposcambio_historial
after update on tiposcambio
for each row
execute function fn_historial_tipo_cambio();

drop trigger if exists trg_estadoscuenta_balance on estadoscuenta;
create trigger trg_estadoscuenta_balance
after insert or update of estado on estadoscuenta
for each row
execute function fn_actualizar_balance();

drop trigger if exists trg_ordendetalles_asignar_lote on ordendetalles;
create trigger trg_ordendetalles_asignar_lote
before insert on ordendetalles
for each row
execute function fn_asignar_lote();

drop trigger if exists trg_recalcular_orden_detalles on ordendetalles;
create trigger trg_recalcular_orden_detalles
after insert or update or delete on ordendetalles
for each row
execute function fn_recalcular_orden();

drop trigger if exists trg_recalcular_orden_impuestos on ordendetalleimpuestos;
create trigger trg_recalcular_orden_impuestos
after insert or update or delete on ordendetalleimpuestos
for each row
execute function fn_recalcular_orden();

drop trigger if exists trg_recalcular_orden_permisos on ordendetallepermisos;
create trigger trg_recalcular_orden_permisos
after insert or update or delete on ordendetallepermisos
for each row
execute function fn_recalcular_orden();

drop trigger if exists trg_recalcular_orden_descuentos on ordendetalledescuentos;
create trigger trg_recalcular_orden_descuentos
after insert or update or delete on ordendetalledescuentos
for each row
execute function fn_recalcular_orden();

drop trigger if exists trg_inventario_movimiento on ordendetalles;
create trigger trg_inventario_movimiento
after insert on ordendetalles
for each row
execute function fn_actualizar_inventario();

/*Creacion de los trigger de los checksums*/

drop trigger if exists trg_checksum_tiposcambio on tiposcambio;
create trigger trg_checksum_tiposcambio
before insert or update on tiposcambio
for each row
execute function fn_set_checksum('tiempo_creacion', 'ultima_actualizacion', 'activo');

drop trigger if exists trg_checksum_historialcambiosmonedas on historialcambiosmonedas;
create trigger trg_checksum_historialcambiosmonedas
before insert or update on historialcambiosmonedas
for each row
execute function fn_set_checksum('fechainicio', 'fechafin', 'horacambio');

drop trigger if exists trg_checksum_ordendetalles on ordendetalles;
create trigger trg_checksum_ordendetalles
before insert or update on ordendetalles
for each row
execute function fn_set_checksum('descuentofinal', 'preciolotefinal');

drop trigger if exists trg_checksum_transacciones on transacciones;
create trigger trg_checksum_transacciones
before insert or update on transacciones
for each row
execute function fn_set_checksum('fecha');

drop trigger if exists trg_checksum_estadoscuenta on estadoscuenta;
create trigger trg_checksum_estadoscuenta
before insert or update on estadoscuenta
for each row
execute function fn_set_checksum('fecharegistro', 'estado');



-- detalle
drop trigger if exists trg_calc_detalle on ordendetalles;
create trigger trg_calc_detalle
after insert or update on ordendetalles
for each row
execute function fn_trigger_recalculo_detalle();

-- impuestos
drop trigger if exists trg_calc_impuestos on ordendetalleimpuestos;
create trigger trg_calc_impuestos
after insert or update or delete on ordendetalleimpuestos
for each row
execute function fn_trigger_recalculo_detalle();

-- permisos
drop trigger if exists trg_calc_permisos on ordendetallepermisos;
create trigger trg_calc_permisos
after insert or update or delete on ordendetallepermisos
for each row
execute function fn_trigger_recalculo_detalle();

-- descuentos
drop trigger if exists trg_calc_descuentos on ordendetalledescuentos;
create trigger trg_calc_descuentos
after insert or update or delete on ordendetalledescuentos
for each row
execute function fn_trigger_recalculo_detalle();

/*Creacion de los trigger de los logs*/

do $$
declare
    r record;
begin
    begin
        for r in
            select *
            from (values
                ('rolesxusuario', null),
                ('permisosxrole', null),

                ('divisionesgeograficas', 'divisionid'),
                ('direcciones', 'direccionid'),

                ('contactos', 'contactoid'),
                ('telefonoscontactos', 'telefonocontactoid'),
                ('correoscontactos', 'correocontactoid'),

                ('centroslogisticos', 'centrologisticoid'),
                ('proveedores', 'proveedorid'),
                ('contactosproveedor', null),

                ('productos', 'productoid'),
                ('valorcaracteristicas', null),

                ('monedas', 'monedaid'),
                ('tiposcambio', 'tipocambioid'),
                ('historialcambiosmonedas', 'historialcambioid'),

                ('permisosimportacion', 'permisoid'),

                ('lotes', 'loteid'),
                ('movimientosinventario', 'movimientoid'),
                ('inventarios', 'inventarioid'),

                ('historialpreciosproducto', 'historialprecioid'),

                ('ordenes', 'ordenid'),
                ('ordendetalles', 'ordendetalleid'),
                ('ordendetalleimpuestos', null),
                ('ordendetallepermisos', null),
                ('ordendetalledescuentos', 'ordendetalledescuentoid'),

                ('trazabilidadorden', 'trazabilidadid'),
                ('impuestospais', 'impuestoid'),

                ('transacciones', 'transaccionid'),

                ('estadoscuenta', 'estadocuentaid'),
                ('balanceneto', 'balanceid')
            ) as t(table_name, pk_col)
        loop
            execute format(
                'drop trigger if exists %I on %I;',
                'trg_audit_' || r.table_name,
                r.table_name
            );

            if r.pk_col is null then
                execute format(
                    'create trigger %I 
                     after insert or update or delete on %I 
                     for each row 
                     execute function fn_trigger_log();',
                    'trg_audit_' || r.table_name,
                    r.table_name
                );
            else
                execute format(
                    'create trigger %I 
                     after insert or update or delete on %I 
                     for each row 
                     execute function fn_trigger_log(%L);',
                    'trg_audit_' || r.table_name,
                    r.table_name,
                    r.pk_col
                );
            end if;
        end loop;

    exception
        when others then
            raise;
    end;
end $$;

/*Creacion de los triggers para ultimo login*/

do $$
declare
    r record;
begin
    begin
        for r in
            select table_name
            from information_schema.columns
            where table_schema = 'core'
              and column_name = 'usuariomodificacion'
              and table_name <> 'usuarios'
        loop
            execute format('drop trigger if exists %I on %I;', 'trg_lastlogin_' || r.table_name, r.table_name);

            execute format(
                'create trigger %I after insert or update on %I for each row execute function fn_update_last_login();',
                'trg_lastlogin_' || r.table_name,
                r.table_name
            );
        end loop;
    exception
        when others then
            raise;
    end;
end $$;