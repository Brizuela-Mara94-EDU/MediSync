<script lang="ts">
  import { onMount } from 'svelte';
  import { supabase } from '../../supabase/supabase-client.js';
  import SessionManager from '../../utils/SessionManager.js';

  let { idPaciente, nombrePaciente, onVolver } = $props();

  let loading = $state(true);
  let recetas = $state([]);
  let medicamentos = $state([]);
  let showRecetaModal = $state(false);
  let showMedicamentoModal = $state(false);
  let idMedico = $state(null);
  
  let nuevaReceta = $state({
    fecha_emision: '',
    validez_dias: 30,
    instrucciones_generales: ''
  });

  let nuevoMedicamento = $state({
    id_receta: '',
    nombre_medicamento: '',
    dosis: '',
    frecuencia_horas: '',
    hora_primera_toma: '',
    duracion_dias: '',
    cantidad_total: '',
    instrucciones_detalladas: ''
  });

  let editandoMedicamento = $state(false);
  let medicamentoAEditar = $state(null);

  onMount(async () => {
    const sesion = SessionManager.obtenerSesion();
    if (sesion?.id_usuario) {
      const { data: medicoData } = await supabase
        .from('medicos')
        .select('id_medico')
        .eq('id_usuario', sesion.id_usuario)
        .single();
      
      if (medicoData) {
        idMedico = medicoData.id_medico;
      }
    }
    
    await cargarRecetas();
  });

  async function cargarRecetas() {
    try {
      // Primero obtener todas las recetas del paciente
      const { data: recetasData, error: recetasError } = await supabase
        .from('recetas')
        .select(`
          *,
          detalle_receta (
            id_detalle,
            nombre_medicamento,
            dosis,
            frecuencia,
            duracion_dias,
            cantidad_total,
            instrucciones_detalladas
          )
        `)
        .eq('id_paciente', idPaciente)
        .order('fecha_emision', { ascending: false });

      if (recetasError) throw recetasError;

      // Obtener información de los médicos
      if (recetasData && recetasData.length > 0) {
        const idsmedicos = [...new Set(recetasData.map(r => r.id_medico))];
        
        const { data: medicosData, error: medicosError } = await supabase
          .from('medicos')
          .select(`
            id_medico,
            usuarios (
              nombre,
              apellido
            )
          `)
          .in('id_medico', idsmedicos);

        if (!medicosError && medicosData) {
          // Mapear la información de médicos a las recetas
          recetas = recetasData.map(receta => {
            const medicoInfo = medicosData.find(m => m.id_medico === receta.id_medico);
            return {
              ...receta,
              medicos: medicoInfo || null
            };
          });
        } else {
          recetas = recetasData;
        }
      } else {
        recetas = [];
      }

      medicamentos = recetas.flatMap(receta => 
        (receta.detalle_receta || []).map(med => ({
          ...med,
          receta_fecha: receta.fecha_emision,
          receta_estado: receta.estado
        }))
      );
    } catch (error) {
      console.error('Error cargando recetas:', error);
    } finally {
      loading = false;
    }
  }

  // Función para verificar si el médico actual puede editar esta receta
  function puedeEditarReceta(receta) {
    return receta.id_medico === idMedico;
  }

  // Función para obtener el nombre del médico
  function obtenerNombreMedico(receta) {
    if (receta.medicos?.usuarios) {
      const { nombre, apellido } = receta.medicos.usuarios;
      return `${nombre} ${apellido}`;
    }
    return 'Médico desconocido';
  }

  async function crearReceta() {
    try {
      if (!idMedico) {
        alert('Error: No se pudo obtener el ID del médico');
        return;
      }

      loading = true;

      const { data, error } = await supabase
        .from('recetas')
        .insert([{
          id_medico: idMedico,
          id_paciente: idPaciente,
          fecha_emision: nuevaReceta.fecha_emision || new Date().toISOString(),
          validez_dias: parseInt(String(nuevaReceta.validez_dias)) || 30,
          instrucciones_generales: nuevaReceta.instrucciones_generales,
          estado: 'activa'
        }])
        .select()
        .single();

      if (error) throw error;

      alert('Receta creada correctamente. Ahora puedes agregar medicamentos.');
      showRecetaModal = false;
      nuevaReceta = {
        fecha_emision: '',
        validez_dias: 30,
        instrucciones_generales: ''
      };
      
      await cargarRecetas();
    } catch (error) {
      console.error('Error creando receta:', error);
      alert('Error al crear la receta: ' + error.message);
    } finally {
      loading = false;
    }
  }

  async function agregarMedicamento() {
    try {
      loading = true;

      const { error } = await supabase
        .from('detalle_receta')
        .insert([{
          id_receta: nuevoMedicamento.id_receta,
          nombre_medicamento: nuevoMedicamento.nombre_medicamento,
          dosis: nuevoMedicamento.dosis,
          frecuencia: `Cada ${nuevoMedicamento.frecuencia_horas} horas`,
          duracion_dias: parseInt(String(nuevoMedicamento.duracion_dias)),
          cantidad_total: parseInt(String(nuevoMedicamento.cantidad_total)),
          instrucciones_detalladas: JSON.stringify({
            frecuencia_horas: parseInt(String(nuevoMedicamento.frecuencia_horas)),
            hora_primera_toma: nuevoMedicamento.hora_primera_toma,
            instrucciones: nuevoMedicamento.instrucciones_detalladas
          })
        }]);

      if (error) throw error;

      alert('Medicamento agregado correctamente');
      showMedicamentoModal = false;
      nuevoMedicamento = {
        id_receta: '',
        nombre_medicamento: '',
        dosis: '',
        frecuencia_horas: '',
        hora_primera_toma: '',
        duracion_dias: '',
        cantidad_total: '',
        instrucciones_detalladas: ''
      };
      
      await cargarRecetas();
    } catch (error) {
      console.error('Error agregando medicamento:', error);
      alert('Error al agregar medicamento: ' + error.message);
    } finally {
      loading = false;
    }
  }

  function abrirModalReceta() {
    nuevaReceta.fecha_emision = new Date().toISOString().split('T')[0];
    showRecetaModal = true;
  }

  function abrirModalMedicamento(receta) {
    if (!puedeEditarReceta(receta)) {
      alert('No tienes permisos para agregar medicamentos a esta receta.');
      return;
    }
    
    editandoMedicamento = false;
    medicamentoAEditar = null;
    nuevoMedicamento = {
      id_receta: receta.id_receta,
      nombre_medicamento: '',
      dosis: '',
      frecuencia_horas: '',
      hora_primera_toma: '',
      duracion_dias: '',
      cantidad_total: '',
      instrucciones_detalladas: ''
    };
    showMedicamentoModal = true;
  }

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  function abrirModalEditarMedicamento(medicamento: any, receta: any) {
    if (!puedeEditarReceta(receta)) {
      alert('No tienes permisos para editar medicamentos de esta receta.');
      return;
    }
    
    editandoMedicamento = true;
    medicamentoAEditar = medicamento;
    
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    let instruccionesObj: any = {};
    try {
      instruccionesObj = JSON.parse(medicamento.instrucciones_detalladas || '{}');
    } catch {
      instruccionesObj = {};
    }
    
    nuevoMedicamento = {
      id_receta: medicamento.id_receta || '',
      nombre_medicamento: medicamento.nombre_medicamento,
      dosis: medicamento.dosis,
      frecuencia_horas: String(instruccionesObj.frecuencia_horas || ''),
      hora_primera_toma: instruccionesObj.hora_primera_toma || '',
      duracion_dias: String(medicamento.duracion_dias || ''),
      cantidad_total: String(medicamento.cantidad_total || ''),
      instrucciones_detalladas: instruccionesObj.instrucciones || ''
    };
    
    showMedicamentoModal = true;
  }

  async function actualizarMedicamento() {
    try {
      loading = true;

      const { error } = await supabase
        .from('detalle_receta')
        .update({
          nombre_medicamento: nuevoMedicamento.nombre_medicamento,
          dosis: nuevoMedicamento.dosis,
          frecuencia: `Cada ${nuevoMedicamento.frecuencia_horas} horas`,
          duracion_dias: parseInt(String(nuevoMedicamento.duracion_dias)),
          cantidad_total: parseInt(String(nuevoMedicamento.cantidad_total)),
          instrucciones_detalladas: JSON.stringify({
            frecuencia_horas: parseInt(String(nuevoMedicamento.frecuencia_horas)),
            hora_primera_toma: nuevoMedicamento.hora_primera_toma,
            instrucciones: nuevoMedicamento.instrucciones_detalladas
          })
        })
        .eq('id_detalle', medicamentoAEditar.id_detalle);

      if (error) throw error;

      alert('Medicamento actualizado correctamente');
      showMedicamentoModal = false;
      editandoMedicamento = false;
      medicamentoAEditar = null;
      nuevoMedicamento = {
        id_receta: '',
        nombre_medicamento: '',
        dosis: '',
        frecuencia_horas: '',
        hora_primera_toma: '',
        duracion_dias: '',
        cantidad_total: '',
        instrucciones_detalladas: ''
      };
      
      await cargarRecetas();
    } catch (error) {
      console.error('Error actualizando medicamento:', error);
      alert('Error al actualizar medicamento: ' + error.message);
    } finally {
      loading = false;
    }
  }

  async function eliminarMedicamento(medicamento, receta) {
    if (!puedeEditarReceta(receta)) {
      alert('No tienes permisos para eliminar medicamentos de esta receta.');
      return;
    }
    
    if (!confirm(`¿Estás seguro de eliminar el medicamento "${medicamento.nombre_medicamento}"?`)) {
      return;
    }

    try {
      loading = true;

      const { error } = await supabase
        .from('detalle_receta')
        .delete()
        .eq('id_detalle', medicamento.id_detalle);

      if (error) throw error;

      alert('Medicamento eliminado correctamente');
      await cargarRecetas();
    } catch (error) {
      console.error('Error eliminando medicamento:', error);
      alert('Error al eliminar medicamento: ' + error.message);
    } finally {
      loading = false;
    }
  }

  function calcularTomasDia(horaInicial, frecuenciaHoras) {
    if (!horaInicial || !frecuenciaHoras || frecuenciaHoras <= 0) return [];
    
    const tomas = [];
    const [horas, minutos] = horaInicial.split(':').map(Number);
    
    // Si la frecuencia es mayor a 24 horas, es un tratamiento semanal/mensual
    if (frecuenciaHoras >= 24) {
      const dias = Math.floor(frecuenciaHoras / 24);
      const h = String(horas).padStart(2, '0');
      const m = String(minutos).padStart(2, '0');
      
      return [{
        hora: `${h}:${m}`,
        esSemanal: true,
        dias: dias,
        descripcion: dias === 7 ? 'semanal' : dias === 14 ? 'quincenal' : dias === 30 ? 'mensual' : `cada ${dias} días`
      }];
    }
    
    let horaActual = horas;
    let minutosActuales = minutos;
    const tomasEnDia = Math.floor(24 / frecuenciaHoras);
    
    for (let i = 0; i < tomasEnDia; i++) {
      const h = String(horaActual).padStart(2, '0');
      const m = String(minutosActuales).padStart(2, '0');
      tomas.push({ hora: `${h}:${m}`, esSemanal: false });
      
      horaActual += frecuenciaHoras;
      if (horaActual >= 24) horaActual -= 24;
    }
    
    return tomas;
  }

  // Calcular cantidad total de comprimidos/dosis necesarios
  function calcularCantidadTotal(frecuenciaHoras, duracionDias, dosisPorToma = 1) {
    if (!frecuenciaHoras || !duracionDias || frecuenciaHoras <= 0 || duracionDias <= 0) {
      return 0;
    }

    // Si la frecuencia es mayor o igual a 24 horas (semanal, mensual, etc)
    if (frecuenciaHoras >= 24) {
      const diasEntreTomas = Math.floor(frecuenciaHoras / 24);
      const numeroTomas = Math.ceil(duracionDias / diasEntreTomas);
      return numeroTomas * dosisPorToma;
    }

    // Para medicamentos diarios
    const tomasPorDia = Math.floor(24 / frecuenciaHoras);
    const totalTomas = tomasPorDia * duracionDias;
    return totalTomas * dosisPorToma;
  }

  // Derived para calcular automáticamente la cantidad
  let cantidadCalculada = $derived.by(() => {
    const frecuencia = parseInt(nuevoMedicamento.frecuencia_horas);
    const duracion = parseInt(nuevoMedicamento.duracion_dias);
    const dosis = nuevoMedicamento.dosis;
    
    // Intentar extraer el número de la dosis (ej: "2 comprimidos" -> 2)
    let dosisPorToma = 1;
    if (dosis) {
      const match = dosis.match(/^(\d+)/);
      if (match) {
        dosisPorToma = parseInt(match[1]);
      }
    }
    
    return calcularCantidadTotal(frecuencia, duracion, dosisPorToma);
  });

  // Obtener solo las recetas del médico actual para el selector
  let recetasPropias = $derived(recetas.filter(r => puedeEditarReceta(r)));
