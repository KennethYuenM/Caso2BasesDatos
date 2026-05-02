CREATE OR REPLACE FUNCTION fn_generar_checksum(p_data jsonb)
RETURNS text
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN encode(digest(p_data::text, 'sha256'), 'hex');
END;
$$;

CREATE OR REPLACE FUNCTION fn_insert_log(
    p_usuario int,
    p_tabla text,
    p_accion text,
    p_objeto_id int,
    p_datos_viejos jsonb DEFAULT null,
    p_datos_nuevos jsonb DEFAULT null,
    p_error text DEFAULT null
)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
    v_tablaid int;
    v_accionid int;
    v_checksum text;
BEGIN
    SELECT tablaid INTO v_tablaid
    FROM tablassistema
    WHERE lower(nombretabla) = lower(p_tabla)
    LIMIT 1;

    SELECT accionid INTO v_accionid
    FROM acciones
    WHERE upper(nombreaccion) = upper(p_accion)
    LIMIT 1;

    IF v_tablaid IS NULL THEN
        INSERT INTO tablassistema(nombretabla)
        VALUES (lower(p_tabla))
        ON CONFLICT(nombretabla) DO NOTHING;

        SELECT tablaid INTO v_tablaid
        FROM tablassistema
        WHERE lower(nombretabla) = lower(p_tabla)
        LIMIT 1;
    END IF;

    IF v_accionid IS NULL THEN
        RETURN;
    END IF;

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

    INSERT INTO logs(
        usuariomodificacion,
        tablaid,
        accionid,
        objetoafectadoid,
        datosviejos,
        datosnuevos,
        error,
        checksum
    )
    VALUES(
        p_usuario,
        v_tablaid,
        v_accionid,
        coalesce(p_objeto_id, 0),
        p_datos_viejos,
        p_datos_nuevos,
        p_error,
        v_checksum
    );
EXCEPTION
    WHEN OTHERS THEN
        NULL;
END;
$$;

CREATE OR REPLACE FUNCTION fn_trigger_log()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    v_usuario int;
    v_objeto_id int := 0;
    v_accion text;
    v_old jsonb;
    v_new jsonb;
BEGIN
    IF tg_op = 'INSERT' THEN
        v_accion := 'CREATE';
        v_new := to_jsonb(new);
    ELSIF tg_op = 'UPDATE' THEN
        v_accion := 'UPDATE';
        v_new := to_jsonb(new);
        v_old := to_jsonb(old);
    ELSE
        v_accion := 'DELETE';
        v_old := to_jsonb(old);
    END IF;

    BEGIN
        v_usuario := (coalesce(v_new, v_old)->>'usuariomodificacion')::int;
    EXCEPTION WHEN OTHERS THEN
        v_usuario := null;
    END;

    IF tg_nargs >= 1 THEN
        BEGIN
            IF tg_op = 'DELETE' THEN
                v_objeto_id := coalesce((to_jsonb(old)->>tg_argv[0])::int, 0);
            ELSE
                v_objeto_id := coalesce((to_jsonb(new)->>tg_argv[0])::int, 0);
            END IF;
        EXCEPTION WHEN OTHERS THEN
            v_objeto_id := 0;
        END;
    END IF;

    PERFORM fn_insert_log(v_usuario, tg_table_name, v_accion, v_objeto_id, v_old, v_new, null);

    RETURN CASE WHEN tg_op = 'DELETE' THEN old ELSE new END;
END;
$$;

CREATE OR REPLACE FUNCTION fn_set_checksum()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    v_data jsonb;
    i int;
BEGIN
    v_data := to_jsonb(new) - 'checksum';

    IF tg_nargs > 0 THEN
        FOR i IN 0 .. tg_nargs - 1 LOOP
            v_data := v_data - lower(tg_argv[i]);
        END LOOP;
    END IF;

    new.checksum := fn_generar_checksum(v_data);
    RETURN new;
END;
$$;

