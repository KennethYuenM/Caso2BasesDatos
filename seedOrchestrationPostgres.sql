CALL sp_cargar_tablas();

DO $$
DECLARE
    r record;
BEGIN
    FOR r IN
        SELECT * FROM (VALUES
            ('rolesxusuario', null), ('permisosxrole', null), ('divisionesgeograficas', 'divisionid'),
            ('direcciones', 'direccionid'), ('contactos', 'contactoid'), ('telefonoscontactos', 'telefonocontactoid'),
            ('correoscontactos', 'correocontactoid'), ('centroslogisticos', 'centrologisticoid'),
            ('proveedores', 'proveedorid'), ('contactosproveedor', null), ('productos', 'productoid'),
            ('valorcaracteristicas', null), ('monedas', 'monedaid'), ('tiposcambio', 'tipocambioid'),
            ('historialcambiosmonedas', 'historialcambioid'), ('permisosimportacion', 'permisoid'),
            ('lotes', 'loteid'), ('movimientosinventario', 'movimientoid'), ('inventarios', 'inventarioid'),
            ('historialpreciosproducto', 'historialprecioid'), ('ordenes', 'ordenid'), ('ordendetalles', 'ordendetalleid'),
            ('ordendetalleimpuestos', null), ('ordendetallepermisos', null), ('ordendetalledescuentos', 'ordendetalledescuentoid'),
            ('trazabilidadorden', 'trazabilidadid'), ('impuestospais', 'impuestoid'), ('transacciones', 'transaccionid'),
            ('estadoscuenta', 'estadocuentaid'), ('balanceneto', 'balanceid')
        ) AS t(table_name, pk_col)
    LOOP
        EXECUTE format('DROP TRIGGER IF EXISTS %I ON %I;', 'trg_audit_' || r.table_name, r.table_name);

        IF r.pk_col IS NULL THEN
            EXECUTE format(
                'CREATE TRIGGER %I AFTER INSERT OR UPDATE OR DELETE ON %I FOR EACH ROW EXECUTE FUNCTION fn_trigger_log();',
                'trg_audit_' || r.table_name,
                r.table_name
            );
        ELSE
            EXECUTE format(
                'CREATE TRIGGER %I AFTER INSERT OR UPDATE OR DELETE ON %I FOR EACH ROW EXECUTE FUNCTION fn_trigger_log(%L);',
                'trg_audit_' || r.table_name,
                r.table_name,
                r.pk_col
            );
        END IF;
    END LOOP;
END $$;

DO $$
DECLARE
    r record;
BEGIN
    FOR r IN
        SELECT table_name
        FROM information_schema.columns
        WHERE table_schema = 'core'
          AND column_name = 'usuariomodificacion'
          AND table_name <> 'usuarios'
    LOOP
        EXECUTE format('DROP TRIGGER IF EXISTS %I ON %I;', 'trg_lastlogin_' || r.table_name, r.table_name);
        EXECUTE format(
            'CREATE TRIGGER %I AFTER INSERT OR UPDATE ON %I FOR EACH ROW EXECUTE FUNCTION fn_update_last_login();',
            'trg_lastlogin_' || r.table_name,
            r.table_name
        );
    END LOOP;
END $$;

CREATE OR REPLACE PROCEDURE sp_cargar_support_base()
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO acciones(nombreaccion)
    VALUES ('CREATE'), ('READ'), ('UPDATE'), ('DELETE'), ('ERROR')
    ON CONFLICT(nombreaccion) DO NOTHING;

    CALL sp_cargar_tablas();
END;
$$;

CREATE OR REPLACE PROCEDURE sp_log_proceso(
    p_proceso text,
    p_tabla text,
    p_estado text,
    p_mensaje text,
    p_objeto_id int DEFAULT 0
)
LANGUAGE plpgsql
AS $$
BEGIN
    PERFORM fn_insert_log(
        null,
        p_tabla,
        CASE WHEN upper(p_estado) = 'ERROR' THEN 'ERROR' ELSE 'CREATE' END,
        coalesce(p_objeto_id, 0),
        null,
        jsonb_build_object('proceso', p_proceso, 'estado', p_estado, 'mensaje', p_mensaje),
        CASE WHEN upper(p_estado) = 'ERROR' THEN p_mensaje ELSE null END
    );
EXCEPTION
    WHEN OTHERS THEN
        NULL;
END;
$$;

CREATE OR REPLACE PROCEDURE sp_cargar_catalogos_etheria()
LANGUAGE plpgsql
AS $$
DECLARE
    v_admin int;
    r record;
