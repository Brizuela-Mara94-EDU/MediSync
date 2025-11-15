<script>
  import Dashboard from './Dashboard.svelte';
  import MisPacientes from './MisPacientes.svelte';
  import Paciente from './Paciente.svelte';
  import Citas from './Citas.svelte';
  import Historial from './Historial.svelte';
  
  let { activeSection } = $props();
  
  let pacienteSeleccionado = $state(null);
  let vistaActual = $state('lista'); // 'lista' o 'detalle'

  function handleVerPaciente(idPaciente) {
    pacienteSeleccionado = idPaciente;
    vistaActual = 'detalle';
  }

  function handleVolverALista() {
    vistaActual = 'lista';
    pacienteSeleccionado = null;
  }

  // Resetear vista cuando cambia la sección
  $effect(() => {
    if (activeSection !== 'pacientes') {
      vistaActual = 'lista';
      pacienteSeleccionado = null;
    }
  });
</script>

<main class="main-content">
  {#if activeSection === 'dashboard'}
    <Dashboard />
  {:else if activeSection === 'pacientes'}
    {#if vistaActual === 'lista'}
      <MisPacientes onVerPaciente={handleVerPaciente} />
    {:else}
      <Paciente idPaciente={pacienteSeleccionado} onVolver={handleVolverALista} />
    {/if}
  {:else if activeSection === 'citas'}
    <Citas />
  {:else if activeSection === 'historial'}
    <Historial />
  {/if}
</main>

<style>
  .main-content {
    flex: 1;
    padding: 32px;
    overflow-y: auto;
    margin-left: 260px;
    width: calc(100% - 260px);
  }
  
  @media (max-width: 768px) {
    .main-content {
      padding: 20px;
      margin-left: 0;
      width: 100%;
    }
  }
</style>
