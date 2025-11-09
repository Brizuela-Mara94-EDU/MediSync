<script>
  // Recibimos 'med' (el objeto) y 'onToggle' (la función)
  let { med, onToggle } = $props();
</script>

<div class="medication-card" class:tomado={med.tomado}>
  <div class="med-header">
    <div class="med-icon">
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
        <rect width="20" height="14" x="2" y="7" rx="2" ry="2"/>
        <path d="M16 21V5a2 2 0 0 0-2-2h-4a2 2 0 0 0-2 2v16"/>
      </svg>
    </div>
    <div class="med-info">
      <h4>{med.nombre}</h4>
      <p class="med-type">{med.tipo}</p>
    </div>
    
    <button class="check-btn" class:checked={med.tomado} onclick={() => onToggle(med)}>
      {#if med.tomado}
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3">
          <polyline points="20 6 9 17 4 12"/>
        </svg>
      {/if}
    </button>
  </div>
  <div class="med-details">
    <div class="detail-item">
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
        <circle cx="12" cy="12" r="10"/>
        <polyline points="12 6 12 12 16 14"/>
      </svg>
      <span>{med.hora}</span>
    </div>
    <div class="detail-item">
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
        <line x1="12" x2="12" y1="2" y2="22"/>
        <path d="M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6"/>
      </svg>
      <span>{med.dosis}</span>
    </div>
  </div>
</div>

<style>
  .medication-card {
    background: white;
    border-radius: 16px;
    padding: 16px;
    box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
    transition: all 0.3s;
  }
  
  .medication-card.tomado {
    opacity: 0.6;
  }
  
  .med-header {
    display: flex;
    align-items: center;
    gap: 12px;
    margin-bottom: 12px;
  }
  
  .med-icon {
    width: 44px;
    height: 44px;
    background: linear-gradient(135deg, #3b82f6 0%, #06b6d4 100%);
    border-radius: 12px;
    display: flex;
    align-items: center;
    justify-content: center;
    color: white;
    flex-shrink: 0;
  }
  
  .med-icon svg {
    width: 24px;
    height: 24px;
  }
  
  .med-info {
    flex: 1;
  }
  
  .med-info h4 {
    margin: 0;
    font-size: 16px;
    color: #1e293b;
    font-weight: 600;
  }
  
  .med-type {
    margin: 4px 0 0;
    font-size: 13px;
    color: #64748b;
  }
  
  .check-btn {
    width: 32px;
    height: 32px;
    border: 2px solid #cbd5e1;
    background: white;
    border-radius: 50%;
    cursor: pointer;
    display: flex;
    align-items: center;
    justify-content: center;
    transition: all 0.2s;
    flex-shrink: 0;
  }
  
  .check-btn.checked {
    background: #10b981;
    border-color: #10b981;
    color: white;
  }
  
  .check-btn svg {
    width: 18px;
    height: 18px;
  }
  
  .med-details {
    display: flex;
    gap: 20px;
    padding-left: 56px;
  }
  
  .detail-item {
    display: flex;
    align-items: center;
    gap: 6px;
    color: #64748b;
    font-size: 14px;
  }
  
  .detail-item svg {
    width: 16px;
    height: 16px;
  }
</style>