BEGIN
    INSERT INTO usuarios(nombreusuario, apellido, segundoapellido, email, contraseñahash, activo)
    VALUES ('Admin', 'Etheria', 'Global', 'admin@etheria.global', encode(digest('Etheria@2026', 'sha256'), 'hex'), true)
    ON CONFLICT(email) DO NOTHING;

    SELECT usuarioid INTO v_admin FROM usuarios WHERE email = 'admin@etheria.global' LIMIT 1;

    IF v_admin IS NULL THEN
        RAISE EXCEPTION 'No existe usuario administrador';
    END IF;

    FOR r IN SELECT * FROM (VALUES
        ('Administrador', 'Acceso total al sistema'),
        ('Operador', 'Operación diaria'),
        ('Auditor', 'Consulta y trazabilidad')
    ) AS x(rolnombre, descripcion)
    LOOP
        INSERT INTO roles(rolnombre, descripcion)
        VALUES (r.rolnombre, r.descripcion)
        ON CONFLICT(rolnombre) DO NOTHING;
    END LOOP;

    FOR r IN SELECT * FROM (VALUES
        ('Gestionar catalogos', 'Alta y mantenimiento de catálogos'),
        ('Gestionar inventario', 'Movimientos y existencias'),
        ('Gestionar ordenes', 'Registro de órdenes'),
        ('Ver reportes', 'Consulta de información')
    ) AS x(nombrepermiso, descripcion)
    LOOP
        INSERT INTO permisossistema(nombrepermiso, descripcion)
        VALUES (r.nombrepermiso, r.descripcion)
        ON CONFLICT(nombrepermiso) DO NOTHING;
    END LOOP;

    INSERT INTO rolesxusuario(usuarioid, roleid)
    SELECT v_admin, roleid
    FROM roles
    WHERE rolnombre = 'Administrador'
    ON CONFLICT DO NOTHING;

    INSERT INTO permisosxrole(roleid, permisoid)
	SELECT rl.roleid, p.permisoid
	FROM roles rl
	JOIN permisossistema p ON true
	WHERE rl.rolnombre = 'Administrador'
	   OR (rl.rolnombre = 'Operador'
	       AND p.nombrepermiso IN ('Gestionar inventario', 'Gestionar ordenes'))
	   OR (rl.rolnombre = 'Auditor'
	       AND p.nombrepermiso = 'Ver reportes')
	ON CONFLICT DO NOTHING;

    FOR r IN SELECT * FROM (VALUES ('Pais',1), ('Region',2), ('Ciudad',3)) AS x(nombre, orden)
    LOOP
        INSERT INTO nivelesgeograficos(nombrengeografico, orden)
        VALUES (r.nombre, r.orden)
        ON CONFLICT(nombrengeografico) DO NOTHING;
    END LOOP;

    INSERT INTO tiposcontactos(nombretipocontacto)
    VALUES ('Proveedor'), ('CentroLogistico')
    ON CONFLICT(nombretipocontacto) DO NOTHING;

    INSERT INTO tipostelefonos(nombretipotelefono)
    VALUES ('Movil'), ('Oficina'), ('WhatsApp')
    ON CONFLICT(nombretipotelefono) DO NOTHING;

    INSERT INTO tiposcentrologistico(nombretipoclogistico)
    VALUES ('Hub'), ('Bodega')
    ON CONFLICT(nombretipoclogistico) DO NOTHING;

    INSERT INTO categorias(nombrecategoriap)
    VALUES ('Bebidas'), ('Alimentos'), ('Cosmetica dermatologica'), ('Cosmetica capilar'), ('Aromaterapia'), ('Jabones'), ('Aceites esenciales')
    ON CONFLICT(nombrecategoriap) DO NOTHING;

    INSERT INTO caracteristicas(nombrecaracteristicap)
    VALUES ('Origen botanico'), ('Beneficio principal'), ('Aroma'), ('Presentacion'), ('Uso recomendado'), ('Conservacion')
    ON CONFLICT(nombrecaracteristicap) DO NOTHING;

    INSERT INTO tipospermisos(nombretipopermiso)
    VALUES ('Sanitario'), ('Etiquetado'), ('Aduana')
    ON CONFLICT(nombretipopermiso) DO NOTHING;

    INSERT INTO estadosordenes(nombreestadoorden)
    VALUES ('Pendiente'), ('Completada'), ('Cancelada')
    ON CONFLICT(nombreestadoorden) DO NOTHING;

    INSERT INTO tiposorden(nombre)
    VALUES ('Importacion'), ('Ajuste'), ('Venta'), ('Salida')
    ON CONFLICT(nombre) DO NOTHING;

    INSERT INTO estadotransacciones(nombreestadotransac)
    VALUES ('Pendiente'), ('Aprobada'), ('Rechazada')
    ON CONFLICT(nombreestadotransac) DO NOTHING;

    INSERT INTO tipotransacciones(nombretipotransac)
    VALUES ('Compra importacion'), ('Pago permiso'), ('Ajuste inventario')
    ON CONFLICT(nombretipotransac) DO NOTHING;

    INSERT INTO tipomovimientosinventario(nombretipomovimientoinventario)
    VALUES ('Entrada'), ('Salida'), ('Ajuste')
    ON CONFLICT(nombretipomovimientoinventario) DO NOTHING;

    CALL sp_log_proceso('sp_cargar_catalogos_etheria', 'catalogos', 'OK', 'Catalogos base cargados', 0);
END;
$$;

CREATE OR REPLACE PROCEDURE sp_cargar_geografia_etheria()
LANGUAGE plpgsql
AS $$
DECLARE
    v_admin int;
    v_nivel_pais int;
    v_nivel_region int;
    v_nivel_ciudad int;
    v_pais int;
    v_div_pais int;
    v_div_region int;
    v_div_ciudad int;
    r record;
