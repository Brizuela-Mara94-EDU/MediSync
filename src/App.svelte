<script>
  import Login from './lib/pages/Login.svelte';
  import DoctorView from './lib/pages/DoctorView.svelte';
  import PatientView from './lib/pages/PatientView.svelte';
  
  let currentUser = $state(null);
  
  function handleLogin(email) {
    if (email.toLowerCase().includes('medico')) {
      currentUser = 'doctor';
    } else if (email.toLowerCase().includes('paciente')) {
      currentUser = 'patient';
    }
  }
  
  function handleLogout() {
    currentUser = null;
  }
</script>

{#if !currentUser}
  <Login onLogin={handleLogin} />
{:else if currentUser === 'doctor'}
  <div>
    <button class="logout-btn" onclick={handleLogout}>
      Cerrar Sesión
    </button>
    <DoctorView />
  </div>
{:else if currentUser === 'patient'}
  <PatientView onLogout={handleLogout} />
{/if}

<style>
  :global(body) {
    margin: 0;
    padding: 0;
    font-family: system-ui, -apple-system, sans-serif;
  }
  
  .logout-btn {
    position: fixed;
    top: 20px;
    right: 20px;
    padding: 8px 16px;
    background: #ef4444;
    color: white;
    border: none;
    border-radius: 8px;
    cursor: pointer;
    z-index: 1000;
    font-size: 14px;
    font-weight: 500;
  }
  
  .logout-btn:hover {
    background: #dc2626;
  }
</style>