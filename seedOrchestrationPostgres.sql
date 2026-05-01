create or replace procedure sp_cargar_support_base()
language plpgsql
as $$
declare
    r record;
begin
    begin
        for r in
            select * from (values
                ('CREATE'),
                ('READ'),
                ('UPDATE'),
                ('DELETE')
            ) as x(nombreaccion)
        loop
            if not exists (
                select 1
                from acciones
                where nombreaccion = r.nombreaccion
            ) then
                insert into acciones(nombreaccion)
                values (r.nombreaccion);
            end if;
        end loop;
        call sp_cargar_tablas();
    exception
        when others then
            raise;
    end;
end;
$$;
create or replace procedure sp_log_proceso(
    p_proceso text,
    p_tabla text,
    p_estado text,
    p_mensaje text,
    p_objeto_id int default 0
)
language plpgsql
as $$
begin
    begin
        perform fn_insert_log(
            null,
            p_tabla,
            case when upper(p_estado) = 'ERROR' then 'UPDATE' else 'CREATE' end,
            coalesce(p_objeto_id, 0),
            null,
            jsonb_build_object(
                'proceso', p_proceso,
                'estado', p_estado,
                'mensaje', p_mensaje
            ),
            case when upper(p_estado) = 'ERROR' then p_mensaje else null end
        );
    exception
        when others then
            null;
    end;
end;
$$;
create or replace procedure sp_cargar_catalogos_etheria()
language plpgsql
as $$
declare
    v_admin int;
    r record;
begin
    begin
        insert into usuarios (
            nombreusuario, apellido, segundoapellido, email, contraseñahash, activo
        )
        select
            'Admin', 'Etheria', 'Global',
            'admin@etheria.global',
            encode(digest('Etheria@2026', 'sha256'), 'hex'),
            true
        where not exists (
            select 1 from usuarios where email = 'admin@etheria.global'
        );
        select usuarioid
        into v_admin
        from usuarios
        where email = 'admin@etheria.global'
        limit 1;
        for r in
            select * from (values
                ('Administrador', 'Acceso total al sistema'),
                ('Operador', 'Operación diaria'),
                ('Auditor', 'Consulta y trazabilidad')
            ) as x(rolnombre, descripcion)
        loop
            if not exists (
                select 1 from roles where rolnombre = r.rolnombre
            ) then
                insert into roles(rolnombre, descripcion)
                values (r.rolnombre, r.descripcion);
            end if;
        end loop;
        for r in
            select * from (values
                ('Gestionar catalogos', 'Alta y mantenimiento de catálogos'),
                ('Gestionar inventario', 'Movimientos y existencias'),
                ('Gestionar ordenes', 'Registro de órdenes'),
                ('Ver reportes', 'Consulta de información')
            ) as x(nombrepermiso, descripcion)
        loop
            if not exists (
                select 1 from permisossistema where nombrepermiso = r.nombrepermiso
            ) then
                insert into permisossistema(nombrepermiso, descripcion)
                values (r.nombrepermiso, r.descripcion);
            end if;
        end loop;
        insert into rolesxusuario(usuarioid, roleid)
        select v_admin, r.roleid
        from roles r
        where r.rolnombre = 'Administrador'
          and not exists (
              select 1
              from rolesxusuario ru
              where ru.usuarioid = v_admin
                and ru.roleid = r.roleid
          );
        insert into permisosxrole(roleid, permisoid)
        select r.roleid, p.permisoid
        from roles r
        join permisossistema p on true
        where (
                r.rolnombre = 'Administrador'
             or (r.rolnombre = 'Operador' and p.nombrepermiso in ('Gestionar inventario', 'Gestionar ordenes'))
             or (r.rolnombre = 'Auditor' and p.nombrepermiso = 'Ver reportes')
        )
          and not exists (
              select 1
              from permisosxrole pr
              where pr.roleid = r.roleid
                and pr.permisoid = p.permisoid
          );
        for r in
            select * from (values
                ('Pais', 1),
                ('Region', 2),
                ('Ciudad', 3)
            ) as x(nombre, orden)
        loop
            if not exists (
                select 1 from nivelesgeograficos where nombrengeografico = r.nombre
            ) then
                insert into nivelesgeograficos(nombrengeografico, orden)
                values (r.nombre, r.orden);
            end if;
        end loop;
        for r in
            select * from (values
                ('Proveedor'),
                ('CentroLogistico')
            ) as x(nombre)
        loop
            if not exists (
                select 1 from tiposcontactos where nombretipocontacto = r.nombre
            ) then
                insert into tiposcontactos(nombretipocontacto)
                values (r.nombre);
            end if;
        end loop;
        for r in
            select * from (values
                ('Movil'),
                ('Oficina'),
                ('WhatsApp')
            ) as x(nombre)
        loop
            if not exists (
                select 1 from tipostelefonos where nombretipotelefono = r.nombre
            ) then
                insert into tipostelefonos(nombretipotelefono)
                values (r.nombre);
            end if;
        end loop;
        for r in
            select * from (values
                ('Hub'),
                ('Bodega')
            ) as x(nombre)
        loop
            if not exists (
                select 1 from tiposcentrologistico where nombretipoclogistico = r.nombre
            ) then
                insert into tiposcentrologistico(nombretipoclogistico)
                values (r.nombre);
            end if;
        end loop;
        for r in
            select * from (values
                ('Bebidas'),
                ('Alimentos'),
                ('Cosmetica dermatologica'),
                ('Cosmetica capilar'),
                ('Aromaterapia'),
                ('Jabones'),
                ('Aceites esenciales')
            ) as x(nombre)
        loop
            if not exists (
                select 1 from categorias where nombrecategoriap = r.nombre
            ) then
                insert into categorias(nombrecategoriap)
                values (r.nombre);
            end if;
        end loop;
        for r in
            select * from (values
                ('Origen botanico'),
                ('Beneficio principal'),
                ('Aroma'),
                ('Presentacion'),
                ('Uso recomendado'),
                ('Conservacion')
            ) as x(nombre)
        loop
            if not exists (
                select 1 from caracteristicas where nombrecaracteristicap = r.nombre
            ) then
                insert into caracteristicas(nombrecaracteristicap)
                values (r.nombre);
            end if;
        end loop;
        for r in
            select * from (values
                ('Sanitario'),
                ('Etiquetado'),
                ('Aduana')
            ) as x(nombre)
        loop
            if not exists (
                select 1 from tipospemisos where nombretipopermiso = r.nombre
            ) then
                insert into tipospemisos(nombretipopermiso)
                values (r.nombre);
            end if;
        end loop;
        for r in
            select * from (values
                ('Pendiente'),
                ('Completada'),
                ('Cancelada')
            ) as x(nombre)
        loop
            if not exists (
                select 1 from estadosordenes where nombreestadoorden = r.nombre
            ) then
                insert into estadosordenes(nombreestadoorden)
                values (r.nombre);
            end if;
        end loop;
        for r in
            select * from (values
                ('Importacion'),
                ('Ajuste')
            ) as x(nombre)
        loop
            if not exists (
                select 1 from tiposorden where nombre = r.nombre
            ) then
                insert into tiposorden(nombre)
                values (r.nombre);
            end if;
        end loop;
        for r in
            select * from (values
                ('Pendiente'),
                ('Aprobada'),
                ('Rechazada')
            ) as x(nombre)
        loop
            if not exists (
                select 1 from estadotransacciones where nombreestadotransac = r.nombre
            ) then
                insert into estadotransacciones(nombreestadotransac)
                values (r.nombre);
            end if;
        end loop;
        for r in
            select * from (values
                ('Compra importacion'),
                ('Pago permiso'),
                ('Ajuste inventario')
            ) as x(nombre)
        loop
            if not exists (
                select 1 from tipotransacciones where nombretipotransac = r.nombre
            ) then
                insert into tipotransacciones(nombretipotransac)
                values (r.nombre);
            end if;
        end loop;
        for r in
            select * from (values
                ('Entrada'),
                ('Salida'),
                ('Ajuste')
            ) as x(nombre)
        loop
            if not exists (
                select 1 from tipomovimientosinventario where nombretipomovimientoinventario = r.nombre
            ) then
                insert into tipomovimientosinventario(nombretipomovimientoinventario)
                values (r.nombre);
            end if;
        end loop;
        call sp_log_proceso(
            'sp_cargar_catalogos_etheria',
            'catalogos',
            'OK',
            'Catalogos base cargados',
            0
        );
    exception
        when others then
            call sp_log_proceso(
                'sp_cargar_catalogos_etheria',
                'catalogos',
                'ERROR',
                sqlerrm,
                0
            );
            raise;
    end;
