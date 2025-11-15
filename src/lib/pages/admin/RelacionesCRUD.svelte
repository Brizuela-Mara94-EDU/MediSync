<script>
  import { supabase } from '../../supabase/supabase-client.js';
  
  let relaciones = $state([]);
  let pacientes = $state([]);
  let medicos = $state([]);
  let loading = $state(false);
  let showModal = $state(false);
  let editingRelacion = $state(null);
  let errorMessage = $state('');
  let successMessage = $state('');
  
  // Campos del formulario
  let formData = $state({
    id_paciente: '',
    id_medico: '',
    activo: true
  });

  // Cargar datos al montar
  $effect(() => {
    loadRelaciones();
    loadPacientes();
    loadMedicos();
  });

  async function loadRelaciones() {
    loading = true;
    try {
      const { data, error } = await supabase
        .from('paciente_medico')
        .select(`
          *,
          pacientes:id_paciente (
            id_paciente,
            usuarios:id_usuario (
              nombre,
              apellido,
              dni,
              email
            )
          ),
          medicos:id_medico (
            id_medico,
            matricula,
            especialidad,
            usuarios:id_usuario (
              nombre,
              apellido,
              dni,
              email
            )
          )
        `);
      
      if (error) throw error;
      relaciones = data || [];
      console.log('Relaciones cargadas:', relaciones);
    } catch (error) {
      console.error('Error cargando relaciones:', error);
      errorMessage = 'Error al cargar relaciones';
    } finally {
      loading = false;
    }
  }

  async function loadPacientes() {
    try {
      const { data, error } = await supabase
        .from('pacientes')
        .select(`
          *,
          usuarios:id_usuario (
            nombre,
            apellido,
            dni
          )
        `);
      
      if (error) throw error;
      pacientes = data || [];
    } catch (error) {
      console.error('Error cargando pacientes:', error);
    }
  }

  async function loadMedicos() {
    try {
      const { data, error } = await supabase
        .from('medicos')
        .select(`
          *,
          matricula,
          especialidad,
          usuarios:id_usuario (
            nombre,
            apellido,
            dni
          )
        `);
      
      if (error) throw error;
      medicos = data || [];
    } catch (error) {
      console.error('Error cargando médicos:', error);
    }
  }

  function openCreateModal() {
    editingRelacion = null;
    formData = {
      id_paciente: '',
      id_medico: '',
      activo: true
    };
    showModal = true;
    errorMessage = '';
    successMessage = '';
  }

  function openEditModal(relacion) {
    editingRelacion = relacion;
    formData = {
      id_paciente: relacion.id_paciente,
      id_medico: relacion.id_medico,
      activo: relacion.activo
    };
    showModal = true;
    errorMessage = '';
    successMessage = '';
  }

  function closeModal() {
    showModal = false;
    editingRelacion = null;
    errorMessage = '';
    successMessage = '';
  }

  async function handleSubmit(e) {
    e.preventDefault();
    errorMessage = '';
    successMessage = '';
    loading = true;

    try {
      if (editingRelacion) {
        // Actualizar relación existente
        const { error } = await supabase
          .from('paciente_medico')
          .update({
            activo: formData.activo
          })
          .eq('id_relacion', editingRelacion.id_relacion);
        
        if (error) throw error;
        successMessage = 'Relación actualizada correctamente';
      } else {
        // Crear nueva relación
        if (!formData.id_paciente || !formData.id_medico) {
          errorMessage = 'Debe seleccionar un paciente y un médico';
          loading = false;
          return;
        }

        const { error } = await supabase
          .from('paciente_medico')
          .insert({
            id_paciente: formData.id_paciente,
            id_medico: formData.id_medico,
            activo: formData.activo
          });

        if (error) {
          if (error.message.includes('duplicate') || error.message.includes('unique')) {
            throw new Error('Esta relación ya existe');
          }
          throw error;
        }
        successMessage = 'Relación creada correctamente';
      }

      await loadRelaciones();
      setTimeout(() => {
        closeModal();
      }, 1500);
    } catch (error) {
      console.error('Error:', error);
      errorMessage = error.message || 'Error al guardar la relación';
    } finally {
      loading = false;
    }
  }

  async function deleteRelacion(relacion) {
    const pacienteNombre = `${relacion.pacientes.usuarios.nombre} ${relacion.pacientes.usuarios.apellido}`;
    const medicoNombre = `${relacion.medicos.usuarios.nombre} ${relacion.medicos.usuarios.apellido}`;
    
    if (!confirm(`¿Está seguro de eliminar la relación entre ${pacienteNombre} y Dr. ${medicoNombre}?`)) {
      return;
    }

    loading = true;
    try {
      const { error } = await supabase
        .from('paciente_medico')
        .delete()
        .eq('id_relacion', relacion.id_relacion);
      
      if (error) throw error;
      successMessage = 'Relación eliminada correctamente';
      await loadRelaciones();
      setTimeout(() => {
        successMessage = '';
      }, 3000);
    } catch (error) {
      console.error('Error:', error);
      errorMessage = 'Error al eliminar la relación';
    } finally {
      loading = false;
    }
  }

  function formatDate(dateString) {
    if (!dateString) return '-';
    return new Date(dateString).toLocaleDateString('es-AR', {
      year: 'numeric',
      month: 'long',
      day: 'numeric'
    });
  }