CREATE OR REPLACE FUNCTION fn_update_last_login()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    v_usuario int;
BEGIN
    BEGIN
        v_usuario := (to_jsonb(new)->>'usuariomodificacion')::int;
    EXCEPTION WHEN OTHERS THEN
        v_usuario := null;
    END;

    IF v_usuario IS NOT NULL THEN
        UPDATE usuarios
        SET ultimologin = current_timestamp
        WHERE usuarioid = v_usuario;
    END IF;

    RETURN CASE WHEN tg_op = 'DELETE' THEN old ELSE new END;
END;
$$;

CREATE OR REPLACE PROCEDURE sp_cargar_tablas()
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO tablassistema(nombretabla)
    SELECT lower(table_name)
    FROM information_schema.tables
    WHERE table_schema = 'core'
      AND table_type = 'BASE TABLE'
    ON CONFLICT(nombretabla) DO NOTHING;
END;
$$;

CREATE OR REPLACE FUNCTION fn_validar_division()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    v_orden_division int;
    v_orden_max int;
BEGIN
    SELECT ng.orden
    INTO v_orden_division
    FROM divisionesgeograficas dg
    JOIN nivelesgeograficos ng ON ng.nivelid = dg.nivelid
    WHERE dg.divisionid = new.divisionid;

    SELECT max(ng.orden)
    INTO v_orden_max
    FROM divisionesgeograficas dg
    JOIN nivelesgeograficos ng ON ng.nivelid = dg.nivelid
    WHERE dg.paisid = (
        SELECT paisid FROM divisionesgeograficas WHERE divisionid = new.divisionid
    );

    IF v_orden_division IS NULL THEN
        RAISE EXCEPTION 'La division % no existe', new.divisionid;
    END IF;

    IF v_orden_division <> v_orden_max THEN
        RAISE EXCEPTION 'La division % no es el nivel más bajo del país', new.divisionid;
    END IF;

    RETURN new;
END;
$$;

CREATE OR REPLACE FUNCTION fn_generar_direccion()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    v_ruta text;
BEGIN
    WITH RECURSIVE ruta AS (
        SELECT dg.divisionid, dg.padreid, dg.nombre, ng.orden
        FROM divisionesgeograficas dg
        JOIN nivelesgeograficos ng ON ng.nivelid = dg.nivelid
        WHERE dg.divisionid = new.divisionid
        UNION ALL
        SELECT p.divisionid, p.padreid, p.nombre, ng.orden
        FROM divisionesgeograficas p
        JOIN nivelesgeograficos ng ON ng.nivelid = p.nivelid
        JOIN ruta r ON r.padreid = p.divisionid
    )
    SELECT string_agg(nombre, ', ' ORDER BY orden)
    INTO v_ruta
    FROM ruta;

    new.direccioncompleta := concat_ws(', ', new.calle, new.numero, new.referencia, v_ruta);
    RETURN new;
END;
$$;