end;
$$;
create or replace procedure sp_cargar_geografia_etheria()
language plpgsql
as $$
declare
    v_admin int;
    v_nivel_pais int;
    v_nivel_region int;
    v_nivel_ciudad int;
    v_pais int;
    v_div_pais int;
    v_div_region int;
    v_div_ciudad int;
    v_hub_direccion int;
    r record;
begin
    begin
        select usuarioid
        into v_admin
        from usuarios
        where email = 'admin@etheria.global'
        limit 1;
        select nivelid into v_nivel_pais
        from nivelesgeograficos where orden = 1 limit 1;
        select nivelid into v_nivel_region
        from nivelesgeograficos where orden = 2 limit 1;
        select nivelid into v_nivel_ciudad
        from nivelesgeograficos where orden = 3 limit 1;
        for r in
            select * from (values
                ('Estados Unidos', 'USA', 'California', 'Los Angeles', 'West District', 'Hub Logistico Caribe', '1', '10001'),
                ('Nicaragua',      'NIC', 'Managua',    'Managua',      'Managua Centro', 'Hub Logistico Caribe', '1', '11001'),
                ('Colombia',       'COL', 'Cundinamarca','Bogota',      'Zona Norte',     'Sede Oriente',         '45', '110111'),
                ('Peru',           'PER', 'Lima',       'Lima',         'Miraflores',      'Sede Andina',          '120', '15074'),
                ('Mexico',         'MEX', 'CDMX',       'Ciudad de Mexico','Centro',      'Sede Centro',          '88', '01000'),
                ('Chile',          'CHL', 'Santiago',   'Santiago',     'Providencia',     'Sede Austral',         '300', '7500000')
            ) as x(
                pais, iso, region, ciudad, subdivision, calle, numero, cp
            )
        loop
            insert into paises(nombrepais, codigoiso, activo)
            values (r.pais, r.iso, true)
            on conflict (codigoiso) do nothing
            returning paisid into v_pais;
            if v_pais is null then
                select paisid into v_pais
                from paises where codigoiso = r.iso
                limit 1;
            end if;
            insert into divisionesgeograficas(paisid, nivelid, padreid, nombre)
            values (v_pais, v_nivel_pais, null, r.pais)
            returning divisionid into v_div_pais;
            insert into divisionesgeograficas(paisid, nivelid, padreid, nombre)
            values (v_pais, v_nivel_region, v_div_pais, r.region)
            returning divisionid into v_div_region;
            insert into divisionesgeograficas(paisid, nivelid, padreid, nombre)
            values (v_pais, v_nivel_ciudad, v_div_region, r.ciudad)
            returning divisionid into v_div_ciudad;
            if r.iso = 'NIC' then
                insert into direcciones(
                    divisionid, usuariomodificacion, calle, numero, geoposicion,
                    referencia, codigopostal, activo
                )
                values (
                    v_div_ciudad, v_admin, r.calle, r.numero, null,
                    'Centro logistico principal de Etheria Global', r.cp, true
                )
                returning direccionid into v_hub_direccion;
            end if;
        end loop;
        call sp_log_proceso(
            'sp_cargar_geografia_etheria',
            'geografia',
            'OK',
            'Paises y divisiones cargados',
            0
        );
    exception
        when others then
            call sp_log_proceso(
                'sp_cargar_geografia_etheria',
                'geografia',
                'ERROR',
                sqlerrm,
                0
            );
            raise;
    end;
end;
$$;
create or replace procedure sp_cargar_proveedores_etheria()
language plpgsql
as $$
declare
    v_admin int;
    v_tipo_contacto_prov int;
    v_tipo_contacto_hub int;
    v_tipo_tel int;
    v_tipo_centro_hub int;
    v_hub_direccion int;
    v_hub_contacto int;
    v_paisid int;
    v_div_ciudad int;
    v_dir_proveedor int;
    v_contacto int;
    v_proveedor int;
    r record;
