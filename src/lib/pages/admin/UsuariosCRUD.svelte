<script>
  import { supabase } from '../../supabase/supabase-client.js';
  
  let usuarios = $state([]);
  let loading = $state(false);
  let showModal = $state(false);
  let editingUser = $state(null);
  let errorMessage = $state('');
  let successMessage = $state('');
  
  // Campos del formulario
  let formData = $state({
    email: '',
    contrasena: '',
    rol: 'paciente',
    nombre: '',
    apellido: '',
    dni: '',
    fecha_nacimiento: '',
    telefono: '',
    activo: true
  });

  // Cargar usuarios al montar
  $effect(() => {
    loadUsuarios();
  });

  async function loadUsuarios() {
    loading = true;
    try {
      const { data, error } = await supabase
        .from('usuarios')
        .select('*')
        .order('creado_en', { ascending: false });
      
      if (error) throw error;
      usuarios = data || [];
    } catch (error) {
      console.error('Error cargando usuarios:', error);
      errorMessage = 'Error al cargar usuarios';
    } finally {
      loading = false;
    }
  }

  function openCreateModal() {
    editingUser = null;
    formData = {
      email: '',
      contrasena: '',
      rol: 'paciente',
      nombre: '',
      apellido: '',
      dni: '',
      fecha_nacimiento: '',
      telefono: '',
      activo: true
    };
    showModal = true;
    errorMessage = '';
    successMessage = '';
  }

  function openEditModal(user) {
    editingUser = user;
    formData = {
      email: user.email,
      contrasena: '', // No mostramos la contraseña
      rol: user.rol,
      nombre: user.nombre,
      apellido: user.apellido,
      dni: user.dni,
      fecha_nacimiento: user.fecha_nacimiento,
      telefono: user.telefono || '',
      activo: user.activo
    };
    showModal = true;
    errorMessage = '';
    successMessage = '';
  }

  function closeModal() {
    showModal = false;
    editingUser = null;
    errorMessage = '';
    successMessage = '';
  }

  async function handleSubmit(e) {
    e.preventDefault();
    errorMessage = '';
    successMessage = '';
    loading = true;

    try {
      if (editingUser) {
        // Actualizar usuario existente
        const updateData = {
          email: formData.email,
          rol: formData.rol,
          nombre: formData.nombre,
          apellido: formData.apellido,
          dni: formData.dni,
          fecha_nacimiento: formData.fecha_nacimiento,
          telefono: formData.telefono || null,
          activo: formData.activo
        };

        // Si hay nueva contraseña, actualizarla
        if (formData.contrasena) {
          const { error: passError } = await supabase.rpc('actualizar_contrasena', {
            p_usuario_id: editingUser.id_usuario,
            p_nueva_contrasena: formData.contrasena
          });
          if (passError) throw passError;
        }

        const { error } = await supabase
          .from('usuarios')
          .update(updateData)
          .eq('id_usuario', editingUser.id_usuario);
        
        if (error) throw error;
        successMessage = 'Usuario actualizado correctamente';
      } else {
        // Crear nuevo usuario
        if (!formData.contrasena) {
          errorMessage = 'La contraseña es obligatoria para nuevos usuarios';
          loading = false;
          return;
        }

        const { data, error } = await supabase.rpc('registrar_usuario', {
          p_email: formData.email,
          p_contrasena: formData.contrasena,
          p_nombre: formData.nombre,
          p_apellido: formData.apellido,
          p_dni: formData.dni,
          p_fecha_nacimiento: formData.fecha_nacimiento,
          p_telefono: formData.telefono || null,
          p_rol: formData.rol
        });

        if (error) throw error;
        successMessage = 'Usuario creado correctamente';
      }

      await loadUsuarios();
      setTimeout(() => {
        closeModal();
      }, 1500);
    } catch (error) {
      console.error('Error:', error);
      errorMessage = error.message || 'Error al guardar el usuario';
    } finally {
      loading = false;
    }
  }

  async function deleteUsuario(usuario) {
    if (!confirm(`¿Está seguro de eliminar al usuario ${usuario.nombre} ${usuario.apellido}?`)) {
      return;
    }

    loading = true;
    try {
      const { error } = await supabase
        .from('usuarios')
        .delete()
        .eq('id_usuario', usuario.id_usuario);
      
      if (error) throw error;
      successMessage = 'Usuario eliminado correctamente';
      await loadUsuarios();
      setTimeout(() => {
        successMessage = '';
      }, 3000);
    } catch (error) {
      console.error('Error:', error);
      errorMessage = 'Error al eliminar el usuario';
    } finally {
      loading = false;
    }
  }

  function getRoleBadgeClass(rol) {
    switch(rol) {
      case 'admin': return 'badge-admin';
      case 'medico': return 'badge-medico';
      case 'paciente': return 'badge-paciente';
      default: return 'badge-default';
    }
  }

  function formatDate(dateString) {
    if (!dateString) return '-';
    return new Date(dateString).toLocaleDateString('es-AR');
  }
</script>

