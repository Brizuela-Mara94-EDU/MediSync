<script>
  let selectedPatient = $state(null);
  
  const pacientes = [
    {
      id: 1,
      nombre: 'Juan Pérez',
      edad: 45,
      ultimaVisita: '2024-10-28',
      condicion: 'Diabetes Tipo 2',
      estado: 'Estable',
      medicamentos: 5
    },
    {
      id: 2,
      nombre: 'María González',
      edad: 62,
      ultimaVisita: '2024-10-30',
      condicion: 'Hipertensión',
      estado: 'Requiere atención',
      medicamentos: 3
    },
    {
      id: 3,
      nombre: 'Carlos Rodríguez',
      edad: 38,
      ultimaVisita: '2024-10-25',
      condicion: 'Gastritis',
      estado: 'Estable',
      medicamentos: 2
    },
    {
      id: 4,
      nombre: 'Ana Martínez',
      edad: 55,
      ultimaVisita: '2024-11-01',
      condicion: 'Artritis',
      estado: 'En tratamiento',
      medicamentos: 4
    },
    {
      id: 5,
      nombre: 'Roberto Silva',
      edad: 51,
      ultimaVisita: '2024-10-29',
      condicion: 'Colesterol Alto',
      estado: 'Estable',
      medicamentos: 2
    }
  ];
  
  function verDetalle(paciente) {
    selectedPatient = paciente;
  }
  
  function cerrarDetalle() {
    selectedPatient = null;
  }
</script>

<header class="header">
  <div>
    <h2>Panel de Control</h2>
    <p>Bienvenido de nuevo, Dr. López</p>
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

<!-- Stats Cards -->
<div class="stats-grid">
  <div class="stat-card">
    <div class="stat-icon blue">
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
        <path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/>
        <circle cx="9" cy="7" r="4"/>
        <path d="M22 21v-2a4 4 0 0 0-3-3.87"/>
        <path d="M16 3.13a4 4 0 0 1 0 7.75"/>
      </svg>
    </div>
    <div class="stat-info">
      <p class="stat-label">Total Pacientes</p>
      <h3 class="stat-value">156</h3>
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
    <div class="stat-icon orange">
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
        <circle cx="12" cy="12" r="10"/>
        <path d="M12 6v6l4 2"/>
      </svg>
    </div>
    <div class="stat-info">
      <p class="stat-label">Pendientes</p>
      <h3 class="stat-value">5</h3>
    </div>
  </div>

  <div class="stat-card">
    <div class="stat-icon purple">
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

<!-- Patients Table -->
<div class="content-card">
  <div class="card-header">
    <h3>Pacientes Recientes</h3>
    <button class="text-btn">Ver todos</button>
  </div>
  
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
              <span class="status-badge" class:warning={paciente.estado === 'Requiere atención'}>
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
</div>

<!-- Patient Detail Modal -->
{#if selectedPatient}
  <div class="modal-overlay" role="dialog" aria-modal="true" tabindex="-1" onclick={cerrarDetalle} onkeydown={(e) => e.key === 'Escape' && cerrarDetalle()}>
    <div class="modal" role="presentation" onclick={(e) => e.stopPropagation()}>
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
          <span class="detail-label">Edad:</span>
          <span class="detail-value">{selectedPatient.edad} años</span>
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
    </div>
  </div>
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
    color: #1e293b;
  }
  
  .header p {
    margin: 4px 0 0;
    color: #64748b;
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
    border: 1px solid #e2e8f0;
    border-radius: 10px;
    cursor: pointer;
    display: flex;
    align-items: center;
    justify-content: center;
    color: #64748b;
    transition: all 0.2s;
  }
  
  .icon-btn:hover {
    background: #f8fafc;
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
  
  .stat-icon.blue {
    background: linear-gradient(135deg, #3b82f6 0%, #2563eb 100%);
  }
  
  .stat-icon.green {
    background: linear-gradient(135deg, #10b981 0%, #059669 100%);
  }
  
  .stat-icon.orange {
    background: linear-gradient(135deg, #f59e0b 0%, #d97706 100%);
  }
  
  .stat-icon.purple {
    background: linear-gradient(135deg, #8b5cf6 0%, #7c3aed 100%);
  }
  
  .stat-label {
    margin: 0;
    color: #64748b;
    font-size: 13px;
  }
  
  .stat-value {
    margin: 4px 0 0;
    font-size: 28px;
    font-weight: 700;
    color: #1e293b;
  }
  
  .content-card {
    background: white;
    border-radius: 16px;
    box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
    overflow: hidden;
  }
  
  .card-header {
    padding: 24px;
    display: flex;
    justify-content: space-between;
    align-items: center;
    border-bottom: 1px solid #e2e8f0;
  }
  
  .card-header h3 {
    margin: 0;
    font-size: 18px;
    color: #1e293b;
  }
  
  .text-btn {
    background: none;
    border: none;
    color: #3b82f6;
    font-size: 14px;
    font-weight: 500;
    cursor: pointer;
    padding: 8px 16px;
    border-radius: 8px;
    transition: background 0.2s;
  }
  
  .text-btn:hover {
    background: #f0f9ff;
  }
  
  .table-container {
    overflow-x: auto;
  }
  
  .patients-table {
    width: 100%;
    border-collapse: collapse;
  }
  
  .patients-table thead {
    background: #f8fafc;
  }
  
  .patients-table th {
    padding: 16px 24px;
    text-align: left;
    font-size: 13px;
    font-weight: 600;
    color: #64748b;
    text-transform: uppercase;
    letter-spacing: 0.05em;
  }
  
  .patients-table td {
    padding: 16px 24px;
    border-top: 1px solid #f1f5f9;
    color: #1e293b;
    font-size: 14px;
  }
  
  .patient-cell {
    display: flex;
    align-items: center;
    gap: 12px;
  }
  
  .patient-avatar {
    width: 36px;
    height: 36px;
    background: linear-gradient(135deg, #3b82f6 0%, #06b6d4 100%);
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
    background: #dcfce7;
    color: #166534;
  }
  
  .status-badge.warning {
    background: #fef3c7;
    color: #92400e;
  }
  
  .action-btn {
    width: 32px;
    height: 32px;
    background: #f1f5f9;
    border: none;
    border-radius: 8px;
    cursor: pointer;
    display: flex;
    align-items: center;
    justify-content: center;
    color: #64748b;
    transition: all 0.2s;
  }
  
  .action-btn:hover {
    background: #e2e8f0;
    color: #3b82f6;
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
  }
  
  .modal {
    background: white;
    border-radius: 16px;
    width: 90%;
    max-width: 500px;
    box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
  }
  
  .modal-header {
    padding: 24px;
    border-bottom: 1px solid #e2e8f0;
    display: flex;
    justify-content: space-between;
    align-items: center;
  }
  
  .modal-header h3 {
    margin: 0;
    font-size: 20px;
    color: #1e293b;
  }
  
  .close-btn {
    width: 36px;
    height: 36px;
    background: #f1f5f9;
    border: none;
    border-radius: 8px;
    cursor: pointer;
    display: flex;
    align-items: center;
    justify-content: center;
    color: #64748b;
    transition: all 0.2s;
  }
  
  .close-btn:hover {
    background: #e2e8f0;
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
    border-bottom: 1px solid #f1f5f9;
  }
  
  .detail-row:last-child {
    border-bottom: none;
  }
  
  .detail-label {
    color: #64748b;
    font-size: 14px;
    font-weight: 500;
  }
  
  .detail-value {
    color: #1e293b;
    font-size: 14px;
    font-weight: 600;
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