begin
    begin
        select usuarioid into v_admin
        from usuarios
        where email = 'admin@etheria.global'
        limit 1;
        select tipocontactoid into v_tipo_contacto_prov
        from tiposcontactos
        where nombretipocontacto = 'Proveedor'
        limit 1;
        select tipocontactoid into v_tipo_contacto_hub
        from tiposcontactos
        where nombretipocontacto = 'CentroLogistico'
        limit 1;
        select tipotelefonoid into v_tipo_tel
        from tipostelefonos
        where nombretipotelefono = 'Movil'
        limit 1;
        select tipoid into v_tipo_centro_hub
        from tiposcentrologistico
        where nombretipoclogistico = 'Hub'
        limit 1;
        select direccionid into v_hub_direccion
        from direcciones
        where referencia = 'Centro logistico principal de Etheria Global'
        limit 1;
        insert into contactos(
            tipocontactoid, usuariomodificacion, nombrecontacto, apellido, segundoapellido, activo
        )
        values (
            v_tipo_contacto_hub, v_admin, 'Hub', 'Etheria', 'Global', true
        )
        returning contactoid into v_hub_contacto;
        insert into telefonoscontactos(
            contactoid, tipotelefonoid, usuariomodificacion, numerocontacto, activo
        )
        values (
            v_hub_contacto, v_tipo_tel, v_admin, '+505-8888-0000', true
        );
        insert into correoscontactos(
            contactoid, usuariomodificacion, correo, activo
        )
        values (
            v_hub_contacto, v_admin, 'hub@etheria.global', true
        );
        insert into centroslogisticos(
            tipoid, direccionid, contactoid, usuariomodificacion,
            nombrecentrologistico, telefono, activo
        )
        values (
            v_tipo_centro_hub, v_hub_direccion, v_hub_contacto, v_admin,
            'HUB Caribe Nicaragua', '+505-8888-0000', true
        );
        for r in
            select * from (values
                ('Proveedor Andino', 'Colombia', 'Bogota', 'proveedor.andino@etheria.global', '+57-300-111-1111'),
                ('Proveedor Pacífico', 'Peru', 'Lima', 'proveedor.pacifico@etheria.global', '+51-900-222-222'),
                ('Proveedor Azteca', 'Mexico', 'Ciudad de Mexico', 'proveedor.azteca@etheria.global', '+52-55-3333-3333'),
                ('Proveedor Austral', 'Chile', 'Santiago', 'proveedor.austral@etheria.global', '+56-9-4444-4444'),
                ('Proveedor Centro', 'Nicaragua', 'Managua', 'proveedor.centro@etheria.global', '+505-8888-1111')
            ) as x(nombreproveedor, pais, ciudad, correo, telefono)
        loop
            select p.paisid, d.divisionid
            into v_paisid, v_div_ciudad
            from paises p
            join divisionesgeograficas d on d.paisid = p.paisid
            join nivelesgeograficos n on n.nivelid = d.nivelid
            where p.nombrepais = r.pais
              and d.nombre = r.ciudad
              and n.orden = 3
            limit 1;
            insert into direcciones(
                divisionid, usuariomodificacion, calle, numero, geoposicion,
                referencia, codigopostal, activo
            )
            values (
                v_div_ciudad, v_admin, 'Calle Principal', '100', null,
                'Direccion de proveedor', '00000', true
            )
            returning direccionid into v_dir_proveedor;
            insert into contactos(
                tipocontactoid, usuariomodificacion, nombrecontacto, apellido, segundoapellido, activo
            )
            values (
                v_tipo_contacto_prov, v_admin, r.nombreproveedor, 'Sourcing', 'Global', true
            )
            returning contactoid into v_contacto;
            insert into telefonoscontactos(
                contactoid, tipotelefonoid, usuariomodificacion, numerocontacto, activo
            )
            values (
                v_contacto, v_tipo_tel, v_admin, r.telefono, true
            );
            insert into correoscontactos(
                contactoid, usuariomodificacion, correo, activo
            )
            values (
                v_contacto, v_admin, r.correo, true
            );
            insert into proveedores(
                direccionid, nombreproveedor, activo
            )
            values (
                v_dir_proveedor, r.nombreproveedor, true
            )
            returning proveedorid into v_proveedor;
            insert into contactosproveedor(
                proveedorid, contactoid, activo
            )
            values (
                v_proveedor, v_contacto, true
            );
        end loop;
        call sp_log_proceso(
            'sp_cargar_proveedores_etheria',
            'proveedores',
            'OK',
            'Proveedores, contactos y HUB cargados',
            0
        );
    exception
        when others then
            call sp_log_proceso(
                'sp_cargar_proveedores_etheria',
                'proveedores',
                'ERROR',
                sqlerrm,
                0
            );
            raise;
    end;
end;
$$;
create or replace procedure sp_cargar_finanzas_etheria()
language plpgsql
as $$
declare
    v_admin int;
    v_m_usd int;
    v_m_nio int;
    v_m_col int;
    v_m_per int;
    v_m_mex int;
    v_m_chl int;
    v_tc_usd_nio int;
    v_tc_usd_col int;
    v_tc_usd_per int;
    v_tc_usd_mex int;
    v_tc_usd_chl int;
    v_tipo_permiso int;
    v_pais int;
    v_moneda int;
    v_tc int;
    r record;
