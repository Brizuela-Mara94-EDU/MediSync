<script lang="ts">
  import { supabase } from '../../supabase/supabase-client.js';
  import { obtenerSesion } from '../../utils/SessionManager.js';
  
  let selectedPatient = $state(null);
  let pacientes = $state([]);
  let totalPacientes = $state(0);
  let pacientesCriticos = $state(0);
  let loading = $state(true);
  let showPatientView = $state(false);
  let currentPatient = $state(null);
  
  const sesion = obtenerSesion();
  const medicoUsuarioId = sesion?.id_usuario;

  $effect(() => {
    if (medicoUsuarioId) {
      loadPacientes();
    }
  });

  async function loadPacientes() {
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

      // Obtener todas las citas de los pacientes (solo pasadas o completadas)
      const pacientesIds = data?.map((rel: any) => rel.id_paciente) || [];
      
      let citasData: any[] = [];
      if (pacientesIds.length > 0) {
        const hoy = new Date();
        hoy.setHours(0, 0, 0, 0); // Resetear horas para comparar solo fecha
        
        const { data: citas, error: citasError } = await supabase
          .from('citas')
          .select('id_paciente, fecha, estado')
          .in('id_paciente', pacientesIds)
          .eq('id_medico', medicoData.id_medico)
          .lte('fecha', hoy.toISOString()) // Solo citas pasadas o de hoy
          .order('fecha', { ascending: false });

        if (!citasError && citas) {
          citasData = citas;
          console.log('Citas obtenidas:', citas);
        }
      }

      // Calcular fecha límite (6 meses atrás)
      const hoy = new Date();
      hoy.setHours(0, 0, 0, 0);
      const seiseMesesAtras = new Date();
      seiseMesesAtras.setMonth(hoy.getMonth() - 6);
      seiseMesesAtras.setHours(0, 0, 0, 0);

      console.log('Fecha límite (6 meses atrás):', seiseMesesAtras.toLocaleDateString('es-AR'));

      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      pacientes = data?.map((rel: any) => {
        const pacienteData = rel.pacientes;
        const usuario = Array.isArray(pacienteData?.usuarios) 
          ? pacienteData.usuarios[0] 
          : pacienteData?.usuarios;
        
        const nacimiento = new Date(usuario?.fecha_nacimiento);
        const edad = hoy.getFullYear() - nacimiento.getFullYear();

        // Buscar la última cita del paciente (solo citas pasadas)
        const citasPaciente = citasData.filter(c => c.id_paciente === rel.id_paciente);
        const ultimaCita = citasPaciente.length > 0 ? citasPaciente[0] : null;
        
        let ultimaVisita = 'Sin registros';
        let estado = 'Estable';
        
        if (ultimaCita) {
          const fechaUltimaCita = new Date(ultimaCita.fecha);
          fechaUltimaCita.setHours(0, 0, 0, 0);
          ultimaVisita = fechaUltimaCita.toLocaleDateString('es-AR');
          
          console.log(`Paciente ${usuario?.nombre}: última cita ${fechaUltimaCita.toLocaleDateString('es-AR')}, límite ${seiseMesesAtras.toLocaleDateString('es-AR')}`);
          
          // Si la última cita fue hace más de 6 meses, estado crítico
          if (fechaUltimaCita < seiseMesesAtras) {
            estado = 'Crítico';
            console.log(`  -> CRÍTICO (cita hace más de 6 meses)`);
          } else {
            console.log(`  -> ESTABLE (cita dentro de los últimos 6 meses)`);
          }
        } else {
          // Si no tiene citas registradas, también es crítico
          estado = 'Crítico';
          console.log(`Paciente ${usuario?.nombre}: SIN CITAS -> CRÍTICO`);
        }

        return {
          id_paciente: pacienteData?.id_paciente,
          nombre: `${usuario?.nombre} ${usuario?.apellido}`,
          edad: edad,
          dni: usuario?.dni,
          telefono: usuario?.telefono,
          email: usuario?.email,
          obra_social: pacienteData?.obra_social,
          grupo_sanguineo: pacienteData?.grupo_sanguineo,
          domicilio: pacienteData?.domicilio,
          ultimaVisita: ultimaVisita,
          condicion: citasPaciente.length > 0 ? 'Bajo seguimiento' : 'Sin registros',
          estado: estado,
          medicamentos: 0
        };
      }) || [];

      totalPacientes = pacientes.length;
      pacientesCriticos = pacientes.filter(p => p.estado === 'Crítico').length;
      console.log('Pacientes cargados:', pacientes);
      console.log('Pacientes críticos:', pacientesCriticos);

    } catch (error) {
      console.error('Error cargando pacientes:', error);
    } finally {
      loading = false;
    }
  }
  
  function verDetalle(paciente) {
    selectedPatient = paciente;
  }
  
  function cerrarDetalle() {
    selectedPatient = null;
  }

  function irAPaciente() {
    if (selectedPatient) {
      currentPatient = selectedPatient.id_paciente; // Pasar solo el ID
      showPatientView = true;
      cerrarDetalle();
    }
  }

  function volverAlDashboard() {
    showPatientView = false;
    currentPatient = null;
    selectedPatient = null;
    // Recargar los datos cuando vuelve al dashboard
    loadPacientes();
  }
