<script>
  import MedicationCard from './MedicationCard.svelte';
  
  let { medicamentos, onToggleMed } = $props();
</script>

<div class="medications-list">
  {#if !Array.isArray(medicamentos) || medicamentos.length === 0}
    <div class="no-medications">
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
        <rect width="20" height="14" x="2" y="7" rx="2" ry="2"/>
        <path d="M16 21V5a2 2 0 0 0-2-2h-4a2 2 0 0 0-2 2v16"/>
      </svg>
      <p>No hay medicamentos programados en este momento</p>
      <small>Los medicamentos aparecerán cuando sea hora de tomarlos</small>
    </div>
  {:else}
    {#each medicamentos as med (med.id_detalle)}
      <MedicationCard {med} onToggle={onToggleMed} />
    {/each}
  {/if}
</div>

<style>
  .medications-list {
    display: flex;
    flex-direction: column;
    gap: 12px;
  }
  
  .no-medications {
    padding: 60px 20px;
    text-align: center;
    color: #64748b;
  }

  .no-medications svg {
    width: 64px;
    height: 64px;
    margin: 0 auto 1rem;
    opacity: 0.3;
    color: var(--color-400);
  }

  .no-medications p {
    font-size: 16px;
    margin: 0 0 0.5rem 0;
    color: var(--color-700);
    font-weight: 500;
  }

  .no-medications small {
    font-size: 13px;
    color: var(--color-600);
  }
  
  @media (min-width: 768px) {
    .medications-list {
      display: grid;
      grid-template-columns: repeat(auto-fill, minmax(350px, 1fr));
      gap: 16px;
    }

    .no-medications {
      grid-column: 1 / -1;
    }
  }
</style>