begin
    begin
        select usuarioid into v_admin
        from usuarios where email = 'admin@etheria.global' limit 1;
        select paisid into v_pais from paises where codigoiso = 'USA' limit 1;
        insert into monedas(usuarioModificacion, paisid, simbolomoneda, nombremoneda, activo)
        values (v_admin, v_pais, '$', 'USD', true)
        on conflict do nothing returning monedaid into v_m_usd;
        if v_m_usd is null then select monedaid into v_m_usd from monedas where nombremoneda = 'USD' limit 1; end if;
        select paisid into v_pais from paises where codigoiso = 'NIC' limit 1;
        insert into monedas(usuarioModificacion, paisid, simbolomoneda, nombremoneda, activo)
        values (v_admin, v_pais, 'C$', 'NIO', true)
        on conflict do nothing returning monedaid into v_m_nio;
        if v_m_nio is null then select monedaid into v_m_nio from monedas where nombremoneda = 'NIO' limit 1; end if;
        select paisid into v_pais from paises where codigoiso = 'COL' limit 1;
        insert into monedas(usuarioModificacion, paisid, simbolomoneda, nombremoneda, activo)
        values (v_admin, v_pais, 'COP$', 'COP', true)
        on conflict do nothing returning monedaid into v_m_col;
        if v_m_col is null then select monedaid into v_m_col from monedas where nombremoneda = 'COP' limit 1; end if;
        select paisid into v_pais from paises where codigoiso = 'PER' limit 1;
        insert into monedas(usuarioModificacion, paisid, simbolomoneda, nombremoneda, activo)
        values (v_admin, v_pais, 'S/', 'PEN', true)
        on conflict do nothing returning monedaid into v_m_per;
        if v_m_per is null then select monedaid into v_m_per from monedas where nombremoneda = 'PEN' limit 1; end if;
        select paisid into v_pais from paises where codigoiso = 'MEX' limit 1;
        insert into monedas(usuarioModificacion, paisid, simbolomoneda, nombremoneda, activo)
        values (v_admin, v_pais, '$', 'MXN', true)
        on conflict do nothing returning monedaid into v_m_mex;
        if v_m_mex is null then select monedaid into v_m_mex from monedas where nombremoneda = 'MXN' limit 1; end if;
        select paisid into v_pais from paises where codigoiso = 'CHL' limit 1;
        insert into monedas(usuarioModificacion, paisid, simbolomoneda, nombremoneda, activo)
        values (v_admin, v_pais, '$', 'CLP', true)
        on conflict do nothing returning monedaid into v_m_chl;
        if v_m_chl is null then select monedaid into v_m_chl from monedas where nombremoneda = 'CLP' limit 1; end if;
        insert into tiposcambio(usuarioModificacion, moneda1id, moneda2id, tipocambio, activo)
        values (v_admin, v_m_usd, v_m_nio, 36.500000, true)
        returning tipocambioid into v_tc_usd_nio;
        insert into tiposcambio(usuarioModificacion, moneda1id, moneda2id, tipocambio, activo)
        values (v_admin, v_m_usd, v_m_col, 3950.000000, true)
        returning tipocambioid into v_tc_usd_col;
        insert into tiposcambio(usuarioModificacion, moneda1id, moneda2id, tipocambio, activo)
        values (v_admin, v_m_usd, v_m_per, 3.750000, true)
        returning tipocambioid into v_tc_usd_per;
        insert into tiposcambio(usuarioModificacion, moneda1id, moneda2id, tipocambio, activo)
        values (v_admin, v_m_usd, v_m_mex, 17.200000, true)
        returning tipocambioid into v_tc_usd_mex;
        insert into tiposcambio(usuarioModificacion, moneda1id, moneda2id, tipocambio, activo)
        values (v_admin, v_m_usd, v_m_chl, 930.000000, true)
        returning tipocambioid into v_tc_usd_chl;
        insert into historialcambiosmonedas(
            moneda1id, moneda2id, tipocambioid, usuariomodificacion,
            fechainicio, fechafin, tipocambio, checksum, horacambio
        )
        values
        (v_m_usd, v_m_nio, v_tc_usd_nio, v_admin, current_timestamp, '9999-12-31 23:59:59'::timestamp, 36.500000, fn_generar_checksum(jsonb_build_object('moneda1id', v_m_usd, 'moneda2id', v_m_nio, 'tipocambio', 36.500000)), current_timestamp),
        (v_m_usd, v_m_col, v_tc_usd_col, v_admin, current_timestamp, '9999-12-31 23:59:59'::timestamp, 3950.000000, fn_generar_checksum(jsonb_build_object('moneda1id', v_m_usd, 'moneda2id', v_m_col, 'tipocambio', 3950.000000)), current_timestamp),
        (v_m_usd, v_m_per, v_tc_usd_per, v_admin, current_timestamp, '9999-12-31 23:59:59'::timestamp, 3.750000, fn_generar_checksum(jsonb_build_object('moneda1id', v_m_usd, 'moneda2id', v_m_per, 'tipocambio', 3.750000)), current_timestamp),
        (v_m_usd, v_m_mex, v_tc_usd_mex, v_admin, current_timestamp, '9999-12-31 23:59:59'::timestamp, 17.200000, fn_generar_checksum(jsonb_build_object('moneda1id', v_m_usd, 'moneda2id', v_m_mex, 'tipocambio', 17.200000)), current_timestamp),
        (v_m_usd, v_m_chl, v_tc_usd_chl, v_admin, current_timestamp, '9999-12-31 23:59:59'::timestamp, 930.000000, fn_generar_checksum(jsonb_build_object('moneda1id', v_m_usd, 'moneda2id', v_m_chl, 'tipocambio', 930.000000)), current_timestamp);
        for r in
            select * from (values
                ('Sanitario'), ('Etiquetado'), ('Aduana')
            ) as x(nombre)
        loop
            select tipopermisoid into v_tipo_permiso
            from tipospemisos where nombretipopermiso = r.nombre limit 1;
            if v_tipo_permiso is null then continue; end if;
        end loop;
        for r in
            select * from (values
                ('Colombia', v_m_col, v_tc_usd_col, 1), ('Colombia', v_m_col, v_tc_usd_col, 2),
                ('Peru', v_m_per, v_tc_usd_per, 1), ('Peru', v_m_per, v_tc_usd_per, 2),
                ('Mexico', v_m_mex, v_tc_usd_mex, 1), ('Mexico', v_m_mex, v_tc_usd_mex, 2),
                ('Chile', v_m_chl, v_tc_usd_chl, 1), ('Chile', v_m_chl, v_tc_usd_chl, 2),
                ('Nicaragua', v_m_nio, v_tc_usd_nio, 1), ('Nicaragua', v_m_nio, v_tc_usd_nio, 2)
            ) as x(pais, monedaid, tipocambioid, idx)
        loop
            select paisid into v_pais from paises where nombrepais = r.pais limit 1;
            select tipopermisoid into v_tipo_permiso from tipospemisos
            order by tipopermisoid offset case when r.idx = 1 then 0 else 1 end limit 1;
            if not exists (select 1 from permisosimportacion where paisid = v_pais and tipoPermisoID = v_tipo_permiso) then
                insert into permisosimportacion(
                    paisid, tipopermisoid, usuariomodificacion, monedaid, tipocambioid,
                    tipocambio, nombrepermiso, descripcion, urldocumentacion, costo, activo
                ) values (
                    v_pais, v_tipo_permiso, v_admin, r.monedaid, r.tipocambioid,
                    case when r.pais = 'Colombia' then 3950.000000 when r.pais = 'Peru' then 3.750000
                         when r.pais = 'Mexico' then 17.200000 when r.pais = 'Chile' then 930.000000 else 36.500000 end,
                    case when r.idx = 1 then 'Permiso sanitario' else 'Permiso etiquetado' end,
                    'Permiso de importacion para Etheria Global', 'https://docs.etheria.global/permisos',
                    case when r.pais = 'Colombia' then 250000.00 when r.pais = 'Peru' then 180.00
                         when r.pais = 'Mexico' then 900.00 when r.pais = 'Chile' then 120000.00 else 2000.00 end,
                    true
                );
            end if;
        end loop;
        for r in
            select * from (values
                ('Colombia', v_m_col, v_tc_usd_col), ('Peru', v_m_per, v_tc_usd_per),
                ('Mexico', v_m_mex, v_tc_usd_mex), ('Chile', v_m_chl, v_tc_usd_chl),
                ('Nicaragua', v_m_nio, v_tc_usd_nio)
            ) as x(pais, monedaid, tipocambioid)
        loop
            select paisid into v_pais from paises where nombrepais = r.pais limit 1;
            if not exists (select 1 from impuestospais where paisid = v_pais and nombre = 'IVA') then
                insert into impuestospais(paisid, usuariomodificacion, monedaid, tipocambioid, tipocambio, nombre, valor, tipo, fechainicio, fechafin, activo)
                values (v_pais, v_admin, r.monedaid, r.tipocambioid, 1.000000, 'IVA', 13.00, 'porcentaje', current_timestamp, null, true);
            end if;
            if not exists (select 1 from impuestospais where paisid = v_pais and nombre = 'Arancel') then
                insert into impuestospais(paisid, usuariomodificacion, monedaid, tipocambioid, tipocambio, nombre, valor, tipo, fechainicio, fechafin, activo)
                values (v_pais, v_admin, r.monedaid, r.tipocambioid, 1.000000, 'Arancel', 25.00, 'monto_fijo', current_timestamp, null, true);
            end if;
        end loop;
        if not exists (select 1 from balanceneto) then
            insert into balanceneto(saldo, ultimaactualizacion) values (0.000000, current_timestamp);
        end if;
        call sp_log_proceso('sp_cargar_finanzas_etheria', 'finanzas', 'OK', 'Monedas, tipos de cambio, permisos e impuestos cargados', 0);
    exception
        when others then
            call sp_log_proceso('sp_cargar_finanzas_etheria', 'finanzas', 'ERROR', sqlerrm, 0);
            raise;
    end;
