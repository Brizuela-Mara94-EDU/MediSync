<script>
  import { supabase } from '../../supabase/supabase-client.js';
  
  let pacientes = $state([]);
  let usuarios = $state([]);
  let loading = $state(false);
  let showModal = $state(false);
  let editingPaciente = $state(null);
  let errorMessage = $state('');
  let successMessage = $state('');
  
  // Campos del formulario
  let formData = $state({
    id_usuario: '',
    domicilio: '',
    obra_social: '',
    grupo_sanguineo: ''
  });

  // Cargar datos al montar
  $effect(() => {
    loadPacientes();
    loadUsuariosPacientes();
  });

  async function loadPacientes() {
    loading = true;
    try {
      const { data, error } = await supabase
        .from('pacientes')
        .select(`
          *,
          usuarios:id_usuario (
            id_usuario,
            nombre,
            apellido,
            email,
            dni,
            fecha_nacimiento,
            telefono,
            activo
          )
        `);
      
      if (error) throw error;
      pacientes = data || [];
      console.log('Pacientes cargados:', pacientes);
    } catch (error) {
      console.error('Error cargando pacientes:', error);
      errorMessage = 'Error al cargar pacientes';
    } finally {
      loading = false;
    }
  }

  async function loadUsuariosPacientes() {
    try {
      // Obtener usuarios con rol paciente que aún no tienen registro en pacientes
      const { data: allPacientes } = await supabase
        .from('pacientes')
        .select('id_usuario');
      
      const pacienteIds = allPacientes?.map(p => p.id_usuario) || [];
      
      let query = supabase
        .from('usuarios')
        .select('*')
        .eq('rol', 'paciente')
        .eq('activo', true);
      
      if (pacienteIds.length > 0) {
        query = query.not('id_usuario', 'in', `(${pacienteIds.join(',')})`);
      }
      
      const { data, error } = await query;
      
      if (error) throw error;
      usuarios = data || [];
    } catch (error) {
      console.error('Error cargando usuarios:', error);
    }
  }

  function openCreateModal() {
    editingPaciente = null;
    formData = {
      id_usuario: '',
      domicilio: '',
      obra_social: '',
      grupo_sanguineo: ''
    };
    showModal = true;
    errorMessage = '';
    successMessage = '';
  }

  function openEditModal(paciente) {
    editingPaciente = paciente;
    formData = {
      id_usuario: paciente.id_usuario,
      domicilio: paciente.domicilio || '',
      obra_social: paciente.obra_social || '',
      grupo_sanguineo: paciente.grupo_sanguineo || ''
    };
    showModal = true;
    errorMessage = '';
    successMessage = '';
  }

  function closeModal() {
    showModal = false;
    editingPaciente = null;
    errorMessage = '';
    successMessage = '';
  }

  async function handleSubmit(e) {
    e.preventDefault();
    errorMessage = '';
    successMessage = '';
    loading = true;

    try {
      if (editingPaciente) {
        // Actualizar paciente existente
        const { error } = await supabase
          .from('pacientes')
          .update({
            domicilio: formData.domicilio || null,
            obra_social: formData.obra_social || null,
            grupo_sanguineo: formData.grupo_sanguineo || null
          })
          .eq('id_paciente', editingPaciente.id_paciente);
        
        if (error) throw error;
        successMessage = 'Paciente actualizado correctamente';
      } else {
        // Crear nuevo paciente
        if (!formData.id_usuario) {
          errorMessage = 'Debe seleccionar un usuario';
          loading = false;
          return;
        }

        const { error } = await supabase
          .from('pacientes')
          .insert({
            id_usuario: formData.id_usuario,
            domicilio: formData.domicilio || null,
            obra_social: formData.obra_social || null,
            grupo_sanguineo: formData.grupo_sanguineo || null
          });

        if (error) throw error;
        successMessage = 'Paciente creado correctamente';
        await loadUsuariosPacientes(); // Recargar usuarios disponibles
      }

      await loadPacientes();
      setTimeout(() => {
        closeModal();
      }, 1500);
    } catch (error) {
      console.error('Error:', error);
      errorMessage = error.message || 'Error al guardar el paciente';
    } finally {
      loading = false;
    }
  }

  async function deletePaciente(paciente) {
    const nombreCompleto = `${paciente.usuarios.nombre} ${paciente.usuarios.apellido}`;
    if (!confirm(`¿Está seguro de eliminar al paciente ${nombreCompleto}?`)) {
      return;
    }

    loading = true;
    try {
      const { error } = await supabase
        .from('pacientes')
        .delete()
        .eq('id_paciente', paciente.id_paciente);
      
      if (error) throw error;
      successMessage = 'Paciente eliminado correctamente';
      await loadPacientes();
      await loadUsuariosPacientes(); // Recargar usuarios disponibles
      setTimeout(() => {
        successMessage = '';
      }, 3000);
    } catch (error) {
      console.error('Error:', error);
      errorMessage = 'Error al eliminar el paciente';
    } finally {
      loading = false;
    }
  }

  function formatDate(dateString) {
    if (!dateString) return '-';
    return new Date(dateString).toLocaleDateString('es-AR');
  }
</script>

