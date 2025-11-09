<script>
  import MedicationCard from './MedicationCard.svelte';
  
  let { medicamentos, onToggleMed } = $props();
</script>

<div class="medications-list">
  {#each medicamentos as med (med.nombre)}
    <MedicationCard med={med} onToggle={onToggleMed} />
  {/each}
</div>

<style>
  .medications-list {
    display: flex;
    flex-direction: column;
    gap: 12px;
  }
  
  @media (min-width: 768px) {
    .medications-list {
      display: grid;
      grid-template-columns: repeat(auto-fill, minmax(350px, 1fr));
      gap: 16px;
    }
  }
</style>