end;
$$;
create or replace procedure sp_cargar_productos_etheria()
language plpgsql
as $$
declare
    v_admin int;
    v_usd int;
    v_tipo_entrada int;
    v_provider_ids int[];
    v_category_ids int[];
    v_char_ids int[];
    v_provider_id int;
    v_category_id int;
    v_char1 int;
    v_char2 int;
    v_char3 int;
    v_product_id int;
    v_lote_id int;
    v_qty int;
    v_price numeric(18,6);
    v_today timestamp;
    r record;
begin
    begin
        select usuarioid into v_admin
        from usuarios
        where email = 'admin@etheria.global'
        limit 1;
        select monedaid into v_usd
        from monedas
        where nombremoneda = 'USD'
        limit 1;
        select tipomovimientoinventarioid into v_tipo_entrada
        from tipomovimientosinventario
        where nombretipomovimientoinventario = 'Entrada'
        limit 1;
        select array_agg(proveedorid order by proveedorid)
        into v_provider_ids
        from proveedores;
        select array_agg(categoriaid order by categoriaid)
        into v_category_ids
        from categorias;
        select array_agg(caracteristicaid order by caracteristicaid)
        into v_char_ids
        from caracteristicas;
        v_today := current_timestamp;
        for r in
            select * from (values
                (1, 'Bebidas', 'Infusion de Manzanilla Organica', 'Infusion relajante de manzanilla organica', 'Vegetal', 'Relajante', '250 ml'),
                (2, 'Alimentos', 'Granola Artesanal con Frutas', 'Granola hecha a mano con frutas secas', 'Semilla', 'Nutritivo', '500 ml'),
                (3, 'Cosmetica dermatologica', 'Crema Facial Antioxidante', 'Crema facial con vitamina C y E', 'Flor', 'Hidratante', '100 g'),
                (4, 'Cosmetica capilar', 'Acondicionador de Aceite de Argan', 'Acondicionador capilar reparador de argan', 'Raiz', 'Hidratante', '250 ml'),
                (5, 'Aromaterapia', 'Aceite Esencial de Lavanda', 'Aceite esencial puro de lavanda para aromaterapia', 'Fruto', 'Relajante', '100 g'),
                (6, 'Jabones', 'Jabon de Avena y Miel', 'Jabon artesanal de avena y miel natural', 'Vegetal', 'Purificante', '250 ml'),
                (7, 'Aceites esenciales', 'Aceite de Rosa Mosqueta', 'Aceite regenerador de rosa mosqueta', 'Semilla', 'Hidratante', '100 g'),
                (8, 'Bebidas', 'Te Verde Organico Premium', 'Te verde organico de hoja entera', 'Flor', 'Equilibrante', '250 ml'),
                (9, 'Alimentos', 'Miel Organica de Abeja', 'Miel pura organica de abejas silvestres', 'Raiz', 'Nutritivo', '500 ml'),
                (10, 'Cosmetica dermatologica', 'Serum de Acido Hialuronico', 'Serum hidratante de acido hialuronico', 'Fruto', 'Hidratante', '100 g'),
                (11, 'Cosmetica capilar', 'Shampoo de Biotina y Colageno', 'Shampoo fortalecedor con biotina y colageno', 'Vegetal', 'Nutritivo', '500 ml'),
                (12, 'Aromaterapia', 'Aceite Esencial de Eucalipto', 'Aceite esencial de eucalipto para respiracion', 'Semilla', 'Purificante', '100 g'),
                (13, 'Jabones', 'Jabon de Carbon Activado', 'Jabon facial de carbon activado purificante', 'Flor', 'Purificante', '250 ml'),
                (14, 'Aceites esenciales', 'Aceite de Coco Organico', 'Aceite de coco virgen extra organico', 'Raiz', 'Hidratante', '250 ml'),
                (15, 'Bebidas', 'Jugo Verde Detox', 'Jugo verde prensado en frio detox', 'Fruto', 'Digestivo', '500 ml'),
                (16, 'Alimentos', 'Quinoa Organica Premium', 'Quinoa blanca organica de los Andes', 'Vegetal', 'Nutritivo', '500 ml'),
                (17, 'Cosmetica dermatologica', 'Mascarilla de Arcilla Verde', 'Mascarilla purificante de arcilla verde', 'Semilla', 'Purificante', '100 g'),
                (18, 'Cosmetica capilar', 'Aceite Capilar de Jojoba', 'Aceite nutritivo para puntas danadas', 'Flor', 'Hidratante', '100 g'),
                (19, 'Aromaterapia', 'Aceite Esencial de Menta', 'Aceite esencial de menta refrescante', 'Raiz', 'Equilibrante', '100 g'),
                (20, 'Jabones', 'Jabon de Aloe Vera', 'Jabon hidratante de aloe vera natural', 'Fruto', 'Hidratante', '250 ml'),
                (21, 'Aceites esenciales', 'Aceite de Almendras Dulces', 'Aceite hidratante de almendras dulces', 'Vegetal', 'Hidratante', '250 ml'),
                (22, 'Bebidas', 'Kombucha de Jengibre', 'Kombucha artesanal de jengibre', 'Semilla', 'Digestivo', '500 ml'),
                (23, 'Alimentos', 'Cacao en Polvo Crudo', 'Cacao crudo organico en polvo', 'Flor', 'Nutritivo', '100 g'),
                (24, 'Cosmetica dermatologica', 'Protector Solar Natural SPF30', 'Protector solar con ingredientes naturales', 'Raiz', 'Hidratante', '100 g'),
                (25, 'Cosmetica capilar', 'Mascarilla Capilar de Coco', 'Mascarilla reparadora de coco para cabello', 'Fruto', 'Hidratante', '250 ml'),
                (26, 'Aromaterapia', 'Aceite Esencial de Naranja', 'Aceite esencial de naranja dulce energizante', 'Vegetal', 'Equilibrante', '100 g'),
                (27, 'Jabones', 'Jabon de Calendula', 'Jabon suave de calendula para piel sensible', 'Semilla', 'Hidratante', '250 ml'),
                (28, 'Aceites esenciales', 'Aceite de Semilla de Uva', 'Aceite ligero de semilla de uva para piel', 'Flor', 'Hidratante', '100 g'),
                (29, 'Bebidas', 'Agua de Horchata Natural', 'Agua de horchata de arroz tradicional', 'Raiz', 'Digestivo', '500 ml'),
                (30, 'Alimentos', 'Semillas de Chia Organicas', 'Semillas de chia premium organicas', 'Fruto', 'Nutritivo', '100 g'),
                (31, 'Cosmetica dermatologica', 'Crema de Manos de Rosa', 'Crema reparadora de manos con rosa', 'Vegetal', 'Hidratante', '100 g'),
                (32, 'Cosmetica capilar', 'Tonico Anticaida Natural', 'Tonico capilar anticaida con romero', 'Semilla', 'Equilibrante', '250 ml'),
                (33, 'Aromaterapia', 'Aceite Esencial de Canela', 'Aceite esencial de canela reconfortante', 'Flor', 'Aromatico', '100 g'),
                (34, 'Jabones', 'Jabon de Romero', 'Jabon artesanal de romero estimulante', 'Raiz', 'Purificante', '250 ml'),
                (35, 'Aceites esenciales', 'Aceite de Aguacate Prensado en Frio', 'Aceite nutritivo de aguacate para piel', 'Fruto', 'Nutritivo', '250 ml'),
                (36, 'Bebidas', 'Chicha Morada Concentrada', 'Concentrado natural de chicha morada', 'Vegetal', 'Digestivo', '500 ml'),
                (37, 'Alimentos', 'Maca en Polvo Gelatinizada', 'Maca peruana gelatinizada en polvo', 'Semilla', 'Nutritivo', '100 g'),
                (38, 'Cosmetica dermatologica', 'Tonico Facial de Hamamelis', 'Tonico astringente natural de hamamelis', 'Flor', 'Purificante', '100 g'),
                (39, 'Cosmetica capilar', 'Serum Capilar de Keratina', 'Serum reconstructor con keratina vegetal', 'Raiz', 'Hidratante', '100 g'),
                (40, 'Aromaterapia', 'Vela Aromatica de Vainilla', 'Vela de cera de soja con aroma de vainilla', 'Fruto', 'Relajante', '250 ml'),
                (41, 'Jabones', 'Jabon de Leche de Cabra', 'Jabon hidratante de leche de cabra', 'Vegetal', 'Hidratante', '250 ml'),
                (42, 'Aceites esenciales', 'Aceite de Sacha Inchi', 'Aceite omega-3 de sacha inchi peruano', 'Semilla', 'Nutritivo', '100 g'),
                (43, 'Bebidas', 'Te de Munia Andino', 'Infusion de hierbas andinas relajante', 'Flor', 'Relajante', '250 ml'),
                (44, 'Alimentos', 'Chocolate Artesanal 70%', 'Chocolate oscuro artesanal 70% cacao', 'Raiz', 'Nutritivo', '100 g'),
                (45, 'Cosmetica dermatologica', 'Gel de Sabila Puro', 'Gel de aloe vera 100% natural', 'Fruto', 'Hidratante', '100 g'),
                (46, 'Cosmetica capilar', 'Aceite de Ricino para Cabello', 'Aceite de ricino fortalecedor capilar', 'Vegetal', 'Nutritivo', '100 g'),
                (47, 'Aromaterapia', 'Incienso de Sandalo Natural', 'Varillas de incienso de sandalo', 'Semilla', 'Aromatico', '100 g'),
                (48, 'Jabones', 'Jabon de Cacao y Vainilla', 'Jabon artesanal de cacao y vainilla', 'Flor', 'Hidratante', '250 ml'),
                (49, 'Aceites esenciales', 'Aceite Esencial de Limoncillo', 'Aceite esencial de lemongrass', 'Raiz', 'Purificante', '100 g'),
                (50, 'Bebidas', 'Agua de Jamaica Premium', 'Agua de jamaica con flor seleccionada', 'Fruto', 'Digestivo', '500 ml'),
                (51, 'Alimentos', 'Cafe Organico de Altura', 'Cafe gourmet organico de altura', 'Vegetal', 'Equilibrante', '500 ml'),
                (52, 'Cosmetica dermatologica', 'Exfoliante Corporal de Sal Marina', 'Exfoliante natural de sal marina y aceites', 'Semilla', 'Purificante', '250 ml'),
                (53, 'Cosmetica capilar', 'Spray Protector Termico', 'Spray protector termico con aceite de argan', 'Flor', 'Hidratante', '250 ml'),
                (54, 'Aromaterapia', 'Difusor de Aceites Esenciales', 'Set difusor con aceites esenciales variados', 'Raiz', 'Relajante', '250 ml'),
                (55, 'Jabones', 'Jabon Exfoliante de Cafe', 'Jabon exfoliante artesanal con cafe', 'Fruto', 'Purificante', '250 ml'),
                (56, 'Aceites esenciales', 'Aceite de Argan Premium', 'Aceite de argan puro para cabello y piel', 'Vegetal', 'Hidratante', '100 g'),
                (57, 'Bebidas', 'Jugo de Camu Camu', 'Jugo de camu camu alto en vitamina C', 'Semilla', 'Nutritivo', '500 ml'),
                (58, 'Alimentos', 'Lucuma en Polvo', 'Polvo de lucuma peruana para smoothies', 'Flor', 'Nutritivo', '100 g'),
                (59, 'Cosmetica dermatologica', 'Desodorante Natural de Coco', 'Desodorante sin aluminio de coco', 'Raiz', 'Purificante', '100 g'),
                (60, 'Cosmetica capilar', 'Balsamo Desenredante Natural', 'Balsamo desenredante con aceites vegetales', 'Fruto', 'Hidratante', '250 ml'),
                (61, 'Aromaterapia', 'Aceite Esencial de Romero', 'Aceite esencial de romero estimulante', 'Vegetal', 'Equilibrante', '100 g'),
                (62, 'Jabones', 'Jabon de Arcilla Blanca', 'Jabon purificante de arcilla blanca', 'Semilla', 'Purificante', '250 ml'),
                (63, 'Aceites esenciales', 'Aceite de Jojoba Puro', 'Aceite de jojoba para piel y cabello', 'Flor', 'Hidratante', '100 g'),
                (64, 'Bebidas', 'Limonada con Chia', 'Limonada natural con semillas de chia', 'Raiz', 'Digestivo', '500 ml'),
                (65, 'Alimentos', 'Mermelada de Guayaba', 'Mermelada artesanal de guayaba', 'Fruto', 'Nutritivo', '250 ml'),
                (66, 'Cosmetica dermatologica', 'Crema Corporal de Karite', 'Crema hidratante corporal de manteca de karite', 'Vegetal', 'Hidratante', '250 ml'),
                (67, 'Cosmetica capilar', 'Ampolla Capilar Reparadora', 'Ampolla de tratamiento capilar intensivo', 'Semilla', 'Nutritivo', '100 g'),
                (68, 'Aromaterapia', 'Sachet Aromatico de Lavanda', 'Saco aromatico de lavanda seca', 'Flor', 'Relajante', '100 g'),
                (69, 'Jabones', 'Jabon de Manzanilla', 'Jabon calmante de manzanilla para bebe', 'Raiz', 'Hidratante', '250 ml'),
                (70, 'Aceites esenciales', 'Aceite Corporal de Coco y Vainilla', 'Aceite corporal hidratante tropical', 'Fruto', 'Hidratante', '250 ml'),
                (71, 'Bebidas', 'Te Matcha Organico', 'Te matcha japones grado ceremonial', 'Vegetal', 'Equilibrante', '100 g'),
                (72, 'Alimentos', 'Cardamomo Premium', 'Cardamomo entero de Alta Verapaz', 'Semilla', 'Aromatico', '100 g'),
                (73, 'Cosmetica dermatologica', 'Balsamo Labial de Menta', 'Balsamo labial natural de menta', 'Flor', 'Hidratante', '100 g'),
                (74, 'Cosmetica capilar', 'Gel Fijador Natural', 'Gel fijador de cabello con extractos naturales', 'Raiz', 'Equilibrante', '250 ml'),
                (75, 'Aromaterapia', 'Aceite Esencial de Ylang Ylang', 'Aceite esencial floral de ylang ylang', 'Fruto', 'Relajante', '100 g'),
                (76, 'Jabones', 'Jabon de Curcuma y Miel', 'Jabon artesanal de curcuma con miel', 'Vegetal', 'Purificante', '250 ml'),
                (77, 'Aceites esenciales', 'Aceite de Oregano Silvestre', 'Aceite de oregano silvestre medicinal', 'Semilla', 'Purificante', '100 g'),
                (78, 'Bebidas', 'Agua de Tamarindo', 'Agua fresca de tamarindo natural', 'Flor', 'Digestivo', '500 ml'),
                (79, 'Alimentos', 'Panela Granulada Organica', 'Panela organica granulada artesanal', 'Raiz', 'Nutritivo', '500 ml'),
                (80, 'Cosmetica dermatologica', 'Contorno de Ojos Antiedad', 'Contorno de ojos con retinol natural', 'Fruto', 'Hidratante', '100 g'),
                (81, 'Cosmetica capilar', 'Aceite de Coco para Cabello', 'Aceite de coco capilar multiusos', 'Vegetal', 'Hidratante', '250 ml'),
                (82, 'Aromaterapia', 'Spray Ambiental de Citricos', 'Spray ambiental natural de citricos', 'Semilla', 'Aromatico', '250 ml'),
                (83, 'Jabones', 'Jabon de Neem', 'Jabon antibacterial natural de neem', 'Flor', 'Purificante', '250 ml'),
                (84, 'Aceites esenciales', 'Aceite de Moringa', 'Aceite nutritivo de semilla de moringa', 'Raiz', 'Nutritivo', '100 g'),
                (85, 'Bebidas', 'Jugo de Mora Andina', 'Jugo de mora de castilla andina', 'Fruto', 'Nutritivo', '500 ml'),
                (86, 'Alimentos', 'Mantequilla de Mani Artesanal', 'Mantequilla de mani sin azucar anadida', 'Vegetal', 'Nutritivo', '500 ml'),
                (87, 'Cosmetica dermatologica', 'Mascarilla Facial de Miel', 'Mascarilla nutritiva de miel y propoleo', 'Semilla', 'Nutritivo', '100 g'),
                (88, 'Cosmetica capilar', 'Rinse de Vinagre de Manzana', 'Rinse capilar de vinagre de manzana', 'Flor', 'Equilibrante', '500 ml'),
                (89, 'Aromaterapia', 'Aceite Esencial de Cedro', 'Aceite esencial de madera de cedro', 'Raiz', 'Relajante', '100 g'),
                (90, 'Jabones', 'Jabon de Te Verde', 'Jabon antioxidante de te verde', 'Fruto', 'Purificante', '250 ml'),
                (91, 'Aceites esenciales', 'Aceite de Marula', 'Aceite premium de marula africana', 'Vegetal', 'Hidratante', '100 g'),
                (92, 'Bebidas', 'Infusion de Jengibre y Limon', 'Infusion energizante de jengibre con limon', 'Semilla', 'Digestivo', '250 ml'),
                (93, 'Alimentos', 'Pimienta de Jamaica Molida', 'Pimienta gorda molida de la zona sur', 'Flor', 'Aromatico', '100 g'),
                (94, 'Cosmetica dermatologica', 'Aceite Facial de Noche', 'Aceite facial regenerador nocturno', 'Raiz', 'Hidratante', '100 g'),
                (95, 'Cosmetica capilar', 'Mascarilla de Platano y Miel', 'Mascarilla capilar de platano con miel', 'Fruto', 'Nutritivo', '250 ml'),
                (96, 'Aromaterapia', 'Potpourri de Flores Secas', 'Mezcla de flores secas aromaticas', 'Vegetal', 'Aromatico', '100 g'),
                (97, 'Jabones', 'Jabon de Papaya', 'Jabon aclarante natural de papaya', 'Semilla', 'Purificante', '250 ml'),
                (98, 'Aceites esenciales', 'Aceite de Baobab', 'Aceite hidratante de baobab africano', 'Flor', 'Hidratante', '100 g'),
                (99, 'Bebidas', 'Agua de Coco Natural', 'Agua de coco embotellada sin azucar', 'Raiz', 'Digestivo', '500 ml'),
                (100, 'Alimentos', 'Tapa de Dulce Organica', 'Tapa de dulce de cana organica', 'Fruto', 'Nutritivo', '250 ml')
            ) as x(idx, categoria, nombre, descripcion, origen, beneficio, presentacion)
        loop
            v_category_id := (select categoriaid from categorias where nombrecategoriap = r.categoria limit 1);
            v_provider_id := v_provider_ids[((r.idx - 1) % array_length(v_provider_ids, 1)) + 1];
            insert into productos(
                categoriaid, usuariomodificacion, proveedorid,
                nombreproducto, descripcion, descripcionmanejo, activo
            )
            values (
                v_category_id,
                v_admin,
                v_provider_id,
                r.nombre,
                r.descripcion,
                'Mantener en condiciones frescas y secas, protegido de la luz directa',
                true
            )
            returning productoid into v_product_id;
