-- =========================================
-- 1. POBLAR TABLA "Tablas"
-- =========================================
INSERT INTO Tablas(nombreTabla)
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
AND table_name NOT IN ('logs','tablas')
ON CONFLICT DO NOTHING;

-- =========================================
-- 2. ACCIONES BASE
-- =========================================
INSERT INTO Acciones(nombreAccion)
VALUES ('INSERT'), ('UPDATE'), ('DELETE')
ON CONFLICT DO NOTHING;

-- =========================================
-- 3. FUNCIÓN PK DINÁMICO
-- =========================================
CREATE OR REPLACE FUNCTION fn_get_pk_column(p_table TEXT)
RETURNS TEXT AS $$
DECLARE v_pk TEXT;
BEGIN
    SELECT a.attname INTO v_pk
    FROM pg_index i -- consulta automaticamente las PK de Postgre
    JOIN pg_attribute a 
        ON a.attrelid = i.indrelid 
       AND a.attnum = ANY(i.indkey)
    WHERE i.indrelid = p_table::regclass
    AND i.indisprimary
    LIMIT 1;

    RETURN v_pk;
END;
$$ LANGUAGE plpgsql;

-- =========================================
-- 4. FUNCIÓN LOG
-- =========================================
CREATE OR REPLACE FUNCTION fn_insert_log(
    p_usuario INT,
    p_tabla TEXT,
    p_accion TEXT,
    p_objeto_id INT,
    p_old JSON,
    p_new JSON,
    p_error TEXT DEFAULT NULL
)
RETURNS VOID AS $$
DECLARE v_tablaID INT; v_accionID INT;
BEGIN
    SELECT tablaID INTO v_tablaID FROM Tablas WHERE LOWER(nombreTabla)=LOWER(p_tabla);
    SELECT accionID INTO v_accionID FROM Acciones WHERE nombreAccion=p_accion;

    INSERT INTO Logs(usuarioModificacion,tablaID,accionID,objetoAfectadoID,datosViejos,datosNuevos,error)
    VALUES (p_usuario,v_tablaID,v_accionID,p_objeto_id,p_old,p_new,p_error);

EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Error log: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- =========================================
-- 5. TRIGGER GLOBAL LOG
-- =========================================
CREATE OR REPLACE FUNCTION fn_trigger_log()
RETURNS TRIGGER AS $$
DECLARE v_pk TEXT; v_id INT; v_usuario INT;
BEGIN
    v_pk := fn_get_pk_column(TG_TABLE_NAME);

    IF TG_OP='INSERT' THEN
        v_id := (to_jsonb(NEW)->>v_pk)::INT;
        v_usuario := NEW.usuarioModificacion;
        PERFORM fn_insert_log(v_usuario,TG_TABLE_NAME,'INSERT',v_id,NULL,row_to_json(NEW),NULL);
        RETURN NEW;

    ELSIF TG_OP='UPDATE' THEN
        v_id := (to_jsonb(NEW)->>v_pk)::INT;
        v_usuario := NEW.usuarioModificacion;
        PERFORM fn_insert_log(v_usuario,TG_TABLE_NAME,'UPDATE',v_id,row_to_json(OLD),row_to_json(NEW),NULL);
        RETURN NEW;

    ELSIF TG_OP='DELETE' THEN
        v_id := (to_jsonb(OLD)->>v_pk)::INT;
        v_usuario := OLD.usuarioModificacion;
        PERFORM fn_insert_log(v_usuario,TG_TABLE_NAME,'DELETE',v_id,row_to_json(OLD),NULL,NULL);
        RETURN OLD;
    END IF;

EXCEPTION WHEN OTHERS THEN
    PERFORM fn_insert_log(NULL,TG_TABLE_NAME,TG_OP,NULL,NULL,NULL,SQLERRM);
    RAISE;
END;
$$ LANGUAGE plpgsql;

-- =========================================
-- 6. UPDATE ultimoLogin
-- =========================================
CREATE OR REPLACE FUNCTION fn_update_last_login()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.usuarioModificacion IS NOT NULL THEN
        UPDATE Usuarios
        SET ultimoLogin = CURRENT_TIMESTAMP
        WHERE usuarioID = NEW.usuarioModificacion;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- =========================================
