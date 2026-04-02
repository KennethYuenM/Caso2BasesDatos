CREATE OR REPLACE FUNCTION fn_log_generic()
RETURNS TRIGGER AS $$
DECLARE
    v_tabla_id INT;
    v_action_id INT;
    v_record_id INT;
    v_user_id INT;
BEGIN
    -- =========================
    -- 1. Obtener ID de la tabla
    -- =========================
    SELECT resource_id INTO v_tabla_id
    FROM tablas
    WHERE resource_name = TG_TABLE_NAME;

    -- =========================
    -- 2. Obtener acción
    -- =========================
    SELECT action_id INTO v_action_id
    FROM actions
    WHERE action_name = TG_OP; -- INSERT, UPDATE, DELETE

    -- =========================
    -- 3. Obtener record_id
    -- (asume PK = id)
    -- =========================
    IF TG_OP = 'INSERT' THEN
        v_record_id := NEW.id;
    ELSIF TG_OP = 'UPDATE' THEN
        v_record_id := NEW.id;
    ELSIF TG_OP = 'DELETE' THEN
        v_record_id := OLD.id;
    END IF;

    -- =========================
    -- 4. Obtener user_id dinámicamente
    -- =========================
    BEGIN
        IF TG_OP = 'INSERT' THEN
            v_user_id := NEW.user_id;
        ELSIF TG_OP = 'UPDATE' THEN
            v_user_id := NEW.user_id;
        ELSIF TG_OP = 'DELETE' THEN
            v_user_id := OLD.user_id;
        END IF;
    EXCEPTION
        WHEN undefined_column THEN
            v_user_id := NULL;
    END;

    -- =========================
    -- 5. Insertar log
    -- =========================
    INSERT INTO logs (
        tabla_id,
        accion_id,
        record_id,
        old_data,
        new_data,
        user_id
    )
    VALUES (
        v_tabla_id,
        v_action_id,
        v_record_id,
        CASE WHEN TG_OP = 'INSERT' THEN NULL ELSE to_jsonb(OLD) END,
        CASE WHEN TG_OP = 'DELETE' THEN NULL ELSE to_jsonb(NEW) END,
        v_user_id
    );

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;