CREATE OR REPLACE FUNCTION fn_historial_tipo_cambio()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE historialcambiosmonedas
    SET fechafin = current_timestamp
    WHERE tipocambioid = old.tipocambioid
      AND fechafin = '9999-12-31 23:59:59'::timestamp;

    INSERT INTO historialcambiosmonedas(
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
    VALUES(
        new.moneda1id,
        new.moneda2id,
        new.tipocambioid,
        new.usuariomodificacion,
        current_timestamp,
        '9999-12-31 23:59:59'::timestamp,
        new.tipocambio,
        fn_generar_checksum(jsonb_build_object('moneda1id', new.moneda1id, 'moneda2id', new.moneda2id, 'tipocambioid', new.tipocambioid, 'tipocambio', new.tipocambio)),
        current_timestamp
    );

    RETURN new;
END;
$$;

CREATE OR REPLACE FUNCTION fn_actualizar_balance()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF new.estado = 'completado'
       AND (tg_op = 'INSERT' OR old.estado IS DISTINCT FROM new.estado) THEN
        UPDATE balanceneto
        SET saldo = coalesce(saldo, 0) + coalesce(new.monto, 0),
            ultimaactualizacion = current_timestamp
        WHERE balanceid = 1;

        IF NOT FOUND THEN
            INSERT INTO balanceneto(balanceid, saldo, ultimaactualizacion)
            VALUES (1, coalesce(new.monto, 0), current_timestamp)
            ON CONFLICT(balanceid) DO UPDATE
            SET saldo = balanceneto.saldo + excluded.saldo,
                ultimaactualizacion = current_timestamp;
        END IF;
    END IF;

    RETURN new;
END;
$$;

CREATE OR REPLACE FUNCTION fn_asignar_lote()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    v_loteid int;
BEGIN
    IF new.loteid IS NOT NULL THEN
        RETURN new;
    END IF;

    SELECT loteid
    INTO v_loteid
    FROM lotes
    WHERE productoid = new.productoid
      AND cantidadproductolotedisponible >= new.cantidad
    ORDER BY fechafabricacion ASC, loteid ASC
    LIMIT 1
    FOR UPDATE SKIP LOCKED;

    IF v_loteid IS NULL THEN
        RAISE EXCEPTION 'No hay lotes suficientes para el producto %', new.productoid;
    END IF;

    new.loteid := v_loteid;
    RETURN new;
END;
$$;

CREATE OR REPLACE FUNCTION fn_recalcular_orden()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    v_ordenid int;
BEGIN
    IF tg_table_name = 'ordendetalles' THEN
        v_ordenid := coalesce(new.ordenid, old.ordenid);
    ELSE
        SELECT od.ordenid
        INTO v_ordenid
        FROM ordendetalles od
        WHERE od.ordendetalleid = coalesce(new.ordendetalleid, old.ordendetalleid);
    END IF;

    IF v_ordenid IS NOT NULL THEN
        UPDATE ordenes o
        SET preciofinal = coalesce((
            SELECT sum(coalesce(od.preciolotefinal, 0))
            FROM ordendetalles od
            WHERE od.ordenid = v_ordenid
        ), 0)
        WHERE o.ordenid = v_ordenid;
    END IF;

    RETURN CASE WHEN tg_op = 'DELETE' THEN old ELSE new END;
END;
$$;

CREATE OR REPLACE FUNCTION fn_calcular_totales_detalle(p_ordendetalleid int)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
    v_cantidad int;
    v_precio_unitario numeric(18,6);
    v_costo_envio numeric(18,6);
    v_precio_base numeric(18,6) := 0;
    v_impuestos numeric(18,6) := 0;
    v_permisos numeric(18,6) := 0;
    v_descuentos numeric(18,6) := 0;
BEGIN
    SELECT od.cantidad, p.precio, coalesce(od.costoenvio, 0)
    INTO v_cantidad, v_precio_unitario, v_costo_envio
    FROM ordendetalles od
    JOIN productos p ON p.productoid = od.productoid
    WHERE od.ordendetalleid = p_ordendetalleid;

    IF v_cantidad IS NULL THEN
        RETURN;
    END IF;

    v_precio_base := coalesce(v_precio_unitario, 0) * coalesce(v_cantidad, 0);

    SELECT coalesce(sum(
        CASE
            WHEN ip.tipo = 'porcentaje' THEN (v_precio_base * ip.valor / 100)
            ELSE ip.valor
        END
    ), 0)
    INTO v_impuestos
    FROM ordendetalleimpuestos odi
    JOIN impuestospais ip ON ip.impuestoid = odi.impuestoid
    WHERE odi.ordendetalleid = p_ordendetalleid;

    SELECT coalesce(sum(pi.costo / nullif(pi.tipocambio, 0)), 0)
    INTO v_permisos
    FROM ordendetallepermisos odp
    JOIN permisosimportacion pi ON pi.permisoid = odp.permisoid
    WHERE odp.ordendetalleid = p_ordendetalleid;

    SELECT coalesce(sum(monto), 0)
    INTO v_descuentos
    FROM ordendetalledescuentos
    WHERE ordendetalleid = p_ordendetalleid;

    UPDATE ordendetalles
    SET descuentofinal = v_descuentos,
        preciolotefinal = greatest((v_precio_base + v_impuestos + v_permisos + v_costo_envio) - v_descuentos, 0)
    WHERE ordendetalleid = p_ordendetalleid;
END;
$$;

CREATE OR REPLACE FUNCTION fn_trigger_recalculo_detalle()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    v_id int;
BEGIN

    IF pg_trigger_depth() > 1 THEN
        RETURN CASE
            WHEN tg_op = 'DELETE' THEN old
            ELSE new
        END;
    END IF;

    v_id := coalesce(new.ordendetalleid, old.ordendetalleid);

    IF tg_op <> 'DELETE' AND v_id IS NOT NULL THEN
        PERFORM fn_calcular_totales_detalle(v_id);
    END IF;

    RETURN CASE
        WHEN tg_op = 'DELETE' THEN old
        ELSE new
    END;
END;
$$;

CREATE OR REPLACE FUNCTION fn_actualizar_inventario()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    v_tipo_nombre text;
    v_stock int;
BEGIN

    SELECT nombre
    INTO v_tipo_nombre
    FROM tiposorden
    WHERE tipoordenid = (
        SELECT tipoordenid
        FROM ordenes
        WHERE ordenid = new.ordenid
    );

    SELECT cantidadproductolotedisponible
    INTO v_stock
    FROM lotes
    WHERE loteid = new.loteid
    FOR UPDATE;

    IF v_stock IS NULL THEN
        RAISE EXCEPTION 'No existe el lote %', new.loteid;
    END IF;

    IF lower(v_tipo_nombre) IN ('venta', 'salida') THEN

        IF v_stock < new.cantidad THEN
            RAISE EXCEPTION 'Stock insuficiente en lote %', new.loteid;
        END IF;

        UPDATE lotes
        SET cantidadproductolotedisponible =
            cantidadproductolotedisponible - new.cantidad
        WHERE loteid = new.loteid;

    ELSE

        UPDATE lotes
        SET cantidadproductolotedisponible =
            LEAST(
                cantidadproductoloteinicial,
                cantidadproductolotedisponible + 0
            )
        WHERE loteid = new.loteid;

    END IF;

    UPDATE inventarios
    SET cantidaddisponible = (
            SELECT cantidadproductolotedisponible
            FROM lotes
            WHERE loteid = new.loteid
        ),
        ultimaactualizacion = current_timestamp
    WHERE loteid = new.loteid;

    RETURN new;

END;
$$;

DROP TRIGGER IF EXISTS trg_direcciones_validar_division ON direcciones;
CREATE TRIGGER trg_direcciones_validar_division
BEFORE INSERT OR UPDATE ON direcciones
FOR EACH ROW EXECUTE FUNCTION fn_validar_division();

DROP TRIGGER IF EXISTS trg_direcciones_generar_completa ON direcciones;
CREATE TRIGGER trg_direcciones_generar_completa
BEFORE INSERT OR UPDATE ON direcciones
FOR EACH ROW EXECUTE FUNCTION fn_generar_direccion();

DROP TRIGGER IF EXISTS trg_tiposcambio_historial ON tiposcambio;
CREATE TRIGGER trg_tiposcambio_historial
AFTER UPDATE ON tiposcambio
FOR EACH ROW EXECUTE FUNCTION fn_historial_tipo_cambio();

DROP TRIGGER IF EXISTS trg_estadoscuenta_balance ON estadoscuenta;
CREATE TRIGGER trg_estadoscuenta_balance
AFTER INSERT OR UPDATE OF estado ON estadoscuenta
FOR EACH ROW EXECUTE FUNCTION fn_actualizar_balance();

DROP TRIGGER IF EXISTS trg_ordendetalles_asignar_lote ON ordendetalles;
CREATE TRIGGER trg_ordendetalles_asignar_lote
BEFORE INSERT ON ordendetalles
FOR EACH ROW EXECUTE FUNCTION fn_asignar_lote();

DROP TRIGGER IF EXISTS trg_recalcular_orden_detalles ON ordendetalles;
CREATE TRIGGER trg_recalcular_orden_detalles
AFTER INSERT OR UPDATE OR DELETE ON ordendetalles
FOR EACH ROW EXECUTE FUNCTION fn_recalcular_orden();

DROP TRIGGER IF EXISTS trg_recalcular_orden_impuestos ON ordendetalleimpuestos;
CREATE TRIGGER trg_recalcular_orden_impuestos
AFTER INSERT OR UPDATE OR DELETE ON ordendetalleimpuestos
FOR EACH ROW EXECUTE FUNCTION fn_recalcular_orden();

DROP TRIGGER IF EXISTS trg_recalcular_orden_permisos ON ordendetallepermisos;
CREATE TRIGGER trg_recalcular_orden_permisos
AFTER INSERT OR UPDATE OR DELETE ON ordendetallepermisos
FOR EACH ROW EXECUTE FUNCTION fn_recalcular_orden();

DROP TRIGGER IF EXISTS trg_recalcular_orden_descuentos ON ordendetalledescuentos;
CREATE TRIGGER trg_recalcular_orden_descuentos
AFTER INSERT OR UPDATE OR DELETE ON ordendetalledescuentos
FOR EACH ROW EXECUTE FUNCTION fn_recalcular_orden();

DROP TRIGGER IF EXISTS trg_inventario_movimiento ON ordendetalles;
CREATE TRIGGER trg_inventario_movimiento
AFTER INSERT ON ordendetalles
FOR EACH ROW EXECUTE FUNCTION fn_actualizar_inventario();

DROP TRIGGER IF EXISTS trg_checksum_tiposcambio ON tiposcambio;
CREATE TRIGGER trg_checksum_tiposcambio
BEFORE INSERT OR UPDATE ON tiposcambio
FOR EACH ROW EXECUTE FUNCTION fn_set_checksum('tiempocreacion', 'ultimaactualizacion', 'activo');

DROP TRIGGER IF EXISTS trg_checksum_historialcambiosmonedas ON historialcambiosmonedas;
CREATE TRIGGER trg_checksum_historialcambiosmonedas
BEFORE INSERT OR UPDATE ON historialcambiosmonedas
FOR EACH ROW EXECUTE FUNCTION fn_set_checksum('fechainicio', 'fechafin', 'horacambio');

DROP TRIGGER IF EXISTS trg_checksum_ordendetalles ON ordendetalles;
CREATE TRIGGER trg_checksum_ordendetalles
BEFORE INSERT OR UPDATE ON ordendetalles
FOR EACH ROW EXECUTE FUNCTION fn_set_checksum('descuentofinal', 'preciolotefinal');

DROP TRIGGER IF EXISTS trg_checksum_transacciones ON transacciones;
CREATE TRIGGER trg_checksum_transacciones
BEFORE INSERT OR UPDATE ON transacciones
FOR EACH ROW EXECUTE FUNCTION fn_set_checksum('fecha');

DROP TRIGGER IF EXISTS trg_checksum_estadoscuenta ON estadoscuenta;
CREATE TRIGGER trg_checksum_estadoscuenta
BEFORE INSERT OR UPDATE ON estadoscuenta
FOR EACH ROW EXECUTE FUNCTION fn_set_checksum('fecharegistro');

DROP TRIGGER IF EXISTS trg_calc_detalle ON ordendetalles;
CREATE TRIGGER trg_calc_detalle
AFTER INSERT OR UPDATE ON ordendetalles
FOR EACH ROW EXECUTE FUNCTION fn_trigger_recalculo_detalle();

DROP TRIGGER IF EXISTS trg_calc_impuestos ON ordendetalleimpuestos;
CREATE TRIGGER trg_calc_impuestos
AFTER INSERT OR UPDATE OR DELETE ON ordendetalleimpuestos
FOR EACH ROW EXECUTE FUNCTION fn_trigger_recalculo_detalle();

DROP TRIGGER IF EXISTS trg_calc_permisos ON ordendetallepermisos;
CREATE TRIGGER trg_calc_permisos
AFTER INSERT OR UPDATE OR DELETE ON ordendetallepermisos
FOR EACH ROW EXECUTE FUNCTION fn_trigger_recalculo_detalle();

DROP TRIGGER IF EXISTS trg_calc_descuentos ON ordendetalledescuentos;
CREATE TRIGGER trg_calc_descuentos
AFTER INSERT OR UPDATE OR DELETE ON ordendetalledescuentos
FOR EACH ROW EXECUTE FUNCTION fn_trigger_recalculo_detalle();
