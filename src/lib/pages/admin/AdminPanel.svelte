<script>
  import UsuariosCRUD from './UsuariosCRUD.svelte';
  import PacientesCRUD from './PacientesCRUD.svelte';
  import DoctoresCRUD from './DoctoresCRUD.svelte';
  import RelacionesCRUD from './RelacionesCRUD.svelte';
  
  let activeTab = $state('usuarios');
  
  function goBack() {
    window.dispatchEvent(new CustomEvent('navigate', { detail: 'login' }));
  }
</script>

<div class="admin-panel">
  <header class="admin-header">
    <div class="header-content">
      <div class="header-left">
        <div class="logo-small">
          <img src="../../../src/assets/Logo.png" alt="MediSync">
        </div>
        <h1>Panel de Administración</h1>
      </div>
      <button class="back-btn" onclick={goBack}>
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <path d="M19 12H5M12 19l-7-7 7-7"/>
        </svg>
        Volver
      </button>
    </div>
  </header>

  <nav class="admin-tabs">
    <button 
      class="tab-btn {activeTab === 'usuarios' ? 'active' : ''}"
      onclick={() => activeTab = 'usuarios'}
    >
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
        <path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/>
        <circle cx="9" cy="7" r="4"/>
        <path d="M22 21v-2a4 4 0 0 0-3-3.87M16 3.13a4 4 0 0 1 0 7.75"/>
      </svg>
      Usuarios
    </button>
    
    <button 
      class="tab-btn {activeTab === 'pacientes' ? 'active' : ''}"
      onclick={() => activeTab = 'pacientes'}
    >
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
        <path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/>
        <circle cx="9" cy="7" r="4"/>
      </svg>
      Pacientes
    </button>
    
    <button 
      class="tab-btn {activeTab === 'doctores' ? 'active' : ''}"
      onclick={() => activeTab = 'doctores'}
    >
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
        <path d="M19 14c1.49-1.46 3-3.21 3-5.5A5.5 5.5 0 0 0 16.5 3c-1.76 0-3 .5-4.5 2-1.5-1.5-2.74-2-4.5-2A5.5 5.5 0 0 0 2 8.5c0 2.3 1.5 4.05 3 5.5l7 7Z"/>
      </svg>
      Médicos
    </button>

    <button 
      class="tab-btn {activeTab === 'relaciones' ? 'active' : ''}"
      onclick={() => activeTab = 'relaciones'}
    >
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
        <path d="M17 18a2 2 0 0 0-2-2H9a2 2 0 0 0-2 2"/>
        <rect width="18" height="18" x="3" y="4" rx="2"/>
        <circle cx="12" cy="10" r="2"/>
        <line x1="8" x2="8" y1="2" y2="4"/>
        <line x1="16" x2="16" y1="2" y2="4"/>
      </svg>
      Relaciones
    </button>
  </nav>

  <main class="admin-content">
    {#if activeTab === 'usuarios'}
      <UsuariosCRUD />
    {:else if activeTab === 'pacientes'}
      <PacientesCRUD />
    {:else if activeTab === 'doctores'}
      <DoctoresCRUD />
    {:else if activeTab === 'relaciones'}
      <RelacionesCRUD />
    {/if}
  </main>
</div>

<style>
  .admin-panel {
    min-height: 100vh;
    background: #f8fafc;
  }

  .admin-header {
    background: white;
    border-bottom: 2px solid #e2e8f0;
    box-shadow: 0 2px 4px rgba(0, 0, 0, 0.05);
  }

  .header-content {
    max-width: 1400px;
    margin: 0 auto;
    padding: 20px 30px;
    display: flex;
    justify-content: space-between;
    align-items: center;
  }

  .header-left {
    display: flex;
    align-items: center;
    gap: 15px;
  }

  .logo-small {
    width: 45px;
    height: 45px;
    border-radius: 10px;
    overflow: hidden;
    background: var(--color-500);
    display: flex;
    align-items: center;
    justify-content: center;
  }

  .logo-small img {
    width: 100%;
    height: 100%;
    object-fit: cover;
  }

  h1 {
    margin: 0;
    font-size: 24px;
    color: #1e293b;
    font-weight: 700;
  }

  .back-btn {
    display: flex;
    align-items: center;
    gap: 8px;
    padding: 10px 20px;
    background: white;
    border: 2px solid var(--color-500);
    color: var(--color-600);
    border-radius: 8px;
    font-size: 14px;
    font-weight: 600;
    cursor: pointer;
    transition: all 0.3s;
  }

  .back-btn svg {
    width: 18px;
    height: 18px;
  }

  .back-btn:hover {
    background: var(--color-500);
    color: white;
  }

  .admin-tabs {
    background: white;
    border-bottom: 1px solid #e2e8f0;
    display: flex;
    gap: 5px;
    padding: 0 30px;
    max-width: 1400px;
    margin: 0 auto;
  }

  .tab-btn {
    display: flex;
    align-items: center;
    gap: 8px;
    padding: 14px 24px;
    background: none;
    border: none;
    border-bottom: 3px solid transparent;
    color: #64748b;
    font-size: 15px;
    font-weight: 600;
    cursor: pointer;
    transition: all 0.3s;
  }

  .tab-btn svg {
    width: 20px;
    height: 20px;
  }

  .tab-btn:hover {
    color: var(--color-600);
    background: #f8fafc;
  }

  .tab-btn.active {
    color: var(--color-600);
    border-bottom-color: var(--color-600);
  }

  .admin-content {
    max-width: 1400px;
    margin: 0 auto;
    padding: 30px;
  }

  @media (max-width: 768px) {
    h1 {
      font-size: 18px;
    }

    .admin-tabs {
      padding: 0 15px;
      overflow-x: auto;
    }

    .tab-btn {
      padding: 12px 16px;
      font-size: 14px;
      white-space: nowrap;
    }

    .admin-content {
      padding: 20px 15px;
    }
  }
</style>
