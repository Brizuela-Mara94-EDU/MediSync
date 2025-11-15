# Sistema de Tomas Programadas de Medicamentos

## 📋 Descripción

Este sistema permite programar horarios específicos para tomar medicamentos y llevar un control de las tomas completadas.

## 🗄️ Configuración de la Base de Datos

### Paso 1: Ejecutar el Script SQL

Debes ejecutar el archivo `database_tomas_medicamento.sql` en tu base de datos PostgreSQL de Supabase:

1. Ve a tu proyecto en Supabase
2. Abre el **SQL Editor**
3. Copia y pega el contenido de `database_tomas_medicamento.sql`
4. Ejecuta el script (haz clic en "Run")

El script creará:
- ✅ Tabla `tomas_medicamento`
- ✅ Índices para optimización
- ✅ Políticas de seguridad (RLS)
- ✅ Función `obtener_proxima_toma_paciente()`

### Estructura de la Tabla

```sql
tomas_medicamento
├── id_toma (UUID) - ID único de la toma
├── id_detalle (UUID) - Referencia al medicamento
├── fecha_hora_programada (TIMESTAMP) - Cuándo debe tomarse
├── tomado (BOOLEAN) - Si ya fue tomado
├── fecha_toma_real (TIMESTAMP) - Cuándo se tomó realmente
└── creado_en (TIMESTAMP) - Cuándo se creó el registro
```

## 🔄 Flujo de Trabajo

### Para el Médico:

1. **Crear Receta**
   - Ingresar instrucciones generales
   - Especificar validez en días

2. **Agregar Medicamento**
   - Nombre del medicamento
   - Dosis (Ej: "1 comprimido")
   - Frecuencia (Ej: "Cada 8 horas")
   - Duración en días (Ej: 7)
   - **Horarios específicos** (Ej: 08:00, 16:00, 00:00)

3. **Sistema Automático**
   - El sistema calcula todas las tomas
   - Crea un registro por cada día x horario
   - Ejemplo: 3 horarios/día x 7 días = 21 tomas programadas

### Para el Paciente:

1. **Vista de Medicamentos**
   - Solo ve la **próxima toma pendiente** de cada medicamento
   - No ve todas las tomas futuras (evita sobrecarga visual)

2. **Marcar como Tomado**
   - Click en el check ✓
   - Se registra la hora real de la toma
   - Aparece automáticamente la siguiente toma programada

3. **Progreso del Día**
   - Si debe tomar a las 08:00, 14:00 y 22:00
   - Primero aparece solo la de las 08:00
   - Al marcarla, aparece la de las 14:00
   - Y así sucesivamente

## 📊 Ejemplo Práctico

### Médico prescribe:
- **Medicamento**: Ibuprofeno 400mg
- **Dosis**: 1 comprimido
- **Horarios**: 06:00, 14:00, 22:00
- **Duración**: 5 días

### Sistema crea:
```
Día 1: 06:00, 14:00, 22:00 (3 tomas)
Día 2: 06:00, 14:00, 22:00 (3 tomas)
Día 3: 06:00, 14:00, 22:00 (3 tomas)
Día 4: 06:00, 14:00, 22:00 (3 tomas)
Día 5: 06:00, 14:00, 22:00 (3 tomas)
Total: 15 tomas programadas
```

### Paciente ve:
- **Lunes 8:00 AM**: "Ibuprofeno - 06:00" ✓ [Marca como tomado]
- **Lunes 2:00 PM**: "Ibuprofeno - 14:00" (aparece automáticamente)
- **Lunes 10:00 PM**: "Ibuprofeno - 22:00" (aparece después)
- **Martes 8:00 AM**: "Ibuprofeno - 06:00" (nuevo día, primera toma)
- ... y así hasta completar los 5 días

## 🎯 Ventajas del Sistema

1. **Un registro = Una toma**: Control preciso
2. **Horarios exactos**: No solo "cada 8 horas"
3. **Historial completo**: Sabe exactamente cuándo tomó cada dosis
4. **Una a la vez**: No abruma al paciente
5. **Automático**: Al marcar tomado, aparece la siguiente

## 🔍 Consultas Útiles

### Ver todas las tomas de un paciente
```sql
SELECT * FROM tomas_medicamento tm
INNER JOIN detalle_receta dr ON tm.id_detalle = dr.id_detalle
INNER JOIN recetas r ON dr.id_receta = r.id_receta
WHERE r.id_paciente = '<id_paciente>'
ORDER BY tm.fecha_hora_programada;
```

### Ver tomas pendientes de hoy
```sql
SELECT * FROM tomas_medicamento
WHERE tomado = FALSE
AND DATE(fecha_hora_programada) = CURRENT_DATE
ORDER BY fecha_hora_programada;
```

### Historial de adherencia
```sql
SELECT 
    COUNT(*) as total_tomas,
    COUNT(CASE WHEN tomado THEN 1 END) as tomas_completadas,
    ROUND(COUNT(CASE WHEN tomado THEN 1 END)::numeric / COUNT(*)::numeric * 100, 2) as adherencia_porcentaje
FROM tomas_medicamento tm
INNER JOIN detalle_receta dr ON tm.id_detalle = dr.id_detalle
INNER JOIN recetas r ON dr.id_receta = r.id_receta
WHERE r.id_paciente = '<id_paciente>';
```

## ⚠️ Importante

- Ejecuta el script SQL **ANTES** de usar el sistema
- Los horarios se guardan con la zona horaria del servidor
- Solo aparecen tomas dentro de la próxima hora
- Al marcar tomado, se recarga la lista automáticamente

## 🐛 Solución de Problemas

**Problema**: No aparecen medicamentos en la vista del paciente
- Verifica que ejecutaste el script SQL
- Verifica que el médico agregó horarios al medicamento
- Verifica que hay tomas pendientes en la tabla

**Problema**: Error al marcar como tomado
- Verifica las políticas RLS en Supabase
- Verifica que la tabla existe
- Revisa la consola del navegador para ver el error específico
