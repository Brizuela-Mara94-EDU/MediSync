<script>
  let { med, onToggle } = $props();
  
  let showDetails = $state(false);
  
  function toggleDetails() {
    showDetails = !showDetails;
  }
  
  function handleToggle() {
    if (!med.tomado) {
      onToggle(med);
    }
  }
</script>

<div class="medication-card" class:taken={med.tomado} class:atrasado={med.es_atrasado}>
  <div class="card-header">
    <div class="med-icon-circle">
      {#if med.tomado}
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <polyline points="20 6 9 17 4 12"/>
        </svg>
      {:else}
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <rect width="20" height="14" x="2" y="7" rx="2" ry="2"/>
          <path d="M16 21V5a2 2 0 0 0-2-2h-4a2 2 0 0 0-2 2v16"/>
        </svg>
      {/if}
    </div>
    
    <div class="med-main-info">
      <h3>{med.nombre}</h3>
      <div class="med-time-info">
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <circle cx="12" cy="12" r="10"/>
          <polyline points="12 6 12 12 16 14"/>
        </svg>
        <span class="time">{med.hora}</span>
        {#if med.es_atrasado}
          <span class="badge-atrasado">Atrasado</span>
        {/if}
      </div>
      <p class="dosage">{med.dosis}</p>
    </div>
    
    <button 
      class="check-button" 
      class:checked={med.tomado}
      onclick={handleToggle}
      disabled={med.tomado}
      aria-label={med.tomado ? 'Medicamento tomado' : 'Marcar como tomado'}
    >
      {#if med.tomado}
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3">
          <polyline points="20 6 9 17 4 12"/>
        </svg>
      {:else}
        <div class="check-circle"></div>
      {/if}
    </button>
  </div>
  
  {#if med.instrucciones}
    <div class="med-instructions">
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
        <circle cx="12" cy="12" r="10"/>
        <path d="M12 16v-4"/>
        <path d="M12 8h.01"/>
      </svg>
      <span>{med.instrucciones}</span>
    </div>
  {/if}
  
  <button class="details-toggle" onclick={toggleDetails}>
    {showDetails ? 'Ocultar detalles' : 'Ver detalles'}
    <svg 
      xmlns="http://www.w3.org/2000/svg" 
      viewBox="0 0 24 24" 
      fill="none" 
      stroke="currentColor" 
      stroke-width="2"
      class:rotated={showDetails}
    >
      <polyline points="6 9 12 15 18 9"/>
    </svg>
  </button>
  
  {#if showDetails}
    <div class="details-panel">
      <div class="detail-item">
        <strong>Frecuencia:</strong>
        <span>Cada {med.frecuencia_horas} {med.frecuencia_horas === 1 ? 'hora' : 'horas'}</span>
      </div>
      
      {#if med.duracion_dias}
        <div class="detail-item">
          <strong>Duración del tratamiento:</strong>
          <span>{med.duracion_dias} {med.duracion_dias === 1 ? 'día' : 'días'}</span>
        </div>
      {/if}
      
      {#if med.cantidad_total}
        <div class="detail-item">
          <strong>Cantidad total recetada:</strong>
          <span>{med.cantidad_total} {med.cantidad_total === 1 ? 'unidad' : 'unidades'}</span>
        </div>
      {/if}
      
      {#if med.fecha_receta}
        <div class="detail-item">
          <strong>Fecha de la receta:</strong>
          <span>{new Date(med.fecha_receta).toLocaleDateString('es-AR')}</span>
        </div>
      {/if}
    </div>
  {/if}
</div>

<style>
  .medication-card {
    background: white;
    border-radius: 16px;
    padding: 20px;
    box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
    transition: all 0.3s ease;
    border: 2px solid transparent;
  }
  
  .medication-card:not(.taken) {
    border-color: var(--color-200);
  }
  
  .medication-card.atrasado:not(.taken) {
    border-color: #fbbf24;
    background: linear-gradient(to bottom, #fffbeb 0%, white 100%);
  }
  
  .medication-card.taken {
    opacity: 0.7;
    background: linear-gradient(to bottom, #f0fdf4 0%, white 100%);
    border-color: #86efac;
  }
  
  .card-header {
    display: flex;
    gap: 16px;
    align-items: flex-start;
  }
  
  .med-icon-circle {
    width: 48px;
    height: 48px;
    min-width: 48px;
    background: var(--color-100);
    border-radius: 12px;
    display: flex;
    align-items: center;
    justify-content: center;
    transition: all 0.3s;
  }
  
  .medication-card.taken .med-icon-circle {
    background: #d1fae5;
  }
  
  .medication-card.atrasado:not(.taken) .med-icon-circle {
    background: #fef3c7;
  }
  
  .med-icon-circle svg {
    width: 24px;
    height: 24px;
    color: var(--color-600);
  }
  
  .medication-card.taken .med-icon-circle svg {
    color: #059669;
  }
  
  .medication-card.atrasado:not(.taken) .med-icon-circle svg {
    color: #d97706;
  }
  
  .med-main-info {
    flex: 1;
  }
  
  .med-main-info h3 {
    margin: 0 0 8px 0;
    font-size: 18px;
    color: #1e293b;
    font-weight: 600;
  }
  
  .medication-card.taken h3 {
    text-decoration: line-through;
    color: #64748b;
  }
  
  .med-time-info {
    display: flex;
    align-items: center;
    gap: 6px;
    margin-bottom: 6px;
    flex-wrap: wrap;
  }
  
  .med-time-info svg {
    width: 16px;
    height: 16px;
    color: var(--color-600);
  }
  
  .medication-card.atrasado:not(.taken) .med-time-info svg {
    color: #d97706;
  }
  
  .time {
    font-size: 16px;
    font-weight: 600;
    color: var(--color-700);
  }
  
  .medication-card.atrasado:not(.taken) .time {
    color: #d97706;
  }
  
  .badge-atrasado {
    display: inline-block;
    padding: 2px 8px;
    background: #fef3c7;
    color: #92400e;
    border-radius: 8px;
    font-size: 11px;
    font-weight: 600;
    border: 1px solid #fde68a;
  }
  
  .dosage {
    margin: 0;
    font-size: 14px;
    color: #64748b;
  }
  
  .check-button {
    width: 44px;
    height: 44px;
    min-width: 44px;
    border: none;
    border-radius: 12px;
    cursor: pointer;
    display: flex;
    align-items: center;
    justify-content: center;
    transition: all 0.3s;
    background: var(--color-100);
  }
  
  .check-button:not(.checked):hover {
    background: var(--color-200);
    transform: scale(1.05);
  }
  
  .check-button.checked {
    background: #059669;
    cursor: default;
  }
  
  .check-button svg {
    width: 24px;
    height: 24px;
    color: white;
  }
  
  .check-circle {
    width: 24px;
    height: 24px;
    border: 3px solid var(--color-600);
    border-radius: 50%;
    transition: all 0.2s;
  }
  
  .check-button:hover .check-circle {
    border-color: var(--color-700);
    transform: scale(1.1);
  }
  
  .med-instructions {
    display: flex;
    align-items: flex-start;
    gap: 10px;
    margin-top: 16px;
    padding: 12px;
    background: #eff6ff;
    border-radius: 10px;
    border-left: 3px solid #3b82f6;
  }
  
  .med-instructions svg {
    width: 18px;
    height: 18px;
    color: #3b82f6;
    flex-shrink: 0;
    margin-top: 2px;
  }
  
  .med-instructions span {
    font-size: 13px;
    color: #1e40af;
    line-height: 1.5;
  }
  
  .details-toggle {
    width: 100%;
    margin-top: 16px;
    padding: 10px;
    background: #f8fafc;
    border: 1px solid #e2e8f0;
    border-radius: 8px;
    cursor: pointer;
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 6px;
    font-size: 13px;
    font-weight: 500;
    color: #64748b;
    transition: all 0.2s;
  }
  
  .details-toggle:hover {
    background: #f1f5f9;
    color: #475569;
  }
  
  .details-toggle svg {
    width: 16px;
    height: 16px;
    transition: transform 0.3s;
  }
  
  .details-toggle svg.rotated {
    transform: rotate(180deg);
  }
  
  .details-panel {
    margin-top: 16px;
    padding: 16px;
    background: #f8fafc;
    border-radius: 10px;
    border: 1px solid #e2e8f0;
  }
  
  .detail-item {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 8px 0;
    border-bottom: 1px solid #e2e8f0;
    gap: 12px;
  }
  
  .detail-item:last-child {
    border-bottom: none;
  }
  
  .detail-item strong {
    font-size: 13px;
    color: #475569;
    font-weight: 600;
  }
  
  .detail-item span {
    font-size: 13px;
    color: #64748b;
    text-align: right;
  }
  
  @media (max-width: 375px) {
    .medication-card {
      padding: 16px;
    }
    
    .card-header {
      gap: 12px;
    }
    
    .med-icon-circle {
      width: 42px;
      height: 42px;
      min-width: 42px;
    }
    
    .med-main-info h3 {
      font-size: 16px;
    }
    
    .check-button {
      width: 40px;
      height: 40px;
      min-width: 40px;
    }
  }
</style>