<div class="crud-container">
  <div class="crud-header">
    <h2>Gestión de Pacientes</h2>
    <button class="btn-primary" onclick={openCreateModal}>
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
        <path d="M12 5v14M5 12h14"/>
      </svg>
      Nuevo Paciente
    </button>
  </div>

  {#if successMessage}
    <div class="alert alert-success">{successMessage}</div>
  {/if}

  {#if errorMessage && !showModal}
    <div class="alert alert-error">{errorMessage}</div>
  {/if}

  {#if loading && !showModal}
    <div class="loading">Cargando pacientes...</div>
  {:else if pacientes.length === 0}
    <div class="empty-state">
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
        <path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/>
        <circle cx="9" cy="7" r="4"/>
      </svg>
      <p>No hay pacientes registrados</p>
    </div>
  {:else}
    <div class="table-container">
      <table>
        <thead>
          <tr>
            <th>Nombre Completo</th>
            <th>DNI</th>
            <th>Email</th>
            <th>Teléfono</th>
            <th>Domicilio</th>
            <th>Obra Social</th>
            <th>Grupo Sang.</th>
            <th>Estado</th>
            <th>Acciones</th>
          </tr>
        </thead>
        <tbody>
          {#each pacientes as paciente}
            <tr>
              <td class="user-name">
                <div class="user-avatar">
                  {paciente.usuarios.nombre.charAt(0)}{paciente.usuarios.apellido.charAt(0)}
                </div>
                {paciente.usuarios.nombre} {paciente.usuarios.apellido}
              </td>
              <td>{paciente.usuarios.dni}</td>
              <td>{paciente.usuarios.email}</td>
              <td>{paciente.usuarios.telefono || '-'}</td>
              <td>{paciente.domicilio || '-'}</td>
              <td>{paciente.obra_social || '-'}</td>
              <td>
                {#if paciente.grupo_sanguineo}
                  <span class="badge-blood">{paciente.grupo_sanguineo}</span>
                {:else}
                  -
                {/if}
              </td>
              <td>
                <span class="badge {paciente.usuarios.activo ? 'badge-active' : 'badge-inactive'}">
                  {paciente.usuarios.activo ? 'Activo' : 'Inactivo'}
                </span>
              </td>
              <td class="actions">
                <button class="btn-icon btn-edit" onclick={() => openEditModal(paciente)} title="Editar">
                  <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/>
                    <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/>
                  </svg>
                </button>
                <button class="btn-icon btn-delete" onclick={() => deletePaciente(paciente)} title="Eliminar">
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
        <h3>{editingPaciente ? 'Editar Paciente' : 'Nuevo Paciente'}</h3>
        <button class="modal-close" onclick={closeModal}>×</button>
      </div>

      {#if errorMessage}
        <div class="alert alert-error">{errorMessage}</div>
      {/if}

      {#if successMessage}
        <div class="alert alert-success">{successMessage}</div>
      {/if}

      <form onsubmit={handleSubmit}>
        {#if !editingPaciente}
          <div class="form-group">
            <label for="id_usuario">Seleccionar Usuario *</label>
            <select 
              id="id_usuario" 
              bind:value={formData.id_usuario}
              required
              disabled={loading}
            >
              <option value="">-- Seleccione un usuario --</option>
              {#each usuarios as usuario}
                <option value={usuario.id_usuario}>
                  {usuario.nombre} {usuario.apellido} - {usuario.dni}
                </option>
              {/each}
            </select>
            <small>Solo se muestran usuarios con rol "paciente" que no tienen registro de paciente</small>
          </div>
        {:else}
          <div class="info-box">
            <strong>Paciente:</strong> 
            {editingPaciente.usuarios.nombre} {editingPaciente.usuarios.apellido}
            <br>
            <strong>DNI:</strong> {editingPaciente.usuarios.dni}
            <br>
            <strong>Email:</strong> {editingPaciente.usuarios.email}
          </div>
        {/if}

        <div class="form-group">
          <label for="domicilio">Domicilio</label>
          <input 
            type="text" 
            id="domicilio" 
            bind:value={formData.domicilio}
            placeholder="Calle 123, Ciudad"
            disabled={loading}
          />
        </div>

        <div class="form-group">
          <label for="obra_social">Obra Social</label>
          <input 
            type="text" 
            id="obra_social" 
            bind:value={formData.obra_social}
            placeholder="OSDE, Swiss Medical, etc."
            disabled={loading}
          />
        </div>

        <div class="form-group">
          <label for="grupo_sanguineo">Grupo Sanguíneo</label>
          <select 
            id="grupo_sanguineo" 
            bind:value={formData.grupo_sanguineo}
            disabled={loading}
          >
            <option value="">Seleccionar</option>
            <option value="A+">A+</option>
            <option value="A-">A-</option>
            <option value="B+">B+</option>
            <option value="B-">B-</option>
            <option value="AB+">AB+</option>
            <option value="AB-">AB-</option>
            <option value="O+">O+</option>
            <option value="O-">O-</option>
          </select>
        </div>

        <div class="modal-actions">
          <button type="button" class="btn-secondary" onclick={closeModal} disabled={loading}>
            Cancelar
          </button>
          <button type="submit" class="btn-primary" disabled={loading}>
            {loading ? 'Guardando...' : editingPaciente ? 'Actualizar' : 'Crear'}
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
    background: var(--color-500);
    color: white;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 13px;
    font-weight: 600;
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

  .badge-blood {
    padding: 4px 10px;
    border-radius: 12px;
    font-size: 12px;
    font-weight: 600;
    background: #fef3c7;
    color: #92400e;
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
    line-height: 1.6;
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

  input, select {
    width: 100%;
    padding: 10px 12px;
    border: 2px solid #e2e8f0;
    border-radius: 8px;
    font-size: 14px;
    transition: all 0.3s;
    box-sizing: border-box;
  }

  input:focus, select:focus {
    outline: none;
    border-color: var(--color-500);
    box-shadow: 0 0 0 3px var(--color-100);
  }

  input:disabled, select:disabled {
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
