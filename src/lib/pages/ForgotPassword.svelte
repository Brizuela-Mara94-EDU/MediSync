<script>
  import { supabase } from '../supabase/supabase-client.js';
  
  let email = $state('');
  let newPassword = $state('');
  let loading = $state(false);
  let errorMessage = $state('');
  let successMessage = $state('');

  async function handleSubmit(e) {
    e.preventDefault();
    errorMessage = '';
    successMessage = '';
    loading = true;

    try {
      console.log('Buscando usuario con email:', email);
      
      // Buscar el usuario por email (puede estar en usuarios o pacientes)
      let usuarioId = null;

      // Primero buscar en la tabla usuarios directamente
      const { data: usuarioDirecto, error: errorUsuario } = await supabase
        .from('usuarios')
        .select('id_usuario, nombre, apellido, rol')
        .eq('email', email)
        .maybeSingle();

      console.log('Resultado búsqueda en usuarios:', usuarioDirecto, errorUsuario);

      if (usuarioDirecto) {
        usuarioId = usuarioDirecto.id_usuario;
        console.log('Usuario encontrado:', usuarioDirecto);
      } else {
        // Si no está ahí, buscar en pacientes y obtener el id_usuario
        const { data: paciente, error: errorPaciente } = await supabase
          .from('pacientes')
          .select('id_usuario, id_paciente')
          .eq('email', email)
          .maybeSingle();

        console.log('Resultado búsqueda en pacientes:', paciente, errorPaciente);

        if (paciente) {
          usuarioId = paciente.id_usuario;
          console.log('Usuario encontrado vía paciente:', paciente);
        }
      }

      if (!usuarioId) {
        throw new Error('No se encontró un usuario con ese correo electrónico');
      }

      console.log('Actualizando contraseña para usuario ID:', usuarioId);

      // Llamar a función RPC que actualiza la contraseña con hash
      const { error: updateError } = await supabase
        .rpc('actualizar_contrasena', {
          p_id_usuario: usuarioId,
          p_nueva_contrasena: newPassword
        });

      if (updateError) {
        console.error('Error al actualizar:', updateError);
        throw updateError;
      }

      console.log('Contraseña actualizada con hash correctamente');

      successMessage = 'Contraseña actualizada correctamente';
      email = '';
      newPassword = '';

      // Redirigir al login después de 2 segundos
      setTimeout(() => {
        window.location.href = '/';
      }, 2000);

    } catch (error) {
      errorMessage = error.message || 'Error al actualizar la contraseña';
      console.error('Error:', error);
    } finally {
      loading = false;
    }
  }

  function goToLogin() {
    window.location.href = '/';
  }
</script>

<div class="forgot-container">
  <div class="forgot-card">
    <div class="logo">
      <div class="logo-icon">
        <img src="../../assets/Logo.png" alt="Logo de MediSync">
      </div>
      <h1>MediSync</h1>
      <p class="subtitle">Cambiar contraseña</p>
    </div>

    <p class="instructions">
      Ingresa tu correo electrónico y la nueva contraseña que deseas usar.
    </p>

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
      <div class="form-group">
        <label for="email">Correo electrónico</label>
        <input 
          type="email" 
          id="email" 
          bind:value={email}
          placeholder="ejemplo@correo.com"
          required
          disabled={loading}
        />
      </div>

      <div class="form-group">
        <label for="password">Nueva contraseña</label>
        <input 
          type="password" 
          id="password" 
          bind:value={newPassword}
          placeholder="Ingresa tu nueva contraseña"
          required
          disabled={loading}
          minlength="6"
        />
      </div>

      <button type="submit" class="submit-button" disabled={loading}>
        {loading ? 'Actualizando...' : 'Cambiar contraseña'}
      </button>
    </form>

    <div class="back-section">
      <button type="button" class="back-link" onclick={goToLogin}>
        ← Volver al inicio de sesión
      </button>
    </div>
  </div>
</div>

<style>
  .forgot-container {
    min-height: 100vh;
    display: flex;
    align-items: center;
    justify-content: center;
    background: linear-gradient(135deg, var(--color-600) 0%, var(--color-800) 100%);
    padding: 20px;
  }

  .forgot-card {
    background: white;
    border-radius: 20px;
    padding: 40px;
    width: 100%;
    max-width: 450px;
    box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
  }

  .logo {
    text-align: center;
    margin-bottom: 24px;
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
    margin: 0 0 8px 0;
    font-weight: 700;
  }

  .subtitle {
    color: var(--color-700);
    font-size: 16px;
    margin: 0;
  }

  .instructions {
    color: var(--color-700);
    font-size: 14px;
    line-height: 1.5;
    margin-bottom: 24px;
    text-align: center;
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

  .submit-button {
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

  .submit-button:hover:not(:disabled) {
    transform: translateY(-2px);
    box-shadow: 0 10px 20px rgba(79, 166, 158, 0.3);
  }

  .submit-button:active:not(:disabled) {
    transform: translateY(0);
  }

  .submit-button:disabled {
    opacity: 0.6;
    cursor: not-allowed;
  }

  .back-section {
    text-align: center;
    margin-top: 24px;
    padding-top: 24px;
    border-top: 1px solid var(--color-200);
  }

  .back-link {
    background: none;
    border: none;
    color: var(--color-600);
    font-size: 14px;
    font-weight: 500;
    cursor: pointer;
    transition: color 0.3s;
  }

  .back-link:hover {
    color: var(--color-700);
    text-decoration: underline;
  }
</style>