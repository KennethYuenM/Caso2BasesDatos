CREATE OR REPLACE FUNCTION fn_validar_y_generar_direccion()
RETURNS TRIGGER AS $$
DECLARE
    v_count INT;
    v_direccion_completa TEXT;
BEGIN
    -- 🔹 BLOQUE PRINCIPAL (TRY)
    BEGIN

        -- 1. Validar que la división exista
        IF NOT EXISTS (
            SELECT 1 FROM divisiones_geograficas 
            WHERE id_division = NEW.id_division
        ) THEN
            RAISE EXCEPTION 'La división no existe';
        END IF;

        -- 2. Validar que sea nivel más bajo (HOJA)
        SELECT COUNT(*) INTO v_count
        FROM divisiones_geograficas
        WHERE id_padre = NEW.id_division;

        IF v_count > 0 THEN
            RAISE EXCEPTION 'La división NO es el nivel más bajo';
        END IF;

        -- 3. Construir jerarquía
        WITH RECURSIVE jerarquia AS (
            SELECT 
                dg.id_division,
                dg.nombre,
                dg.id_padre,
                ng.orden
            FROM divisiones_geograficas dg
            JOIN niveles_geograficos ng 
                ON dg.id_nivel = ng.id_nivel
            WHERE dg.id_division = NEW.id_division

            UNION ALL

            SELECT 
                d.id_division,
                d.nombre,
                d.id_padre,
                ng.orden
            FROM divisiones_geograficas d
            JOIN niveles_geograficos ng 
                ON d.id_nivel = ng.id_nivel
            INNER JOIN jerarquia j 
                ON d.id_division = j.id_padre
        )
        SELECT 
            NEW.calle || ' ' || NEW.numero || ', ' ||
            string_agg(nombre, ', ' ORDER BY orden DESC)
        INTO v_direccion_completa
        FROM jerarquia;

        -- 4. Validar resultado
        IF v_direccion_completa IS NULL THEN
            RAISE EXCEPTION 'Error generando la dirección completa';
        END IF;

        -- 5. Asignar valor
        NEW.direccion_completa := v_direccion_completa;

        RETURN NEW;

    -- 🔻 BLOQUE CATCH
    EXCEPTION

        WHEN NO_DATA_FOUND THEN
            RAISE EXCEPTION 'No se encontraron datos en la jerarquía';

        WHEN OTHERS THEN
            RAISE EXCEPTION 'Error en trigger de direcciones: %', SQLERRM;

    END;
END;
$$ LANGUAGE plpgsql;

--TRIGGER
CREATE TRIGGER trg_direccion
BEFORE INSERT ON direcciones
FOR EACH ROW
EXECUTE FUNCTION fn_validar_y_generar_direccion();