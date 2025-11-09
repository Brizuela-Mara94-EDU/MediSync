<script>
  import Dolor from './Dolor.svelte'; 
  import Sintoma from './Sintomas.svelte'; 
  
  let currentEstadoView = $state('default');
</script>

{#if currentEstadoView === 'default'}
  <div class="estado-container">
    <div class="estado-section">
      <div class="section-header">
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <circle cx="12" cy="12" r="10"/>
          <path d="M12 2v20M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6"/>
        </svg>
        <h4>Registro de Dolor</h4>
      </div>
      <p>Registra cómo te sientes hoy</p>
      <button class="add-btn" onclick={() => currentEstadoView = 'dolor'}>Agregar Estado</button>
    </div>
    
    <div class="estado-section">
      <div class="section-header">
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <path d="M9.09 9a3 3 0 0 1 5.83 1c0 2-3 3-3 3"/>
          <circle cx="12" cy="12" r="10"/>
          <line x1="12" x2="12.01" y1="17" y2="17"/>
        </svg>
        <h4>Síntomas</h4>
      </div>
      <p>Registra tus síntomas diarios</p>
      <button class="add-btn" onclick={() => currentEstadoView = 'sintoma'}>Agregar Síntoma</button>
    </div>
  </div>

{:else if currentEstadoView === 'dolor'}
  <Dolor onReturn={() => currentEstadoView = 'default'} />

{:else if currentEstadoView === 'sintoma'}
  <Sintoma onReturn={() => currentEstadoView = 'default'} />
{/if}

<style>
  .estado-container {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
    gap: 24px;
    max-width: 900px;
    margin: 0 auto;
  }
  
  .estado-section {
    background: white;
    border-radius: 16px;
    padding: 32px;
    box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
    text-align: center;
  }
  
  .section-header {
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 12px;
    margin-bottom: 12px;
  }
  
  .section-header svg {
    width: 32px;
    height: 32px;
    color: #3b82f6;
  }
  
  .section-header h4 {
    margin: 0;
    font-size: 20px;
    color: #1e293b;
  }
  
  .estado-section p {
    color: #64748b;
    font-size: 14px;
    margin: 0 0 24px;
  }
  
  .add-btn {
    padding: 12px 32px;
    background: linear-gradient(135deg, #3b82f6 0%, #06b6d4 100%);
    color: white;
    border: none;
    border-radius: 12px;
    font-size: 15px;
    font-weight: 600;
    cursor: pointer;
    transition: transform 0.2s;
  }
  
  .add-btn:active {
    transform: scale(0.96);
  }
</style>