BEGIN
    SELECT usuarioid INTO v_admin FROM usuarios WHERE email = 'admin@etheria.global' LIMIT 1;
    SELECT nivelid INTO v_nivel_pais FROM nivelesgeograficos WHERE orden = 1 LIMIT 1;
    SELECT nivelid INTO v_nivel_region FROM nivelesgeograficos WHERE orden = 2 LIMIT 1;
    SELECT nivelid INTO v_nivel_ciudad FROM nivelesgeograficos WHERE orden = 3 LIMIT 1;

    FOR r IN SELECT * FROM (VALUES
        ('Estados Unidos', 'USA', 'California', 'Los Angeles', 'West District', 'Hub Logistico Caribe', '1', '10001'),
        ('Nicaragua', 'NIC', 'Managua', 'Managua', 'Managua Centro', 'Hub Logistico Caribe', '1', '11001'),
        ('Colombia', 'COL', 'Cundinamarca', 'Bogota', 'Zona Norte', 'Sede Oriente', '45', '110111'),
        ('Peru', 'PER', 'Lima', 'Lima', 'Miraflores', 'Sede Andina', '120', '15074'),
        ('Mexico', 'MEX', 'CDMX', 'Ciudad de Mexico', 'Centro', 'Sede Centro', '88', '01000'),
        ('Chile', 'CHL', 'Santiago', 'Santiago', 'Providencia', 'Sede Austral', '300', '7500000')
    ) AS x(pais, iso, region, ciudad, subdivision, calle, numero, cp)
    LOOP
        INSERT INTO paises(nombrepais, codigoiso, activo)
        VALUES (r.pais, r.iso, true)
        ON CONFLICT(codigoiso) DO UPDATE SET nombrepais = excluded.nombrepais
        RETURNING paisid INTO v_pais;

        INSERT INTO divisionesgeograficas(paisid, nivelid, padreid, nombre)
        VALUES (v_pais, v_nivel_pais, null, r.pais)
        ON CONFLICT(paisid, nivelid, COALESCE(padreid, 0), nombre) DO UPDATE SET nombre = excluded.nombre
        RETURNING divisionid INTO v_div_pais;

        INSERT INTO divisionesgeograficas(paisid, nivelid, padreid, nombre)
        VALUES (v_pais, v_nivel_region, v_div_pais, r.region)
        ON CONFLICT(paisid, nivelid, COALESCE(padreid, 0), nombre) DO UPDATE SET nombre = excluded.nombre
        RETURNING divisionid INTO v_div_region;

        INSERT INTO divisionesgeograficas(paisid, nivelid, padreid, nombre)
        VALUES (v_pais, v_nivel_ciudad, v_div_region, r.ciudad)
        ON CONFLICT(paisid, nivelid, COALESCE(padreid, 0), nombre) DO UPDATE SET nombre = excluded.nombre
        RETURNING divisionid INTO v_div_ciudad;

        IF r.iso = 'NIC' AND NOT EXISTS (
            SELECT 1 FROM direcciones WHERE referencia = 'Centro logistico principal de Etheria Global'
        ) THEN
            INSERT INTO direcciones(divisionid, usuariomodificacion, calle, numero, geoposicion, referencia, codigopostal, activo)
            VALUES (v_div_ciudad, v_admin, r.calle, r.numero, null, 'Centro logistico principal de Etheria Global', r.cp, true);
        END IF;
    END LOOP;

    CALL sp_log_proceso('sp_cargar_geografia_etheria', 'geografia', 'OK', 'Paises y divisiones cargados', 0);
END;
$$;

CREATE OR REPLACE PROCEDURE sp_cargar_proveedores_etheria()
LANGUAGE plpgsql
AS $$
DECLARE
    v_admin int;
    v_tipo_contacto_prov int;
    v_tipo_contacto_hub int;
    v_tipo_tel int;
    v_tipo_centro_hub int;
    v_hub_direccion int;
    v_hub_contacto int;
    v_div_ciudad int;
    v_dir_proveedor int;
    v_contacto int;
    v_proveedor int;
    r record;
