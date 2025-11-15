<script lang="ts">
  import { onMount } from 'svelte';
  import { supabase } from '../../supabase/supabase-client.js';
  import SessionManager from '../../utils/SessionManager.js';
  import Recetas from './Recetas.svelte';

  let { paciente = null, idPaciente = null, onVolver } = $props();

  // Estados
  let loading = $state(true);
  let pacienteActual = $state(null);
  let vistaActual = $state('ficha'); // 'ficha' o 'recetas'
  let modelContainer = $state<HTMLDivElement | null>(null);
  
  // Datos del paciente editable
  let pacienteData = $state({
    domicilio: '',
    obra_social: '',
    grupo_sanguineo: ''
  });

  // Datos de ejemplo para Body Condition (órganos afectados)
  let organosAfectados = $state([
    { nombre: 'Corazón', estado: 'Atención', color: '#fbbf24' },
    { nombre: 'Pulmones', estado: 'Normal', color: '#10b981' },
    { nombre: 'Hígado', estado: 'Riesgo', color: '#ef4444' },
    { nombre: 'Riñones', estado: 'Normal', color: '#10b981' }
  ]);

  onMount(async () => {
    console.log('Paciente.svelte onMount - paciente:', paciente, 'idPaciente:', idPaciente);
    
    if (idPaciente && !paciente) {
      await cargarDatosPaciente(idPaciente);
    } else {
      pacienteActual = paciente;
      if (pacienteActual) {
        pacienteData = {
          domicilio: pacienteActual.domicilio || '',
          obra_social: pacienteActual.obra_social || '',
          grupo_sanguineo: pacienteActual.grupo_sanguineo || ''
        };
      }
      loading = false;
    }

    // Inicializar el modelo 3D
    if (modelContainer) {
      inicializarModelo3D();
    }
  });

  async function cargarDatosPaciente(id_paciente) {
    console.log('Cargando datos completos del paciente con ID:', id_paciente);
    try {
      const { data: pacienteDB, error } = await supabase
        .from('pacientes')
        .select(`
          id_paciente,
          domicilio,
          obra_social,
          grupo_sanguineo,
          usuarios!inner (
            nombre,
            apellido,
            dni,
            email,
            telefono,
            fecha_nacimiento
          )
        `)
        .eq('id_paciente', id_paciente)
        .single();

      if (error) {
        console.error('Error en query:', error);
        return;
      }

      if (pacienteDB) {
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        const usuario: any = Array.isArray(pacienteDB.usuarios) 
          ? pacienteDB.usuarios[0] 
          : pacienteDB.usuarios;
        
        const nacimiento = new Date(usuario.fecha_nacimiento);
        const hoy = new Date();
        const edad = hoy.getFullYear() - nacimiento.getFullYear();

        pacienteActual = {
          id_paciente: pacienteDB.id_paciente,
          nombre: usuario.nombre,
          apellido: usuario.apellido,
          dni: usuario.dni,
          email: usuario.email,
          telefono: usuario.telefono,
          edad: edad,
          domicilio: pacienteDB.domicilio || '',
          obra_social: pacienteDB.obra_social || '',
          grupo_sanguineo: pacienteDB.grupo_sanguineo || ''
        };

        pacienteData = {
          domicilio: pacienteActual.domicilio,
          obra_social: pacienteActual.obra_social,
          grupo_sanguineo: pacienteActual.grupo_sanguineo
        };
      }
    } catch (error) {
      console.error('Error cargando datos del paciente:', error);
    } finally {
      loading = false;
    }
  }

  function irARecetas() {
    vistaActual = 'recetas';
  }

  function volverAFicha() {
    vistaActual = 'ficha';
  }

  async function inicializarModelo3D() {
    if (!modelContainer) return;

    try {
      // Importar Three.js dinámicamente
      const THREE = await import('three');
      const { GLTFLoader } = await import('three/examples/jsm/loaders/GLTFLoader.js');
      const { OrbitControls } = await import('three/examples/jsm/controls/OrbitControls.js');

      // Limpiar contenedor
      modelContainer.innerHTML = '';

      // Crear escena
      const scene = new THREE.Scene();
      scene.background = new THREE.Color(0xf0f9ff);

      // Crear cámara
      const camera = new THREE.PerspectiveCamera(
        45,
        modelContainer.clientWidth / modelContainer.clientHeight,
        0.1,
        1000
      );
      // @ts-ignore - Three.js types
      camera.position.set(0, 1, 3);

      // Crear renderer
      const renderer = new THREE.WebGLRenderer({ antialias: true });
      renderer.setSize(modelContainer.clientWidth, modelContainer.clientHeight);
      renderer.setPixelRatio(window.devicePixelRatio);
      // @ts-ignore - Three.js types
      renderer.shadowMap.enabled = true;
      modelContainer.appendChild(renderer.domElement as Node);

      // Controles de órbita
      const controls = new OrbitControls(camera, renderer.domElement as HTMLElement);
      controls.enableDamping = true;
      controls.dampingFactor = 0.05;
      controls.minDistance = 1;
      controls.maxDistance = 10;

      // Luces
      const ambientLight = new THREE.AmbientLight(0xffffff, 0.6);
      scene.add(ambientLight);

      const directionalLight = new THREE.DirectionalLight(0xffffff, 0.8);
      // @ts-ignore - Three.js types
      directionalLight.position.set(5, 10, 5);
      directionalLight.castShadow = true;
      scene.add(directionalLight);

      const hemisphereLight = new THREE.HemisphereLight(0xffffff, 0x444444, 0.4);
      scene.add(hemisphereLight);

      // Cargar modelo GLB
      const loader = new GLTFLoader();
      loader.load(
        '/assets/models/digestivo.glb',
        (gltf) => {
          const model = gltf.scene;
          
          // Centrar y escalar modelo
          const box = new THREE.Box3().setFromObject(model);
          const center = box.getCenter(new THREE.Vector3());
          const size = box.getSize(new THREE.Vector3());
          
          const maxDim = Math.max(size.x, size.y, size.z);
          const scale = 2 / maxDim;
          model.scale.multiplyScalar(scale);
          
          model.position.sub(center.multiplyScalar(scale));
          
          scene.add(model);
        },
        (progress) => {
          console.log('Cargando modelo 3D:', (progress.loaded / progress.total * 100).toFixed(2) + '%');
        },
        (error) => {
          console.error('Error cargando modelo 3D:', error);
          // Mostrar un cubo placeholder si falla la carga
          const geometry = new THREE.BoxGeometry(1, 2, 0.5);
          const material = new THREE.MeshPhongMaterial({ color: 0x4fa69e });
          const cube = new THREE.Mesh(geometry, material);
          // @ts-ignore - Three.js types
          scene.add(cube);
        }
      );

      // Animación
      function animate() {
        requestAnimationFrame(animate);
        controls.update();
        renderer.render(scene, camera);
      }
      animate();

      // Responsive
      const handleResize = () => {
        if (!modelContainer) return;
        camera.aspect = modelContainer.clientWidth / modelContainer.clientHeight;
        camera.updateProjectionMatrix();
        renderer.setSize(modelContainer.clientWidth, modelContainer.clientHeight);
      };
      window.addEventListener('resize', handleResize);

      // Cleanup
      return () => {
        window.removeEventListener('resize', handleResize);
        renderer.dispose();
      };
    } catch (error) {
      console.error('Error inicializando modelo 3D:', error);
    }
  }
