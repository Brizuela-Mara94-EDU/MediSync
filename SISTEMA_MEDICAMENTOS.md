# Sistema de Medicamentos con Horarios Calculados

## Descripción

Sistema simplificado de gestión de medicamentos donde el médico indica:
- **Frecuencia en horas**: Cada cuántas horas debe tomar el medicamento (ej: 8 horas)
- **Hora de primera toma**: A qué hora el paciente tomará la primera dosis (ej: 08:00)

El sistema **calcula automáticamente** los horarios subsiguientes basándose en estos dos valores.

## ¿Cómo Funciona?

### 1. El Médico Crea la Receta

En `Paciente.svelte`, el médico:
1. Crea una receta para el paciente
2. Agrega medicamentos con:
   - Nombre del medicamento
   - Dosis (ej: "1 comprimido")
   - **Frecuencia en horas** (ej: 8)
   - **Hora de primera toma** (ej: "08:00")
   - Duración en días (ej: 7)
   - Cantidad total (ej: 21 comprimidos)
   - Instrucciones adicionales

### 2. Vista Previa Automática

Cuando el médico ingresa la frecuencia y hora de primera toma, se muestra automáticamente:
- **Tomas calculadas por día**: 08:00, 16:00, 00:00
- **Total de tomas**: 3 tomas/día × 7 días = 21 tomas

**Cálculo**: 
- Hora inicial: 08:00
- Frecuencia: 8 horas
- Tomas: 08:00 → 16:00 → 00:00 → 08:00 (siguiente día)

### 3. Almacenamiento en Base de Datos

Los datos se guardan en la tabla `detalle_receta`:
- `frecuencia`: Texto descriptivo "Cada 8 horas (primera toma: 08:00)"
- `instrucciones_detalladas`: JSON con:
  ```json
  {
    "frecuencia_horas": 8,
    "hora_primera_toma": "08:00",
    "instrucciones": "Tomar con alimentos"
  }
  ```

**NO se crea tabla adicional de tomas** - todo se calcula en tiempo real.

### 4. El Paciente Ve Sus Medicamentos

En `PatientView.svelte`, el sistema:
1. Lee los medicamentos activos de la base de datos
2. Obtiene `frecuencia_horas` y `hora_primera_toma` del JSON
3. Consulta el `localStorage` para ver cuándo fue la última toma
4. **Calcula la próxima hora de toma**:
   - Si nunca tomó: usa la hora de primera toma del día actual
   - Si ya tomó: última toma + frecuencia en horas
5. Muestra **solo los medicamentos que debe tomar ahora** (ventana de 30 min antes a 1 hora después)

### 5. Marcar Como Tomado

Cuando el paciente marca un medicamento como tomado:
1. Se guarda la fecha/hora actual en `localStorage`
2. El medicamento desaparece de la lista
3. Después de 1.5 segundos, se recalcula y muestra la **siguiente toma**

## Ventajas del Sistema

✅ **Simple**: Solo dos campos (frecuencia y hora inicial)
✅ **Sin tablas extra**: No necesita `tomas_medicamento`
✅ **Flexible**: El sistema calcula todo automáticamente
✅ **Offline-first**: Usa `localStorage` para tracking
✅ **Escalable**: Funciona para cualquier frecuencia (1-24 horas)

## Ejemplo Completo

### Médico prescribe:
- Medicamento: Ibuprofeno 400mg
- Dosis: 1 comprimido
- Frecuencia: **8 horas**
- Primera toma: **08:00**
- Duración: 7 días

### Sistema calcula:
- **Tomas por día**: 3 (08:00, 16:00, 00:00)
- **Total tomas**: 21

### Paciente ve:
**Día 1 - 07:45**: "Ibuprofeno 08:00" (próxima toma)
**Día 1 - 08:10**: Marca como tomado → guardado en localStorage
**Día 1 - 15:45**: "Ibuprofeno 16:00" (próxima toma)
**Día 1 - 16:05**: Marca como tomado → guardado
**Día 1 - 23:50**: "Ibuprofeno 00:00" (próxima toma)

Y así sucesivamente durante 7 días...

## Archivos Modificados

1. **`src/lib/pages/medico/Paciente.svelte`**
   - Agregados campos: `frecuencia_horas`, `hora_primera_toma`
   - Función `calcularTomasDia()` para vista previa
   - Guarda JSON en `instrucciones_detalladas`

2. **`src/lib/pages/PatientView.svelte`**
   - Función `cargarMedicamentos()` simplificada
   - Cálculo de próxima toma en tiempo real
   - Funciones `obtenerUltimaToma()` y `guardarToma()` para localStorage
   - Función `marcarTomado()` actualizada

## Estructura de datos

### detalle_receta (tabla PostgreSQL)
```sql
- id_detalle
- id_receta
- nombre_medicamento: "Ibuprofeno 400mg"
- dosis: "1 comprimido"
- frecuencia: "Cada 8 horas (primera toma: 08:00)"
- duracion_dias: 7
- cantidad_total: 21
- instrucciones_detalladas: JSON {
    frecuencia_horas: 8,
    hora_primera_toma: "08:00",
    instrucciones: "..."
  }
```

### localStorage (navegador del paciente)
```json
{
  "tomas_medicamentos": {
    "123": "2024-01-15T08:05:00.000Z",
    "124": "2024-01-15T16:03:00.000Z"
  }
}
```
- Key: `id_detalle` del medicamento
- Value: Fecha/hora ISO de última toma
