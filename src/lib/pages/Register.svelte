<script>
  import { supabase } from '../supabase/supabase-client.js';
  
  let email = $state('');
  let password = $state('');
  let confirmPassword = $state('');
  let nombre = $state('');
  let apellido = $state('');
  let dni = $state('');
  let fechaNacimiento = $state('');
  let telefono = $state('');
  let rol = $state('paciente');
  
  // Campos específicos para médicos
  let matricula = $state('');
  let especialidad = $state('');
  
  // Campos específicos para pacientes
  let obraSocial = $state('');
  let grupoSanguineo = $state('');
  
  let loading = $state(false);
  let errorMessage = $state('');
  let successMessage = $state('');

  async function handleSubmit(e) {
    e.preventDefault();
    errorMessage = '';
    successMessage = '';

    // Validaciones
    if (password !== confirmPassword) {
      errorMessage = 'Las contraseñas no coinciden';
      return;
    }

    if (password.length < 6) {
      errorMessage = 'La contraseña debe tener al menos 6 caracteres';
      return;
    }

    if (!fechaNacimiento) {
      errorMessage = 'La fecha de nacimiento es obligatoria';
      return;
    }

    if (!nombre || !apellido || !dni) {
      errorMessage = 'Todos los campos obligatorios deben estar completos';
      return;
    }

    if (rol === 'medico' && !matricula) {
      errorMessage = 'La matrícula es obligatoria para médicos';
      return;
    }

    loading = true;

    try {
      console.log('Iniciando registro...');

      // 1. Llamar a la función RPC para registrar usuario
      const { data: usuarioData, error: usuarioError } = await supabase
        .rpc('registrar_usuario', {
          p_email: email,
          p_contrasena: password,
          p_nombre: nombre,
          p_apellido: apellido,
          p_dni: dni,
          p_fecha_nacimiento: fechaNacimiento,
          p_telefono: telefono || null,
          p_rol: rol
        });

      if (usuarioError) {
        console.error('Error al registrar usuario:', usuarioError);
        throw new Error(usuarioError.message);
      }

      const usuarioId = usuarioData;
      console.log('✅ Usuario creado con ID:', usuarioId);

      // 2. Crear registro específico según el rol
      if (rol === 'paciente') {
        const { error: pacienteError } = await supabase
          .from('pacientes')
          .insert({
            id_usuario: usuarioId,
            obra_social: obraSocial || null,
            grupo_sanguineo: grupoSanguineo || null
          });

        if (pacienteError) {
          console.error('Error al crear paciente:', pacienteError);
          throw new Error('Error al crear el perfil de paciente');
        }
        console.log('✅ Paciente creado');

      } else if (rol === 'medico') {
        const { error: medicoError } = await supabase
          .from('medicos')
          .insert({
            id_usuario: usuarioId,
            matricula: matricula,
            especialidad: especialidad || null
          });

        if (medicoError) {
          console.error('Error al crear médico:', medicoError);
          throw new Error('Error al crear el perfil de médico');
        }
        console.log('✅ Médico creado');
      }

      successMessage = '¡Registro exitoso! Redirigiendo al inicio de sesión...';
      
      // Limpiar formulario
      email = '';
      password = '';
      confirmPassword = '';
      nombre = '';
      apellido = '';
      dni = '';
      fechaNacimiento = '';
      telefono = '';
      matricula = '';
      especialidad = '';
      obraSocial = '';
      grupoSanguineo = '';
      rol = 'paciente';

      // Redirigir al login después de 2 segundos
      setTimeout(() => {
        goToLogin();
      }, 2000);

    } catch (error) {
      console.error('❌ Error en el registro:', error);
      
      if (error.message.includes('duplicate key') || error.message.includes('already exists')) {
        errorMessage = 'El correo electrónico o DNI ya está registrado';
      } else if (error.message.includes('email')) {
        errorMessage = 'El formato del correo electrónico no es válido';
      } else {
        errorMessage = error.message || 'Error al registrarse. Por favor, intenta nuevamente.';
      }
    } finally {
      loading = false;
    }
  }

  function goToLogin() {
    window.dispatchEvent(new CustomEvent('navigate', { detail: 'login' }));
  }

  function goToAdmin() {
    window.dispatchEvent(new CustomEvent('navigate', { detail: 'admin' }));
  }
</script>