-- 7. DIRECCIONES
-- =========================================
CREATE OR REPLACE FUNCTION fn_validar_division()
RETURNS TRIGGER AS $$
DECLARE v_max INT; v_actual INT;
BEGIN
    SELECT MAX(nivelID) INTO v_max FROM NivelesGeograficos;
    SELECT nivelID INTO v_actual FROM DivisionesGeograficas WHERE divisionID=NEW.divisionID;

    IF v_actual <> v_max THEN
        RAISE EXCEPTION 'Division no es nivel más bajo';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION fn_generar_direccion()
RETURNS TRIGGER AS $$
DECLARE v_text TEXT := ''; v_nombre TEXT; v_padre INT; v_id INT := NEW.divisionID;
BEGIN
    WHILE v_id IS NOT NULL LOOP
        SELECT nombre, padreID INTO v_nombre, v_padre
        FROM DivisionesGeograficas
        WHERE divisionID = v_id;

        v_text := v_nombre || ', ' || v_text;
        v_id := v_padre;
    END LOOP;

    NEW.direccionCompleta :=
        TRIM(v_text) || ' ' ||
        COALESCE(NEW.calle,'') || ' ' ||
        COALESCE(NEW.numero,'') || ' ' ||
        COALESCE(NEW.referencia,'');

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- =========================================
-- 8. MONEDAS
-- =========================================
CREATE OR REPLACE FUNCTION fn_validar_monedas()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.moneda1ID = NEW.moneda2ID THEN
        RAISE EXCEPTION 'Monedas iguales no permitidas';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION fn_historial_tipo_cambio()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE HistorialCambiosMonedas
    SET fechaFin = CURRENT_TIMESTAMP
    WHERE tipoCambioID = OLD.tipoCambioID
    AND fechaFin = '9999-12-31';

    INSERT INTO HistorialCambiosMonedas(
        moneda1ID, moneda2ID, tipoCambioID,
        usuarioModificacion, fechaInicio, fechaFin, tipoCambio
    )
    VALUES (
        NEW.moneda1ID, NEW.moneda2ID, NEW.tipoCambioID,
        NEW.usuarioModificacion, CURRENT_TIMESTAMP,
        '9999-12-31', NEW.tipoCambio
    );

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- =========================================
-- 9. ORDENES AUTOMÁTICAS
-- =========================================
CREATE OR REPLACE FUNCTION fn_post_orden()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO Transacciones(monedaID,usuarioModificacion,tipoID,estadoTransaccionID,ordenID,monto)
    VALUES (1,NEW.usuarioModificacion,1,1,NEW.ordenID,NEW.precioFinal);

    INSERT INTO EstadosCuenta(ordenID,usuarioModificacion,tipoMovimiento,estado,monto)
    VALUES (NEW.ordenID,NEW.usuarioModificacion,'Debito','pendiente',NEW.precioFinal);

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- =========================================
-- 10. BALANCE
-- =========================================
CREATE OR REPLACE FUNCTION fn_actualizar_balance()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.estado='completado' THEN
        UPDATE BalanceNeto
        SET saldo = saldo + NEW.monto,
            ultimaActualizacion = CURRENT_TIMESTAMP;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- =========================================