</script>

{#if vistaActual === 'recetas'}
  <Recetas 
    idPaciente={pacienteActual?.id_paciente} 
    nombrePaciente={`${pacienteActual?.nombre} ${pacienteActual?.apellido}`}
    onVolver={volverAFicha} 
  />
{:else}
  <div class="paciente-container">
    <!-- Header -->
    <div class="paciente-header">
      <button class="btn-back" onclick={onVolver}>
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <path d="M19 12H5"/>
          <path d="m12 19-7-7 7-7"/>
        </svg>
        Volver
      </button>
      <h2>Ficha del Paciente</h2>
    </div>

    {#if !pacienteActual || loading}
      <div class="loading-state">
        <p>{loading ? 'Cargando información del paciente...' : 'No hay información del paciente disponible'}</p>
      </div>
    {:else}
      <!-- Layout Principal: Izquierda (Datos + Cards) | Derecha (Modelo 3D) -->
      <div class="main-layout">
        <!-- Columna Izquierda: Ficha, Cards y Body Condition -->
        <div class="left-column">
          <!-- Ficha del Paciente -->
          <div class="ficha-card">
            <div class="ficha-header">
              <div class="patient-avatar-large">
                {pacienteActual.nombre.charAt(0)}{pacienteActual.apellido.charAt(0)}
              </div>
              <div class="patient-title-info">
                <h3>{pacienteActual.nombre} {pacienteActual.apellido}</h3>
                <p class="subtitle">DNI: {pacienteActual.dni} • {pacienteActual.edad} años</p>
              </div>
            </div>

            <div class="ficha-grid">
              <div class="info-item">
                <span class="info-label">Email</span>
                <p>{pacienteActual.email || 'No registrado'}</p>
              </div>
              <div class="info-item">
                <span class="info-label">Teléfono</span>
                <p>{pacienteActual.telefono || 'No registrado'}</p>
              </div>
              <div class="info-item">
                <span class="info-label">Domicilio</span>
                <p>{pacienteData.domicilio || 'No registrado'}</p>
              </div>
              <div class="info-item">
                <span class="info-label">Obra Social</span>
                <p>{pacienteData.obra_social || 'Sin obra social'}</p>
              </div>
              <div class="info-item">
                <span class="info-label">Grupo Sanguíneo</span>
                <p>{pacienteData.grupo_sanguineo || 'No registrado'}</p>
              </div>
            </div>
          </div>

          <!-- Cards de Acciones -->
          <div class="action-cards-grid">
            <!-- Card Dolor -->
            <div class="action-card disabled">
              <div class="action-icon" style="background: #fef3c7;">
                <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="color: #f59e0b;">
                  <path d="m21.73 18-8-14a2 2 0 0 0-3.48 0l-8 14A2 2 0 0 0 4 21h16a2 2 0 0 0 1.73-3Z"/>
                  <path d="M12 9v4"/>
                  <path d="M12 17h.01"/>
                </svg>
              </div>
              <span class="action-label">Dolor</span>
            </div>

            <!-- Card Síntomas -->
            <div class="action-card disabled">
              <div class="action-icon" style="background: #dbeafe;">
                <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="color: #3b82f6;">
                  <path d="M22 12h-4l-3 9L9 3l-3 9H2"/>
                </svg>
              </div>
              <span class="action-label">Síntomas</span>
            </div>

            <!-- Card Chequeos -->
            <div class="action-card disabled">
              <div class="action-icon" style="background: #e0e7ff;">
                <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="color: #6366f1;">
                  <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/>
                  <polyline points="14 2 14 8 20 8"/>
                  <line x1="16" x2="8" y1="13" y2="13"/>
                  <line x1="16" x2="8" y1="17" y2="17"/>
                </svg>
              </div>
              <span class="action-label">Chequeos</span>
            </div>

            <!-- Card Recetas Médicas (activo) -->
            <div 
              class="action-card active" 
              onclick={irARecetas} 
              onkeydown={(e) => e.key === 'Enter' && irARecetas()}
              role="button" 
              tabindex="0"
            >
              <div class="action-icon" style="background: #d1fae5;">
                <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="color: #059669;">
                  <rect width="20" height="14" x="2" y="7" rx="2" ry="2"/>
                  <path d="M16 21V5a2 2 0 0 0-2-2h-4a2 2 0 0 0-2 2v16"/>
                </svg>
              </div>
              <span class="action-label">Recetas Médicas</span>
            </div>
          </div>

          <!-- Body Condition Carousel -->
          <div class="body-condition-card">
            <h3>🫀 Body Condition</h3>
            <div class="organs-carousel">
              {#each organosAfectados as organo}
                <div class="organ-card" style="border-left: 4px solid {organo.color}">
                  <div class="organ-name">{organo.nombre}</div>
                  <div class="organ-status" style="color: {organo.color}">{organo.estado}</div>
                </div>
              {/each}
            </div>
          </div>
        </div>

        <!-- Columna Derecha: Modelo 3D (toda la altura) -->
        <div class="right-column">
          <div class="model-3d-card">
            <div class="model-3d-container" bind:this={modelContainer}></div>
          </div>
        </div>
      </div>
    {/if}
  </div>
{/if}

<style>
  .paciente-container {
    padding: 2rem;
    max-width: 1600px;
    margin: 0 auto;
  }

  .paciente-header {
    margin-bottom: 2rem;
  }

  .paciente-header h2 {
    margin: 1rem 0;
    font-size: 28px;
    color: var(--color-900);
  }

  .btn-back {
    display: inline-flex;
    align-items: center;
    gap: 0.5rem;
    padding: 0.5rem 1rem;
    background: white;
    border: 2px solid var(--color-200);
    border-radius: 10px;
    cursor: pointer;
    font-size: 0.9rem;
    color: var(--color-700);
    font-weight: 500;
    transition: all 0.2s;
  }

  .btn-back:hover {
    background: var(--color-50);
    border-color: var(--color-300);
  }

  .btn-back svg {
    width: 20px;
    height: 20px;
  }

  .loading-state {
    text-align: center;
    padding: 3rem;
    color: var(--color-700);
  }

  .main-layout {
    display: grid;
    grid-template-columns: 1fr 500px;
    gap: 2rem;
    min-height: calc(100vh - 200px);
  }

  /* Columna Izquierda */
  .left-column {
    display: flex;
    flex-direction: column;
    gap: 1.5rem;
  }

  /* Columna Derecha - Modelo 3D */
  .right-column {
    display: flex;
    flex-direction: column;
  }

  .model-3d-card {
    background: white;
    border-radius: 16px;
    padding: 16px;
    box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
    border: 1px solid var(--color-100);
    flex: 1;
    display: flex;
    flex-direction: column;
  }

  .model-3d-container {
    background: linear-gradient(135deg, #f0f9ff 0%, #e0f2fe 100%);
    border-radius: 12px;
    flex: 1;
    min-height: 600px;
    position: relative;
    overflow: hidden;
  }

  .body-condition-card {
    background: white;
    border-radius: 16px;
    padding: 24px;
    box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
    border: 1px solid var(--color-100);
  }

  .body-condition-card h3 {
    margin: 0 0 1rem 0;
    font-size: 18px;
    color: var(--color-900);
    font-weight: 600;
  }

  .organs-carousel {
    display: flex;
    flex-direction: column;
    gap: 0.75rem;
  }

  .organ-card {
    background: var(--color-50);
    border-radius: 10px;
    padding: 12px 16px;
    border-left-width: 4px;
    border-left-style: solid;
    transition: all 0.2s;
  }

  .organ-card:hover {
    transform: translateX(4px);
    box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
  }

  .organ-name {
    font-weight: 600;
    color: var(--color-900);
    margin-bottom: 4px;
  }

  .organ-status {
    font-size: 12px;
    font-weight: 600;
    text-transform: uppercase;
    letter-spacing: 0.5px;
  }

  /* Ficha del Paciente */
  .ficha-card {
    background: white;
    border-radius: 16px;
    padding: 24px;
    box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
    border: 1px solid var(--color-100);
  }

  /* Columna Derecha */
  .right-column {
    display: flex;
    flex-direction: column;
  }

  .action-cards-grid {
    display: grid;
    grid-template-columns: repeat(2, 1fr);
    gap: 1rem;
  }

  .action-card {
    background: white;
    border-radius: 16px;
    padding: 20px;
    box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
    border: 1px solid var(--color-100);
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 12px;
    transition: all 0.2s;
  }

  .action-card.active {
    cursor: pointer;
  }

  .action-card.active:hover {
    transform: translateY(-4px);
    box-shadow: 0 8px 16px rgba(0, 0, 0, 0.15);
  }

  .action-card.disabled {
    opacity: 0.6;
    cursor: not-allowed;
  }

  .action-icon {
    width: 60px;
    height: 60px;
    border-radius: 12px;
    display: flex;
    align-items: center;
    justify-content: center;
  }

  .action-icon svg {
    width: 32px;
    height: 32px;
  }

  .action-label {
    font-size: 14px;
    font-weight: 600;
    color: var(--color-900);
    text-align: center;
  }

  .ficha-header {
    display: flex;
    align-items: center;
    gap: 1rem;
    padding-bottom: 20px;
    border-bottom: 1px solid var(--color-200);
    margin-bottom: 24px;
  }

  .patient-avatar-large {
    width: 70px;
    height: 70px;
    border-radius: 50%;
    background: linear-gradient(135deg, var(--color-500) 0%, var(--color-700) 100%);
    display: flex;
    align-items: center;
    justify-content: center;
    color: white;
    font-size: 24px;
    font-weight: 700;
  }

  .patient-title-info h3 {
    margin: 0;
    font-size: 24px;
    color: var(--color-900);
    font-weight: 700;
  }

  .subtitle {
    color: var(--color-700);
    margin: 4px 0 0 0;
    font-size: 14px;
  }

  .ficha-grid {
    display: grid;
    grid-template-columns: repeat(2, 1fr);
    gap: 1.5rem;
  }

  .info-item .info-label {
    display: block;
    font-size: 12px;
    color: var(--color-600);
    margin-bottom: 6px;
    font-weight: 600;
    text-transform: uppercase;
    letter-spacing: 0.5px;
  }

  .info-item p {
    margin: 0;
    color: var(--color-900);
    font-size: 16px;
    font-weight: 500;
  }

  @media (max-width: 1200px) {
    .main-layout {
      grid-template-columns: 1fr;
    }

    .action-cards-grid {
      grid-template-columns: repeat(2, 1fr);
    }

    .ficha-grid {
      grid-template-columns: 1fr;
    }
  }

  @media (max-width: 768px) {
    .paciente-container {
      padding: 1rem;
    }

    .action-cards-grid {
      grid-template-columns: 1fr;
    }
  }
</style>
