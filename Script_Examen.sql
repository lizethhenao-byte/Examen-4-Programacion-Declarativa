/* ============================================================
   EXAMEN 4 - PROGRAMACIÓN DECLARATIVA
   Script completo: creación de funciones y alimentación de datos
   ============================================================ */

/* ------------------------------------------------------------
   1. FUNCIÓN: agregar_moneda
      - Verifica si la moneda existe.
      - Si no existe, la inserta y devuelve el ID.
      - Si existe, devuelve el ID existente.
   ------------------------------------------------------------ */
CREATE OR REPLACE FUNCTION agregar_moneda(
    p_moneda VARCHAR,
    p_sigla VARCHAR,
    p_simbolo VARCHAR,
    p_emisor VARCHAR
)
RETURNS INT AS $$
DECLARE
    v_id INT;
BEGIN
    SELECT "Id" INTO v_id
    FROM moneda
    WHERE "Sigla" = p_sigla;

    IF v_id IS NULL THEN
        INSERT INTO moneda("Moneda", "Sigla", "Simbolo", "Emisor")
        VALUES (p_moneda, p_sigla, p_simbolo, p_emisor)
        RETURNING "Id" INTO v_id;
    END IF;

    RETURN v_id;
END;
$$ LANGUAGE plpgsql;


/* ------------------------------------------------------------
   2. FUNCIÓN: insertar_o_actualizar_cambio
      - Verifica si ya existe un cambio para esa moneda y fecha.
      - Si existe: actualiza.
      - Si no existe: inserta.
   ------------------------------------------------------------ */
CREATE OR REPLACE FUNCTION insertar_o_actualizar_cambio(
    p_idmoneda INT,
    p_fecha DATE,
    p_cambio FLOAT
)
RETURNS VOID AS $$
DECLARE
    v_existente INT;
BEGIN
    SELECT "IdMoneda" INTO v_existente
    FROM cambiodemoneda
    WHERE "IdMoneda" = p_idmoneda
      AND "Fecha" = p_fecha;

    IF v_existente IS NOT NULL THEN
        UPDATE cambiodemoneda
        SET "Cambio" = p_cambio
        WHERE "IdMoneda" = p_idmoneda
          AND "Fecha" = p_fecha;
    ELSE
        INSERT INTO cambiodemoneda("IdMoneda", "Fecha", "Cambio")
        VALUES (p_idmoneda, p_fecha, p_cambio);
    END IF;
END;
$$ LANGUAGE plpgsql;


/* ------------------------------------------------------------
   3. PROGRAMA PRINCIPAL - Alimentación de 2 meses
      Inserta o actualiza el cambio diario de 4 monedas:
      - USD
      - EUR
      - COP
      - GBP
   ------------------------------------------------------------ */
DO $$
DECLARE
    monedas TEXT[][] := ARRAY[
        ['Dólar estadounidense', 'USD', '$', 'Estados Unidos'],
        ['Euro', 'EUR', '€', 'Unión Europea'],
        ['Peso colombiano', 'COP', '$', 'Colombia'],
        ['Libra esterlina', 'GBP', '£', 'Reino Unido']
    ];
    i INT;
    v_id_moneda INT;
    fecha_actual DATE := CURRENT_DATE;
    fecha_inicio DATE := (CURRENT_DATE - INTERVAL '2 months')::DATE;
BEGIN

    FOR i IN 1..array_length(monedas, 1) LOOP
        
        -- Registrar o validar moneda
        v_id_moneda := agregar_moneda(
            monedas[i][1],  -- Nombre
            monedas[i][2],  -- Sigla
            monedas[i][3],  -- Símbolo
            monedas[i][4]   -- Emisor
        );

        -- Insertar/actualizar 2 meses de historial
        FOR d IN fecha_inicio..fecha_actual LOOP
            PERFORM insertar_o_actualizar_cambio(
                v_id_moneda,
                d,
                round(random() * 5000 + 100, 2)
            );
        END LOOP;

    END LOOP;

END $$;
