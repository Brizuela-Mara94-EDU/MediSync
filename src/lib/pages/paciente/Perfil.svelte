<script>
  import { onMount } from 'svelte';
  import { supabase } from '../../supabase/supabase-client.js';
  import SessionManager from '../../utils/SessionManager.js';

  let { onVolver } = $props();

  let loading = $state(false);
  let errorMessage = $state('');
  let successMessage = $state('');
  let showPassword = $state(false);
  
  // Datos del usuario
  let datosUsuario = $state({
    nombre: '',
    apellido: '',
    dni: '',
    email: '',
    telefono: '',
    fecha_nacimiento: ''
  });

  // Datos del paciente
  let datosPaciente = $state({
    domicilio: '',
    obra_social: '',
    grupo_sanguineo: ''
  });

  // Cambio de contraseña
  let cambioContrasena = $state({
    actual: '',
    nueva: '',
    confirmar: ''
  });

  let idUsuario = $state(null);
  let idPaciente = $state(null);

  onMount(async () => {
    await cargarDatos();
  });

  async function cargarDatos() {
    try {
      const sesion = SessionManager.obtenerSesion();
      if (!sesion?.id_usuario) return;

      idUsuario = sesion.id_usuario;

      // Obtener datos del usuario
      const { data: usuario, error: errorUsuario } = await supabase
        .from('usuarios')
        .select('nombre, apellido, dni, email, telefono, fecha_nacimiento')
        .eq('id_usuario', sesion.id_usuario)
        .single();

      if (errorUsuario) throw errorUsuario;

      datosUsuario = {
        nombre: usuario.nombre || '',
        apellido: usuario.apellido || '',
        dni: usuario.dni || '',
        email: usuario.email || '',
        telefono: usuario.telefono || '',
        fecha_nacimiento: usuario.fecha_nacimiento || ''
      };

      // Obtener datos del paciente
      const { data: paciente, error: errorPaciente } = await supabase
        .from('pacientes')
        .select('id_paciente, domicilio, obra_social, grupo_sanguineo')
        .eq('id_usuario', sesion.id_usuario)
        .single();

      if (errorPaciente) throw errorPaciente;

      idPaciente = paciente.id_paciente;
      datosPaciente = {
        domicilio: paciente.domicilio || '',
        obra_social: paciente.obra_social || '',
        grupo_sanguineo: paciente.grupo_sanguineo || ''
      };

    } catch (error) {
      console.error('Error cargando datos:', error);
      errorMessage = 'Error al cargar tus datos';
    }
  }

  async function guardarCambios(e) {
    e.preventDefault();
    errorMessage = '';
    successMessage = '';
    loading = true;

    try {
      // Actualizar tabla usuarios
      const { error: errorUsuario } = await supabase
        .from('usuarios')
        .update({
          nombre: datosUsuario.nombre,
          apellido: datosUsuario.apellido,
          dni: datosUsuario.dni,
          email: datosUsuario.email,
          telefono: datosUsuario.telefono,
          fecha_nacimiento: datosUsuario.fecha_nacimiento
        })
        .eq('id_usuario', idUsuario);

      if (errorUsuario) throw errorUsuario;

      // Actualizar tabla pacientes
      const { error: errorPaciente } = await supabase
        .from('pacientes')
        .update({
          domicilio: datosPaciente.domicilio,
          obra_social: datosPaciente.obra_social,
          grupo_sanguineo: datosPaciente.grupo_sanguineo
        })
        .eq('id_paciente', idPaciente);

      if (errorPaciente) throw errorPaciente;

      // Actualizar sesión en localStorage
      const sesionActual = SessionManager.obtenerSesion();
      const sesionActualizada = {
        ...sesionActual,
        nombre: datosUsuario.nombre,
        apellido: datosUsuario.apellido,
        email: datosUsuario.email
      };
      localStorage.setItem('medisync_session', JSON.stringify(sesionActualizada));

      successMessage = 'Datos actualizados correctamente';

      // Limpiar el mensaje después de 3 segundos
      setTimeout(() => {
        successMessage = '';
      }, 3000);

    } catch (error) {
      console.error('Error guardando cambios:', error);
      errorMessage = error.message || 'Error al guardar los cambios';
    } finally {
      loading = false;
    }
  }

  async function cambiarContrasena(e) {
    e.preventDefault();
    errorMessage = '';
    successMessage = '';

    // Validaciones
    if (cambioContrasena.nueva !== cambioContrasena.confirmar) {
      errorMessage = 'Las contraseñas nuevas no coinciden';
      return;
    }

    if (cambioContrasena.nueva.length < 6) {
      errorMessage = 'La contraseña debe tener al menos 6 caracteres';
      return;
    }

    loading = true;

    try {
      // Verificar contraseña actual
      const { data: validacion, error: errorValidacion } = await supabase
        .rpc('validar_login', {
          p_email: datosUsuario.email,
          p_contrasena: cambioContrasena.actual
        });

      if (errorValidacion) throw errorValidacion;

      if (!validacion || validacion.length === 0 || !validacion[0].exito) {
        throw new Error('La contraseña actual es incorrecta');
      }

      // Actualizar contraseña con hash
      const { error: errorUpdate } = await supabase
        .rpc('actualizar_contrasena', {
          p_id_usuario: idUsuario,
          p_nueva_contrasena: cambioContrasena.nueva
        });

      if (errorUpdate) throw errorUpdate;

      successMessage = 'Contraseña actualizada correctamente';
      
      // Limpiar campos
      cambioContrasena = {
        actual: '',
        nueva: '',
        confirmar: ''
      };

      // Limpiar mensaje después de 3 segundos
      setTimeout(() => {
        successMessage = '';
      }, 3000);

    } catch (error) {
      console.error('Error cambiando contraseña:', error);
      errorMessage = error.message || 'Error al cambiar la contraseña';
    } finally {
      loading = false;
    }
  }