BEGIN
    SELECT usuarioid INTO v_admin FROM usuarios WHERE email = 'admin@etheria.global' LIMIT 1;
    SELECT tipocontactoid INTO v_tipo_contacto_prov FROM tiposcontactos WHERE nombretipocontacto = 'Proveedor' LIMIT 1;
    SELECT tipocontactoid INTO v_tipo_contacto_hub FROM tiposcontactos WHERE nombretipocontacto = 'CentroLogistico' LIMIT 1;
    SELECT tipotelefonoid INTO v_tipo_tel FROM tipostelefonos WHERE nombretipotelefono = 'Movil' LIMIT 1;
    SELECT tipoid INTO v_tipo_centro_hub FROM tiposcentrologistico WHERE nombretipoclogistico = 'Hub' LIMIT 1;
    SELECT direccionid INTO v_hub_direccion FROM direcciones WHERE referencia = 'Centro logistico principal de Etheria Global' LIMIT 1;

    IF NOT EXISTS (SELECT 1 FROM centroslogisticos WHERE nombrecentrologistico = 'HUB Caribe Nicaragua') THEN
        INSERT INTO contactos(tipocontactoid, usuariomodificacion, nombrecontacto, apellido, segundoapellido, activo)
        VALUES (v_tipo_contacto_hub, v_admin, 'Hub', 'Etheria', 'Global', true)
        RETURNING contactoid INTO v_hub_contacto;

        INSERT INTO telefonoscontactos(contactoid, tipotelefonosid, usuariomodificacion, numerocontacto, activo)
        VALUES (v_hub_contacto, v_tipo_tel, v_admin, '+505-8888-0000', true);

        INSERT INTO correoscontactos(contactoid, usuariomodificacion, correo, activo)
        VALUES (v_hub_contacto, v_admin, 'hub@etheria.global', true);

        INSERT INTO centroslogisticos(tipoid, direccionid, contactoid, usuariomodificacion, nombrecentrologistico, telefono, activo)
        VALUES (v_tipo_centro_hub, v_hub_direccion, v_hub_contacto, v_admin, 'HUB Caribe Nicaragua', '+505-8888-0000', true);
    END IF;

    FOR r IN SELECT * FROM (VALUES
        ('Proveedor Andino', 'Colombia', 'Bogota', 'proveedor.andino@etheria.global', '+57-300-111-1111'),
        ('Proveedor Pacífico', 'Peru', 'Lima', 'proveedor.pacifico@etheria.global', '+51-900-222-222'),
        ('Proveedor Azteca', 'Mexico', 'Ciudad de Mexico', 'proveedor.azteca@etheria.global', '+52-55-3333-3333'),
        ('Proveedor Austral', 'Chile', 'Santiago', 'proveedor.austral@etheria.global', '+56-9-4444-4444'),
        ('Proveedor Centro', 'Nicaragua', 'Managua', 'proveedor.centro@etheria.global', '+505-8888-1111')
    ) AS x(nombreproveedor, pais, ciudad, correo, telefono)
    LOOP
        IF NOT EXISTS (SELECT 1 FROM proveedores WHERE nombreproveedor = r.nombreproveedor) THEN
            SELECT d.divisionid
            INTO v_div_ciudad
            FROM paises p
            JOIN divisionesgeograficas d ON d.paisid = p.paisid
            JOIN nivelesgeograficos n ON n.nivelid = d.nivelid
            WHERE p.nombrepais = r.pais
              AND d.nombre = r.ciudad
              AND n.orden = 3
            LIMIT 1;

            INSERT INTO direcciones(divisionid, usuariomodificacion, calle, numero, geoposicion, referencia, codigopostal, activo)
            VALUES (v_div_ciudad, v_admin, 'Calle Principal', '100', null, 'Direccion de proveedor ' || r.nombreproveedor, '00000', true)
            RETURNING direccionid INTO v_dir_proveedor;

            INSERT INTO contactos(tipocontactoid, usuariomodificacion, nombrecontacto, apellido, segundoapellido, activo)
            VALUES (v_tipo_contacto_prov, v_admin, r.nombreproveedor, 'Sourcing', 'Global', true)
            RETURNING contactoid INTO v_contacto;

            INSERT INTO telefonoscontactos(contactoid, tipotelefonosid, usuariomodificacion, numerocontacto, activo)
            VALUES (v_contacto, v_tipo_tel, v_admin, r.telefono, true);

            INSERT INTO correoscontactos(contactoid, usuariomodificacion, correo, activo)
            VALUES (v_contacto, v_admin, r.correo, true);

            INSERT INTO proveedores(direccionid, nombreproveedor, activo)
            VALUES (v_dir_proveedor, r.nombreproveedor, true)
            RETURNING proveedorid INTO v_proveedor;

            INSERT INTO contactosproveedor(proveedorid, contactoid, activo)
            VALUES (v_proveedor, v_contacto, true)
            ON CONFLICT DO NOTHING;
        END IF;
    END LOOP;

    CALL sp_log_proceso('sp_cargar_proveedores_etheria', 'proveedores', 'OK', 'Proveedores, contactos y HUB cargados', 0);
END;
$$;

CREATE OR REPLACE PROCEDURE sp_cargar_finanzas_etheria()
LANGUAGE plpgsql
AS $$
DECLARE
    v_admin int;
    v_m_usd int;
    v_pais int;
    v_moneda int;
    v_tc int;
    v_tipo_permiso int;
    r record;
