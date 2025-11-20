<script lang="ts">
  import { supabase } from '../../supabase/supabase-client.js';
  import { obtenerSesion } from '../../utils/SessionManager.js';
  
  let pacientes = $state([]);
  let pacientesFiltrados = $state([]);
  let loading = $state(true);
  let showModal = $state(false);
  let errorMessage = $state('');
  let successMessage = $state('');
  let busqueda = $state('');
  
  // Props para navegación
  let { onVerPaciente } = $props();
  
  // Datos del nuevo paciente
  let nuevoUsuario = $state({
    nombre: '',
    apellido: '',
    dni: '',
    email: '',
    telefono: '',
    fecha_nacimiento: ''
  });
  
  let nuevoPaciente = $state({
    domicilio: '',
    obra_social: '',
    grupo_sanguineo: ''
  });
  
  const sesion = obtenerSesion();
  const medicoUsuarioId = sesion?.id_usuario;

  $effect(() => {
    if (medicoUsuarioId) {
      cargarPacientes();
    }
  });

  // Filtrar pacientes por apellido
  $effect(() => {
    if (busqueda.trim() === '') {
      pacientesFiltrados = pacientes;
    } else {
      const termino = busqueda.toLowerCase();
      pacientesFiltrados = pacientes.filter(p => 
        p.apellido.toLowerCase().includes(termino)
      );
    }
  });

  async function cargarPacientes() {
    loading = true;
    try {
      const { data: medicoData, error: medicoError } = await supabase
        .from('medicos')
        .select('id_medico')
        .eq('id_usuario', medicoUsuarioId)
        .single();

      if (medicoError) throw medicoError;

      if (!medicoData) {
        console.log('No se encontró el médico');
        loading = false;
        return;
      }

      const { data, error } = await supabase
        .from('paciente_medico')
        .select(`
          id_paciente,
          activo,
          fecha_asignacion,
          pacientes:id_paciente (
            id_paciente,
            obra_social,
            grupo_sanguineo,
            domicilio,
            usuarios:id_usuario (
              nombre,
              apellido,
              dni,
              fecha_nacimiento,
              telefono,
              email
            )
          )
        `)
        .eq('id_medico', medicoData.id_medico)
        .eq('activo', true);

      if (error) throw error;

      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      pacientes = data?.map((rel: any) => {
        const pacienteData = rel.pacientes;
        const usuario = Array.isArray(pacienteData?.usuarios) 
          ? pacienteData.usuarios[0] 
          : pacienteData?.usuarios;
        
        const nacimiento = new Date(usuario?.fecha_nacimiento);
        const hoy = new Date();
        const edad = hoy.getFullYear() - nacimiento.getFullYear();

        return {
          id_paciente: pacienteData?.id_paciente,
          nombre: usuario?.nombre,
          apellido: usuario?.apellido,
          edad: edad,
          dni: usuario?.dni,
          telefono: usuario?.telefono,
          email: usuario?.email,
          obra_social: pacienteData?.obra_social,
          grupo_sanguineo: pacienteData?.grupo_sanguineo,
          domicilio: pacienteData?.domicilio,
          fecha_asignacion: rel.fecha_asignacion
        };
      }) || [];

      console.log('Pacientes cargados:', pacientes);

    } catch (error) {
      console.error('Error cargando pacientes:', error);
      errorMessage = 'Error al cargar pacientes';
    } finally {
      loading = false;
    }
  }

  function abrirModal() {
    showModal = true;
    errorMessage = '';
    successMessage = '';
    nuevoUsuario = {
      nombre: '',
      apellido: '',
      dni: '',
      email: '',
      telefono: '',
      fecha_nacimiento: ''
    };
    nuevoPaciente = {
      domicilio: '',
      obra_social: '',
      grupo_sanguineo: ''
    };
  }

  function cerrarModal() {
    showModal = false;
    errorMessage = '';
    successMessage = '';
  }

  async function agregarPaciente(e) {
    e.preventDefault();
    errorMessage = '';
    successMessage = '';
    loading = true;

    try {
      // Obtener el id_medico
      const { data: medicoData, error: medicoError } = await supabase
        .from('medicos')
        .select('id_medico')
        .eq('id_usuario', medicoUsuarioId)
        .single();

      if (medicoError) throw medicoError;

      // 1. Crear usuario usando la función RPC (que maneja el hash automáticamente)
      const contrasenaPorDefecto = nuevoUsuario.dni; // Usar DNI como contraseña inicial
      
      const { data: usuarioId, error: errorUsuario } = await supabase
        .rpc('registrar_usuario', {
          p_email: nuevoUsuario.email,
          p_contrasena: contrasenaPorDefecto,
          p_nombre: nuevoUsuario.nombre,
          p_apellido: nuevoUsuario.apellido,
          p_dni: nuevoUsuario.dni,
          p_fecha_nacimiento: nuevoUsuario.fecha_nacimiento,
          p_telefono: nuevoUsuario.telefono || null,
          p_rol: 'paciente'
        });

      if (errorUsuario) throw errorUsuario;

      // 2. Crear paciente
      const { data: pacienteCreado, error: errorPaciente } = await supabase
        .from('pacientes')
        .insert({
          id_usuario: usuarioId,
          domicilio: nuevoPaciente.domicilio,
          obra_social: nuevoPaciente.obra_social,
          grupo_sanguineo: nuevoPaciente.grupo_sanguineo
        })
        .select()
        .single();

      if (errorPaciente) throw errorPaciente;

      // 3. Crear relación paciente-médico
      const { error: errorRelacion } = await supabase
        .from('paciente_medico')
        .insert({
          id_paciente: pacienteCreado.id_paciente,
          id_medico: medicoData.id_medico,
          activo: true
        });

      if (errorRelacion) throw errorRelacion;

      successMessage = 'Paciente agregado correctamente';
      await cargarPacientes();
      
      setTimeout(() => {
        cerrarModal();
      }, 1500);

    } catch (error) {
      console.error('Error agregando paciente:', error);
      errorMessage = error.message || 'Error al agregar el paciente';
    } finally {
      loading = false;
    }
  }

  function formatDate(dateString) {
    if (!dateString) return '-';
    return new Date(dateString).toLocaleDateString('es-AR');
  }

  function getInitials(nombre, apellido) {
    return `${nombre?.charAt(0) || ''}${apellido?.charAt(0) || ''}`.toUpperCase();
  }

  function verDetallesPaciente(paciente) {
    if (onVerPaciente) {
      onVerPaciente(paciente.id_paciente);
    }
  }
