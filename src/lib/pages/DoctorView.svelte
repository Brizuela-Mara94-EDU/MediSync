<script>
  import Menu from './medico/Menu.svelte';
  import Content from './medico/Content.svelte';
  
  let { onLogout } = $props();
  
  let activeSection = $state('dashboard');
  
  function handleSectionChange(section) {
    activeSection = section;
  }
</script>

<div class="dashboard">
  <Menu activeSection={activeSection} onSectionChange={handleSectionChange} onLogout={onLogout} />
  <Content activeSection={activeSection} />
</div>

<style>
  .dashboard {
    display: flex;
    min-height: 100vh;
    background: #f1f5f9;
    width: 100%;
  }
</style>