BEGIN
    SELECT usuarioid INTO v_admin FROM usuarios WHERE email = 'admin@etheria.global' LIMIT 1;

    SELECT paisid INTO v_pais FROM paises WHERE codigoiso = 'USA' LIMIT 1;
    INSERT INTO monedas(usuariomodificacion, paisid, simbolomoneda, nombremoneda, activo)
    VALUES (v_admin, v_pais, '$', 'USD', true)
    ON CONFLICT(nombremoneda) DO UPDATE SET paisid = excluded.paisid
    RETURNING monedaid INTO v_m_usd;

    FOR r IN SELECT * FROM (VALUES
        ('NIC', 'C$', 'NIO', 36.500000),
        ('COL', 'COP$', 'COP', 3950.000000),
        ('PER', 'S/', 'PEN', 3.750000),
        ('MEX', '$', 'MXN', 17.200000),
        ('CHL', '$', 'CLP', 930.000000)
    ) AS x(iso, simbolo, moneda, rate)
    LOOP
        SELECT paisid INTO v_pais FROM paises WHERE codigoiso = r.iso LIMIT 1;

        INSERT INTO monedas(usuariomodificacion, paisid, simbolomoneda, nombremoneda, activo)
        VALUES (v_admin, v_pais, r.simbolo, r.moneda, true)
        ON CONFLICT(nombremoneda) DO UPDATE SET paisid = excluded.paisid
        RETURNING monedaid INTO v_moneda;

        INSERT INTO tiposcambio(usuariomodificacion, moneda1id, moneda2id, tipocambio, activo)
        VALUES (v_admin, v_m_usd, v_moneda, r.rate, true)
        ON CONFLICT(moneda1id, moneda2id) DO UPDATE
        SET tipocambio = excluded.tipocambio,
            usuariomodificacion = excluded.usuariomodificacion,
            ultimaactualizacion = current_timestamp
        RETURNING tipocambioid INTO v_tc;

        IF NOT EXISTS (
            SELECT 1 FROM historialcambiosmonedas
            WHERE tipocambioid = v_tc
              AND fechafin = '9999-12-31 23:59:59'::timestamp
        ) THEN
            INSERT INTO historialcambiosmonedas(moneda1id, moneda2id, tipocambioid, usuariomodificacion, fechainicio, fechafin, tipocambio, checksum, horacambio)
            VALUES (v_m_usd, v_moneda, v_tc, v_admin, current_timestamp, '9999-12-31 23:59:59'::timestamp, r.rate, fn_generar_checksum(jsonb_build_object('moneda1id', v_m_usd, 'moneda2id', v_moneda, 'tipocambio', r.rate)), current_timestamp);
        END IF;

        SELECT tipopermisoid INTO v_tipo_permiso FROM tipospermisos WHERE nombretipopermiso = 'Sanitario' LIMIT 1;
        SELECT paisid INTO v_pais FROM paises WHERE codigoiso = r.iso LIMIT 1;

        INSERT INTO permisosimportacion(paisid, tipopermisoid, usuariomodificacion, monedaid, tipocambioid, tipocambio, nombrepermiso, descripcion, urldocumentacion, costo, activo)
        VALUES (v_pais, v_tipo_permiso, v_admin, v_moneda, v_tc, r.rate, 'Permiso sanitario', 'Permiso de importacion para Etheria Global', 'https://docs.etheria.global/permisos', 100.000000, true)
        ON CONFLICT(paisid, tipopermisoid) DO NOTHING;

        INSERT INTO impuestospais(paisid, usuariomodificacion, monedaid, tipocambioid, tipocambio, nombre, valor, tipo, fechainicio, fechafin, activo)
        VALUES (v_pais, v_admin, v_moneda, v_tc, r.rate, 'IVA', 13.000000, 'porcentaje', current_timestamp, null, true)
        ON CONFLICT(paisid, nombre) DO NOTHING;

        INSERT INTO impuestospais(paisid, usuariomodificacion, monedaid, tipocambioid, tipocambio, nombre, valor, tipo, fechainicio, fechafin, activo)
        VALUES (v_pais, v_admin, v_moneda, v_tc, r.rate, 'Arancel', 25.000000, 'monto_fijo', current_timestamp, null, true)
        ON CONFLICT(paisid, nombre) DO NOTHING;
    END LOOP;

    INSERT INTO balanceneto(balanceid, saldo, ultimaactualizacion)
    VALUES (1, 0.000000, current_timestamp)
    ON CONFLICT(balanceid) DO NOTHING;

    CALL sp_log_proceso('sp_cargar_finanzas_etheria', 'finanzas', 'OK', 'Monedas, tipos de cambio, permisos e impuestos cargados', 0);
END;
$$;

CREATE OR REPLACE PROCEDURE sp_cargar_productos_etheria()
LANGUAGE plpgsql
AS $$
DECLARE
    v_admin int;
    v_usd int;
    v_tipo_entrada int;
    v_provider_ids int[];
    v_category_ids int[];
    v_char_ids int[];
    v_provider_id int;
    v_category_id int;
    v_product_id int;
    v_lote_id int;
    v_qty int;
    v_price numeric(18,6);
    v_today timestamp := current_timestamp;
    i int;
    v_categoria_nombre text;
    v_nombre text;
