<script>
  import Home from './paciente/Home.svelte';
  import MiEstado from './paciente/MiEstado.svelte';
  import Historial from './paciente/Historial.svelte';

  let { onLogout } = $props();
  
  let activeTab = $state('medicamentos');
  let showMenu = $state(false);
  let showNotifications = $state(false);

  function handleLogout() {
    if (confirm('¿Estás seguro de que deseas cerrar sesión?')) {
      showMenu = false;
      onLogout();
    }
  }

  let currentDate = new Date().toLocaleString('es-ES', { 
    weekday: 'long', 
    year: 'numeric', 
    month: 'long', 
    day: 'numeric' 
  });
  
  let medicamentos = $state([
    { nombre: 'Omeprazol', dosis: '20mg', hora: '08:00', tomado: false, tipo: 'Cápsula' },
    { nombre: 'Metformina', dosis: '850mg', hora: '12:00', tomado: false, tipo: 'Tableta' },
    { nombre: 'Atorvastatina', dosis: '10mg', hora: '14:00', tomado: false, tipo: 'Tableta' },
    { nombre: 'Aspirina', dosis: '100mg', hora: '18:00', tomado: false, tipo: 'Tableta' },
    { nombre: 'Losartán', dosis: '50mg', hora: '20:00', tomado: true, tipo: 'Tableta' }
  ]);
  
  function marcarTomado(medicamento) {
    medicamento.tomado = !medicamento.tomado;
  }
  
  function changeTab(newTab) {
    activeTab = newTab;
  }

  function handleMenuAction(action) {
    showMenu = false;
    
    if (action === 'logout') {
      handleLogout();
    } else if (action === 'perfil') {
      alert('Ir a Perfil - Funcionalidad próximamente');
    } else if (action === 'configuracion') {
      alert('Ir a Configuración - Funcionalidad próximamente');
    } else if (action === 'citas') {
      alert('Ver Mis Citas Médicas - Funcionalidad próximamente');
    } else if (action === 'recetas') {
      alert('Ver Recetas Médicas - Funcionalidad próximamente');
    } else if (action === 'contacto') {
      alert('Contacto de Emergencia - FuncionalIDAD próximamente');
    } else if (action === 'ayuda') {
      alert('Centro de Ayuda y Soporte - Funcionalidad próximamente');
    }
  }
</script>

