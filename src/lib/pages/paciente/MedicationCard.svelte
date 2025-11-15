<script>
  // Recibimos 'med' (el objeto) y 'onToggle' (la función)
  let { med, onToggle } = $props();
  
  // Extraer tipo y cantidad de la dosis
  // Ejemplo: "1 comprimido" -> tipo: "Comprimido", "400mg" -> cantidad: "400mg"
  function extraerTipoDosis(nombre, dosis) {
    // Intentar extraer miligramos del nombre del medicamento
    const mgMatch = nombre?.match(/(\d+)\s*mg/i);
    const cantidad = mgMatch ? mgMatch[1] + 'mg' : dosis || '';
    
    // Determinar el tipo basado en la dosis
    let tipo = 'Tableta'; // Default
    if (dosis) {
      const dosisLower = dosis.toLowerCase();
      if (dosisLower.includes('cápsula') || dosisLower.includes('capsula')) {
        tipo = 'Cápsula';
      } else if (dosisLower.includes('comprimido')) {
        tipo = 'Comprimido';
      } else if (dosisLower.includes('tableta')) {
        tipo = 'Tableta';
      } else if (dosisLower.includes('ml') || dosisLower.includes('jarabe')) {
        tipo = 'Líquido';
      }
    }
    
    return { tipo, cantidad };
  }
  
  let tipoDosis = $derived(extraerTipoDosis(med.nombre, med.dosis));
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
      <p class="med-type">{tipoDosis.tipo}</p>
    </div>
    
    <button class="check-btn" class:checked={med.tomado} onclick={() => onToggle(med)} aria-label={med.tomado ? 'Marcar como no tomado' : 'Marcar como tomado'}>
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
      <span>{tipoDosis.cantidad}</span>
    </div>
  </div>
  
  {#if med.instrucciones}
    <div class="med-instructions">
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
        <circle cx="12" cy="12" r="10"/>
        <path d="M12 16v-4"/>
        <path d="M12 8h.01"/>
      </svg>
      <p>{med.instrucciones}</p>
    </div>
  {/if}
</div>

<style>
  .medication-card {
    background: linear-gradient(135deg, var(--color-50) 0%, var(--color-100) 50%, #ffffff 100%);
    border-radius: 20px;
    padding: 20px;
    box-shadow: 0 4px 12px rgba(0, 0, 0, 0.08);
    transition: all 0.3s;
    border: 1px solid var(--color-200);
  }
  
  .medication-card:hover {
    box-shadow: 0 6px 20px rgba(67, 142, 135, 0.15);
    transform: translateY(-2px);
  }
  
  .medication-card.tomado {
    opacity: 0.6;
    background: linear-gradient(135deg, #f0f0f0 0%, #f9f9f9 50%, #ffffff 100%);
  }
  
  .med-header {
    display: flex;
    align-items: center;
    gap: 14px;
    margin-bottom: 16px;
  }
  
  .med-icon {
    width: 52px;
    height: 52px;
    background: linear-gradient(135deg, var(--color-600) 0%, var(--color-500) 100%);
    border-radius: 14px;
    display: flex;
    align-items: center;
    justify-content: center;
    color: white;
    flex-shrink: 0;
    box-shadow: 0 4px 8px rgba(67, 142, 135, 0.3);
  }
  
  .med-icon svg {
    width: 28px;
    height: 28px;
  }
  
  .med-info {
    flex: 1;
    min-width: 0;
  }
  
  .med-info h4 {
    margin: 0;
    font-size: 17px;
    color: #1e293b;
    font-weight: 600;
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
  }
  
  .med-type {
    margin: 4px 0 0;
    font-size: 14px;
    color: #64748b;
    font-weight: 400;
  }
  
  .check-btn {
    width: 36px;
    height: 36px;
    border: 2.5px solid #cbd5e1;
    background: white;
    border-radius: 50%;
    cursor: pointer;
    display: flex;
    align-items: center;
    justify-content: center;
    transition: all 0.2s;
    flex-shrink: 0;
  }
  
  .check-btn:hover {
    border-color: #94a3b8;
    transform: scale(1.05);
  }
  
  .check-btn.checked {
    background: #10b981;
    border-color: #10b981;
    color: white;
  }
  
  .check-btn svg {
    width: 20px;
    height: 20px;
  }
  
  .med-details {
    display: flex;
    gap: 24px;
    padding-left: 0;
    flex-wrap: wrap;
  }
  
  .detail-item {
    display: flex;
    align-items: center;
    gap: 8px;
    color: #475569;
    font-size: 15px;
    font-weight: 500;
  }
  
  .detail-item svg {
    width: 18px;
    height: 18px;
    color: #64748b;
  }

  .med-instructions {
    margin-top: 14px;
    padding: 12px 14px;
    background: var(--color-50);
    border-left: 3px solid var(--color-600);
    border-radius: 10px;
    display: flex;
    align-items: flex-start;
    gap: 10px;
  }

  .med-instructions svg {
    width: 16px;
    height: 16px;
    color: var(--color-600);
    flex-shrink: 0;
    margin-top: 2px;
  }

  .med-instructions p {
    margin: 0;
    font-size: 13px;
    color: #1e293b;
    line-height: 1.6;
  }
</style>