BEGIN
    SELECT usuarioid INTO v_admin FROM usuarios WHERE email = 'admin@etheria.global' LIMIT 1;
    SELECT monedaid INTO v_usd FROM monedas WHERE nombremoneda = 'USD' LIMIT 1;
    SELECT tipomovimientoinventarioid INTO v_tipo_entrada FROM tipomovimientosinventario WHERE nombretipomovimientoinventario = 'Entrada' LIMIT 1;

    SELECT array_agg(proveedorid ORDER BY proveedorid) INTO v_provider_ids FROM proveedores;
    SELECT array_agg(categoriaid ORDER BY categoriaid) INTO v_category_ids FROM categorias;
    SELECT array_agg(caracteristicaid ORDER BY caracteristicaid) INTO v_char_ids FROM caracteristicas;

    IF v_provider_ids IS NULL OR v_category_ids IS NULL OR v_char_ids IS NULL THEN
        RAISE EXCEPTION 'Faltan proveedores, categorias o caracteristicas para cargar productos';
    END IF;

    FOR i IN 1..100 LOOP
        v_category_id := v_category_ids[((i - 1) % array_length(v_category_ids, 1)) + 1];
        v_provider_id := v_provider_ids[((i - 1) % array_length(v_provider_ids, 1)) + 1];
        SELECT nombrecategoriap INTO v_categoria_nombre FROM categorias WHERE categoriaid = v_category_id;

        v_nombre := 'Producto Etheria ' || lpad(i::text, 3, '0') || ' - ' || v_categoria_nombre;
        v_price := round((18 + (i * 0.85) + (v_category_id * 1.25))::numeric, 6);

        INSERT INTO productos(categoriaid, usuariomodificacion, proveedorid, precio, nombreproducto, descripcion, descripcionmanejo, activo)
        VALUES (
            v_category_id,
            v_admin,
            v_provider_id,
            v_price,
            v_nombre,
            'Producto natural premium de la categoria ' || v_categoria_nombre,
            'Mantener en condiciones frescas y secas, protegido de la luz directa',
            true
        )
        ON CONFLICT(nombreproducto) DO UPDATE
        SET precio = excluded.precio,
            categoriaid = excluded.categoriaid,
            proveedorid = excluded.proveedorid
        RETURNING productoid INTO v_product_id;

        INSERT INTO valorcaracteristicas(productoid, caracteristicaid, valor, activo)
        VALUES
        (v_product_id, v_char_ids[1], CASE WHEN i % 2 = 0 THEN 'Vegetal' ELSE 'Semilla' END, true),
        (v_product_id, v_char_ids[2], CASE WHEN i % 3 = 0 THEN 'Hidratante' WHEN i % 3 = 1 THEN 'Nutritivo' ELSE 'Purificante' END, true),
        (v_product_id, v_char_ids[3], CASE WHEN i % 2 = 0 THEN 'Aroma herbal' ELSE 'Aroma floral' END, true)
        ON CONFLICT(productoid, caracteristicaid) DO UPDATE SET valor = excluded.valor;

        IF NOT EXISTS (SELECT 1 FROM historialpreciosproducto WHERE productoid = v_product_id AND activo = true) THEN
            INSERT INTO historialpreciosproducto(productoid, precio, monedaid, fechainicio, fechafin, activo)
            VALUES (v_product_id, v_price, v_usd, v_today, null, true);
        END IF;

        IF NOT EXISTS (SELECT 1 FROM lotes WHERE productoid = v_product_id) THEN
            v_qty := 40 + (i % 25);

            INSERT INTO lotes(productoid, cantidadproductoloteinicial, cantidadproductolotedisponible, fechafabricacion, fechavencimiento)
            VALUES (v_product_id, v_qty, v_qty, v_today - ((i % 30) || ' days')::interval, v_today + interval '365 days')
            RETURNING loteid INTO v_lote_id;

            INSERT INTO inventarios(loteid, usuariomodificacion, cantidaddisponible, ultimaactualizacion)
            VALUES (v_lote_id, v_admin, v_qty, v_today)
            ON CONFLICT(loteid) DO NOTHING;

            INSERT INTO movimientosinventario(loteid, usuariomodificacion, tipomovimientoinventarioid, cantidad, fecha)
            VALUES (v_lote_id, v_admin, v_tipo_entrada, v_qty, v_today);
        END IF;
    END LOOP;

    CALL sp_log_proceso('sp_cargar_productos_etheria', 'productos', 'OK', '100 productos, lotes e inventario inicial cargados', 0);
END;
$$;

CREATE OR REPLACE PROCEDURE sp_cargar_operacion_etheria()
LANGUAGE plpgsql
AS $$
DECLARE
    v_admin int;
    v_usd int;
    v_estado_pendiente int;
    v_estado_completada int;
    v_tipo_importacion int;
    v_estado_tx_pendiente int;
    v_estado_tx_aprobada int;
    v_tipo_tx_importacion int;
    v_hub_direccion int;
    v_hub_centro int;
    v_provider_ids int[];
    v_rate_ids int[];
    v_rate_values numeric[];
    v_products int[];
    v_product_id int;
    v_lote_id int;
    v_rate_id int;
    v_rate_value numeric(18,6);
    v_permiso_id int;
    v_impuesto_id int;
    v_order_id int;
    v_detail_id int;
    v_total_order numeric(18,6);
    v_qty int;
    i int;
    j int;