<div class="register-container">
  <div class="register-card">
    <div class="logo">
      <div class="logo-icon">
        <img src="../../assets/Logo.png" alt="Logo de MediSync">
      </div>
      <h1>MediSync</h1>
      <p class="subtitle">Crear nueva cuenta</p>
    </div>

    {#if errorMessage}
      <div class="error-message">
        {errorMessage}
      </div>
    {/if}

    {#if successMessage}
      <div class="success-message">
        {successMessage}
      </div>
    {/if}

    <form onsubmit={handleSubmit}>
      <!-- Selector de Rol -->
      <div class="form-group">
        <span class="label-text">Tipo de cuenta</span>
        <div class="role-selector">
          <button 
            type="button"
            class="role-btn {rol === 'paciente' ? 'active' : ''}"
            onclick={() => rol = 'paciente'}
            disabled={loading}
          >
            👤 Paciente
          </button>
          <button 
            type="button"
            class="role-btn {rol === 'medico' ? 'active' : ''}"
            onclick={() => rol = 'medico'}
            disabled={loading}
          >
            👨‍⚕️ Médico
          </button>
        </div>
      </div>

      <!-- Datos Personales -->
      <div class="form-row">
        <div class="form-group">
          <label for="nombre">Nombre *</label>
          <input 
            type="text" 
            id="nombre" 
            bind:value={nombre}
            placeholder="Juan"
            required
            disabled={loading}
          />
        </div>

        <div class="form-group">
          <label for="apellido">Apellido *</label>
          <input 
            type="text" 
            id="apellido" 
            bind:value={apellido}
            placeholder="Pérez"
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
            bind:value={dni}
            placeholder="12345678"
            required
            disabled={loading}
          />
        </div>

        <div class="form-group">
          <label for="fechaNacimiento">Fecha de Nacimiento *</label>
          <input 
            type="date" 
            id="fechaNacimiento" 
            bind:value={fechaNacimiento}
            required
            disabled={loading}
          />
        </div>
      </div>

      <div class="form-group">
        <label for="telefono">Teléfono</label>
        <input 
          type="tel" 
          id="telefono" 
          bind:value={telefono}
          placeholder="+54 9 11 1234-5678"
          disabled={loading}
        />
      </div>

      <div class="form-group">
        <label for="email">Correo electrónico *</label>
        <input 
          type="email" 
          id="email" 
          bind:value={email}
          placeholder="ejemplo@correo.com"
          required
          disabled={loading}
        />
      </div>

      <!-- Campos específicos para Médicos -->
      {#if rol === 'medico'}
        <div class="specific-fields">
          <h3>Datos profesionales</h3>
          <div class="form-group">
            <label for="matricula">Matrícula Profesional *</label>
            <input 
              type="text" 
              id="matricula" 
              bind:value={matricula}
              placeholder="MP 12345"
              required
              disabled={loading}
            />
          </div>

          <div class="form-group">
            <label for="especialidad">Especialidad</label>
            <input 
              type="text" 
              id="especialidad" 
              bind:value={especialidad}
              placeholder="Cardiología, Pediatría, etc."
              disabled={loading}
            />
          </div>
        </div>
      {/if}

      <!-- Campos específicos para Pacientes -->
      {#if rol === 'paciente'}
        <div class="specific-fields">
          <h3>Datos médicos</h3>
          <div class="form-row">
            <div class="form-group">
              <label for="obraSocial">Obra Social</label>
              <input 
                type="text" 
                id="obraSocial" 
                bind:value={obraSocial}
                placeholder="OSDE, Swiss Medical, etc."
                disabled={loading}
              />
            </div>

            <div class="form-group">
              <label for="grupoSanguineo">Grupo Sanguíneo</label>
              <select 
                id="grupoSanguineo" 
                bind:value={grupoSanguineo}
                disabled={loading}
              >
                <option value="">Seleccionar</option>
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
      {/if}

      <!-- Contraseña -->
      <div class="form-group">
        <label for="password">Contraseña *</label>
        <input 
          type="password" 
          id="password" 
          bind:value={password}
          placeholder="••••••••"
          required
          disabled={loading}
          minlength="6"
        />
        <small>Mínimo 6 caracteres</small>
      </div>

      <div class="form-group">
        <label for="confirmPassword">Confirmar contraseña *</label>
        <input 
          type="password" 
          id="confirmPassword" 
          bind:value={confirmPassword}
          placeholder="••••••••"
          required
          disabled={loading}
        />
      </div>

      <button type="submit" class="register-button" disabled={loading}>
        {loading ? 'Registrando...' : 'Registrarse'}
      </button>
    </form>

    <div class="login-section">
      <p>¿Ya tienes una cuenta?</p>
      <button type="button" class="login-link" onclick={goToLogin}>
        Iniciar Sesión
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
  .register-container {
    min-height: 100vh;
    display: flex;
    align-items: center;
    justify-content: center;
    background: linear-gradient(135deg, var(--color-600) 0%, var(--color-800) 100%);
    padding: 40px 20px;
  }

  .register-card {
    background: white;
    border-radius: 20px;
    padding: 40px;
    width: 100%;
    max-width: 600px;
    box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
    max-height: 90vh;
    overflow-y: auto;
  }

  .logo {
    text-align: center;
    margin-bottom: 30px;
  }

  .logo-icon {
    width: 70px;
    height: 70px;
    margin: 0 auto 12px;
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
    font-size: 26px;
    color: var(--color-900);
    margin: 0 0 6px 0;
    font-weight: 700;
  }

  .subtitle {
    color: var(--color-700);
    font-size: 15px;
    margin: 0;
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

  .success-message {
    background: #efe;
    color: #373;
    padding: 12px;
    border-radius: 8px;
    margin-bottom: 20px;
    font-size: 14px;
    text-align: center;
  }

  .role-selector {
    display: flex;
    gap: 10px;
  }

  .role-btn {
    flex: 1;
    padding: 12px;
    border: 2px solid var(--color-300);
    background: white;
    border-radius: 8px;
    cursor: pointer;
    font-size: 14px;
    font-weight: 600;
    transition: all 0.3s;
    color: var(--color-700);
  }

  .role-btn:hover:not(:disabled) {
    border-color: var(--color-500);
    background: var(--color-50);
  }

  .role-btn.active {
    border-color: var(--color-500);
    background: var(--color-500);
    color: white;
  }

  .role-btn:disabled {
    opacity: 0.5;
    cursor: not-allowed;
  }

  .form-row {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 15px;
  }

  .form-group {
    margin-bottom: 18px;
  }

  label {
    display: block;
    margin-bottom: 6px;
    color: var(--color-800);
    font-weight: 500;
    font-size: 14px;
  }

  .label-text {
    display: block;
    margin-bottom: 6px;
    color: var(--color-800);
    font-weight: 500;
    font-size: 14px;
  }

  input, select {
    width: 100%;
    padding: 10px 14px;
    border: 2px solid var(--color-200);
    border-radius: 8px;
    font-size: 15px;
    transition: all 0.3s;
    box-sizing: border-box;
  }

  input:focus, select:focus {
    outline: none;
    border-color: var(--color-500);
    box-shadow: 0 0 0 3px var(--color-100);
  }

  input:disabled, select:disabled {
    background: #f5f5f5;
    cursor: not-allowed;
  }

  small {
    display: block;
    color: var(--color-600);
    font-size: 12px;
    margin-top: 4px;
  }

  .specific-fields {
    background: var(--color-50);
    padding: 20px;
    border-radius: 10px;
    margin-bottom: 20px;
  }

  .specific-fields h3 {
    margin: 0 0 15px 0;
    font-size: 16px;
    color: var(--color-900);
  }

  .register-button {
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
    margin-top: 10px;
  }

  .register-button:hover:not(:disabled) {
    transform: translateY(-2px);
    box-shadow: 0 10px 20px rgba(79, 166, 158, 0.3);
  }

  .register-button:active:not(:disabled) {
    transform: translateY(0);
  }

  .register-button:disabled {
    opacity: 0.6;
    cursor: not-allowed;
  }

  .login-section {
    text-align: center;
    margin-top: 20px;
    padding-top: 20px;
    border-top: 1px solid var(--color-200);
  }

  .login-section p {
    color: var(--color-700);
    font-size: 14px;
    margin: 0 0 10px 0;
  }

  .login-link {
    background: none;
    border: 2px solid var(--color-500);
    color: var(--color-600);
    padding: 8px 20px;
    border-radius: 8px;
    font-size: 14px;
    font-weight: 600;
    cursor: pointer;
    transition: all 0.3s;
  }

  .login-link:hover {
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

  @media (max-width: 600px) {
    .form-row {
      grid-template-columns: 1fr;
    }

    .register-card {
      padding: 30px 20px;
    }
  }
</style>