create or replace procedure sp_cargar_operacion_etheria()
language plpgsql
as $$
declare
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
    v_price numeric(18,6);
    v_rate_id int;
    v_rate_value numeric(18,6);
    v_permiso_id int;
    v_impuesto_id int;
    v_order_id int;
    v_detail_id int;
    v_total_order numeric(18,6);
    v_base numeric(18,6);
    v_tax_local numeric(18,6);
    v_tax_usd numeric(18,6);
    v_permiso_local numeric(18,6);
    v_permiso_usd numeric(18,6);
    v_discount numeric(18,6);
    v_shipping numeric(18,6);
    v_final numeric(18,6);
    v_qty int;
    i int;
    j int;
begin
    begin
        select usuarioid into v_admin from usuarios where email = 'admin@etheria.global' limit 1;
        select monedaid into v_usd from monedas where nombremoneda = 'USD' limit 1;
        select estadoid into v_estado_pendiente from estadosordenes where nombreestadoorden = 'Pendiente' limit 1;
        select estadoid into v_estado_completada from estadosordenes where nombreestadoorden = 'Completada' limit 1;
        select tipoordenid into v_tipo_importacion from tiposorden where nombre = 'Importacion' limit 1;
        select estadotransaccionid into v_estado_tx_pendiente from estadotransacciones where nombreestadotransac = 'Pendiente' limit 1;
        select estadotransaccionid into v_estado_tx_aprobada from estadotransacciones where nombreestadotransac = 'Aprobada' limit 1;
        select tipoid into v_tipo_tx_importacion from tipotransacciones where nombretipotransac = 'Compra importacion' limit 1;
        select direccionid into v_hub_direccion from direcciones where referencia = 'Centro logistico principal de Etheria Global' limit 1;
        select centrologisticoid into v_hub_centro from centroslogisticos where nombrecentrologistico = 'HUB Caribe Nicaragua' limit 1;
        select array_agg(proveedorid order by proveedorid) into v_provider_ids from proveedores;
        select array_agg(tipocambioid order by tipocambioid) into v_rate_ids from tiposcambio where moneda1id = v_usd;
        select array_agg(tipocambio order by tipocambioid) into v_rate_values from tiposcambio where moneda1id = v_usd;
        for i in 1..5 loop
            v_total_order := 0;
            v_rate_id := v_rate_ids[i];
            v_rate_value := v_rate_values[i];
            select array_agg(p.productoid order by p.productoid)
            into v_products
            from productos p
            where p.proveedorid = v_provider_ids[i];
            insert into ordenes(
                estadoid, tipoordenid, usuariomodificacion,
                direccionenvioid, direccionentregaid,
                monedaid, tipocambioid, tipocambio,
                numeroorden, preciofinal
            ) values (
                case when i % 2 = 0 then v_estado_completada else v_estado_pendiente end,
                v_tipo_importacion, v_admin,
                (select d.direccionid from direcciones d
                 join proveedores pr on pr.direccionid = d.direccionid
                 where pr.proveedorid = v_provider_ids[i] limit 1),
                v_hub_direccion, v_usd, v_rate_id, v_rate_value,
                'EG-ORD-' || lpad(i::text, 4, '0'), 0
            ) returning ordenid into v_order_id;
            for j in 1..2 loop
                v_product_id := v_products[j];
                select loteid into v_lote_id from lotes where productoid = v_product_id order by loteid limit 1;
                select precio into v_price from historialpreciosproducto where productoid = v_product_id order by fechainicio desc limit 1;
                select i2.impuestoid, i2.valor into v_impuesto_id, v_tax_local
                from impuestospais i2
                join proveedores pr on true
                join productos p on p.proveedorid = pr.proveedorid
                join direcciones d on d.direccionid = pr.direccionid
                join divisionesgeograficas dg on dg.divisionid = d.divisionid
                join paises pa on pa.paisid = dg.paisid
                where p.productoid = v_product_id and i2.paisid = pa.paisid
                order by i2.impuestoid limit 1;
                select pi.permisoid, pi.costo into v_permiso_id, v_permiso_local
                from permisosimportacion pi
                join proveedores pr on true
                join productos p on p.proveedorid = pr.proveedorid
                join direcciones d on d.direccionid = pr.direccionid
                join divisionesgeograficas dg on dg.divisionid = d.divisionid
                join paises pa on pa.paisid = dg.paisid
                where p.productoid = v_product_id and pi.paisid = pa.paisid
                order by pi.permisoid limit 1;
                v_qty := case when j = 1 then 2 else 3 end;
                v_base := round(v_price * v_qty, 6);
                if v_tax_local is null then v_tax_usd := 0;
                else v_tax_usd := round((v_base * v_tax_local / 100.0), 6); end if;
                if v_permiso_local is null then v_permiso_usd := 0;
                else v_permiso_usd := round(v_permiso_local / v_rate_value, 6); end if;
                v_discount := case when j = 2 then round(v_base * 0.05, 6) else 0 end;
                v_shipping := round((12 + (i * 2) + j)::numeric, 6);
                v_final := v_base + v_tax_usd + v_permiso_usd + v_shipping - v_discount;
                v_total_order := v_total_order + v_final;
                insert into ordendetalles(
                    ordenid, productoid, loteid, monedaid, tipocambioid, tipocambio,
                    cantidad, descuentofinal, costoenvio, preciolotefinal, checksum
                ) values (
                    v_order_id, v_product_id, v_lote_id, v_usd, v_rate_id, v_rate_value,
                    v_qty, v_discount, v_shipping, v_final, null
                ) returning ordendetalleid into v_detail_id;
                insert into ordendetalleimpuestos(ordendetalleid, impuestoid) values (v_detail_id, v_impuesto_id);
                insert into ordendetallepermisos(ordendetalleid, permisoid) values (v_detail_id, v_permiso_id);
                if v_discount > 0 then
                    insert into ordendetalledescuentos(
                        ordendetalleid, monedaid, tipocambioid, tipocambio, descripcion, monto
                    ) values (
                        v_detail_id, v_usd, v_rate_id, v_rate_value, 'Descuento promocional Etheria', v_discount
                    );
                end if;
            end loop;
            update ordenes set preciofinal = v_total_order where ordenid = v_order_id;
            insert into trazabilidadorden(ordenid, centrologisticoid, direccionid, usuariomodificacion, estadoid, fecha)
            values (v_order_id, v_hub_centro, v_hub_direccion, v_admin,
                    case when i % 2 = 0 then v_estado_completada else v_estado_pendiente end, current_timestamp);
            insert into estadoscuenta(ordenid, usuariomodificacion, tipomovimiento, estado, monedaid, tipocambioid, tipocambio, monto, fecharegistro, checksum)
            values (v_order_id, v_admin, 'Debito',
                    case when i % 2 = 0 then 'completado' else 'pendiente' end,
                    v_usd, v_rate_id, v_rate_value, v_total_order, current_timestamp, null);
            insert into transacciones(monedaid, usuariomodificacion, tipoid, estadotransaccionid, ordenid, tipocambioid, tipocambio, monto, descripcion, fecha, checksum)
            values (v_usd, v_admin, v_tipo_tx_importacion,
                    case when i % 2 = 0 then v_estado_tx_aprobada else v_estado_tx_pendiente end,
                    v_order_id, v_rate_id, v_rate_value, v_total_order,
                    'Transaccion de importacion generada por carga inicial', current_timestamp, null);
        end loop;
        call sp_log_proceso('sp_cargar_operacion_etheria', 'operacion', 'OK',
            'Ordenes, detalles, trazabilidad, transacciones y estados de cuenta cargados', 0);
    exception
        when others then
            call sp_log_proceso('sp_cargar_operacion_etheria', 'operacion', 'ERROR', sqlerrm, 0);
            raise;
    end;
end;
$$;
create or replace procedure sp_orquestar_carga_etheria_global()
language plpgsql
as $$
begin
    begin
        call sp_cargar_support_base();
        call sp_cargar_catalogos_etheria();
        call sp_cargar_geografia_etheria();
        call sp_cargar_proveedores_etheria();
        call sp_cargar_finanzas_etheria();
        call sp_cargar_productos_etheria();
        call sp_cargar_operacion_etheria();
    exception
        when others then
            raise;
    end;
end;
$$;