BEGIN
    SELECT usuarioid INTO v_admin FROM usuarios WHERE email = 'admin@etheria.global' LIMIT 1;
    SELECT monedaid INTO v_usd FROM monedas WHERE nombremoneda = 'USD' LIMIT 1;
    SELECT estadoid INTO v_estado_pendiente FROM estadosordenes WHERE nombreestadoorden = 'Pendiente' LIMIT 1;
    SELECT estadoid INTO v_estado_completada FROM estadosordenes WHERE nombreestadoorden = 'Completada' LIMIT 1;
    SELECT tipoordenid INTO v_tipo_importacion FROM tiposorden WHERE nombre = 'Importacion' LIMIT 1;
    SELECT estadotransaccionid INTO v_estado_tx_pendiente FROM estadotransacciones WHERE nombreestadotransac = 'Pendiente' LIMIT 1;
    SELECT estadotransaccionid INTO v_estado_tx_aprobada FROM estadotransacciones WHERE nombreestadotransac = 'Aprobada' LIMIT 1;
    SELECT tipoid INTO v_tipo_tx_importacion FROM tipotransacciones WHERE nombretipotransac = 'Compra importacion' LIMIT 1;
    SELECT direccionid INTO v_hub_direccion FROM direcciones WHERE referencia = 'Centro logistico principal de Etheria Global' LIMIT 1;
    SELECT centrologisticoid INTO v_hub_centro FROM centroslogisticos WHERE nombrecentrologistico = 'HUB Caribe Nicaragua' LIMIT 1;

    SELECT array_agg(proveedorid ORDER BY proveedorid) INTO v_provider_ids FROM proveedores;
    SELECT array_agg(tipocambioid ORDER BY tipocambioid) INTO v_rate_ids FROM tiposcambio WHERE moneda1id = v_usd;
    SELECT array_agg(tipocambio ORDER BY tipocambioid) INTO v_rate_values FROM tiposcambio WHERE moneda1id = v_usd;

    IF v_provider_ids IS NULL OR v_rate_ids IS NULL THEN
        RAISE EXCEPTION 'Faltan proveedores o tipos de cambio';
    END IF;

    FOR i IN 1..5 LOOP
        IF EXISTS (SELECT 1 FROM ordenes WHERE numeroorden = 'EG-ORD-' || lpad(i::text, 4, '0')) THEN
            CONTINUE;
        END IF;

        v_total_order := 0;
        v_rate_id := v_rate_ids[((i - 1) % array_length(v_rate_ids, 1)) + 1];
        v_rate_value := v_rate_values[((i - 1) % array_length(v_rate_values, 1)) + 1];

        SELECT array_agg(p.productoid ORDER BY p.productoid)
        INTO v_products
        FROM productos p
        WHERE p.proveedorid = v_provider_ids[((i - 1) % array_length(v_provider_ids, 1)) + 1];

        IF v_products IS NULL THEN
            CONTINUE;
        END IF;

        INSERT INTO ordenes(
            estadoid, tipoordenid, usuariomodificacion,
            direccionenvioid, direccionentregaid,
            monedaid, tipocambioid, tipocambio,
            numeroorden, preciofinal
        )
        VALUES (
            CASE WHEN i % 2 = 0 THEN v_estado_completada ELSE v_estado_pendiente END,
            v_tipo_importacion,
            v_admin,
            (SELECT d.direccionid
             FROM direcciones d
             JOIN proveedores pr ON pr.direccionid = d.direccionid
             WHERE pr.proveedorid = v_provider_ids[((i - 1) % array_length(v_provider_ids, 1)) + 1]
             LIMIT 1),
            v_hub_direccion,
            v_usd,
            v_rate_id,
            v_rate_value,
            'EG-ORD-' || lpad(i::text, 4, '0'),
            0
        )
        RETURNING ordenid INTO v_order_id;

        FOR j IN 1..2 LOOP
            v_product_id := v_products[j];
            IF v_product_id IS NULL THEN
                CONTINUE;
            END IF;

            SELECT loteid INTO v_lote_id
            FROM lotes
            WHERE productoid = v_product_id
            ORDER BY loteid
            LIMIT 1;

            SELECT ip.impuestoid
            INTO v_impuesto_id
            FROM impuestospais ip
            JOIN paises pa ON pa.paisid = ip.paisid
            JOIN divisionesgeograficas dg ON dg.paisid = pa.paisid
            JOIN direcciones d ON d.divisionid = dg.divisionid
            JOIN proveedores pr ON pr.direccionid = d.direccionid
            JOIN productos p ON p.proveedorid = pr.proveedorid
            WHERE p.productoid = v_product_id
              AND ip.nombre = 'IVA'
            LIMIT 1;

            SELECT pi.permisoid
            INTO v_permiso_id
            FROM permisosimportacion pi
            JOIN paises pa ON pa.paisid = pi.paisid
            JOIN divisionesgeograficas dg ON dg.paisid = pa.paisid
            JOIN direcciones d ON d.divisionid = dg.divisionid
            JOIN proveedores pr ON pr.direccionid = d.direccionid
            JOIN productos p ON p.proveedorid = pr.proveedorid
            WHERE p.productoid = v_product_id
            LIMIT 1;

            v_qty := CASE WHEN j = 1 THEN 2 ELSE 3 END;

            INSERT INTO ordendetalles(
                ordenid, productoid, loteid, monedaid, tipocambioid, tipocambio,
                cantidad, descuentofinal, costoenvio, preciolotefinal, checksum
            )
            VALUES (
                v_order_id, v_product_id, v_lote_id, v_usd, v_rate_id, v_rate_value,
                v_qty, 0, 12 + i + j, 0, null
            )
            RETURNING ordendetalleid INTO v_detail_id;

            IF v_impuesto_id IS NOT NULL THEN
                INSERT INTO ordendetalleimpuestos(ordendetalleid, impuestoid)
                VALUES (v_detail_id, v_impuesto_id)
                ON CONFLICT DO NOTHING;
            END IF;

            IF v_permiso_id IS NOT NULL THEN
                INSERT INTO ordendetallepermisos(ordendetalleid, permisoid)
                VALUES (v_detail_id, v_permiso_id)
                ON CONFLICT DO NOTHING;
            END IF;

            IF j = 2 THEN
                INSERT INTO ordendetalledescuentos(ordendetalleid, monedaid, tipocambioid, tipocambio, descripcion, monto)
                VALUES (v_detail_id, v_usd, v_rate_id, v_rate_value, 'Descuento promocional Etheria', 5.000000);
            END IF;

            PERFORM fn_calcular_totales_detalle(v_detail_id);
        END LOOP;

        SELECT coalesce(sum(preciolotefinal), 0)
        INTO v_total_order
        FROM ordendetalles
        WHERE ordenid = v_order_id;

        UPDATE ordenes SET preciofinal = v_total_order WHERE ordenid = v_order_id;

        INSERT INTO trazabilidadorden(ordenid, centrologisticoid, direccionid, usuariomodificacion, estadoid, fecha)
        VALUES (v_order_id, v_hub_centro, v_hub_direccion, v_admin,
                CASE WHEN i % 2 = 0 THEN v_estado_completada ELSE v_estado_pendiente END,
                current_timestamp);

		INSERT INTO estadoscuenta(
		    ordenid,
		    usuariomodificacion,
		    tipomovimiento,
		    estado,
		    monedaid,
		    tipocambioid,
		    tipocambio,
		    monto,
		    fecharegistro,
		    checksum
		)
		VALUES (
		    v_order_id,
		    v_admin,
		    'Debito',
		    CASE
		        WHEN i % 2 = 0
		            THEN 'completado'::estado_cuenta_enum
		        ELSE
		            'pendiente'::estado_cuenta_enum
		    END,
		    v_usd,
		    v_rate_id,
		    v_rate_value,
		    v_total_order,
		    current_timestamp,
		    null
		);

        INSERT INTO transacciones(monedaid, usuariomodificacion, tipoid, estadotransaccionid, ordenid, tipocambioid, tipocambio, monto, descripcion, fecha, checksum)
        VALUES (v_usd, v_admin, v_tipo_tx_importacion,
                CASE WHEN i % 2 = 0 THEN v_estado_tx_aprobada ELSE v_estado_tx_pendiente END,
                v_order_id, v_rate_id, v_rate_value, v_total_order,
                'Transaccion de importacion generada por carga inicial', current_timestamp, null);
    END LOOP;

    CALL sp_log_proceso('sp_cargar_operacion_etheria', 'operacion', 'OK', 'Ordenes, detalles, trazabilidad, transacciones y estados de cuenta cargados', 0);
