<script>
  import { supabase } from '../supabase/supabase-client.js';
  
  let email = $state('');
  let password = $state('');
  let loading = $state(false);
  let errorMessage = $state('');
  
  // Props del componente
  let { onLogin } = $props();

  async function handleSubmit(e) {
    e.preventDefault();
    errorMessage = '';
    loading = true;

    try {
      console.log('Intentando iniciar sesión...');

      // Llamar a la función RPC para validar login
      const { data, error } = await supabase
        .rpc('validar_login', {
          p_email: email,
          p_contrasena: password
        });

      if (error) {
        console.error('Error al validar login:', error);
        throw new Error(error.message);
      }

      // Verificar si se recibió algún resultado
      if (!data || data.length === 0) {
        throw new Error('Usuario no encontrado');
      }

      const usuario = data[0];

      // Verificar si el login fue exitoso
      if (!usuario.exito) {
        throw new Error('Contraseña incorrecta');
      }

      console.log('✅ Login exitoso:', usuario.email);

      // Obtener información adicional según el rol
      let datosAdicionales = null;

      if (usuario.rol === 'paciente') {
        const { data: pacienteData } = await supabase
          .from('pacientes')
          .select('*')
          .eq('id_usuario', usuario.id_usuario)
          .single();
        
        datosAdicionales = pacienteData;
      } else if (usuario.rol === 'medico') {
        const { data: medicoData } = await supabase
          .from('medicos')
          .select('*')
          .eq('id_usuario', usuario.id_usuario)
          .single();
        
        datosAdicionales = medicoData;
      }

      console.log('Datos adicionales:', datosAdicionales);

      // Guardar sesión en localStorage
      const sesion = {
        id_usuario: usuario.id_usuario,
        email: usuario.email,
        nombre: usuario.nombre,
        apellido: usuario.apellido,
        rol: usuario.rol,
        timestamp: Date.now()
      };
      
      localStorage.setItem('medisync_session', JSON.stringify(sesion));

      // Llamar al callback de login exitoso
      onLogin(usuario, datosAdicionales);

    } catch (error) {
      console.error('❌ Error en login:', error);
      
      // Mensajes de error más descriptivos
      if (error.message.includes('Usuario no encontrado')) {
        errorMessage = 'El correo electrónico no está registrado';
      } else if (error.message.includes('Contraseña incorrecta')) {
        errorMessage = 'Contraseña incorrecta';
      } else if (error.message.includes('email')) {
        errorMessage = 'El formato del correo electrónico no es válido';
      } else {
        errorMessage = error.message || 'Error al iniciar sesión. Intenta nuevamente.';
      }
    } finally {
      loading = false;
    }
  }

  function goToRegister() {
    window.dispatchEvent(new CustomEvent('navigate', { detail: 'register' }));
  }

  function goToForgotPassword() {
    window.dispatchEvent(new CustomEvent('navigate', { detail: 'forgot-password' }));
  }

  function goToAdmin() {
    window.dispatchEvent(new CustomEvent('navigate', { detail: 'admin' }));
  }
</script>

