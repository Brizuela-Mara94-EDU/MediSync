<script>
  import { onMount } from 'svelte';
  import Login from './lib/pages/Login.svelte';
  import Register from './lib/pages/Register.svelte';
  import ForgotPassword from './lib/pages/ForgotPassword.svelte';
  import DoctorView from './lib/pages/DoctorView.svelte';
  import PatientView from './lib/pages/PatientView.svelte';
  import AdminPanel from './lib/pages/admin/AdminPanel.svelte';
  import { obtenerSesion, cerrarSesion } from './lib/utils/SessionManager.js';
  
  let currentUser = $state(null);
  let currentPage = $state('login');
  let userRole = $state(null);
  let userProfile = $state(null);
  let loading = $state(true);

  // Verificar sesión al cargar la aplicación
  onMount(() => {
    checkUserSession();
    
    // Escuchar eventos de navegación personalizados
    const handleNavigation = (event) => {
      if (event.detail) {
        console.log('🔀 Navegando a:', event.detail);
        currentPage = event.detail;
      }
    };

    window.addEventListener('navigate', handleNavigation);

    return () => {
      window.removeEventListener('navigate', handleNavigation);
    };
  });

  // Verificar si existe una sesión guardada
  function checkUserSession() {
    const sesion = obtenerSesion();
    
    if (sesion) {
      console.log('✅ Sesión encontrada:', sesion);
      currentUser = {
        id_usuario: sesion.id_usuario,
        email: sesion.email,
        nombre: sesion.nombre,
        apellido: sesion.apellido
      };
      userRole = sesion.rol;
      userProfile = sesion;
      currentPage = 'dashboard';
    } else {
      console.log('❌ No hay sesión activa');
    }
    
    loading = false;
  }

  // Manejar login exitoso
  function handleLogin(usuario, vistaDestino) {
    console.log('🔐 Login exitoso en App.svelte');
    console.log('Usuario:', usuario);
    console.log('Rol:', usuario.rol);
    console.log('Vista destino:', vistaDestino);
    
    currentUser = usuario;
    userRole = usuario.rol;
    userProfile = usuario;
    currentPage = 'dashboard';
    
    console.log('✅ Estado actualizado - userRole:', userRole);
  }

  // Cerrar sesión
  function handleLogout() {
    console.log('🚪 Cerrando sesión');
    cerrarSesion();
    currentUser = null;
    userRole = null;
    userProfile = null;
    currentPage = 'login';
  }
</script>

{#if loading}
  <div class="loading-screen">
    <div class="logo-loading">
      <div class="logo-icon-loading">
        <img src="./assets/Logo.png" alt="MediSync Logo">
      </div>
      <h2>MediSync</h2>
    </div>
    <div class="loading-spinner"></div>
    <p>Cargando...</p>
  </div>
{:else if !currentUser}
  {#if currentPage === 'login'}
    <Login onLogin={handleLogin} />
  {:else if currentPage === 'register'}
    <Register />
  {:else if currentPage === 'admin'}
    <AdminPanel />
  {:else if currentPage === 'forgot-password'}
    <ForgotPassword />
  {:else}
    <Login onLogin={handleLogin} />
  {/if}
{:else}
  {#if userRole === 'medico'}
    <DoctorView onLogout={handleLogout} />
  {:else if userRole === 'paciente'}
    <PatientView onLogout={handleLogout} />
  {:else}
    <div class="role-error">
      <h2>⚠️ Rol no reconocido</h2>
      <p>Rol detectado: <strong>{userRole || 'ninguno'}</strong></p>
      <p>Por favor contacta al administrador del sistema.</p>
      <button onclick={handleLogout}>Volver al inicio</button>
    </div>
  {/if}
{/if}

<style>
  :global(:root) {
    --color-50: #EEF7F6;
    --color-100: #CEE8E6;
    --color-200: #AFD9D5;
    --color-300: #90CBC5;
    --color-400: #71BCB5;
    --color-500: #4FA69E;
    --color-600: #438E87;
    --color-700: #346F69;
    --color-800: #26504C;
    --color-900: #17312E;
    --color-950: #081110;
  }

  :global(body) {
    margin: 0;
    padding: 0;
    font-family: system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
    background: var(--color-50);
  }

  .loading-screen {
    min-height: 100vh;
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    background: linear-gradient(135deg, var(--color-600) 0%, var(--color-800) 100%);
    color: white;
    gap: 30px;
  }

  .logo-loading {
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 15px;
  }

  .logo-icon-loading {
    width: 80px;
    height: 80px;
    background: white;
    border-radius: 50%;
    display: flex;
    align-items: center;
    justify-content: center;
    overflow: hidden;
    box-shadow: 0 5px 20px rgba(0, 0, 0, 0.2);
  }

  .logo-icon-loading img {
    width: 100%;
    height: 100%;
    object-fit: cover;
  }

  .logo-loading h2 {
    margin: 0;
    font-size: 32px;
    font-weight: 700;
  }

  .loading-spinner {
    width: 50px;
    height: 50px;
    border: 4px solid var(--color-300);
    border-top-color: white;
    border-radius: 50%;
    animation: spin 1s linear infinite;
  }

  @keyframes spin {
    to { transform: rotate(360deg); }
  }

  .loading-screen p {
    margin: 0;
    font-size: 16px;
    font-weight: 500;
  }

  .role-error {
    background: white;
    border-radius: 15px;
    padding: 40px;
    text-align: center;
    box-shadow: 0 5px 20px rgba(0, 0, 0, 0.1);
    max-width: 500px;
    margin: 40px auto;
  }

  .role-error h2 {
    color: var(--color-900);
    margin: 0 0 15px 0;
  }

  .role-error p {
    color: var(--color-700);
    margin: 0 0 15px 0;
  }

  .role-error strong {
    color: var(--color-600);
    font-weight: 700;
  }

  .role-error button {
    padding: 12px 30px;
    background: var(--color-500);
    color: white;
    border: none;
    border-radius: 8px;
    font-size: 15px;
    font-weight: 600;
    cursor: pointer;
    transition: all 0.3s;
    margin-top: 10px;
  }

  .role-error button:hover {
    background: var(--color-600);
    transform: translateY(-2px);
  }
</style>