<div class="app-container">
  <header class="header">
    <div class="header-content">
      <div class="profile-section" role="button" tabindex="0" onclick={() => showMenu = !showMenu} onkeydown={(e) => (e.key === 'Enter' || e.key === ' ') && (showMenu = !showMenu)} style="cursor: pointer;">
        <div class="avatar">
          <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <path d="M19 21v-2a4 4 0 0 0-4-4H9a4 4 0 0 0-4 4v2"/>
            <circle cx="12" cy="7" r="4"/>
          </svg>
        </div>
        <div class="profile-info">
          <h2>Juan Pérez</h2>
          <p>Paciente ID: 12345</p>
        </div>
        
        {#if showMenu}
          <div class="dropdown-menu" role="presentation" onclick={(e) => e.stopPropagation()}>
            <button class="menu-item" onclick={() => handleMenuAction('perfil')}>
              <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M19 21v-2a4 4 0 0 0-4-4H9a4 4 0 0 0-4 4v2"/>
                <circle cx="12" cy="7" r="4"/>
              </svg>
              Perfil
            </button>
            <button class="menu-item" onclick={() => handleMenuAction('configuracion')}>
              <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <circle cx="12" cy="12" r="3"/>
                <path d="M12 1v6m0 6v6M5.6 5.6l4.2 4.2m4.2 4.2l4.2 4.2M1 12h6m6 0h6M5.6 18.4l4.2-4.2m4.2-4.2l4.2-4.2"/>
              </svg>
              Configuración
            </button>
            <button class="menu-item" onclick={() => handleMenuAction('citas')}>
              <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <rect width="18" height="18" x="3" y="4" rx="2" ry="2"/>
                <line x1="16" x2="16" y1="2" y2="6"/>
                <line x1="8" x2="8" y1="2" y2="6"/>
                <line x1="3" x2="21" y1="10" y2="10"/>
              </svg>
              Mis Citas Médicas
            </button>
            <button class="menu-item" onclick={() => handleMenuAction('recetas')}>
              <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M14.5 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V7.5L14.5 2z"/>
                <polyline points="14 2 14 8 20 8"/>
                <line x1="16" x2="8" y1="13" y2="13"/>
                <line x1="16" x2="8" y1="17" y2="17"/>
                <line x1="10" x2="8" y1="9" y2="9"/>
              </svg>
              Recetas Médicas
            </button>
            <button class="menu-item" onclick={() => handleMenuAction('contacto')}>
              <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07 19.5 19.5 0 0 1-6-6 19.79 19.79 0 0 1-3.07-8.67A2 2 0 0 1 4.11 2h3a2 2 0 0 1 2 1.72 12.84 12.84 0 0 0 .7 2.81 2 2 0 0 1-.45 2.11L8.09 9.91a16 16 0 0 0 6 6l1.27-1.27a2 2 0 0 1 2.11-.45 12.84 12.84 0 0 0 2.81.7A2 2 0 0 1 22 16.92z"/>
              </svg>
              Contacto de Emergencia
            </button>
            <button class="menu-item" onclick={() => handleMenuAction('ayuda')}>
              <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <circle cx="12" cy="12" r="10"/>
                <path d="M9.09 9a3 3 0 0 1 5.83 1c0 2-3 3-3 3"/>
                <line x1="12" x2="12.01" y1="17" y2="17"/>
              </svg>
              Ayuda y Soporte
            </button>
            
            <div class="menu-divider"></div>
            
            <button class="menu-item logout" onclick={() => handleMenuAction('logout')}>
              <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/>
                <polyline points="16 17 21 12 16 7"/>
                <line x1="21" x2="9" y1="12" y2="12"/>
              </svg>
              Cerrar Sesión
            </button>
          </div>
        {/if}
      </div>
      <div class="header-actions">
        <button class="notification-btn" onclick={() => showNotifications = !showNotifications}>
          <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"/>
            <path d="M13.73 21a2 2 0 0 1-3.46 0"/>
          </svg>
          <span class="badge">2</span>
        </button>
        
        {#if showNotifications}
          <div class="notifications-panel">
            <div class="notifications-header">
              <h4>Notificaciones</h4>
              <button class="close-notifications" onclick={() => showNotifications = false} title="Cerrar notificaciones" aria-label="Cerrar panel de notificaciones">
                <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <line x1="18" x2="6" y1="6" y2="18"/>
                  <line x1="6" x2="18" y1="6" y2="18"/>
                </svg>
              </button>
            </div>
            <div class="notification-item">
              <div class="notification-icon new">
                <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <rect width="18" height="18" x="3" y="4" rx="2" ry="2"/>
                  <line x1="16" x2="16" y1="2" y2="6"/>
                  <line x1="8" x2="8" y1="2" y2="6"/>
                  <line x1="3" x2="21" y1="10" y2="10"/>
                </svg>
              </div>
              <div class="notification-content">
                <p class="notification-title">Recordatorio de cita</p>
                <p class="notification-text">Tienes una cita mañana a las 10:00 AM</p>
                <p class="notification-time">Hace 2 horas</p>
              </div>
            </div>
            <div class="notification-item">
              <div class="notification-icon">
                <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <rect width="20" height="14" x="2" y="7" rx="2" ry="2"/>
                  <path d="M16 21V5a2 2 0 0 0-2-2h-4a2 2 0 0 0-2 2v16"/>
                </svg>
              </div>
              <div class="notification-content">
                <p class="notification-title">Hora de medicamento</p>
                <p class="notification-text">No olvides tomar tu Omeprazol a las 8:00 PM</p>
                <p class="notification-time">Hace 5 horas</p>
              </div>
            </div>
          </div>
        {/if}
      </div>
    </div>
  </header>

  <div class="date-section">
    <h3>{currentDate.charAt(0).toUpperCase() + currentDate.slice(1)}</h3>
    <p>Tienes 4 medicamentos pendientes</p>
  </div>

  <main class="content">
    {#if activeTab === 'medicamentos'}
      <Home medicamentos={medicamentos} onToggleMed={marcarTomado} />
    {:else if activeTab === 'estado'}
      <MiEstado />
    {:else if activeTab === 'historial'}
      <Historial />
    {/if}
  </main>

  <nav class="bottom-nav">
    <button class="nav-item" class:active={activeTab === 'medicamentos'} onclick={() => changeTab('medicamentos')}>
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
        <rect width="20" height="14" x="2" y="7" rx="2" ry="2"/>
        <path d="M16 21V5a2 2 0 0 0-2-2h-4a2 2 0 0 0-2 2v16"/>
      </svg>
      <span>Medicamentos</span>
    </button>
    
    <button class="nav-item" class:active={activeTab === 'estado'} onclick={() => changeTab('estado')}>
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
        <path d="M22 12h-4l-3 9L9 3l-3 9H2"/>
      </svg>
      <span>Mi Estado</span>
    </button>
    
    <button class="nav-item" class:active={activeTab === 'historial'} onclick={() => changeTab('historial')}>
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
        <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/>
        <polyline points="14 2 14 8 20 8"/>
      </svg>
      <span>Historial</span>
    </button>
  </nav>
</div>

<style>
  * {
    margin: 0;
    padding: 0;
    box-sizing: border-box;
  }
  
  .app-container {
    min-height: 100vh;
    background: linear-gradient(to bottom, #e0f2fe 0%, #f0f9ff 100%);
    padding-bottom: 80px;
    max-width: 100%;
    overflow-x: hidden;
  }
  
  .header {
    background: linear-gradient(135deg, #3b82f6 0%, #06b6d4 100%);
    padding: 20px;
    color: white;
  }
  
  .header-content {
    max-width: 1200px;
    margin: 0 auto;
    display: flex;
    justify-content: space-between;
    align-items: center;
  }
  
  .profile-section {
    display: flex;
    align-items: center;
    gap: 12px;
    position: relative;
  }
  
  .avatar {
    width: 50px;
    height: 50px;
    background: rgba(255, 255, 255, 0.2);
    border-radius: 50%;
    display: flex;
    align-items: center;
    justify-content: center;
  }
  
  .avatar svg {
    width: 28px;
    height: 28px;
  }
  
  .profile-info h2 {
    margin: 0;
    font-size: 18px;
    font-weight: 600;
  }
  
  .profile-info p {
    margin: 4px 0 0;
    font-size: 13px;
    opacity: 0.9;
  }
  
  .header-actions {
    display: flex;
    align-items: center;
    gap: 16px;
    position: relative;
  }
  
  .notification-btn {
    position: relative;
    width: 44px;
    height: 44px;
    background: rgba(255, 255, 255, 0.2);
    border: none;
    border-radius: 50%;
    color: white;
    cursor: pointer;
    display: flex;
    align-items: center;
    justify-content: center;
  }
  
  .notification-btn svg {
    width: 22px;
    height: 22px;
  }
  
  .badge {
    position: absolute;
    top: 6px;
    right: 6px;
    background: #ef4444;
    color: white;
    font-size: 10px;
    font-weight: 600;
    width: 18px;
    height: 18px;
    border-radius: 50%;
    display: flex;
    align-items: center;
    justify-content: center;
  }
  
  .dropdown-menu {
    position: absolute;
    top: 70px;
    left: 0;
    background: white;
    border-radius: 16px;
    box-shadow: 0 10px 30px rgba(0, 0, 0, 0.2);
    min-width: 260px;
    overflow: hidden;
    animation: slideIn 0.3s ease-out;
    z-index: 1001;
  }
  
  @keyframes slideIn {
    from {
      opacity: 0;
      transform: translateY(-10px);
    }
    to {
      opacity: 1;
      transform: translateY(0);
    }
  }
  
  .menu-item {
    width: 100%;
    padding: 14px 18px;
    background: none;
    border: none;
    display: flex;
    align-items: center;
    gap: 12px;
    cursor: pointer;
    font-size: 14px;
    font-weight: 500;
    color: #1e293b;
    transition: background 0.2s;
    text-align: left;
  }
  
  .menu-item svg {
    width: 20px;
    height: 20px;
    color: #64748b;
    flex-shrink: 0;
  }
  
  .menu-item:hover {
    background: #f1f5f9;
  }
  
  .menu-divider {
    height: 1px;
    background: #e2e8f0;
    margin: 8px 0;
  }
  
  .menu-item.logout {
    color: #ef4444;
    font-weight: 600;
  }
  
  .menu-item.logout svg {
    color: #ef4444;
  }
  
  .menu-item.logout:hover {
    background: #fef2f2;
  }
  
  .notifications-panel {
    position: absolute;
    top: 60px;
    right: 0;
    background: white;
    border-radius: 16px;
    box-shadow: 0 10px 30px rgba(0, 0, 0, 0.2);
    width: 340px;
    max-height: 480px;
    overflow-y: auto;
    animation: slideIn 0.3s ease-out;
    z-index: 1001;
  }
  
  .notifications-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 16px 18px;
    border-bottom: 1px solid #e2e8f0;
    position: sticky;
    top: 0;
    background: white;
  }
  
  .notifications-header h4 {
    margin: 0;
    font-size: 16px;
    font-weight: 600;
    color: #1e293b;
  }
  
  .close-notifications {
    background: none;
    border: none;
    color: #64748b;
    cursor: pointer;
    padding: 4px;
    display: flex;
    align-items: center;
    justify-content: center;
    border-radius: 6px;
    transition: all 0.2s;
  }
  
  .close-notifications:hover {
    background: #f1f5f9;
    color: #1e293b;
  }
  
  .close-notifications svg {
    width: 18px;
    height: 18px;
  }
  
  .notification-item {
    display: flex;
    gap: 12px;
    padding: 14px 18px;
    border-bottom: 1px solid #f1f5f9;
    cursor: pointer;
    transition: background 0.2s;
  }
  
  .notification-item:hover {
    background: #f8fafc;
  }
  
  .notification-item:last-child {
    border-bottom: none;
  }
  
  .notification-icon {
    width: 40px;
    height: 40px;
    background: #f1f5f9;
    border-radius: 10px;
    display: flex;
    align-items: center;
    justify-content: center;
    flex-shrink: 0;
  }
  
  .notification-icon.new {
    background: #dbeafe;
  }
  
  .notification-icon svg {
    width: 20px;
    height: 20px;
    color: #64748b;
  }
  
  .notification-icon.new svg {
    color: #3b82f6;
  }
  
  .notification-content {
    flex: 1;
  }
  
  .notification-title {
    margin: 0 0 4px 0;
    font-size: 14px;
    font-weight: 600;
    color: #1e293b;
  }
  
  .notification-text {
    margin: 0 0 6px 0;
    font-size: 13px;
    color: #64748b;
    line-height: 1.4;
  }
  
  .notification-time {
    margin: 0;
    font-size: 12px;
    color: #94a3b8;
  }
  
  .date-section {
    padding: 20px;
    background: white;
    margin: -20px auto 0;
    max-width: 1200px;
    border-radius: 16px;
    box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
  }
  
  .date-section h3 {
    margin: 0;
    font-size: 20px;
    color: #1e293b;
  }
  
  .date-section p {
    margin: 6px 0 0;
    color: #64748b;
    font-size: 14px;
  }
  
  .content {
    padding: 20px;
    max-width: 1200px;
    margin: 0 auto;
  }
  
  .bottom-nav {
    position: fixed;
    bottom: 0;
    left: 0;
    right: 0;
    background: white;
    display: flex;
    justify-content: space-around;
    padding: 8px 8px 20px;
    box-shadow: 0 -2px 10px rgba(0, 0, 0, 0.1);
  }
  
  .nav-item {
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 4px;
    background: none;
    border: none;
    color: #94a3b8;
    cursor: pointer;
    padding: 8px 12px;
    border-radius: 12px;
    transition: all 0.2s;
    font-size: 11px;
  }
  
  .nav-item svg {
    width: 24px;
    height: 24px;
  }
  
  .nav-item.active {
    color: #3b82f6;
    background: #e0f2fe;
  }
  
  @media (max-width: 768px) {
    .date-section {
      margin: -20px 16px 0;
    }
    
    .header {
      padding: 20px 20px 30px;
    }
  }
  
  @media (min-width: 768px) {
    .app-container {
      padding-bottom: 0;
    }
    
    .bottom-nav {
      position: relative;
      max-width: 1200px;
      margin: 20px auto 0;
      border-radius: 16px;
      padding: 12px;
      box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
    }
  }
  
  @media (max-width: 375px) {
    .header {
      padding: 16px 16px 24px;
    }
    
    .profile-info h2 {
      font-size: 16px;
    }
    
    .profile-info p {
      font-size: 12px;
    }
    
    .date-section {
      padding: 16px;
    }
    
    .date-section h3 {
      font-size: 18px;
    }
    
    .nav-item {
      padding: 6px 8px;
      font-size: 10px;
    }
    
    .nav-item svg {
      width: 20px;
      height: 20px;
    }
  }
</style>