<div class="login-container">
  <div class="login-card">
    <div class="logo">
      <div class="logo-icon">
          <img src="../../../src/assets/Logo.png" alt="MediSync">
      </div>
      <h1>MediSync</h1>
    </div>

    {#if errorMessage}
      <div class="error-message">
        {errorMessage}
      </div>
    {/if}

    <form onsubmit={handleSubmit}>
      <div class="form-group">
        <label for="email">Correo electrónico</label>
        <input 
          type="email" 
          id="email" 
          bind:value={email}
          placeholder="ejemplo@correo.com"
          required
          disabled={loading}
          autocomplete="email"
        />
      </div>

      <div class="form-group">
        <label for="password">Contraseña</label>
        <input 
          type="password" 
          id="password" 
          bind:value={password}
          placeholder="••••••••"
          required
          disabled={loading}
          autocomplete="current-password"
        />
      </div>

      <button type="button" class="forgot-password-link" onclick={goToForgotPassword}>
        ¿Olvidaste tu contraseña?
      </button>

      <button type="submit" class="login-button" disabled={loading}>
        {loading ? 'Iniciando sesión...' : 'Iniciar Sesión'}
      </button>
    </form>

    <div class="register-section">
      <p>¿No tienes una cuenta?</p>
      <button type="button" class="register-link" onclick={goToRegister}>
        Registrarse
      </button>
    </div>

    <div class="admin-section">
      <button type="button" class="admin-link" onclick={goToAdmin}>
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <path d="M12.22 2h-.44a2 2 0 0 0-2 2v.18a2 2 0 0 1-1 1.73l-.43.25a2 2 0 0 1-2 0l-.15-.08a2 2 0 0 0-2.73.73l-.22.38a2 2 0 0 0 .73 2.73l.15.1a2 2 0 0 1 1 1.72v.51a2 2 0 0 1-1 1.74l-.15.09a2 2 0 0 0-.73 2.73l.22.38a2 2 0 0 0 2.73.73l.15-.08a2 2 0 0 1 2 0l.43.25a2 2 0 0 1 1 1.73V20a2 2 0 0 0 2 2h.44a2 2 0 0 0 2-2v-.18a2 2 0 0 1 1-1.73l.43-.25a2 2 0 0 1 2 0l.15.08a2 2 0 0 0 2.73-.73l.22-.39a2 2 0 0 0-.73-2.73l-.15-.08a2 2 0 0 1-1-1.74v-.5a2 2 0 0 1 1-1.74l.15-.09a2 2 0 0 0 .73-2.73l-.22-.38a2 2 0 0 0-2.73-.73l-.15.08a2 2 0 0 1-2 0l-.43-.25a2 2 0 0 1-1-1.73V4a2 2 0 0 0-2-2z"/>
          <circle cx="12" cy="12" r="3"/>
        </svg>
        Panel de Administración
      </button>
    </div>
  </div>
</div>

<style>
  .login-container {
    min-height: 100vh;
    display: flex;
    align-items: center;
    justify-content: center;
    background: linear-gradient(135deg, var(--color-600) 0%, var(--color-800) 100%);
    padding: 20px;
  }

  .login-card {
    background: white;
    border-radius: 20px;
    padding: 40px;
    width: 100%;
    max-width: 400px;
    box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
  }

  .logo {
    text-align: center;
    margin-bottom: 40px;
  }

  .logo-icon {
    width: 80px;
    height: 80px;
    margin: 0 auto 16px;
    background: var(--color-500);
    border-radius: 50%;
    display: flex;
    align-items: center;
    justify-content: center;
    overflow: hidden;
  }

  .logo-icon img {
    width: 100%;
    height: 100%;
    object-fit: cover;
  }

  h1 {
    font-size: 28px;
    color: var(--color-900);
    margin: 0;
    font-weight: 700;
  }

  .error-message {
    background: #fee;
    color: #c33;
    padding: 12px;
    border-radius: 8px;
    margin-bottom: 20px;
    font-size: 14px;
    text-align: center;
  }

  .form-group {
    margin-bottom: 24px;
  }

  label {
    display: block;
    margin-bottom: 8px;
    color: var(--color-800);
    font-weight: 500;
    font-size: 14px;
  }

  input {
    width: 100%;
    padding: 12px 16px;
    border: 2px solid var(--color-200);
    border-radius: 10px;
    font-size: 16px;
    transition: all 0.3s;
    box-sizing: border-box;
  }

  input:focus {
    outline: none;
    border-color: var(--color-500);
    box-shadow: 0 0 0 3px var(--color-100);
  }

  input:disabled {
    background: #f5f5f5;
    cursor: not-allowed;
  }

  .forgot-password-link {
    background: none;
    border: none;
    color: var(--color-600);
    font-size: 14px;
    cursor: pointer;
    padding: 0;
    margin-bottom: 16px;
    text-decoration: underline;
    display: block;
    width: 100%;
    text-align: right;
  }

  .forgot-password-link:hover {
    color: var(--color-700);
  }

  .login-button {
    width: 100%;
    padding: 14px;
    background: linear-gradient(135deg, var(--color-500) 0%, var(--color-700) 100%);
    color: white;
    border: none;
    border-radius: 10px;
    font-size: 16px;
    font-weight: 600;
    cursor: pointer;
    transition: transform 0.2s, box-shadow 0.2s;
  }

  .login-button:hover:not(:disabled) {
    transform: translateY(-2px);
    box-shadow: 0 10px 20px rgba(79, 166, 158, 0.3);
  }

  .login-button:active:not(:disabled) {
    transform: translateY(0);
  }

  .login-button:disabled {
    opacity: 0.6;
    cursor: not-allowed;
  }

  .register-section {
    text-align: center;
    margin-top: 24px;
    padding-top: 24px;
    border-top: 1px solid var(--color-200);
  }

  .register-section p {
    color: var(--color-700);
    font-size: 14px;
    margin: 0 0 12px 0;
  }

  .register-link {
    background: none;
    border: 2px solid var(--color-500);
    color: var(--color-600);
    padding: 10px 24px;
    border-radius: 10px;
    font-size: 14px;
    font-weight: 600;
    cursor: pointer;
    transition: all 0.3s;
  }

  .register-link:hover {
    background: var(--color-500);
    color: white;
  }

  .admin-section {
    text-align: center;
    margin-top: 16px;
    padding-top: 16px;
    border-top: 1px solid var(--color-200);
  }

  .admin-link {
    display: inline-flex;
    align-items: center;
    gap: 8px;
    background: linear-gradient(135deg, #6366f1 0%, #4f46e5 100%);
    border: none;
    color: white;
    padding: 10px 20px;
    border-radius: 8px;
    font-size: 13px;
    font-weight: 600;
    cursor: pointer;
    transition: all 0.3s;
  }

  .admin-link svg {
    width: 16px;
    height: 16px;
  }

  .admin-link:hover {
    transform: translateY(-2px);
    box-shadow: 0 6px 20px rgba(99, 102, 241, 0.4);
  }
</style>