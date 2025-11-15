-- ============================================
-- TABLA PARA GESTIÓN DE TOMAS DE MEDICAMENTOS
-- ============================================

-- Tabla: tomas_medicamento
-- Esta tabla registra cada toma programada de un medicamento
-- Permite llevar un control de qué medicamentos se deben tomar, a qué hora, y si fueron tomados
CREATE TABLE tomas_medicamento (
    id_toma UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_detalle UUID NOT NULL, -- Referencia a detalle_receta
    fecha_hora_programada TIMESTAMP WITH TIME ZONE NOT NULL, -- Cuándo se debe tomar
    tomado BOOLEAN DEFAULT FALSE, -- Si ya fue tomado
    fecha_toma_real TIMESTAMP WITH TIME ZONE, -- Cuándo realmente se tomó
    creado_en TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT fk_toma_detalle FOREIGN KEY (id_detalle) 
        REFERENCES detalle_receta(id_detalle) ON DELETE CASCADE
);

-- ============================================
-- ÍNDICES PARA OPTIMIZACIÓN
-- ============================================

CREATE INDEX idx_tomas_detalle ON tomas_medicamento(id_detalle);
CREATE INDEX idx_tomas_programada ON tomas_medicamento(fecha_hora_programada);
CREATE INDEX idx_tomas_tomado ON tomas_medicamento(tomado);
CREATE INDEX idx_tomas_detalle_fecha ON tomas_medicamento(id_detalle, fecha_hora_programada);

-- ============================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================

ALTER TABLE tomas_medicamento ENABLE ROW LEVEL SECURITY;

-- Política permisiva para operaciones básicas
CREATE POLICY "Permitir todas las operaciones en tomas_medicamento"
    ON tomas_medicamento FOR ALL
    USING (true)
    WITH CHECK (true);

-- ============================================
-- COMENTARIOS
-- ============================================

COMMENT ON TABLE tomas_medicamento IS 'Registro de tomas programadas de medicamentos con su estado';
COMMENT ON COLUMN tomas_medicamento.id_detalle IS 'Referencia al medicamento en detalle_receta';
COMMENT ON COLUMN tomas_medicamento.fecha_hora_programada IS 'Fecha y hora en que debe tomarse el medicamento';
COMMENT ON COLUMN tomas_medicamento.tomado IS 'Indica si el medicamento ya fue tomado';
COMMENT ON COLUMN tomas_medicamento.fecha_toma_real IS 'Fecha y hora real en que se tomó el medicamento';

-- ============================================
-- FUNCIÓN AUXILIAR PARA OBTENER PRÓXIMA TOMA
-- ============================================

-- Función para obtener la próxima toma pendiente de un paciente
CREATE OR REPLACE FUNCTION obtener_proxima_toma_paciente(p_id_paciente UUID)
RETURNS TABLE(
    id_toma UUID,
    id_detalle UUID,
    nombre_medicamento VARCHAR,
    dosis VARCHAR,
    fecha_hora_programada TIMESTAMP WITH TIME ZONE,
    instrucciones_detalladas TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        tm.id_toma,
        tm.id_detalle,
        dr.nombre_medicamento,
        dr.dosis,
        tm.fecha_hora_programada,
        dr.instrucciones_detalladas
    FROM tomas_medicamento tm
    INNER JOIN detalle_receta dr ON tm.id_detalle = dr.id_detalle
    INNER JOIN recetas r ON dr.id_receta = r.id_receta
    WHERE r.id_paciente = p_id_paciente
    AND tm.tomado = FALSE
    AND tm.fecha_hora_programada <= NOW() + INTERVAL '1 hour' -- Próxima hora
    ORDER BY tm.fecha_hora_programada ASC
    LIMIT 1;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- VERIFICACIÓN
-- ============================================

-- Ver la tabla creada
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public'
AND table_name = 'tomas_medicamento';

-- Ver función creada
SELECT routine_name, routine_type
FROM information_schema.routines
WHERE routine_schema = 'public'
AND routine_name = 'obtener_proxima_toma_paciente';