</script>

{#if !showPatientView}
<header class="header">
  <div>
    <h2>Panel de Control</h2>
    <p>Bienvenido de nuevo, Dr. {sesion?.nombre || 'Médico'}</p>
  </div>
  <div class="header-actions">
    <button class="icon-btn" title="Notificaciones" aria-label="Ver notificaciones">
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
        <path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"/>
        <path d="M13.73 21a2 2 0 0 1-3.46 0"/>
      </svg>
      <span class="notification-badge">3</span>
    </button>
  </div>
</header>

<div class="stats-grid">
  <div class="stat-card">
    <div class="stat-icon primary">
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
        <path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/>
        <circle cx="9" cy="7" r="4"/>
        <path d="M22 21v-2a4 4 0 0 0-3-3.87"/>
        <path d="M16 3.13a4 4 0 0 1 0 7.75"/>
      </svg>
    </div>
    <div class="stat-info">
      <p class="stat-label">Total Pacientes</p>
      <h3 class="stat-value">{totalPacientes}</h3>
    </div>
  </div>

  <div class="stat-card">
    <div class="stat-icon green">
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
        <path d="M8 2v4"/>
        <path d="M16 2v4"/>
        <rect width="18" height="18" x="3" y="4" rx="2"/>
        <path d="M3 10h18"/>
      </svg>
    </div>
    <div class="stat-info">
      <p class="stat-label">Citas Hoy</p>
      <h3 class="stat-value">8</h3>
    </div>
  </div>

  <div class="stat-card">
    <div class="stat-icon red">
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
        <path d="m21.73 18-8-14a2 2 0 0 0-3.48 0l-8 14A2 2 0 0 0 4 21h16a2 2 0 0 0 1.73-3Z"/>
        <path d="M12 9v4"/>
        <path d="M12 17h.01"/>
      </svg>
    </div>
    <div class="stat-info">
      <p class="stat-label">Pacientes Críticos</p>
      <h3 class="stat-value">{pacientesCriticos}</h3>
    </div>
  </div>

  <div class="stat-card">
    <div class="stat-icon accent">
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
        <line x1="12" x2="12" y1="20" y2="10"/>
        <line x1="18" x2="18" y1="20" y2="4"/>
        <line x1="6" x2="6" y1="20" y2="16"/>
      </svg>
    </div>
    <div class="stat-info">
      <p class="stat-label">Atendidos Mes</p>
      <h3 class="stat-value">234</h3>
    </div>
  </div>
</div>

<div class="content-card">
  <div class="card-header">
    <h3>Mis Pacientes</h3>
    <button class="text-btn">Ver todos</button>
  </div>
  
  {#if loading}
    <div class="loading-state">
      <p>Cargando pacientes...</p>
    </div>
  {:else if pacientes.length === 0}
    <div class="empty-state">
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
        <path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/>
        <circle cx="9" cy="7" r="4"/>
      </svg>
      <p>No tienes pacientes asignados aún</p>
    </div>
  {:else}
    <div class="table-container">
      <table class="patients-table">
        <thead>
          <tr>
            <th>Paciente</th>
            <th>Edad</th>
            <th>Condición</th>
            <th>Última Visita</th>
            <th>Estado</th>
            <th>Acciones</th>
          </tr>
        </thead>
        <tbody>
          {#each pacientes as paciente}
            <tr>
              <td>
                <div class="patient-cell">
                  <div class="patient-avatar">
                    {paciente.nombre.charAt(0)}
                  </div>
                  <span>{paciente.nombre}</span>
                </div>
              </td>
              <td>{paciente.edad} años</td>
              <td>{paciente.condicion}</td>
              <td>{paciente.ultimaVisita}</td>
              <td>
                <span 
                  class="status-badge" 
                  class:warning={paciente.estado === 'Requiere atención'}
                  class:critical={paciente.estado === 'Crítico'}
                >
                  {paciente.estado}
                </span>
              </td>
              <td>
                <button class="action-btn" onclick={() => verDetalle(paciente)} title="Ver detalles" aria-label="Ver detalles de {paciente.nombre}">
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

{#if selectedPatient}
  <div 
    class="modal-overlay" 
    role="button" 
    tabindex="0"
    onclick={cerrarDetalle} 
    onkeydown={(e) => e.key === 'Escape' && cerrarDetalle()}
  >
    <div 
      class="modal" 
      role="dialog" 
      tabindex="-1"
      onclick={(e) => e.stopPropagation()} 
      onkeydown={(e) => e.stopPropagation()}
    >
      <div class="modal-header">
        <h3>Detalles del Paciente</h3>
        <button class="close-btn" onclick={cerrarDetalle} title="Cerrar" aria-label="Cerrar detalles del paciente">
          <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <path d="M18 6 6 18"/>
            <path d="m6 6 12 12"/>
          </svg>
        </button>
      </div>
      <div class="modal-body">
        <div class="detail-row">
          <span class="detail-label">Nombre:</span>
          <span class="detail-value">{selectedPatient.nombre}</span>
        </div>
        <div class="detail-row">
          <span class="detail-label">DNI:</span>
          <span class="detail-value">{selectedPatient.dni}</span>
        </div>
        <div class="detail-row">
          <span class="detail-label">Edad:</span>
          <span class="detail-value">{selectedPatient.edad} años</span>
        </div>
        <div class="detail-row">
          <span class="detail-label">Teléfono:</span>
          <span class="detail-value">{selectedPatient.telefono || 'No registrado'}</span>
        </div>
        <div class="detail-row">
          <span class="detail-label">Email:</span>
          <span class="detail-value">{selectedPatient.email}</span>
        </div>
        <div class="detail-row">
          <span class="detail-label">Obra Social:</span>
          <span class="detail-value">{selectedPatient.obra_social || 'Sin obra social'}</span>
        </div>
        <div class="detail-row">
          <span class="detail-label">Grupo Sanguíneo:</span>
          <span class="detail-value">{selectedPatient.grupo_sanguineo || 'No registrado'}</span>
        </div>
        <div class="detail-row">
          <span class="detail-label">Condición:</span>
          <span class="detail-value">{selectedPatient.condicion}</span>
        </div>
        <div class="detail-row">
          <span class="detail-label">Última visita:</span>
          <span class="detail-value">{selectedPatient.ultimaVisita}</span>
        </div>
        <div class="detail-row">
          <span class="detail-label">Medicamentos activos:</span>
          <span class="detail-value">{selectedPatient.medicamentos}</span>
        </div>
        <div class="detail-row">
          <span class="detail-label">Estado:</span>
          <span class="detail-value">{selectedPatient.estado}</span>
        </div>
      </div>
      <div class="modal-footer">
        <button class="btn-secondary" onclick={cerrarDetalle}>
          Cerrar
        </button>
        <button class="btn-primary" onclick={irAPaciente}>
          <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <path d="M18 13v6a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h6"/>
            <path d="M15 3h6v6"/>
            <path d="M10 14L21 3"/>
          </svg>
          Ir a Ficha del Paciente
        </button>
      </div>
    </div>
  </div>
{/if}
{:else}
  {#await import('./Paciente.svelte') then module}
    {@const Component = module.default}
    <Component idPaciente={currentPatient} onVolver={volverAlDashboard} />
  {/await}
{/if}

<style>
  .header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 32px;
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
  
  .icon-btn {
    position: relative;
    width: 44px;
    height: 44px;
    background: white;
    border: 1px solid var(--color-200);
    border-radius: 10px;
    cursor: pointer;
    display: flex;
    align-items: center;
    justify-content: center;
    color: var(--color-600);
    transition: all 0.2s;
  }
  
  .icon-btn:hover {
    background: var(--color-50);
    border-color: var(--color-300);
  }
  
  .icon-btn svg {
    width: 20px;
    height: 20px;
  }
  
  .notification-badge {
    position: absolute;
    top: 8px;
    right: 8px;
    background: #ef4444;
    color: white;
    font-size: 10px;
    font-weight: 600;
    width: 16px;
    height: 16px;
    border-radius: 50%;
    display: flex;
    align-items: center;
    justify-content: center;
  }
  
  .stats-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
    gap: 20px;
    margin-bottom: 32px;
  }
  
  .stat-card {
    background: white;
    padding: 24px;
    border-radius: 16px;
    box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
    display: flex;
    align-items: center;
    gap: 16px;
    border: 1px solid var(--color-100);
    transition: all 0.2s;
  }

  .stat-card:hover {
    box-shadow: 0 4px 12px rgba(79, 166, 158, 0.15);
    transform: translateY(-2px);
  }
  
  .stat-icon {
    width: 56px;
    height: 56px;
    border-radius: 12px;
    display: flex;
    align-items: center;
    justify-content: center;
    color: white;
  }
  
  .stat-icon svg {
    width: 28px;
    height: 28px;
  }
  
  .stat-icon.primary {
    background: linear-gradient(135deg, var(--color-500) 0%, var(--color-700) 100%);
  }
  
  .stat-icon.green {
    background: linear-gradient(135deg, #10b981 0%, #059669 100%);
  }

  .stat-icon.red {
    background: linear-gradient(135deg, #ef4444 0%, #dc2626 100%);
  }
  
  .stat-icon.accent {
    background: linear-gradient(135deg, var(--color-400) 0%, var(--color-600) 100%);
  }
  
  .stat-label {
    margin: 0;
    color: var(--color-700);
    font-size: 13px;
  }
  
  .stat-value {
    margin: 4px 0 0;
    font-size: 28px;
    font-weight: 700;
    color: var(--color-900);
  }
  
  .content-card {
    background: white;
    border-radius: 16px;
    box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
    overflow: hidden;
    border: 1px solid var(--color-100);
  }
  
  .card-header {
    padding: 24px;
    display: flex;
    justify-content: space-between;
    align-items: center;
    border-bottom: 1px solid var(--color-200);
  }
  
  .card-header h3 {
    margin: 0;
    font-size: 18px;
    color: var(--color-900);
  }
  
  .text-btn {
    background: none;
    border: none;
    color: var(--color-600);
    font-size: 14px;
    font-weight: 500;
    cursor: pointer;
    padding: 8px 16px;
    border-radius: 8px;
    transition: all 0.2s;
  }
  
  .text-btn:hover {
    background: var(--color-50);
    color: var(--color-700);
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
    width: 36px;
    height: 36px;
    background: linear-gradient(135deg, var(--color-500) 0%, var(--color-600) 100%);
    border-radius: 50%;
    display: flex;
    align-items: center;
    justify-content: center;
    color: white;
    font-weight: 600;
    font-size: 14px;
  }
  
  .status-badge {
    padding: 4px 12px;
    border-radius: 12px;
    font-size: 12px;
    font-weight: 500;
    background: var(--color-100);
    color: var(--color-800);
  }
  
  .status-badge.warning {
    background: #fef3c7;
    color: #92400e;
  }

  .status-badge.critical {
    background: #fee2e2;
    color: #991b1b;
    font-weight: 600;
  }
  
  .action-btn {
    width: 32px;
    height: 32px;
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
    width: 18px;
    height: 18px;
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
    max-width: 500px;
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
  
  .detail-row {
    display: flex;
    justify-content: space-between;
    padding: 12px 0;
    border-bottom: 1px solid var(--color-100);
  }
  
  .detail-row:last-child {
    border-bottom: none;
  }
  
  .detail-label {
    color: var(--color-700);
    font-size: 14px;
    font-weight: 500;
  }
  
  .detail-value {
    color: var(--color-900);
    font-size: 14px;
    font-weight: 600;
  }

  .modal-footer {
    display: flex;
    justify-content: flex-end;
    gap: 1rem;
    padding: 1.5rem;
    border-top: 1px solid var(--color-200);
  }

  .btn-secondary {
    padding: 0.75rem 1.5rem;
    background: var(--color-100);
    color: var(--color-800);
    border: none;
    border-radius: 8px;
    cursor: pointer;
    font-size: 0.9rem;
    font-weight: 500;
    transition: all 0.2s;
  }

  .btn-secondary:hover {
    background: var(--color-200);
    color: var(--color-900);
  }

  .btn-primary {
    display: inline-flex;
    align-items: center;
    gap: 0.5rem;
    padding: 0.75rem 1.5rem;
    background: linear-gradient(135deg, var(--color-500) 0%, var(--color-700) 100%);
    color: white;
    border: none;
    border-radius: 8px;
    cursor: pointer;
    font-size: 0.9rem;
    font-weight: 500;
    transition: all 0.2s;
  }

  .btn-primary:hover {
    transform: translateY(-2px);
    box-shadow: 0 4px 12px rgba(79, 166, 158, 0.4);
  }

  .btn-primary svg {
    width: 18px;
    height: 18px;
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
  
  @media (max-width: 768px) {
    .stats-grid {
      grid-template-columns: 1fr;
    }
    
    .header h2 {
      font-size: 24px;
    }
    
    .table-container {
      overflow-x: auto;
      -webkit-overflow-scrolling: touch;
    }
    
    .patients-table {
      min-width: 600px;
    }
  }
  
  @media (max-width: 1024px) and (min-width: 769px) {
    .stats-grid {
      grid-template-columns: repeat(2, 1fr);
    }
  }
</style>