</script>

<header class="header">
  <div>
    <h2>Mis Pacientes</h2>
    <p>Gestiona todos tus pacientes registrados</p>
  </div>
  <div class="header-actions">
    <button class="btn-primary" onclick={abrirModal}>
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
        <path d="M12 5v14M5 12h14"/>
      </svg>
      Agregar Paciente
    </button>
  </div>
</header>

{#if successMessage}
  <div class="alert alert-success">{successMessage}</div>
{/if}

{#if errorMessage && !showModal}
  <div class="alert alert-error">{errorMessage}</div>
{/if}

<div class="search-section">
  <div class="search-box">
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
      <circle cx="11" cy="11" r="8"/>
      <path d="m21 21-4.35-4.35"/>
    </svg>
    <input 
      type="text" 
      placeholder="Buscar por apellido..." 
      bind:value={busqueda}
    />
  </div>
  {#if busqueda.trim() !== ''}
    <div class="results-count">
      {pacientesFiltrados.length} paciente{pacientesFiltrados.length !== 1 ? 's' : ''} encontrado{pacientesFiltrados.length !== 1 ? 's' : ''}
    </div>
  {:else}
    <div class="results-count">
      {pacientes.length} paciente{pacientes.length !== 1 ? 's' : ''} total{pacientes.length !== 1 ? 'es' : ''}
    </div>
  {/if}
</div>

<div class="content-card">
  {#if loading}
    <div class="loading-state">
      <p>Cargando pacientes...</p>
    </div>
  {:else if pacientesFiltrados.length === 0}
    <div class="empty-state">
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
        <path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/>
        <circle cx="9" cy="7" r="4"/>
        <path d="M22 21v-2a4 4 0 0 0-3-3.87M16 3.13a4 4 0 0 1 0 7.75"/>
      </svg>
      <p>{busqueda ? 'No se encontraron pacientes con ese apellido' : 'No hay pacientes registrados'}</p>
    </div>
  {:else}
    <div class="table-container">
      <table class="patients-table">
        <thead>
          <tr>
            <th>Paciente</th>
            <th>DNI</th>
            <th>Edad</th>
            <th>Teléfono</th>
            <th>Email</th>
            <th>Obra Social</th>
            <th>Grupo Sang.</th>
            <th>Fecha Asignación</th>
            <th>Acciones</th>
          </tr>
        </thead>
        <tbody>
          {#each pacientesFiltrados as paciente}
            <tr>
              <td>
                <div class="patient-cell">
                  <div class="patient-avatar">
                    {getInitials(paciente.nombre, paciente.apellido)}
                  </div>
                  <div>
                    <div class="patient-name">{paciente.nombre} {paciente.apellido}</div>
                  </div>
                </div>
              </td>
              <td>{paciente.dni}</td>
              <td>{paciente.edad} años</td>
              <td>{paciente.telefono || '-'}</td>
              <td>{paciente.email || '-'}</td>
              <td>{paciente.obra_social || '-'}</td>
              <td>
                {#if paciente.grupo_sanguineo}
                  <span class="badge-blood">{paciente.grupo_sanguineo}</span>
                {:else}
                  -
                {/if}
              </td>
              <td>{formatDate(paciente.fecha_asignacion)}</td>
              <td>
                <button 
                  class="action-btn" 
                  onclick={() => verDetallesPaciente(paciente)}
                  title="Ver detalles del paciente"
                  aria-label="Ver detalles de {paciente.nombre} {paciente.apellido}"
                >
                  <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M2 12s3-7 10-7 10 7 10 7-3 7-10 7-10-7-10-7Z"/>
                    <circle cx="12" cy="12" r="3"/>
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
    onclick={cerrarModal}
    onkeydown={(e) => e.key === 'Escape' && cerrarModal()}
  >
    <div 
      class="modal" 
      role="dialog"
      tabindex="-1"
      onclick={(e) => e.stopPropagation()}
      onkeydown={(e) => e.stopPropagation()}
    >
      <div class="modal-header">
        <h3>Agregar Nuevo Paciente</h3>
        <button class="close-btn" onclick={cerrarModal} aria-label="Cerrar modal">
          <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <path d="M18 6 6 18M6 6l12 12"/>
          </svg>
        </button>
      </div>

      {#if errorMessage}
        <div class="alert alert-error">{errorMessage}</div>
      {/if}

      {#if successMessage}
        <div class="alert alert-success">{successMessage}</div>
      {/if}

      <form onsubmit={agregarPaciente}>
        <div class="modal-body">
          <div class="info-box">
            <strong>Nota:</strong> La contraseña inicial del paciente será su número de DNI. 
            El paciente podrá cambiarla después de iniciar sesión.
          </div>
          
          <h4 class="section-title">Datos del Usuario</h4>
          
          <div class="form-row">
            <div class="form-group">
              <label for="nombre">Nombre *</label>
              <input 
                type="text" 
                id="nombre"
                bind:value={nuevoUsuario.nombre}
                required
                disabled={loading}
              />
            </div>

            <div class="form-group">
              <label for="apellido">Apellido *</label>
              <input 
                type="text" 
                id="apellido"
                bind:value={nuevoUsuario.apellido}
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
                bind:value={nuevoUsuario.dni}
                required
                disabled={loading}
                pattern="[0-9]+"
                minlength="7"
                maxlength="8"
                title="Ingrese un DNI válido (7-8 dígitos)"
              />
            </div>

            <div class="form-group">
              <label for="fecha_nacimiento">Fecha de Nacimiento *</label>
              <input 
                type="date" 
                id="fecha_nacimiento"
                bind:value={nuevoUsuario.fecha_nacimiento}
                required
                disabled={loading}
              />
            </div>
          </div>

          <div class="form-row">
            <div class="form-group">
              <label for="telefono">Teléfono</label>
              <input 
                type="tel" 
                id="telefono"
                bind:value={nuevoUsuario.telefono}
                disabled={loading}
              />
            </div>

            <div class="form-group">
              <label for="email">Email</label>
              <input 
                type="email" 
                id="email"
                bind:value={nuevoUsuario.email}
                disabled={loading}
              />
            </div>
          </div>

          <h4 class="section-title">Datos del Paciente</h4>

          <div class="form-group">
            <label for="domicilio">Domicilio</label>
            <input 
              type="text" 
              id="domicilio"
              bind:value={nuevoPaciente.domicilio}
              disabled={loading}
            />
          </div>

          <div class="form-row">
            <div class="form-group">
              <label for="obra_social">Obra Social</label>
              <input 
                type="text" 
                id="obra_social"
                bind:value={nuevoPaciente.obra_social}
                disabled={loading}
              />
            </div>

            <div class="form-group">
              <label for="grupo_sanguineo">Grupo Sanguíneo</label>
              <select 
                id="grupo_sanguineo"
                bind:value={nuevoPaciente.grupo_sanguineo}
                disabled={loading}
              >
                <option value="">Seleccionar...</option>
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
          </div>
        </div>

        <div class="modal-footer">
          <button 
            type="button" 
            class="btn-secondary" 
            onclick={cerrarModal}
            disabled={loading}
          >
            Cancelar
          </button>
          <button 
            type="submit" 
            class="btn-primary"
            disabled={loading}
          >
            {loading ? 'Guardando...' : 'Guardar Paciente'}
          </button>
        </div>
      </form>
    </div>
  </div>
{/if}

<style>
  .header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 24px;
  }
  
  .header h2 {
    margin: 0;
    font-size: 28px;
    color: var(--color-900);
  }
  
  .header p {
    margin: 4px 0 0;
    color: var(--color-700);
    font-size: 14px;
  }
  
  .header-actions {
    display: flex;
    gap: 12px;
  }

  .btn-primary {
    display: inline-flex;
    align-items: center;
    gap: 8px;
    padding: 12px 24px;
    background: linear-gradient(135deg, var(--color-500) 0%, var(--color-700) 100%);
    color: white;
    border: none;
    border-radius: 10px;
    cursor: pointer;
    font-size: 14px;
    font-weight: 600;
    transition: all 0.2s;
  }

  .btn-primary svg {
    width: 18px;
    height: 18px;
  }

  .btn-primary:hover:not(:disabled) {
    transform: translateY(-2px);
    box-shadow: 0 4px 12px rgba(79, 166, 158, 0.4);
  }

  .btn-primary:disabled {
    opacity: 0.5;
    cursor: not-allowed;
  }

  .alert {
    padding: 12px 16px;
    border-radius: 12px;
    margin-bottom: 16px;
    font-size: 14px;
    font-weight: 500;
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

  .search-section {
    background: white;
    padding: 20px 24px;
    border-radius: 16px;
    box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
    margin-bottom: 20px;
    border: 1px solid var(--color-100);
    display: flex;
    justify-content: space-between;
    align-items: center;
    gap: 20px;
  }

  .search-box {
    flex: 1;
    max-width: 500px;
    position: relative;
  }

  .search-box svg {
    position: absolute;
    left: 16px;
    top: 50%;
    transform: translateY(-50%);
    width: 20px;
    height: 20px;
    color: var(--color-400);
  }

  .search-box input {
    width: 100%;
    padding: 12px 16px 12px 48px;
    border: 2px solid var(--color-200);
    border-radius: 10px;
    font-size: 14px;
    transition: all 0.2s;
  }

  .search-box input:focus {
    outline: none;
    border-color: var(--color-500);
    box-shadow: 0 0 0 3px var(--color-100);
  }

  .results-count {
    color: var(--color-700);
    font-size: 14px;
    font-weight: 500;
  }

  .content-card {
    background: white;
    border-radius: 16px;
    box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
    overflow: hidden;
    border: 1px solid var(--color-100);
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

  .table-container {
    overflow-x: auto;
  }
  
  .patients-table {
    width: 100%;
    border-collapse: collapse;
  }
  
  .patients-table thead {
    background: var(--color-50);
  }
  
  .patients-table th {
    padding: 16px 24px;
    text-align: left;
    font-size: 13px;
    font-weight: 600;
    color: var(--color-700);
    text-transform: uppercase;
    letter-spacing: 0.05em;
  }
  
  .patients-table td {
    padding: 16px 24px;
    border-top: 1px solid var(--color-100);
    color: var(--color-900);
    font-size: 14px;
  }

  .patients-table tbody tr {
    transition: background 0.2s;
  }

  .patients-table tbody tr:hover {
    background: var(--color-50);
  }
  
  .patient-cell {
    display: flex;
    align-items: center;
    gap: 12px;
  }
  
  .patient-avatar {
    width: 40px;
    height: 40px;
    background: linear-gradient(135deg, var(--color-500) 0%, var(--color-600) 100%);
    border-radius: 50%;
    display: flex;
    align-items: center;
    justify-content: center;
    color: white;
    font-weight: 600;
    font-size: 14px;
  }

  .patient-name {
    font-weight: 500;
    color: var(--color-900);
  }

  .badge-blood {
    padding: 4px 12px;
    border-radius: 12px;
    font-size: 12px;
    font-weight: 600;
    background: #fef3c7;
    color: #92400e;
  }

  /* Modal */
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
    max-width: 700px;
    max-height: 90vh;
    overflow-y: auto;
    box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
    border: 1px solid var(--color-200);
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
    width: 36px;
    height: 36px;
    background: var(--color-100);
    border: none;
    border-radius: 8px;
    cursor: pointer;
    display: flex;
    align-items: center;
    justify-content: center;
    color: var(--color-600);
    transition: all 0.2s;
  }
  
  .close-btn:hover {
    background: var(--color-200);
    color: var(--color-700);
  }
  
  .close-btn svg {
    width: 20px;
    height: 20px;
  }
  
  .modal-body {
    padding: 24px;
  }

  .info-box {
    background: #f0f9ff;
    border: 1px solid #bae6fd;
    border-radius: 8px;
    padding: 12px 16px;
    margin-bottom: 20px;
    font-size: 13px;
    color: #0c4a6e;
    line-height: 1.6;
  }

  .info-box strong {
    color: #075985;
  }

  .section-title {
    margin: 0 0 16px 0;
    font-size: 16px;
    color: var(--color-800);
    font-weight: 600;
    padding-bottom: 8px;
    border-bottom: 2px solid var(--color-200);
  }

  .section-title:not(:first-child) {
    margin-top: 24px;
  }

  .form-row {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 16px;
  }

  .form-group {
    margin-bottom: 16px;
  }

  .form-group label {
    display: block;
    margin-bottom: 6px;
    color: var(--color-700);
    font-weight: 500;
    font-size: 14px;
  }

  .form-group input,
  .form-group select {
    width: 100%;
    padding: 10px 12px;
    border: 2px solid var(--color-200);
    border-radius: 8px;
    font-size: 14px;
    transition: all 0.2s;
    box-sizing: border-box;
  }

  .form-group input:focus,
  .form-group select:focus {
    outline: none;
    border-color: var(--color-500);
    box-shadow: 0 0 0 3px var(--color-100);
  }

  .form-group input:disabled,
  .form-group select:disabled {
    background: var(--color-50);
    cursor: not-allowed;
  }

  .modal-footer {
    display: flex;
    justify-content: flex-end;
    gap: 12px;
    padding: 20px 24px;
    border-top: 1px solid var(--color-200);
  }

  .btn-secondary {
    padding: 10px 20px;
    background: white;
    border: 2px solid var(--color-200);
    color: var(--color-700);
    border-radius: 8px;
    font-size: 14px;
    font-weight: 600;
    cursor: pointer;
    transition: all 0.2s;
  }

  .btn-secondary:hover:not(:disabled) {
    border-color: var(--color-300);
    background: var(--color-50);
  }

  .btn-secondary:disabled {
    opacity: 0.5;
    cursor: not-allowed;
  }

  .action-btn {
    width: 36px;
    height: 36px;
    background: var(--color-100);
    border: none;
    border-radius: 8px;
    cursor: pointer;
    display: flex;
    align-items: center;
    justify-content: center;
    color: var(--color-600);
    transition: all 0.2s;
  }

  .action-btn:hover {
    background: var(--color-200);
    color: var(--color-700);
  }

  .action-btn svg {
    width: 20px;
    height: 20px;
  }

  @media (max-width: 768px) {
    .header {
      flex-direction: column;
      align-items: flex-start;
      gap: 16px;
    }

    .search-section {
      flex-direction: column;
      align-items: stretch;
    }

    .search-box {
      max-width: none;
    }

    .table-container {
      overflow-x: auto;
    }

    .patients-table {
      font-size: 12px;
    }

    .patients-table th,
    .patients-table td {
      padding: 12px;
    }

    .form-row {
      grid-template-columns: 1fr;
    }

    .modal {
      width: 95%;
    }
  }
</style>