END;
$$;

CREATE OR REPLACE PROCEDURE sp_orquestar_carga_etheria_global()
LANGUAGE plpgsql
AS $$
BEGIN
    TRUNCATE TABLE
        acciones, balanceneto, caracteristicas, categorias, centroslogisticos,
        contactos, contactosproveedor, correoscontactos, direcciones,
        divisionesgeograficas, estadoscuenta, estadosordenes, estadotransacciones,
        historialcambiosmonedas, historialpreciosproducto, impuestospais,
        inventarios, logs, lotes, monedas, movimientosinventario, nivelesgeograficos,
        ordendetalledescuentos, ordendetalleimpuestos, ordendetallepermisos,
        ordendetalles, ordenes, paises, permisosimportacion, permisossistema,
        permisosxrole, productos, proveedores, roles, rolesxusuario, tablassistema,
        telefonoscontactos, tipomovimientosinventario, tiposcambio,
        tiposcentrologistico, tiposcontactos, tiposorden, tipospermisos,
        tipostelefonos, tipotransacciones, transacciones, trazabilidadorden,
        usuarios, valorcaracteristicas
    RESTART IDENTITY CASCADE;
    CALL sp_cargar_support_base();
    CALL sp_cargar_catalogos_etheria();
    CALL sp_cargar_geografia_etheria();
    CALL sp_cargar_proveedores_etheria();
    CALL sp_cargar_finanzas_etheria();
    CALL sp_cargar_productos_etheria();
    CALL sp_cargar_operacion_etheria();

    CALL sp_log_proceso('sp_orquestar_carga_etheria_global', 'general', 'OK', 'Carga completa ejecutada correctamente', 0);
EXCEPTION
    WHEN OTHERS THEN
        CALL sp_log_proceso('sp_orquestar_carga_etheria_global', 'general', 'ERROR', sqlerrm, 0);
        RAISE;
END;
$$;