</script>

<div class="recetas-container">
  <div class="recetas-header">
    <button class="btn-back" onclick={onVolver}>
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
        <path d="M19 12H5"/>
        <path d="m12 19-7-7 7-7"/>
      </svg>
      Volver
    </button>
    <h2>Recetas Médicas - {nombrePaciente}</h2>
  </div>

  <div class="content-card">
    <div class="card-header">
      <h3>Recetas</h3>
      <button class="btn-primary" onclick={abrirModalReceta}>
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <path d="M12 5v14M5 12h14"/>
        </svg>
        Nueva Receta
      </button>
    </div>

    {#if loading}
      <div class="loading-state">
        <p>Cargando recetas...</p>
      </div>
    {:else if recetas.length === 0}
      <div class="empty-state">
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/>
          <polyline points="14 2 14 8 20 8"/>
        </svg>
        <p>No hay recetas registradas para este paciente</p>
      </div>
    {:else}
      <div class="recetas-list">
        {#each recetas as receta}
          {@const esEditable = puedeEditarReceta(receta)}
          {@const nombreMedico = obtenerNombreMedico(receta)}
          
          <div class="receta-card" class:readonly={!esEditable}>
            <div class="receta-header">
              <div>
                <div class="receta-title-row">
                  <h4>Receta #{receta.id_receta.slice(0, 8)}</h4>
                  {#if !esEditable}
                    <span class="badge-readonly">Solo lectura</span>
                  {/if}
                </div>
                <p class="receta-medico">👨‍⚕️ Dr. {nombreMedico}</p>
                <p class="receta-date">
                  {new Date(receta.fecha_emision).toLocaleDateString('es-AR')} • 
                  Válida por {receta.validez_dias} días
                </p>
              </div>
              <div class="receta-actions">
                <span class="badge {receta.estado === 'activa' ? 'activa' : 'vencida'}">
                  {receta.estado}
                </span>
                {#if esEditable}
                  <button 
                    class="btn-primary btn-small" 
                    onclick={() => abrirModalMedicamento(receta)}
                  >
                    + Medicamento
                  </button>
                {/if}
              </div>
            </div>

            {#if receta.instrucciones_generales}
              <div class="receta-info">
                <p><strong>Instrucciones:</strong> {receta.instrucciones_generales}</p>
              </div>
            {/if}

            {#if receta.detalle_receta && receta.detalle_receta.length > 0}
              <div class="medicamentos-list">
                <h5>💊 Medicamentos ({receta.detalle_receta.length})</h5>
                {#each receta.detalle_receta as medicamento}
                  <div class="medicamento-item">
                    <div class="med-icon">💊</div>
                    <div class="med-info">
                      <p class="med-name">{medicamento.nombre_medicamento}</p>
                      <p class="med-detail">Dosis: {medicamento.dosis} • {medicamento.frecuencia}</p>
                      {#if medicamento.duracion_dias}
                        <p class="med-duration">Duración: {medicamento.duracion_dias} días</p>
                      {/if}
                      {#if medicamento.cantidad_total}
                        <p class="med-quantity">Cantidad total: {medicamento.cantidad_total}</p>
                      {/if}
                    </div>
                    {#if esEditable}
                      <div class="med-actions">
                        <button 
                          class="btn-icon-edit" 
                          onclick={() => abrirModalEditarMedicamento(medicamento, receta)}
                          title="Editar medicamento"
                        >
                          <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                            <path d="M17 3a2.85 2.83 0 1 1 4 4L7.5 20.5 2 22l1.5-5.5Z"/>
                          </svg>
                        </button>
                        <button 
                          class="btn-icon-delete" 
                          onclick={() => eliminarMedicamento(medicamento, receta)}
                          title="Eliminar medicamento"
                        >
                          <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                            <path d="M3 6h18M19 6v14c0 1-1 2-2 2H7c-1 0-2-1-2-2V6M8 6V4c0-1 1-2 2-2h4c1 0 2 1 2 2v2"/>
                          </svg>
                        </button>
                      </div>
                    {:else}
                      <div class="med-locked">
                        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                          <rect width="18" height="11" x="3" y="11" rx="2" ry="2"/>
                          <path d="M7 11V7a5 5 0 0 1 10 0v4"/>
                        </svg>
                      </div>
                    {/if}
                  </div>
                {/each}
              </div>
            {:else}
              <p class="empty-meds">No hay medicamentos en esta receta</p>
            {/if}
          </div>
        {/each}
      </div>
    {/if}
  </div>
</div>

<!-- Modal Nueva Receta -->
{#if showRecetaModal}
  <div 
    class="modal-overlay" 
    role="button" 
    tabindex="0"
    onclick={() => showRecetaModal = false}
    onkeydown={(e) => e.key === 'Escape' && (showRecetaModal = false)}
  >
    <div 
      class="modal" 
      role="dialog"
      tabindex="-1"
      onclick={(e) => e.stopPropagation()} 
      onkeydown={(e) => e.stopPropagation()}
    >
      <div class="modal-header">
        <h3>Nueva Receta</h3>
        <button class="close-btn" onclick={() => showRecetaModal = false} aria-label="Cerrar">
          <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <path d="M18 6 6 18M6 6l12 12"/>
          </svg>
        </button>
      </div>

      <form onsubmit={(e) => { e.preventDefault(); crearReceta(); }}>
        <div class="modal-body">
          <div class="form-group">
            <label for="fecha_emision">Fecha de Emisión</label>
            <input 
              type="date" 
              id="fecha_emision" 
              bind:value={nuevaReceta.fecha_emision}
              required
            />
          </div>

          <div class="form-group">
            <label for="validez_dias">Días de Validez</label>
            <input 
              type="number" 
              id="validez_dias" 
              bind:value={nuevaReceta.validez_dias}
              min="1"
              required
            />
          </div>

          <div class="form-group">
            <label for="instrucciones">Instrucciones Generales</label>
            <textarea 
              id="instrucciones" 
              bind:value={nuevaReceta.instrucciones_generales}
              rows="3"
              placeholder="Indicaciones generales para el paciente..."
            ></textarea>
          </div>
        </div>

        <div class="modal-footer">
          <button type="button" class="btn-secondary" onclick={() => showRecetaModal = false}>
            Cancelar
          </button>
          <button type="submit" class="btn-primary" disabled={loading}>
            {loading ? 'Creando...' : 'Crear Receta'}
          </button>
        </div>
      </form>
    </div>
  </div>
{/if}

<!-- Modal Agregar/Editar Medicamento -->
{#if showMedicamentoModal}
  <div 
    class="modal-overlay" 
    role="button" 
    tabindex="0"
    onclick={() => showMedicamentoModal = false}
    onkeydown={(e) => e.key === 'Escape' && (showMedicamentoModal = false)}
  >
    <div 
      class="modal" 
      role="dialog"
      tabindex="-1"
      onclick={(e) => e.stopPropagation()} 
      onkeydown={(e) => e.stopPropagation()}
    >
      <div class="modal-header">
        <h3>{editandoMedicamento ? 'Editar' : 'Agregar'} Medicamento</h3>
        <button class="close-btn" onclick={() => showMedicamentoModal = false} aria-label="Cerrar">
          <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <path d="M18 6 6 18M6 6l12 12"/>
          </svg>
        </button>
      </div>

      <form onsubmit={(e) => { e.preventDefault(); editandoMedicamento ? actualizarMedicamento() : agregarMedicamento(); }}>
        <div class="modal-body">
          {#if !editandoMedicamento && recetasPropias.length > 0}
            <div class="form-group">
              <label for="id_receta">Receta</label>
              <select id="id_receta" bind:value={nuevoMedicamento.id_receta} required>
                <option value="">Seleccione una receta</option>
                {#each recetasPropias as receta}
                  <option value={receta.id_receta}>
                    Receta {new Date(receta.fecha_emision).toLocaleDateString()} - {receta.estado}
                  </option>
                {/each}
              </select>
            </div>
          {/if}

          <div class="form-group">
            <label for="nombre_medicamento">Nombre del Medicamento</label>
            <input 
              type="text" 
              id="nombre_medicamento" 
              bind:value={nuevoMedicamento.nombre_medicamento}
              placeholder="Ej: Ibuprofeno 600mg"
              required
            />
          </div>

          <div class="form-group">
            <label for="dosis">Dosis</label>
            <input 
              type="text" 
              id="dosis" 
              bind:value={nuevoMedicamento.dosis}
              placeholder="Ej: 1 comprimido"
              required
            />
          </div>

          <div class="form-group">
            <label for="frecuencia_horas">Frecuencia (cada cuántas horas)</label>
            <input 
              type="number" 
              id="frecuencia_horas" 
              bind:value={nuevoMedicamento.frecuencia_horas}
              placeholder="Ej: 8 (cada 8 horas) o 168 (cada 7 días)"
              min="1"
              required
            />
            <small>
              Para medicamentos diarios: cada cuántas horas (ej: 8 = cada 8 horas)<br/>
              Para medicamentos semanales/mensuales: 168 = cada 7 días, 336 = cada 14 días, 720 = cada 30 días
            </small>
          </div>

          <div class="form-group">
            <label for="hora_primera_toma">Hora de la Primera Toma</label>
            <input 
              type="time" 
              id="hora_primera_toma" 
              bind:value={nuevoMedicamento.hora_primera_toma}
              required
            />
            <small>Hora en que debe tomar la primera dosis del día</small>
          </div>

          {#if nuevoMedicamento.frecuencia_horas && nuevoMedicamento.hora_primera_toma}
            {@const tomas = calcularTomasDia(nuevoMedicamento.hora_primera_toma, parseInt(nuevoMedicamento.frecuencia_horas))}
            <div class="tomas-preview">
              {#if tomas.length > 0 && tomas[0].esSemanal}
                <strong>📅 Frecuencia de toma:</strong>
                <div class="tomas-calculadas">
                  <span class="toma-chip toma-semanal">
                    🗓️ {tomas[0].hora} - {tomas[0].descripcion}
                  </span>
                </div>
                <p class="tomas-totales">
                  <strong>Nota:</strong> Este medicamento se toma {tomas[0].descripcion} a las {tomas[0].hora}
                  {#if nuevoMedicamento.duracion_dias && parseInt(nuevoMedicamento.duracion_dias) > 0}
                    <br/>
                    <strong>Durante {nuevoMedicamento.duracion_dias} días</strong> = aproximadamente {Math.ceil(parseInt(nuevoMedicamento.duracion_dias) / tomas[0].dias)} tomas totales
                  {/if}
                </p>
              {:else}
                <strong>📅 Tomas programadas del día:</strong>
                <div class="tomas-calculadas">
                  {#each tomas as toma}
                    <span class="toma-chip">🕐 {toma.hora}</span>
                  {/each}
                </div>
                <p class="tomas-totales">
                  <strong>Total:</strong> {tomas.length} toma(s) por día
                  {#if nuevoMedicamento.duracion_dias && parseInt(nuevoMedicamento.duracion_dias) > 0}
                    <br/>
                    <strong>Durante {nuevoMedicamento.duracion_dias} días</strong> = {tomas.length * parseInt(nuevoMedicamento.duracion_dias)} tomas totales
                  {/if}
                </p>
              {/if}
            </div>
          {/if}

          <div class="form-group">
            <label for="duracion_dias">Duración (días)</label>
            <input 
              type="number" 
              id="duracion_dias" 
              bind:value={nuevoMedicamento.duracion_dias}
              min="1"
              placeholder="Ej: 7, 30, 60"
            />
            <small>Por cuántos días debe continuar el tratamiento</small>
          </div>

          <div class="form-group">
            <label for="cantidad_total">
              Cantidad Total
              {#if cantidadCalculada > 0}
                <span class="cantidad-sugerida">💡 Sugerido: {cantidadCalculada}</span>
              {/if}
            </label>
            <input 
              type="number" 
              id="cantidad_total" 
              bind:value={nuevoMedicamento.cantidad_total}
              min="1"
              placeholder={cantidadCalculada > 0 ? `Sugerido: ${cantidadCalculada}` : "Número de comprimidos/dosis"}
            />
            <small>
              {#if cantidadCalculada > 0}
                Cálculo automático: {cantidadCalculada} unidades. Puedes modificar este valor si es necesario.
              {:else}
                Número total de comprimidos o dosis necesarios para el tratamiento
              {/if}
            </small>
          </div>

          <div class="form-group">
            <label for="instrucciones_detalladas">Instrucciones Adicionales</label>
            <textarea 
              id="instrucciones_detalladas" 
              bind:value={nuevoMedicamento.instrucciones_detalladas}
              rows="3"
              placeholder="Ej: Tomar con las comidas, no con el estómago vacío..."
            ></textarea>
          </div>
        </div>

        <div class="modal-footer">
          <button type="button" class="btn-secondary" onclick={() => showMedicamentoModal = false}>
            Cancelar
          </button>
          <button type="submit" class="btn-primary" disabled={loading}>
            {loading ? 'Guardando...' : (editandoMedicamento ? 'Actualizar' : 'Agregar')}
          </button>
        </div>
      </form>
    </div>
  </div>
{/if}

<style>
  .recetas-container {
    padding: 2rem;
    max-width: 1400px;
    margin: 0 auto;
  }

  .recetas-header {
    margin-bottom: 2rem;
  }

  .recetas-header h2 {
    margin: 1rem 0;
    font-size: 28px;
    color: var(--color-900);
  }

  .btn-back {
    display: inline-flex;
    align-items: center;
    gap: 0.5rem;
    padding: 0.5rem 1rem;
    background: white;
    border: 2px solid var(--color-200);
    border-radius: 10px;
    cursor: pointer;
    font-size: 0.9rem;
    color: var(--color-700);
    font-weight: 500;
    transition: all 0.2s;
  }

  .btn-back:hover {
    background: var(--color-50);
    border-color: var(--color-300);
  }

  .btn-back svg {
    width: 20px;
    height: 20px;
  }

  .content-card {
    background: white;
    border-radius: 16px;
    padding: 24px;
    box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
    border: 1px solid var(--color-100);
  }

  .card-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 24px;
    padding-bottom: 16px;
    border-bottom: 1px solid var(--color-200);
  }

  .card-header h3 {
    margin: 0;
    font-size: 18px;
    color: var(--color-900);
    font-weight: 600;
  }

  .btn-primary {
    display: inline-flex;
    align-items: center;
    gap: 0.5rem;
    padding: 0.75rem 1.5rem;
    background: linear-gradient(135deg, var(--color-500) 0%, var(--color-700) 100%);
    color: white;
    border: none;
    border-radius: 10px;
    cursor: pointer;
    font-size: 0.9rem;
    font-weight: 600;
    transition: all 0.2s;
  }

  .btn-primary:hover:not(:disabled) {
    transform: translateY(-2px);
    box-shadow: 0 4px 12px rgba(79, 166, 158, 0.4);
  }

  .btn-primary:disabled {
    opacity: 0.5;
    cursor: not-allowed;
  }

  .btn-primary svg {
    width: 18px;
    height: 18px;
  }

  .btn-small {
    padding: 0.5rem 1rem;
    font-size: 0.85rem;
  }

  .btn-secondary {
    padding: 0.75rem 1.5rem;
    background: white;
    color: var(--color-700);
    border: 2px solid var(--color-200);
    border-radius: 8px;
    cursor: pointer;
    font-size: 0.9rem;
    font-weight: 600;
    transition: all 0.2s;
  }

  .btn-secondary:hover {
    background: var(--color-50);
    border-color: var(--color-300);
  }

  .loading-state,
  .empty-state {
    text-align: center;
    padding: 3rem 1rem;
    color: var(--color-700);
  }

  .empty-state svg {
    width: 48px;
    height: 48px;
    margin-bottom: 1rem;
    opacity: 0.5;
    color: var(--color-400);
  }

  .recetas-list {
    display: flex;
    flex-direction: column;
    gap: 1rem;
  }

  .receta-card {
    border: 1px solid var(--color-200);
    border-radius: 16px;
    padding: 20px;
    transition: all 0.2s;
    background: white;
    box-shadow: 0 1px 3px rgba(0, 0, 0, 0.05);
  }

  .receta-card:hover {
    box-shadow: 0 4px 12px rgba(79, 166, 158, 0.15);
    transform: translateY(-2px);
  }

  .receta-card.readonly {
    background: linear-gradient(135deg, #fafafa 0%, #f5f5f5 100%);
    border-color: #e0e0e0;
  }

  .receta-card.readonly:hover {
    box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
  }

  .receta-header {
    display: flex;
    justify-content: space-between;
    align-items: flex-start;
    margin-bottom: 1rem;
  }

  .receta-title-row {
    display: flex;
    align-items: center;
    gap: 0.75rem;
    margin-bottom: 0.5rem;
  }

  .receta-header h4 {
    margin: 0;
    color: var(--color-900);
    font-size: 16px;
    font-weight: 600;
  }

  .receta-medico {
    margin: 0.25rem 0;
    font-size: 0.9rem;
    color: var(--color-800);
    font-weight: 500;
  }

  .receta-date {
    margin: 0;
    font-size: 0.875rem;
    color: var(--color-700);
  }

  .receta-actions {
    display: flex;
    align-items: center;
    gap: 0.5rem;
  }

  .receta-info p {
    margin: 0.5rem 0;
    font-size: 0.9rem;
    color: var(--color-800);
  }

  .medicamentos-list {
    margin-top: 1rem;
    padding-top: 1rem;
    border-top: 1px solid var(--color-200);
  }

  .medicamentos-list h5 {
    margin: 0 0 0.75rem 0;
    font-size: 14px;
    color: var(--color-900);
    font-weight: 600;
  }

  .medicamento-item {
    display: flex;
    gap: 1rem;
    padding: 12px;
    background: var(--color-50);
    border-radius: 10px;
    margin-bottom: 0.5rem;
    align-items: center;
    border: 1px solid var(--color-100);
  }

  .readonly .medicamento-item {
    background: white;
    border-color: #e0e0e0;
  }

  .med-icon {
    font-size: 1.5rem;
  }

  .med-info {
    flex: 1;
  }

  .med-actions {
    display: flex;
    gap: 0.5rem;
  }

  .med-locked {
    display: flex;
    align-items: center;
    justify-content: center;
    width: 40px;
    height: 40px;
    color: #9e9e9e;
  }

  .med-locked svg {
    width: 20px;
    height: 20px;
  }

  .btn-icon-edit,
  .btn-icon-delete {
    width: 36px;
    height: 36px;
    border-radius: 8px;
    border: none;
    cursor: pointer;
    display: flex;
    align-items: center;
    justify-content: center;
    transition: all 0.2s;
  }

  .btn-icon-edit {
    background: #dbeafe;
    color: #1e40af;
  }

  .btn-icon-edit:hover {
    background: #3b82f6;
    color: white;
  }

  .btn-icon-edit svg {
    width: 18px;
    height: 18px;
  }

  .btn-icon-delete {
    background: #fee2e2;
    color: #991b1b;
  }

  .btn-icon-delete:hover {
    background: #ef4444;
    color: white;
  }

  .btn-icon-delete svg {
    width: 18px;
    height: 18px;
  }

  .med-name {
    margin: 0 0 0.25rem 0;
    font-weight: 600;
    color: var(--color-900);
  }

  .med-detail,
  .med-duration,
  .med-quantity {
    margin: 0.25rem 0;
    font-size: 0.875rem;
    color: var(--color-700);
  }

  .badge {
    display: inline-block;
    padding: 4px 12px;
    border-radius: 12px;
    font-size: 12px;
    font-weight: 600;
  }

  .badge.activa {
    background: #d1fae5;
    color: #065f46;
  }

  .badge.vencida {
    background: #fee2e2;
    color: #991b1b;
  }

  .badge-readonly {
    display: inline-flex;
    align-items: center;
    gap: 0.25rem;
    padding: 4px 10px;
    border-radius: 12px;
    font-size: 11px;
    font-weight: 600;
    background: #fff3cd;
    color: #856404;
    border: 1px solid #ffeaa7;
  }

  .empty-meds {
    color: var(--color-600);
    font-style: italic;
    margin: 1rem 0;
  }

  .modal-overlay {
    position: fixed;
    inset: 0;
    background: rgba(0, 0, 0, 0.5);
    display: flex;
    align-items: center;
    justify-content: center;
    z-index: 1000;
    backdrop-filter: blur(4px);
  }

  .modal {
    background: white;
    border-radius: 16px;
    width: 90%;
    max-width: 600px;
    max-height: 90vh;
    overflow-y: auto;
    box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
  }

  .modal-header {
    padding: 24px;
    border-bottom: 1px solid var(--color-200);
    display: flex;
    justify-content: space-between;
    align-items: center;
  }

  .modal-header h3 {
    margin: 0;
    font-size: 20px;
    color: var(--color-900);
  }

  .close-btn {
    padding: 0.5rem;
    background: transparent;
    border: none;
    cursor: pointer;
    color: var(--color-600);
    border-radius: 6px;
    transition: all 0.2s;
  }

  .close-btn:hover {
    background: var(--color-100);
  }

  .close-btn svg {
    width: 20px;
    height: 20px;
    display: block;
  }

  .modal-body {
    padding: 24px;
  }

  .modal-footer {
    display: flex;
    justify-content: flex-end;
    gap: 12px;
    padding: 20px 24px;
    border-top: 1px solid var(--color-200);
  }

  .form-group {
    margin-bottom: 1.25rem;
  }

  .form-group label {
    display: block;
    margin-bottom: 6px;
    font-weight: 500;
    color: var(--color-700);
    font-size: 14px;
  }

  .cantidad-sugerida {
    display: inline-block;
    margin-left: 8px;
    padding: 2px 8px;
    background: #dcfce7;
    color: #166534;
    border-radius: 8px;
    font-size: 12px;
    font-weight: 600;
  }

  .form-group input,
  .form-group select,
  .form-group textarea {
    width: 100%;
    padding: 10px 12px;
    border: 2px solid var(--color-200);
    border-radius: 8px;
    font-size: 14px;
    font-family: inherit;
    transition: all 0.2s;
    box-sizing: border-box;
  }

  .form-group input:focus,
  .form-group select:focus,
  .form-group textarea:focus {
    outline: none;
    border-color: var(--color-500);
    box-shadow: 0 0 0 3px var(--color-100);
  }

  .form-group textarea {
    resize: vertical;
  }

  .form-group small {
    display: block;
    margin-top: 0.25rem;
    font-size: 0.8rem;
    color: var(--color-700);
  }

  .tomas-preview {
    margin-top: 1rem;
    padding: 1rem;
    background: #f0f9ff;
    border: 1px solid #bae6fd;
    border-radius: 8px;
  }

  .tomas-preview strong {
    color: #0369a1;
    font-size: 0.9rem;
    display: block;
    margin-bottom: 0.75rem;
  }

  .tomas-calculadas {
    display: flex;
    flex-wrap: wrap;
    gap: 0.5rem;
    margin-bottom: 0.75rem;
  }

  .toma-chip {
    display: inline-flex;
    align-items: center;
    gap: 0.35rem;
    padding: 0.5rem 0.75rem;
    background: white;
    border: 1px solid #0ea5e9;
    border-radius: 20px;
    font-size: 0.9rem;
    color: #0369a1;
    font-weight: 600;
  }

  .toma-chip.toma-semanal {
    background: #fef3c7;
    border-color: #f59e0b;
    color: #92400e;
    padding: 0.6rem 1rem;
    font-size: 0.95rem;
  }

  .tomas-totales {
    margin: 0;
    padding-top: 0.75rem;
    border-top: 1px solid #bae6fd;
    font-size: 0.85rem;
    color: #0c4a6e;
  }

  .tomas-totales strong {
    color: #0369a1;
    font-size: 0.9rem;
    display: inline;
  }
</style>