</script>

<div class="perfil-container">
  <button class="btn-volver" onclick={onVolver} aria-label="Volver a home">
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
      <path d="M19 12H5M12 19l-7-7 7-7"/>
    </svg>
  </button>
  
  <div class="perfil-header">
    <h1>Mi Perfil</h1>
    <p>Gestiona tu información personal y de contacto</p>
  </div>

  {#if errorMessage}
    <div class="alert alert-error">
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
        <circle cx="12" cy="12" r="10"/>
        <line x1="12" x2="12" y1="8" y2="12"/>
        <line x1="12" x2="12.01" y1="16" y2="16"/>
      </svg>
      {errorMessage}
    </div>
  {/if}

  {#if successMessage}
    <div class="alert alert-success">
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
        <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/>
        <polyline points="22 4 12 14.01 9 11.01"/>
      </svg>
      {successMessage}
    </div>
  {/if}

  <form class="perfil-form" onsubmit={guardarCambios}>
    <div class="section-card">
      <h2>Datos Personales</h2>
      
      <div class="form-row">
        <div class="form-group">
          <label for="nombre">Nombre</label>
          <input 
            type="text" 
            id="nombre" 
            bind:value={datosUsuario.nombre}
            required
            disabled={loading}
          />
        </div>

        <div class="form-group">
          <label for="apellido">Apellido</label>
          <input 
            type="text" 
            id="apellido" 
            bind:value={datosUsuario.apellido}
            required
            disabled={loading}
          />
        </div>
      </div>

      <div class="form-row">
        <div class="form-group">
          <label for="dni">DNI</label>
          <input 
            type="text" 
            id="dni" 
            bind:value={datosUsuario.dni}
            required
            disabled={loading}
          />
        </div>

        <div class="form-group">
          <label for="fecha_nacimiento">Fecha de Nacimiento</label>
          <input 
            type="date" 
            id="fecha_nacimiento" 
            bind:value={datosUsuario.fecha_nacimiento}
            required
            disabled={loading}
          />
        </div>
      </div>
    </div>

    <div class="section-card">
      <h2>Información de Contacto</h2>
      
      <div class="form-row">
        <div class="form-group">
          <label for="email">Correo Electrónico</label>
          <input 
            type="email" 
            id="email" 
            bind:value={datosUsuario.email}
            required
            disabled={loading}
          />
        </div>

        <div class="form-group">
          <label for="telefono">Teléfono</label>
          <input 
            type="tel" 
            id="telefono" 
            bind:value={datosUsuario.telefono}
            disabled={loading}
          />
        </div>
      </div>

      <div class="form-group">
        <label for="domicilio">Domicilio</label>
        <input 
          type="text" 
          id="domicilio" 
          bind:value={datosPaciente.domicilio}
          disabled={loading}
        />
      </div>
    </div>

    <div class="section-card">
      <h2>Información Médica</h2>
      
      <div class="form-row">
        <div class="form-group">
          <label for="obra_social">Obra Social</label>
          <input 
            type="text" 
            id="obra_social" 
            bind:value={datosPaciente.obra_social}
            disabled={loading}
          />
        </div>

        <div class="form-group">
          <label for="grupo_sanguineo">Grupo Sanguíneo</label>
          <select 
            id="grupo_sanguineo" 
            bind:value={datosPaciente.grupo_sanguineo}
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

    <div class="form-actions">
      <button type="submit" class="btn-primary" disabled={loading}>
        {loading ? 'Guardando...' : 'Guardar Cambios'}
      </button>
    </div>
  </form>

  <form class="password-form" onsubmit={cambiarContrasena}>
    <div class="section-card">
      <h2>Cambiar Contraseña</h2>
      
      <div class="form-group">
        <label for="contrasena_actual">Contraseña Actual</label>
        <div class="password-input">
          <input 
            type={showPassword ? 'text' : 'password'}
            id="contrasena_actual" 
            bind:value={cambioContrasena.actual}
            disabled={loading}
          />
          <button 
            type="button" 
            class="toggle-password"
            onclick={() => showPassword = !showPassword}
          >
            {#if showPassword}
              <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19m-6.72-1.07a3 3 0 1 1-4.24-4.24"/>
                <line x1="1" x2="23" y1="1" y2="23"/>
              </svg>
            {:else}
              <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/>
                <circle cx="12" cy="12" r="3"/>
              </svg>
            {/if}
          </button>
        </div>
      </div>

      <div class="form-group">
        <label for="contrasena_nueva">Nueva Contraseña</label>
        <input 
          type={showPassword ? 'text' : 'password'}
          id="contrasena_nueva" 
          bind:value={cambioContrasena.nueva}
          minlength="6"
          disabled={loading}
        />
      </div>

      <div class="form-group">
        <label for="contrasena_confirmar">Confirmar Nueva Contraseña</label>
        <input 
          type={showPassword ? 'text' : 'password'}
          id="contrasena_confirmar" 
          bind:value={cambioContrasena.confirmar}
          minlength="6"
          disabled={loading}
        />
      </div>

      <div class="form-actions">
        <button type="submit" class="btn-secondary" disabled={loading}>
          {loading ? 'Cambiando...' : 'Cambiar Contraseña'}
        </button>
      </div>
    </div>
  </form>
</div>

<style>
  .perfil-container {
    max-width: 900px;
    margin: 0 auto;
    padding: 20px;
  }

  .btn-volver {
    display: inline-flex;
    align-items: center;
    gap: 8px;
    padding: 10px 20px;
    background: white;
    border: 2px solid var(--color-600);
    border-radius: 10px;
    color: var(--color-700);
    font-size: 15px;
    font-weight: 600;
    cursor: pointer;
    transition: all 0.2s;
    margin-bottom: 16px;
  }

  .btn-volver:hover {
    background: var(--color-600);
    color: white;
    transform: translateX(-4px);
  }

  .btn-volver svg {
    width: 20px;
    height: 20px;
  }

  .perfil-header {
    margin-bottom: 24px;
  }

  .perfil-header h1 {
    margin: 0 0 8px 0;
    font-size: 28px;
    color: #1e293b;
    font-weight: 700;
  }

  .perfil-header p {
    margin: 0;
    color: #64748b;
    font-size: 15px;
  }

  .alert {
    padding: 14px 16px;
    border-radius: 12px;
    margin-bottom: 20px;
    display: flex;
    align-items: center;
    gap: 12px;
    font-size: 14px;
    font-weight: 500;
  }

  .alert svg {
    width: 20px;
    height: 20px;
    flex-shrink: 0;
  }

  .alert-error {
    background: #fef2f2;
    color: #dc2626;
    border: 1px solid #fecaca;
  }

  .alert-success {
    background: #f0fdf4;
    color: #16a34a;
    border: 1px solid #bbf7d0;
  }

  .perfil-form,
  .password-form {
    margin-bottom: 24px;
  }

  .section-card {
    background: white;
    border-radius: 16px;
    padding: 24px;
    margin-bottom: 20px;
    box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
  }

  .section-card h2 {
    margin: 0 0 20px 0;
    font-size: 18px;
    color: #1e293b;
    font-weight: 600;
    padding-bottom: 12px;
    border-bottom: 2px solid #e2e8f0;
  }

  .form-row {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 16px;
    margin-bottom: 16px;
  }

  .form-group {
    margin-bottom: 16px;
  }

  .form-group:last-child {
    margin-bottom: 0;
  }

  label {
    display: block;
    margin-bottom: 8px;
    color: #475569;
    font-weight: 500;
    font-size: 14px;
  }

  input,
  select {
    width: 100%;
    padding: 12px 16px;
    border: 2px solid #e2e8f0;
    border-radius: 10px;
    font-size: 15px;
    transition: all 0.3s;
    box-sizing: border-box;
    color: #1e293b;
  }

  input:focus,
  select:focus {
    outline: none;
    border-color: var(--color-600);
    box-shadow: 0 0 0 3px var(--color-100);
  }

  input:disabled,
  select:disabled {
    background: #f8fafc;
    cursor: not-allowed;
    opacity: 0.6;
  }

  .password-input {
    position: relative;
  }

  .password-input input {
    padding-right: 48px;
  }

  .toggle-password {
    position: absolute;
    right: 12px;
    top: 50%;
    transform: translateY(-50%);
    background: none;
    border: none;
    color: #64748b;
    cursor: pointer;
    padding: 4px;
    display: flex;
    align-items: center;
    justify-content: center;
    transition: color 0.2s;
  }

  .toggle-password:hover {
    color: var(--color-600);
  }

  .toggle-password svg {
    width: 20px;
    height: 20px;
  }

  .form-actions {
    margin-top: 24px;
    display: flex;
    justify-content: flex-end;
  }

  .btn-primary,
  .btn-secondary {
    padding: 12px 32px;
    border: none;
    border-radius: 10px;
    font-size: 15px;
    font-weight: 600;
    cursor: pointer;
    transition: all 0.2s;
  }

  .btn-primary {
    background: linear-gradient(135deg, var(--color-600) 0%, var(--color-500) 100%);
    color: white;
  }

  .btn-primary:hover:not(:disabled) {
    transform: translateY(-2px);
    box-shadow: 0 10px 20px rgba(67, 142, 135, 0.3);
  }

  .btn-secondary {
    background: white;
    color: var(--color-600);
    border: 2px solid var(--color-600);
  }

  .btn-secondary:hover:not(:disabled) {
    background: var(--color-600);
    color: white;
    transform: translateY(-2px);
    box-shadow: 0 10px 20px rgba(67, 142, 135, 0.3);
  }

  .btn-primary:disabled,
  .btn-secondary:disabled {
    opacity: 0.5;
    cursor: not-allowed;
  }

  @media (max-width: 768px) {
    .perfil-container {
      padding: 16px;
    }

    .perfil-header h1 {
      font-size: 24px;
    }

    .section-card {
      padding: 20px;
    }

    .form-row {
      grid-template-columns: 1fr;
      gap: 0;
    }

    .form-actions {
      justify-content: stretch;
    }

    .btn-primary,
    .btn-secondary {
      width: 100%;
    }
  }
</style>