<div class="crud-container">
  <div class="crud-header">
    <h2>Gestión de Usuarios</h2>
    <button class="btn-primary" onclick={openCreateModal}>
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
        <path d="M12 5v14M5 12h14"/>
      </svg>
      Nuevo Usuario
    </button>
  </div>

  {#if successMessage}
    <div class="alert alert-success">{successMessage}</div>
  {/if}

  {#if errorMessage && !showModal}
    <div class="alert alert-error">{errorMessage}</div>
  {/if}

  {#if loading && !showModal}
    <div class="loading">Cargando usuarios...</div>
  {:else if usuarios.length === 0}
    <div class="empty-state">
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
        <path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/>
        <circle cx="9" cy="7" r="4"/>
        <path d="M22 21v-2a4 4 0 0 0-3-3.87M16 3.13a4 4 0 0 1 0 7.75"/>
      </svg>
      <p>No hay usuarios registrados</p>
    </div>
  {:else}
    <div class="table-container">
      <table>
        <thead>
          <tr>
            <th>Nombre Completo</th>
            <th>Email</th>
            <th>DNI</th>
            <th>Rol</th>
            <th>Fecha Nac.</th>
            <th>Teléfono</th>
            <th>Estado</th>
            <th>Acciones</th>
          </tr>
        </thead>
        <tbody>
          {#each usuarios as usuario}
            <tr>
              <td class="user-name">
                <div class="user-avatar">
                  {usuario.nombre.charAt(0)}{usuario.apellido.charAt(0)}
                </div>
                {usuario.nombre} {usuario.apellido}
              </td>
              <td>{usuario.email}</td>
              <td>{usuario.dni}</td>
              <td>
                <span class="badge {getRoleBadgeClass(usuario.rol)}">
                  {usuario.rol}
                </span>
              </td>
              <td>{formatDate(usuario.fecha_nacimiento)}</td>
              <td>{usuario.telefono || '-'}</td>
              <td>
                <span class="badge {usuario.activo ? 'badge-active' : 'badge-inactive'}">
                  {usuario.activo ? 'Activo' : 'Inactivo'}
                </span>
              </td>
              <td class="actions">
                <button class="btn-icon btn-edit" onclick={() => openEditModal(usuario)} title="Editar">
                  <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/>
                    <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/>
                  </svg>
                </button>
                <button class="btn-icon btn-delete" onclick={() => deleteUsuario(usuario)} title="Eliminar">
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
        <h3>{editingUser ? 'Editar Usuario' : 'Nuevo Usuario'}</h3>
        <button class="modal-close" onclick={closeModal}>×</button>
      </div>

      {#if errorMessage}
        <div class="alert alert-error">{errorMessage}</div>
      {/if}

      {#if successMessage}
        <div class="alert alert-success">{successMessage}</div>
      {/if}

      <form onsubmit={handleSubmit}>
        <div class="form-row">
          <div class="form-group">
            <label for="nombre">Nombre *</label>
            <input 
              type="text" 
              id="nombre" 
              bind:value={formData.nombre}
              required
              disabled={loading}
            />
          </div>

          <div class="form-group">
            <label for="apellido">Apellido *</label>
            <input 
              type="text" 
              id="apellido" 
              bind:value={formData.apellido}
              required
              disabled={loading}
            />
          </div>
        </div>

        <div class="form-row">
          <div class="form-group">
            <label for="dni">DNI *</label>
            <input 
              type="text" 
              id="dni" 
              bind:value={formData.dni}
              required
              disabled={loading}
            />
          </div>

          <div class="form-group">
            <label for="fecha_nacimiento">Fecha de Nacimiento *</label>
            <input 
              type="date" 
              id="fecha_nacimiento" 
              bind:value={formData.fecha_nacimiento}
              required
              disabled={loading}
            />
          </div>
        </div>

        <div class="form-group">
          <label for="email">Email *</label>
          <input 
            type="email" 
            id="email" 
            bind:value={formData.email}
            required
            disabled={loading}
          />
        </div>

        <div class="form-group">
          <label for="telefono">Teléfono</label>
          <input 
            type="tel" 
            id="telefono" 
            bind:value={formData.telefono}
            disabled={loading}
          />
        </div>

        <div class="form-row">
          <div class="form-group">
            <label for="rol">Rol *</label>
            <select 
              id="rol" 
              bind:value={formData.rol}
              required
              disabled={loading}
            >
              <option value="paciente">Paciente</option>
              <option value="medico">Médico</option>
              <option value="admin">Administrador</option>
            </select>
          </div>

          <div class="form-group">
            <label for="activo">Estado</label>
            <select 
              id="activo" 
              bind:value={formData.activo}
              disabled={loading}
            >
              <option value={true}>Activo</option>
              <option value={false}>Inactivo</option>
            </select>
          </div>
        </div>

        <div class="form-group">
          <label for="contrasena">
            Contraseña {editingUser ? '(dejar en blanco para no cambiar)' : '*'}
          </label>
          <input 
            type="password" 
            id="contrasena" 
            bind:value={formData.contrasena}
            required={!editingUser}
            disabled={loading}
            minlength="6"
          />
          <small>Mínimo 6 caracteres</small>
        </div>

        <div class="modal-actions">
          <button type="button" class="btn-secondary" onclick={closeModal} disabled={loading}>
            Cancelar
          </button>
          <button type="submit" class="btn-primary" disabled={loading}>
            {loading ? 'Guardando...' : editingUser ? 'Actualizar' : 'Crear'}
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
    text-transform: capitalize;
  }

  .badge-admin {
    background: #fef3c7;
    color: #92400e;
  }

  .badge-medico {
    background: #dbeafe;
    color: #1e40af;
  }

  .badge-paciente {
    background: #d1fae5;
    color: #065f46;
  }

  .badge-active {
    background: #d1fae5;
    color: #065f46;
  }

  .badge-inactive {
    background: #fee2e2;
    color: #991b1b;
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

  .form-row {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 16px;
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
    .form-row {
      grid-template-columns: 1fr;
    }

    .table-container {
      font-size: 12px;
    }

    th, td {
      padding: 8px;
    }
  }
</style>