</script>

<div class="crud-container">
  <div class="crud-header">
    <h2>Relaciones Paciente-Médico</h2>
    <button class="btn-primary" onclick={openCreateModal}>
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
        <path d="M12 5v14M5 12h14"/>
      </svg>
      Nueva Relación
    </button>
  </div>

  {#if successMessage}
    <div class="alert alert-success">{successMessage}</div>
  {/if}

  {#if errorMessage && !showModal}
    <div class="alert alert-error">{errorMessage}</div>
  {/if}

  {#if loading && !showModal}
    <div class="loading">Cargando relaciones...</div>
  {:else if relaciones.length === 0}
    <div class="empty-state">
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
        <path d="M17 18a2 2 0 0 0-2-2H9a2 2 0 0 0-2 2"/>
        <rect width="18" height="18" x="3" y="4" rx="2"/>
        <circle cx="12" cy="10" r="2"/>
        <line x1="8" x2="8" y1="2" y2="4"/>
        <line x1="16" x2="16" y1="2" y2="4"/>
      </svg>
      <p>No hay relaciones paciente-médico registradas</p>
    </div>
  {:else}
    <div class="table-container">
      <table>
        <thead>
          <tr>
            <th>Paciente</th>
            <th>DNI Paciente</th>
            <th>Médico</th>
            <th>Matrícula</th>
            <th>Especialidad</th>
            <th>Fecha Asignación</th>
            <th>Estado</th>
            <th>Acciones</th>
          </tr>
        </thead>
        <tbody>
          {#each relaciones as relacion}
            <tr>
              <td class="user-name">
                <div class="user-avatar patient">
                  {relacion.pacientes.usuarios.nombre.charAt(0)}{relacion.pacientes.usuarios.apellido.charAt(0)}
                </div>
                {relacion.pacientes.usuarios.nombre} {relacion.pacientes.usuarios.apellido}
              </td>
              <td>{relacion.pacientes.usuarios.dni}</td>
              <td class="user-name">
                <div class="user-avatar doctor">
                  {relacion.medicos.usuarios.nombre.charAt(0)}{relacion.medicos.usuarios.apellido.charAt(0)}
                </div>
                Dr. {relacion.medicos.usuarios.nombre} {relacion.medicos.usuarios.apellido}
              </td>
              <td>
                <span class="badge-matricula">{relacion.medicos.matricula}</span>
              </td>
              <td>{relacion.medicos.especialidad || '-'}</td>
              <td>{formatDate(relacion.fecha_asignacion)}</td>
              <td>
                <span class="badge {relacion.activo ? 'badge-active' : 'badge-inactive'}">
                  {relacion.activo ? 'Activa' : 'Inactiva'}
                </span>
              </td>
              <td class="actions">
                <button class="btn-icon btn-edit" onclick={() => openEditModal(relacion)} title="Editar">
                  <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/>
                    <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/>
                  </svg>
                </button>
                <button class="btn-icon btn-delete" onclick={() => deleteRelacion(relacion)} title="Eliminar">
                  <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M3 6h18M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/>
                  </svg>
                </button>
              </td>
            </tr>
          {/each}
        </tbody>
      </table>
    </div>
  {/if}
</div>

{#if showModal}
  <div 
    class="modal-overlay" 
    role="button" 
    tabindex="0"
    onclick={closeModal}
    onkeydown={(e) => e.key === 'Escape' && closeModal()}
  >
    <div 
      class="modal" 
      role="dialog"
      tabindex="-1"
      onclick={(e) => e.stopPropagation()}
      onkeydown={(e) => e.stopPropagation()}
    >
      <div class="modal-header">
        <h3>{editingRelacion ? 'Editar Relación' : 'Nueva Relación Paciente-Médico'}</h3>
        <button class="modal-close" onclick={closeModal}>×</button>
      </div>

      {#if errorMessage}
        <div class="alert alert-error">{errorMessage}</div>
      {/if}

      {#if successMessage}
        <div class="alert alert-success">{successMessage}</div>
      {/if}

      <form onsubmit={handleSubmit}>
        {#if !editingRelacion}
          <div class="form-group">
            <label for="id_paciente">Seleccionar Paciente *</label>
            <select 
              id="id_paciente" 
              bind:value={formData.id_paciente}
              required
              disabled={loading}
            >
              <option value="">-- Seleccione un paciente --</option>
              {#each pacientes as paciente}
                <option value={paciente.id_paciente}>
                  {paciente.usuarios.nombre} {paciente.usuarios.apellido} - DNI: {paciente.usuarios.dni}
                </option>
              {/each}
            </select>
          </div>

          <div class="form-group">
            <label for="id_medico">Seleccionar Médico *</label>
            <select 
              id="id_medico" 
              bind:value={formData.id_medico}
              required
              disabled={loading}
            >
              <option value="">-- Seleccione un médico --</option>
              {#each medicos as medico}
                <option value={medico.id_medico}>
                  Dr. {medico.usuarios.nombre} {medico.usuarios.apellido} - {medico.especialidad || 'Sin especialidad'}
                </option>
              {/each}
            </select>
          </div>
        {:else}
          <div class="info-box">
            <div class="info-row">
              <strong>Paciente:</strong> 
              {editingRelacion.pacientes.usuarios.nombre} {editingRelacion.pacientes.usuarios.apellido}
            </div>
            <div class="info-row">
              <strong>Médico:</strong> 
              Dr. {editingRelacion.medicos.usuarios.nombre} {editingRelacion.medicos.usuarios.apellido}
            </div>
            <div class="info-row">
              <strong>Asignado:</strong> 
              {formatDate(editingRelacion.fecha_asignacion)}
            </div>
          </div>
        {/if}

        <div class="form-group">
          <label for="activo">Estado de la Relación</label>
          <select 
            id="activo" 
            bind:value={formData.activo}
            disabled={loading}
          >
            <option value={true}>Activa</option>
            <option value={false}>Inactiva</option>
          </select>
          <small>Las relaciones inactivas se mantienen en el historial pero no son consideradas activas</small>
        </div>

        <div class="modal-actions">
          <button type="button" class="btn-secondary" onclick={closeModal} disabled={loading}>
            Cancelar
          </button>
          <button type="submit" class="btn-primary" disabled={loading}>
            {loading ? 'Guardando...' : editingRelacion ? 'Actualizar' : 'Crear Relación'}
          </button>
        </div>
      </form>
    </div>
  </div>
{/if}

<style>
  .crud-container {
    background: white;
    border-radius: 12px;
    box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
    padding: 24px;
  }

  .crud-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 24px;
  }

  h2 {
    margin: 0;
    font-size: 22px;
    color: #1e293b;
    font-weight: 700;
  }

  .btn-primary {
    display: flex;
    align-items: center;
    gap: 8px;
    padding: 10px 20px;
    background: var(--color-500);
    color: white;
    border: none;
    border-radius: 8px;
    font-size: 14px;
    font-weight: 600;
    cursor: pointer;
    transition: all 0.3s;
  }

  .btn-primary svg {
    width: 18px;
    height: 18px;
  }

  .btn-primary:hover:not(:disabled) {
    background: var(--color-600);
    transform: translateY(-2px);
  }

  .btn-primary:disabled {
    opacity: 0.5;
    cursor: not-allowed;
  }

  .alert {
    padding: 12px 16px;
    border-radius: 8px;
    margin-bottom: 16px;
    font-size: 14px;
  }

  .alert-success {
    background: #d1fae5;
    color: #065f46;
    border: 1px solid #6ee7b7;
  }

  .alert-error {
    background: #fee2e2;
    color: #991b1b;
    border: 1px solid #fca5a5;
  }

  .loading {
    text-align: center;
    padding: 40px;
    color: #64748b;
  }

  .empty-state {
    text-align: center;
    padding: 60px 20px;
    color: #94a3b8;
  }

  .empty-state svg {
    width: 64px;
    height: 64px;
    margin-bottom: 16px;
    opacity: 0.5;
  }

  .table-container {
    overflow-x: auto;
  }

  table {
    width: 100%;
    border-collapse: collapse;
  }

  thead {
    background: #f8fafc;
    border-bottom: 2px solid #e2e8f0;
  }

  th {
    padding: 12px 16px;
    text-align: left;
    font-size: 13px;
    font-weight: 600;
    color: #475569;
    text-transform: uppercase;
    letter-spacing: 0.5px;
  }

  td {
    padding: 16px;
    border-bottom: 1px solid #e2e8f0;
    font-size: 14px;
    color: #334155;
  }

  .user-name {
    display: flex;
    align-items: center;
    gap: 12px;
    font-weight: 500;
  }

  .user-avatar {
    width: 36px;
    height: 36px;
    border-radius: 50%;
    color: white;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 13px;
    font-weight: 600;
  }

  .user-avatar.patient {
    background: #10b981;
  }

  .user-avatar.doctor {
    background: #3b82f6;
  }

  .badge {
    padding: 4px 10px;
    border-radius: 12px;
    font-size: 12px;
    font-weight: 600;
  }

  .badge-active {
    background: #d1fae5;
    color: #065f46;
  }

  .badge-inactive {
    background: #fee2e2;
    color: #991b1b;
  }

  .badge-matricula {
    padding: 4px 10px;
    border-radius: 12px;
    font-size: 12px;
    font-weight: 600;
    background: #dbeafe;
    color: #1e40af;
  }

  .actions {
    display: flex;
    gap: 8px;
  }

  .btn-icon {
    width: 32px;
    height: 32px;
    padding: 6px;
    border: none;
    border-radius: 6px;
    cursor: pointer;
    transition: all 0.2s;
    display: flex;
    align-items: center;
    justify-content: center;
  }

  .btn-icon svg {
    width: 16px;
    height: 16px;
  }

  .btn-edit {
    background: #dbeafe;
    color: #1e40af;
  }

  .btn-edit:hover {
    background: #3b82f6;
    color: white;
  }

  .btn-delete {
    background: #fee2e2;
    color: #991b1b;
  }

  .btn-delete:hover {
    background: #ef4444;
    color: white;
  }

  /* Modal */
  .modal-overlay {
    position: fixed;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    background: rgba(0, 0, 0, 0.5);
    display: flex;
    align-items: center;
    justify-content: center;
    z-index: 1000;
    padding: 20px;
  }

  .modal {
    background: white;
    border-radius: 12px;
    width: 100%;
    max-width: 600px;
    max-height: 90vh;
    overflow-y: auto;
  }

  .modal-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 20px 24px;
    border-bottom: 1px solid #e2e8f0;
  }

  .modal-header h3 {
    margin: 0;
    font-size: 20px;
    color: #1e293b;
  }

  .modal-close {
    width: 32px;
    height: 32px;
    border: none;
    background: #f1f5f9;
    border-radius: 6px;
    font-size: 24px;
    cursor: pointer;
    color: #64748b;
    transition: all 0.2s;
  }

  .modal-close:hover {
    background: #e2e8f0;
    color: #1e293b;
  }

  form {
    padding: 24px;
  }

  .info-box {
    background: #f0f9ff;
    border: 1px solid #bae6fd;
    border-radius: 8px;
    padding: 16px;
    margin-bottom: 20px;
    font-size: 14px;
    color: #0c4a6e;
  }

  .info-row {
    margin-bottom: 8px;
    line-height: 1.6;
  }

  .info-row:last-child {
    margin-bottom: 0;
  }

  .form-group {
    margin-bottom: 16px;
  }

  label {
    display: block;
    margin-bottom: 6px;
    color: #475569;
    font-weight: 500;
    font-size: 14px;
  }

  select {
    width: 100%;
    padding: 10px 12px;
    border: 2px solid #e2e8f0;
    border-radius: 8px;
    font-size: 14px;
    transition: all 0.3s;
    box-sizing: border-box;
  }

  select:focus {
    outline: none;
    border-color: var(--color-500);
    box-shadow: 0 0 0 3px var(--color-100);
  }

  select:disabled {
    background: #f8fafc;
    cursor: not-allowed;
  }

  small {
    display: block;
    color: #64748b;
    font-size: 12px;
    margin-top: 4px;
  }

  .modal-actions {
    display: flex;
    gap: 12px;
    justify-content: flex-end;
    margin-top: 24px;
    padding-top: 20px;
    border-top: 1px solid #e2e8f0;
  }

  .btn-secondary {
    padding: 10px 20px;
    background: white;
    border: 2px solid #e2e8f0;
    color: #64748b;
    border-radius: 8px;
    font-size: 14px;
    font-weight: 600;
    cursor: pointer;
    transition: all 0.3s;
  }

  .btn-secondary:hover:not(:disabled) {
    border-color: #cbd5e1;
    background: #f8fafc;
  }

  @media (max-width: 768px) {
    .table-container {
      font-size: 12px;
    }

    th, td {
      padding: 8px;
    }
  }
</style>
