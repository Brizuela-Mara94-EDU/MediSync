<script>
  let { activeSection, onSectionChange } = $props();
</script>

<aside class="sidebar">
  <div class="logo">
    <div class="logo-icon">
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
        <path d="M19 14c1.49-1.46 3-3.21 3-5.5A5.5 5.5 0 0 0 16.5 3c-1.76 0-3 .5-4.5 2-1.5-1.5-2.74-2-4.5-2A5.5 5.5 0 0 0 2 8.5c0 2.3 1.5 4.05 3 5.5l7 7Z"/>
      </svg>
    </div>
    <h1>MediCare Pro</h1>
  </div>
  
  <nav class="nav-menu">
    <button 
      class="nav-btn" 
      class:active={activeSection === 'dashboard'}
      onclick={() => onSectionChange('dashboard')}
    >
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
        <rect width="7" height="9" x="3" y="3" rx="1"/>
        <rect width="7" height="5" x="14" y="3" rx="1"/>
        <rect width="7" height="9" x="14" y="12" rx="1"/>
        <rect width="7" height="5" x="3" y="16" rx="1"/>
      </svg>
      <span>Dashboard</span>
    </button>
    
    <button 
      class="nav-btn"
      class:active={activeSection === 'pacientes'}
      onclick={() => onSectionChange('pacientes')}
    >
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
        <path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/>
        <circle cx="9" cy="7" r="4"/>
        <path d="M22 21v-2a4 4 0 0 0-3-3.87"/>
        <path d="M16 3.13a4 4 0 0 1 0 7.75"/>
      </svg>
      <span>Mis Pacientes</span>
    </button>
    
    <button 
      class="nav-btn"
      class:active={activeSection === 'citas'}
      onclick={() => onSectionChange('citas')}
    >
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
        <path d="M8 2v4"/>
        <path d="M16 2v4"/>
        <rect width="18" height="18" x="3" y="4" rx="2"/>
        <path d="M3 10h18"/>
      </svg>
      <span>Citas</span>
    </button>
    
    <button 
      class="nav-btn"
      class:active={activeSection === 'historial'}
      onclick={() => onSectionChange('historial')}
    >
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
        <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/>
        <polyline points="14 2 14 8 20 8"/>
      </svg>
      <span>Historial</span>
    </button>
  </nav>
  
  <div class="profile-section">
    <div class="profile-avatar">
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
        <path d="M19 21v-2a4 4 0 0 0-4-4H9a4 4 0 0 0-4 4v2"/>
        <circle cx="12" cy="7" r="4"/>
      </svg>
    </div>
    <div class="profile-info">
      <p class="profile-name">Dr. López</p>
      <p class="profile-role">Médico General</p>
    </div>
  </div>
</aside>

<style>
  .sidebar {
    width: 260px;
    min-width: 260px;
    background: linear-gradient(180deg, #1e40af 0%, #1e3a8a 100%);
    color: white;
    padding: 24px;
    display: flex;
    flex-direction: column;
    position: fixed;
    height: 100vh;
    overflow-y: auto;
    z-index: 100;
  }
  
  .logo {
    margin-bottom: 40px;
  }
  
  .logo-icon {
    width: 48px;
    height: 48px;
    background: rgba(255, 255, 255, 0.2);
    border-radius: 12px;
    display: flex;
    align-items: center;
    justify-content: center;
    margin-bottom: 12px;
  }
  
  .logo-icon svg {
    width: 28px;
    height: 28px;
  }
  
  .logo h1 {
    margin: 0;
    font-size: 22px;
    font-weight: 700;
  }
  
  .nav-menu {
    flex: 1;
    display: flex;
    flex-direction: column;
    gap: 8px;
  }
  
  .nav-btn {
    display: flex;
    align-items: center;
    gap: 12px;
    padding: 12px 16px;
    background: none;
    border: none;
    color: rgba(255, 255, 255, 0.7);
    cursor: pointer;
    border-radius: 10px;
    transition: all 0.2s;
    text-align: left;
    font-size: 15px;
  }
  
  .nav-btn:hover {
    background: rgba(255, 255, 255, 0.1);
    color: white;
  }
  
  .nav-btn.active {
    background: rgba(255, 255, 255, 0.2);
    color: white;
  }
  
  .nav-btn svg {
    width: 20px;
    height: 20px;
  }
  
  .profile-section {
    display: flex;
    align-items: center;
    gap: 12px;
    padding: 16px;
    background: rgba(255, 255, 255, 0.1);
    border-radius: 12px;
    margin-top: 20px;
  }
  
  .profile-avatar {
    width: 40px;
    height: 40px;
    background: rgba(255, 255, 255, 0.2);
    border-radius: 50%;
    display: flex;
    align-items: center;
    justify-content: center;
  }
  
  .profile-avatar svg {
    width: 22px;
    height: 22px;
  }
  
  .profile-info {
    flex: 1;
  }
  
  .profile-name {
    margin: 0;
    font-size: 14px;
    font-weight: 600;
  }
  
  .profile-role {
    margin: 2px 0 0;
    font-size: 12px;
    opacity: 0.8;
  }
  
  @media (max-width: 768px) {
    .sidebar {
      display: none;
    }
  }
</style>