-- 11. TRIGGERS DINÁMICOS
-- =========================================
DO $$
DECLARE r RECORD; v_exists INT;
BEGIN
    FOR r IN
        SELECT table_name
        FROM information_schema.columns
        WHERE column_name='usuarioModificacion'
        AND table_schema='public'
    LOOP
        SELECT COUNT(*) INTO v_exists FROM pg_trigger WHERE tgname='trg_log_'||r.table_name;

        IF v_exists=0 THEN
            EXECUTE format('
                CREATE TRIGGER trg_log_%I
                AFTER INSERT OR UPDATE OR DELETE ON %I
                FOR EACH ROW EXECUTE FUNCTION fn_trigger_log();
            ',r.table_name,r.table_name);
        END IF;

        SELECT COUNT(*) INTO v_exists FROM pg_trigger WHERE tgname='trg_login_'||r.table_name;

        IF v_exists=0 THEN
            EXECUTE format('
                CREATE TRIGGER trg_login_%I
                AFTER INSERT OR UPDATE ON %I
                FOR EACH ROW EXECUTE FUNCTION fn_update_last_login();
            ',r.table_name,r.table_name);
        END IF;
    END LOOP;
END;
$$;

-- =========================================
-- 12. CHECKSUM ESPECÍFICOS
-- =========================================

-- TiposCambio
CREATE FUNCTION fn_checksum_tipos_cambio() RETURNS TRIGGER AS $$
BEGIN
    NEW.checksum := md5(NEW.moneda1ID||'|'||NEW.moneda2ID||'|'||NEW.tipoCambio);
    RETURN NEW;
END; $$ LANGUAGE plpgsql;
CREATE TRIGGER trg_checksum_tiposCambio BEFORE INSERT OR UPDATE ON TiposCambio FOR EACH ROW EXECUTE FUNCTION fn_checksum_tipos_cambio();

-- Historial
CREATE FUNCTION fn_checksum_historial() RETURNS TRIGGER AS $$
BEGIN
    NEW.checksum := md5(NEW.moneda1ID||'|'||NEW.moneda2ID||'|'||NEW.tipoCambioID||'|'||NEW.tipoCambio);
    RETURN NEW;
END; $$ LANGUAGE plpgsql;
CREATE TRIGGER trg_checksum_historial BEFORE INSERT OR UPDATE ON HistorialCambiosMonedas FOR EACH ROW EXECUTE FUNCTION fn_checksum_historial();

-- OrdenDetalles
CREATE FUNCTION fn_checksum_orden_detalles() RETURNS TRIGGER AS $$
BEGIN
    NEW.checksum := md5(
        NEW.ordenID||'|'||NEW.loteID||'|'||
        NEW.impuestoID||'|'||NEW.permisoID||'|'||
        NEW.cantidad||'|'||
        COALESCE(NEW.descuento,0)||'|'||
        COALESCE(NEW.costoEnvio,0)
    );
    RETURN NEW;
END; $$ LANGUAGE plpgsql;
CREATE TRIGGER trg_checksum_ordenDetalles BEFORE INSERT OR UPDATE ON OrdenDetalles FOR EACH ROW EXECUTE FUNCTION fn_checksum_orden_detalles();

-- Transacciones
CREATE FUNCTION fn_checksum_transacciones() RETURNS TRIGGER AS $$
BEGIN
    NEW.checksum := md5(NEW.monedaID||'|'||NEW.tipoID||'|'||NEW.estadoTransaccionID||'|'||NEW.ordenID||'|'||NEW.monto);
    RETURN NEW;
END; $$ LANGUAGE plpgsql;
CREATE TRIGGER trg_checksum_transacciones BEFORE INSERT OR UPDATE ON Transacciones FOR EACH ROW EXECUTE FUNCTION fn_checksum_transacciones();

-- EstadosCuenta
CREATE FUNCTION fn_checksum_estados_cuenta() RETURNS TRIGGER AS $$
BEGIN
    NEW.checksum := md5(NEW.ordenID||'|'||NEW.tipoMovimiento||'|'||NEW.estado||'|'||NEW.monto);
    RETURN NEW;
END; $$ LANGUAGE plpgsql;
CREATE TRIGGER trg_checksum_estadosCuenta BEFORE INSERT OR UPDATE ON EstadosCuenta FOR EACH ROW EXECUTE FUNCTION fn_checksum_estados_cuenta();

-- Logs
CREATE FUNCTION fn_checksum_logs() RETURNS TRIGGER AS $$
BEGIN
    NEW.checksum := md5(
        COALESCE(NEW.usuarioModificacion,0)||'|'||
        NEW.tablaID||'|'||
        NEW.accionID||'|'||
        NEW.objetoAfectadoID
    );
    RETURN NEW;
END; $$ LANGUAGE plpgsql;
CREATE TRIGGER trg_checksum_logs BEFORE INSERT ON Logs FOR EACH ROW EXECUTE FUNCTION fn_checksum_logs();

-- =========================================
-- 13. TRIGGERS RESTANTES
-- =========================================

CREATE TRIGGER trg_validar_direccion BEFORE INSERT OR UPDATE ON Direcciones FOR EACH ROW EXECUTE FUNCTION fn_validar_division();
CREATE TRIGGER trg_generar_direccion BEFORE INSERT OR UPDATE ON Direcciones FOR EACH ROW EXECUTE FUNCTION fn_generar_direccion();
CREATE TRIGGER trg_validar_monedas BEFORE INSERT OR UPDATE ON TiposCambio FOR EACH ROW EXECUTE FUNCTION fn_validar_monedas();
CREATE TRIGGER trg_historial_tipo_cambio AFTER UPDATE ON TiposCambio FOR EACH ROW EXECUTE FUNCTION fn_historial_tipo_cambio();
CREATE TRIGGER trg_post_orden AFTER INSERT ON Ordenes FOR EACH ROW EXECUTE FUNCTION fn_post_orden();
CREATE TRIGGER trg_balance AFTER UPDATE ON EstadosCuenta FOR EACH ROW EXECUTE FUNCTION fn_actualizar_balance();