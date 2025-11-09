<script>
  let { onReturn } = $props();
</script>

<div class="sintomas-container">
  <button class="back-btn" onclick={onReturn}>
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
      <path d="M19 12H5M12 19l-7-7 7-7"/>
    </svg>
    Volver
  </button>
  
  <div class="form-card">
    <h3>Registro de Síntomas</h3>
    <p>Registra los síntomas que estás experimentando</p>
    
    <div class="form-group">
      <label for="tipo-sintoma">Tipo de síntoma</label>
      <select id="tipo-sintoma">
        <option value="">Selecciona un síntoma</option>
        <option value="fiebre">Fiebre</option>
        <option value="tos">Tos</option>
        <option value="dolor_cabeza">Dolor de cabeza</option>
        <option value="nauseas">Náuseas</option>
        <option value="fatiga">Fatiga</option>
        <option value="otro">Otro</option>
      </select>
    </div>
    
    <div class="form-group">
      <label for="intensidad-sintoma">Intensidad (1-10)</label>
      <input type="range" id="intensidad-sintoma" min="1" max="10" value="5" />
    </div>
    
    <div class="form-group">
      <label for="descripcion-sintoma">Descripción</label>
      <textarea id="descripcion-sintoma" placeholder="Describe tus síntomas..."></textarea>
    </div>
    
    <button class="submit-btn">Guardar Síntoma</button>
  </div>
</div>

<style>
  .sintomas-container {
    max-width: 600px;
    margin: 0 auto;
  }
  
  .back-btn {
    display: flex;
    align-items: center;
    gap: 8px;
    background: none;
    border: none;
    color: #3b82f6;
    font-size: 14px;
    font-weight: 500;
    cursor: pointer;
    padding: 8px 0;
    margin-bottom: 20px;
  }
  
  .back-btn svg {
    width: 20px;
    height: 20px;
  }
  
  .form-card {
    background: white;
    border-radius: 16px;
    padding: 24px;
    box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
  }
  
  .form-card h3 {
    margin: 0 0 8px 0;
    font-size: 22px;
    color: #1e293b;
  }
  
  .form-card p {
    margin: 0 0 24px 0;
    color: #64748b;
    font-size: 14px;
  }
  
  .form-group {
    margin-bottom: 20px;
  }
  
  .form-group label {
    display: block;
    margin-bottom: 8px;
    color: #1e293b;
    font-weight: 500;
    font-size: 14px;
  }
  
  .form-group input[type="range"] {
    width: 100%;
  }
  
  .form-group select,
  .form-group textarea {
    width: 100%;
    padding: 12px;
    border: 2px solid #e2e8f0;
    border-radius: 8px;
    font-size: 14px;
    box-sizing: border-box;
  }
  
  .form-group textarea {
    min-height: 100px;
    resize: vertical;
    font-family: inherit;
  }
  
  .submit-btn {
    width: 100%;
    padding: 14px;
    background: linear-gradient(135deg, #3b82f6 0%, #06b6d4 100%);
    color: white;
    border: none;
    border-radius: 12px;
    font-size: 16px;
    font-weight: 600;
    cursor: pointer;
    transition: transform 0.2s;
  }
  
  .submit-btn:active {
    transform: scale(0.98);
  }
</style>
