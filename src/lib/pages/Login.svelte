<script>
  let email = $state('');
  let password = $state('');
  let { onLogin = (email) => {} } = $props();
  
  function handleSubmit(e) {
    e.preventDefault();
    if (email && password) {
      onLogin(email);
    }
  }
</script>

<div class="login-container">
  <div class="login-card">
    <div class="logo">
      <div class="logo-icon">
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <path d="M19 14c1.49-1.46 3-3.21 3-5.5A5.5 5.5 0 0 0 16.5 3c-1.76 0-3 .5-4.5 2-1.5-1.5-2.74-2-4.5-2A5.5 5.5 0 0 0 2 8.5c0 2.3 1.5 4.05 3 5.5l7 7Z"/>
        </svg>
      </div>
      <h1>MediCare</h1>
    </div>
    
    <form onsubmit={handleSubmit}>
      <div class="form-group">
        <label for="email">Correo electrónico</label>
        <input 
          type="email" 
          id="email" 
          bind:value={email}
          placeholder="ejemplo@correo.com"
          required
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
        />
      </div>
      
      <button type="submit" class="login-button">
        Iniciar Sesión
      </button>
    </form>
    
    <p class="hint">Prueba con:<br/>paciente@gmail.com o medico@gmail.com</p>
  </div>
</div>

<style>
  .login-container {
    min-height: 100vh;
    display: flex;
    align-items: center;
    justify-content: center;
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
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
    width: 60px;
    height: 60px;
    margin: 0 auto 16px;
    background: linear-gradient(135deg, #3b82f6 0%, #06b6d4 100%);
    border-radius: 50%;
    display: flex;
    align-items: center;
    justify-content: center;
    color: white;
  }
  
  .logo-icon svg {
    width: 32px;
    height: 32px;
  }
  
  h1 {
    font-size: 28px;
    color: #1e293b;
    margin: 0;
    font-weight: 700;
  }
  
  .form-group {
    margin-bottom: 24px;
  }
  
  label {
    display: block;
    margin-bottom: 8px;
    color: #475569;
    font-weight: 500;
    font-size: 14px;
  }
  
  input {
    width: 100%;
    padding: 12px 16px;
    border: 2px solid #e2e8f0;
    border-radius: 10px;
    font-size: 16px;
    transition: all 0.3s;
    box-sizing: border-box;
  }
  
  input:focus {
    outline: none;
    border-color: #3b82f6;
    box-shadow: 0 0 0 3px rgba(59, 130, 246, 0.1);
  }
  
  .login-button {
    width: 100%;
    padding: 14px;
    background: linear-gradient(135deg, #3b82f6 0%, #06b6d4 100%);
    color: white;
    border: none;
    border-radius: 10px;
    font-size: 16px;
    font-weight: 600;
    cursor: pointer;
    transition: transform 0.2s, box-shadow 0.2s;
    margin-top: 8px;
  }
  
  .login-button:hover {
    transform: translateY(-2px);
    box-shadow: 0 10px 20px rgba(59, 130, 246, 0.3);
  }
  
  .login-button:active {
    transform: translateY(0);
  }
  
  .hint {
    text-align: center;
    color: #94a3b8;
    font-size: 13px;
    margin-top: 24px;
  }
</style>