<script>
  import { onMount } from 'svelte';
  import { supabase } from '../supabase/supabase-client.js';
  import SessionManager from '../utils/SessionManager.js';
  import Home from './paciente/Home.svelte';
  import MiEstado from './paciente/MiEstado.svelte';
  import Historial from './paciente/Historial.svelte';
  import Perfil from './paciente/Perfil.svelte';

  let { onLogout } = $props();
  
  let activeTab = $state('medicamentos');
  let showMenu = $state(false);
  let showNotifications = $state(false);
  let loading = $state(true);
  let pacienteData = $state(null);
  
  function handleLogout() {
    if (confirm('¿Estás seguro de que deseas cerrar sesión?')) {
      showMenu = false;
      onLogout();
    }
  }

  let currentDate = new Date().toLocaleString('es-ES', { 
    weekday: 'long', 
    year: 'numeric', 
    month: 'long', 
    day: 'numeric' 
  });
  
  let medicamentos = $state([]);

  onMount(() => {
    cargarDatosPaciente();
    cargarMedicamentos();
    
    // Recargar medicamentos cada minuto
    const interval = setInterval(() => {
      cargarMedicamentos();
    }, 60000);
    
    return () => {
      clearInterval(interval);
    };
  });

  async function cargarDatosPaciente() {
    try {
      const sesion = SessionManager.obtenerSesion();
      if (!sesion?.id_usuario) return;

      const { data: paciente, error } = await supabase
        .from('pacientes')
        .select(`
          *,
          usuarios!inner (
            nombre,
            apellido,
            dni
          )
        `)
        .eq('id_usuario', sesion.id_usuario)
        .single();

      if (error) {
        console.error('Error cargando datos del paciente:', error);
        return;
      }

      pacienteData = {
        ...paciente,
        nombre: paciente.usuarios.nombre,
        apellido: paciente.usuarios.apellido,
        dni: paciente.usuarios.dni
      };

    } catch (error) {
      console.error('Error:', error);
    }
  }

  async function cargarMedicamentos() {
    try {
      const sesion = SessionManager.obtenerSesion();
      if (!sesion?.id_usuario) return;

      const { data: pacienteInfo } = await supabase
        .from('pacientes')
        .select('id_paciente')
        .eq('id_usuario', sesion.id_usuario)
        .single();

      if (!pacienteInfo) return;

      const { data: detalles, error } = await supabase
        .from('detalle_receta')
        .select(`
          id_detalle,
          nombre_medicamento,
          dosis,
          frecuencia,
          duracion_dias,
          cantidad_total,
          instrucciones_detalladas,
          recetas!inner (
            id_receta,
            id_paciente,
            fecha_emision,
            estado
          )
        `)
        .eq('recetas.id_paciente', pacienteInfo.id_paciente)
        .eq('recetas.estado', 'activa');

      if (error) {
        console.error('Error cargando medicamentos:', error);
        return;
      }

      const ahora = new Date();
      const medicamentosActualizados = [];

      console.log('=== INICIO CARGA DE MEDICAMENTOS ===');
      console.log('Fecha/Hora actual:', ahora.toLocaleString('es-AR'));

      // CONFIGURACIÓN DE VENTANA DE TIEMPO - MODIFICR AQUÍ
      const HORAS_ANTES = 4;    //  Cambiar : horas ANTES de la toma 
      const HORAS_DESPUES = 4;  //  Cambiar : horas DESPUÉS de la toma para seguir mostrando medicamento
      
      const VENTANA_ANTES = HORAS_ANTES * 60 * 60 * 1000;
      const VENTANA_DESPUES = HORAS_DESPUES * 60 * 60 * 1000;

      detalles?.forEach(detalle => {
        try {
          let instruccionesObj = {};
          try {
            instruccionesObj = JSON.parse(detalle.instrucciones_detalladas || '{}');
          } catch {
            instruccionesObj = {};
          }

          const frecuenciaHoras = instruccionesObj.frecuencia_horas;
          const horaPrimeraToma = instruccionesObj.hora_primera_toma;
          const duracionDias = detalle.duracion_dias;
          
          if (!frecuenciaHoras || !horaPrimeraToma) {
            console.log(`❌ ${detalle.nombre_medicamento}: Falta frecuencia u hora`);
            return;
          }

          const receta = Array.isArray(detalle.recetas) ? detalle.recetas[0] : detalle.recetas;
          if (!receta?.fecha_emision) {
            console.log(`❌ ${detalle.nombre_medicamento}: Sin fecha de receta`);
            return;
          }

          // Verificar que el tratamiento esté vigente
          const fechaInicioTratamiento = new Date(receta.fecha_emision);
          
          let fechaFinTratamiento;
          if (duracionDias && duracionDias > 0) {
            fechaFinTratamiento = new Date(fechaInicioTratamiento);
            fechaFinTratamiento.setDate(fechaFinTratamiento.getDate() + duracionDias);
            fechaFinTratamiento.setHours(23, 59, 59, 999);
          } else {
            fechaFinTratamiento = new Date('2099-12-31');
          }

          console.log(`\n📋 ${detalle.nombre_medicamento}:`);
          console.log('  Inicio:', fechaInicioTratamiento.toLocaleString('es-AR'));
          console.log('  Fin:', fechaFinTratamiento.toLocaleString('es-AR'));
          console.log('  Duración:', duracionDias, 'días');

          if (ahora < fechaInicioTratamiento) {
            console.log(`  ⏭️ Aún no comenzó el tratamiento`);
            return;
          }

          if (ahora > fechaFinTratamiento) {
            console.log(`  ⏭️ Tratamiento finalizado`);
            return;
          }

          // Obtener historial de tomas
          const historialTomas = obtenerHistorialTomas(detalle.id_detalle);
          console.log('  📝 Tomas registradas:', historialTomas.length);
          
          // ✅ Calcular próxima hora PROGRAMADA (no basada en cuándo se tomó)
          const proximaTomaProgramada = calcularProximaHoraProgramada(
            horaPrimeraToma, 
            frecuenciaHoras, 
            historialTomas,
            ahora,
            fechaInicioTratamiento,
            VENTANA_DESPUES  // Pasar la ventana para buscar pendientes
          );

          if (!proximaTomaProgramada) {
            console.log(`  ❌ No hay próxima toma programada`);
            return;
          }

          console.log('  🎯 Próxima toma:', proximaTomaProgramada.toLocaleString('es-AR'));

          if (proximaTomaProgramada > fechaFinTratamiento) {
            console.log(`  ⏭️ Próxima toma fuera del período de tratamiento`);
            return;
          }

          // ✅ Verificar si esta hora programada específica ya fue marcada como tomada
          const yaFueTomadaEstaHora = historialTomas.some(toma => {
            const fechaToma = new Date(toma);
            // Tolerancia de 30 minutos para considerar que es la misma hora programada
            return Math.abs(fechaToma.getTime() - proximaTomaProgramada.getTime()) < 30 * 60 * 1000;
          });

          if (yaFueTomadaEstaHora) {
            console.log(`  ✅ Ya tomado en esta hora programada`);
            return;
          }
          
          const tiempoRestante = proximaTomaProgramada.getTime() - ahora.getTime();
          
          console.log('  ⏱️ Tiempo restante:', Math.round(tiempoRestante / 60000), 'minutos');
          
          // Mostrar solo si está dentro de la ventana de tiempo
          if (tiempoRestante <= VENTANA_ANTES && tiempoRestante >= -VENTANA_DESPUES) {
            console.log(`  ✅ MOSTRANDO medicamento`);
            
            medicamentosActualizados.push({
              id_detalle: detalle.id_detalle,
              nombre: detalle.nombre_medicamento,
              dosis: detalle.dosis,
              hora: proximaTomaProgramada.toLocaleTimeString('es-AR', { hour: '2-digit', minute: '2-digit' }),
              fecha_hora_programada: proximaTomaProgramada.toISOString(),
              tomado: false,
              tipo: 'Medicamento',
              duracion_dias: detalle.duracion_dias,
              cantidad_total: detalle.cantidad_total,
              instrucciones: instruccionesObj.instrucciones || '',
              frecuencia_horas: frecuenciaHoras,
              receta_id: receta?.id_receta,
              fecha_receta: receta?.fecha_emision,
              fecha_inicio_tratamiento: fechaInicioTratamiento.toISOString(),
              fecha_fin_tratamiento: fechaFinTratamiento.toISOString(),
              es_atrasado: tiempoRestante < 0
            });
          } else {
            console.log(`  ⏰ Fuera de ventana (${Math.round(tiempoRestante / 60000)} min)`);
          }
        } catch (err) {
          console.error('Error procesando medicamento:', err);
        }
      });

      // ✅ Ordenar primero por nombre y luego por hora para mantener posiciones consistentes
      medicamentosActualizados.sort((a, b) => {
        // Primero ordenar por nombre del medicamento
        const nombreComp = a.nombre.localeCompare(b.nombre);
        if (nombreComp !== 0) return nombreComp;
        
        // Si son el mismo medicamento, ordenar por hora
        const fechaA = new Date(a.fecha_hora_programada);
        const fechaB = new Date(b.fecha_hora_programada);
        return fechaA.getTime() - fechaB.getTime();
      });

      console.log('\n=== RESUMEN ===');
      console.log('Total medicamentos a mostrar:', medicamentosActualizados.length);
      console.log('=== FIN CARGA ===\n');

      medicamentos = medicamentosActualizados;
      loading = false;

    } catch (error) {
      console.error('Error cargando medicamentos:', error);
      loading = false;
    }
  }

  // ✅ NUEVA FUNCIÓN: Calcular próxima HORA PROGRAMADA (independiente de cuándo se tomó)
  function calcularProximaHoraProgramada(horaPrimeraToma, frecuenciaHoras, historialTomas, ahora, fechaInicioTratamiento, ventanaDespues) {
    const [horas, minutos] = horaPrimeraToma.split(':').map(Number);
    
    // Para medicamentos semanales/mensuales (>= 24 horas)
    if (frecuenciaHoras >= 24) {
      const diasFrecuencia = Math.floor(frecuenciaHoras / 24);
      
      const primeraTomaTratamiento = new Date(fechaInicioTratamiento);
      primeraTomaTratamiento.setHours(horas, minutos, 0, 0);
      
      // Calcular todas las horas programadas desde el inicio
      let horaProgramada = new Date(primeraTomaTratamiento);
      
      // Buscar la primera hora no tomada (incluyendo pasadas recientes)
      while (horaProgramada < ahora) {
        // Verificar si esta hora ya fue tomada
        const yaFueTomada = historialTomas.some(toma => {
          const fechaToma = new Date(toma);
          return Math.abs(fechaToma.getTime() - horaProgramada.getTime()) < 30 * 60 * 1000;
        });
        
        // Si no fue tomada y está dentro de la ventana, mostrarla
        if (!yaFueTomada) {
          const tiempoDesdeHora = ahora.getTime() - horaProgramada.getTime();
          if (tiempoDesdeHora <= ventanaDespues) {
            return horaProgramada;
          }
        }
        
        // Siguiente hora programada
        horaProgramada.setDate(horaProgramada.getDate() + diasFrecuencia);
      }
      
      return horaProgramada; // Próxima hora futura
    }
    
    // Para medicamentos diarios (< 24 horas) - Ej: cada 2, 4, 6, 8 horas
    const tomasPorDia = Math.floor(24 / frecuenciaHoras);
    
    // Generar horas programadas desde ayer hasta mañana
    const horasProgramadas = [];
    
    const ayerInicio = new Date(ahora);
    ayerInicio.setDate(ayerInicio.getDate() - 1);
    ayerInicio.setHours(0, 0, 0, 0);
    
    for (let dia = 0; dia < 3; dia++) { // Ayer, hoy y mañana
      const diaBase = new Date(ayerInicio);
      diaBase.setDate(diaBase.getDate() + dia);
      
      for (let i = 0; i < tomasPorDia; i++) {
        const horaProgramada = new Date(diaBase);
        const horasTotales = horas + (i * frecuenciaHoras);
        horaProgramada.setHours(horasTotales % 24, minutos, 0, 0);
        
        // Ajustar el día si las horas se pasan de 24
        if (horasTotales >= 24) {
          horaProgramada.setDate(horaProgramada.getDate() + Math.floor(horasTotales / 24));
        }
        
        // Solo agregar si es después del inicio del tratamiento
        if (horaProgramada >= fechaInicioTratamiento) {
          horasProgramadas.push(horaProgramada);
        }
      }
    }
    
    // Ordenar cronológicamente
    horasProgramadas.sort((a, b) => a.getTime() - b.getTime());
    
    // Encontrar la primera hora programada pendiente
    for (const horaProgramada of horasProgramadas) {
      // Si la hora ya pasó hace más tiempo que la ventana, saltarla
      const tiempoDesdeHora = ahora.getTime() - horaProgramada.getTime();
      if (tiempoDesdeHora > ventanaDespues) {
        continue;
      }
      
      // Verificar si ya fue tomada (tolerancia de 30 minutos)
      const yaFueTomada = historialTomas.some(toma => {
        const fechaToma = new Date(toma);
        return Math.abs(fechaToma.getTime() - horaProgramada.getTime()) < 30 * 60 * 1000;
      });
      
      if (!yaFueTomada) {
        return horaProgramada; // Primera hora no tomada
      }
    }
    
    // Si no hay pendientes recientes, retornar la próxima futura
    const proximaFutura = horasProgramadas.find(h => h > ahora);
    return proximaFutura || null;
  }

  // Obtener historial de tomas del localStorage
  function obtenerHistorialTomas(idDetalle) {
    try {
      const tomas = JSON.parse(localStorage.getItem('tomas_medicamentos') || '{}');
      const historial = tomas[idDetalle];
      
      if (!historial) return [];
      
      if (typeof historial === 'string') {
        return [historial];
      }
      
      if (Array.isArray(historial)) {
        return historial;
      }
      
      return [];
    } catch {
      return [];
    }
  }

  // ✅ Guardar toma con la hora PROGRAMADA (no la hora actual)
  function guardarToma(idDetalle, fechaHoraProgramada) {
    try {
      const tomas = JSON.parse(localStorage.getItem('tomas_medicamentos') || '{}');
      
      if (!tomas[idDetalle]) {
        tomas[idDetalle] = [];
      }
      
      if (typeof tomas[idDetalle] === 'string') {
        tomas[idDetalle] = [tomas[idDetalle]];
      }
      
      // Agregar la hora PROGRAMADA (no la hora actual de cuando se marcó)
      tomas[idDetalle].push(fechaHoraProgramada);
      
      // Guardar solo las últimas 100 tomas
      if (tomas[idDetalle].length > 100) {
        tomas[idDetalle] = tomas[idDetalle].slice(-100);
      }
      
      localStorage.setItem('tomas_medicamentos', JSON.stringify(tomas));
      
      console.log(`💾 Guardado: ${idDetalle} para hora programada ${new Date(fechaHoraProgramada).toLocaleString('es-AR')}`);
    } catch (err) {
      console.error('Error guardando toma:', err);
    }
  }
  
  async function marcarTomado(medicamento) {
    try {
      // Guardar con la fecha/hora PROGRAMADA (no la actual)
      guardarToma(medicamento.id_detalle, medicamento.fecha_hora_programada);

      // Marcar como tomado visualmente
      medicamento.tomado = true;

      // Recargar después de medio segundo
      setTimeout(() => {
        cargarMedicamentos();
      }, 500);

    } catch (error) {
      console.error('Error marcando toma:', error);
      alert('Error al marcar el medicamento como tomado');
    }
  }
  
  function changeTab(newTab) {
    activeTab = newTab;
  }

  function handleMenuAction(action) {
    showMenu = false;
    
    if (action === 'logout') {
      handleLogout();
    } else if (action === 'perfil') {
      changeTab('perfil');
    } else if (action === 'configuracion') {
      alert('Ir a Configuración - Funcionalidad próximamente');
    } else if (action === 'citas') {
      alert('Ver Mis Citas Médicas - Funcionalidad próximamente');
    } else if (action === 'recetas') {
      alert('Ver Recetas Médicas - Funcionalidad próximamente');
    } else if (action === 'contacto') {
      alert('Contacto de Emergencia - Funcionalidad próximamente');
    } else if (action === 'ayuda') {
      alert('Centro de Ayuda y Soporte - Funcionalidad próximamente');
    }
  }
</script>

<div class="app-container">
  <header class="header">
    <div class="header-content">
      <div 
        class="profile-section" 
        role="button" 
        tabindex="0" 
        onclick={() => showMenu = !showMenu} 
        onkeydown={(e) => (e.key === 'Enter' || e.key === ' ') && (showMenu = !showMenu)} 
        style="cursor: pointer;"
        aria-label="Abrir menú de usuario"
      >
        <div class="avatar">
          <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <path d="M19 21v-2a4 4 0 0 0-4-4H9a4 4 0 0 0-4 4v2"/>
            <circle cx="12" cy="7" r="4"/>
          </svg>
        </div>
        <div class="profile-info">
          <h2>{pacienteData ? `${pacienteData.nombre} ${pacienteData.apellido}` : 'Cargando...'}</h2>
          <p>DNI: {pacienteData?.dni || '...'}</p>
        </div>
        
        {#if showMenu}
          <div class="dropdown-menu" role="presentation" onclick={(e) => e.stopPropagation()}>
            <button class="menu-item" onclick={() => handleMenuAction('perfil')}>
              <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M19 21v-2a4 4 0 0 0-4-4H9a4 4 0 0 0-4 4v2"/>
                <circle cx="12" cy="7" r="4"/>
              </svg>
              Perfil
            </button>
            <button class="menu-item" onclick={() => handleMenuAction('configuracion')}>
              <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <circle cx="12" cy="12" r="3"/>
                <path d="M12 1v6m0 6v6M5.6 5.6l4.2 4.2m4.2 4.2l4.2 4.2M1 12h6m6 0h6M5.6 18.4l4.2-4.2m4.2-4.2l4.2-4.2"/>
              </svg>
              Configuración
            </button>
            <button class="menu-item" onclick={() => handleMenuAction('citas')}>
              <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <rect width="18" height="18" x="3" y="4" rx="2" ry="2"/>
                <line x1="16" x2="16" y1="2" y2="6"/>
                <line x1="8" x2="8" y1="2" y2="6"/>
                <line x1="3" x2="21" y1="10" y2="10"/>
              </svg>
              Mis Citas Médicas
            </button>
            <button class="menu-item" onclick={() => handleMenuAction('recetas')}>
              <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M14.5 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V7.5L14.5 2z"/>
                <polyline points="14 2 14 8 20 8"/>
                <line x1="16" x2="8" y1="13" y2="13"/>
                <line x1="16" x2="8" y1="17" y2="17"/>
                <line x1="10" x2="8" y1="9" y2="9"/>
              </svg>
              Recetas Médicas
            </button>
            <button class="menu-item" onclick={() => handleMenuAction('contacto')}>
              <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07 19.5 19.5 0 0 1-6-6 19.79 19.79 0 0 1-3.07-8.67A2 2 0 0 1 4.11 2h3a2 2 0 0 1 2 1.72 12.84 12.84 0 0 0 .7 2.81 2 2 0 0 1-.45 2.11L8.09 9.91a16 16 0 0 0 6 6l1.27-1.27a2 2 0 0 1 2.11-.45 12.84 12.84 0 0 0 2.81.7A2 2 0 0 1 22 16.92z"/>
              </svg>
              Contacto de Emergencia
            </button>
            <button class="menu-item" onclick={() => handleMenuAction('ayuda')}>
              <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <circle cx="12" cy="12" r="10"/>
                <path d="M9.09 9a3 3 0 0 1 5.83 1c0 2-3 3-3 3"/>
                <line x1="12" x2="12.01" y1="17" y2="17"/>
              </svg>
              Ayuda y Soporte
            </button>
            
            <div class="menu-divider"></div>
            
            <button class="menu-item logout" onclick={() => handleMenuAction('logout')}>
              <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/>
                <polyline points="16 17 21 12 16 7"/>
                <line x1="21" x2="9" y1="12" y2="12"/>
              </svg>
              Cerrar Sesión
            </button>
          </div>
        {/if}
      </div>
      <div class="header-actions">
        <button class="notification-btn" onclick={() => showNotifications = !showNotifications} aria-label="Abrir notificaciones">
          <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"/>
            <path d="M13.73 21a2 2 0 0 1-3.46 0"/>
          </svg>
          <span class="badge">2</span>
        </button>
        
        {#if showNotifications}
          <div class="notifications-panel">
            <div class="notifications-header">
              <h4>Notificaciones</h4>
              <button class="close-notifications" onclick={() => showNotifications = false} aria-label="Cerrar notificaciones">
                <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <line x1="18" x2="6" y1="6" y2="18"/>
                  <line x1="6" x2="18" y1="6" y2="18"/>
                </svg>
              </button>
            </div>
            <div class="notification-item">
              <div class="notification-icon new">
                <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <rect width="18" height="18" x="3" y="4" rx="2" ry="2"/>
                  <line x1="16" x2="16" y1="2" y2="6"/>
                  <line x1="8" x2="8" y1="2" y2="6"/>
                  <line x1="3" x2="21" y1="10" y2="10"/>
                </svg>
              </div>
              <div class="notification-content">
                <p class="notification-title">Recordatorio de cita</p>
                <p class="notification-text">Tienes una cita mañana a las 10:00 AM</p>
                <p class="notification-time">Hace 2 horas</p>
              </div>
            </div>
            <div class="notification-item">
              <div class="notification-icon">
                <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <rect width="20" height="14" x="2" y="7" rx="2" ry="2"/>
                  <path d="M16 21V5a2 2 0 0 0-2-2h-4a2 2 0 0 0-2 2v16"/>
                </svg>
              </div>
              <div class="notification-content">
                <p class="notification-title">Hora de medicamento</p>
                <p class="notification-text">No olvides tomar tu Omeprazol a las 8:00 PM</p>
                <p class="notification-time">Hace 5 horas</p>
              </div>
            </div>
          </div>
        {/if}
      </div>
    </div>
  </header>

  <div class="date-section">
    <h3>{currentDate.charAt(0).toUpperCase() + currentDate.slice(1)}</h3>
    <p>
      {#if loading}
        Cargando medicamentos...
      {:else if medicamentos.length === 0}
        No tienes medicamentos pendientes en este momento
      {:else}
        Tienes {medicamentos.filter(m => !m.tomado).length} medicamento{medicamentos.filter(m => !m.tomado).length !== 1 ? 's' : ''} pendiente{medicamentos.filter(m => !m.tomado).length !== 1 ? 's' : ''}
      {/if}
    </p>
  </div>

  <main class="content">
    {#if activeTab === 'medicamentos'}
      {#if loading}
        <div class="loading-state">
          <p>Cargando tus medicamentos...</p>
        </div>
      {:else if medicamentos.length === 0}
        <div class="empty-state">
          <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <rect width="20" height="14" x="2" y="7" rx="2" ry="2"/>
            <path d="M16 21V5a2 2 0 0 0-2-2h-4a2 2 0 0 0-2 2v16"/>
          </svg>
          <h3>No hay medicamentos pendientes</h3>
          <p>Los medicamentos aparecerán 15 minutos antes de la hora programada</p>
        </div>
      {:else}
        <Home medicamentos={medicamentos} onToggleMed={marcarTomado} />
      {/if}
    {:else if activeTab === 'estado'}
      <MiEstado />
    {:else if activeTab === 'historial'}
      <Historial />
    {:else if activeTab === 'perfil'}
      <Perfil onVolver={() => changeTab('medicamentos')} />
    {/if}
  </main>

  <nav class="bottom-nav">
    <button class="nav-item" class:active={activeTab === 'medicamentos'} onclick={() => changeTab('medicamentos')}>
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
        <rect width="20" height="14" x="2" y="7" rx="2" ry="2"/>
        <path d="M16 21V5a2 2 0 0 0-2-2h-4a2 2 0 0 0-2 2v16"/>
      </svg>
      <span>Medicamentos</span>
    </button>
    
    <button class="nav-item" class:active={activeTab === 'estado'} onclick={() => changeTab('estado')}>
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
        <path d="M22 12h-4l-3 9L9 3l-3 9H2"/>
      </svg>
      <span>Mi Estado</span>
    </button>
    
    <button class="nav-item" class:active={activeTab === 'historial'} onclick={() => changeTab('historial')}>
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
        <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/>
        <polyline points="14 2 14 8 20 8"/>
      </svg>
      <span>Historial</span>
    </button>
  </nav>
</div>

<style>
  * {
    margin: 0;
    padding: 0;
    box-sizing: border-box;
  }
  
  .app-container {
    min-height: 100vh;
    background: linear-gradient(to bottom, #e0f2f1 0%, #b2dfdb 100%);
    padding-bottom: 80px;
    max-width: 100%;
    overflow-x: hidden;
  }
  
  .header {
    background: linear-gradient(135deg, #26a69a 0%, #4fa69e 100%);
    padding: 20px;
    color: white;
  }
  
  .header-content {
    max-width: 1200px;
    margin: 0 auto;
    display: flex;
    justify-content: space-between;
    align-items: center;
  }
  
  .profile-section {
    display: flex;
    align-items: center;
    gap: 12px;
    position: relative;
  }
  
  .avatar {
    width: 50px;
    height: 50px;
    background: rgba(255, 255, 255, 0.2);
    border-radius: 50%;
    display: flex;
    align-items: center;
    justify-content: center;
  }
  
  .avatar svg {
    width: 28px;
    height: 28px;
  }
  
  .profile-info h2 {
    margin: 0;
    font-size: 18px;
    font-weight: 600;
  }
  
  .profile-info p {
    margin: 4px 0 0;
    font-size: 13px;
    opacity: 0.9;
  }
  
  .header-actions {
    display: flex;
    align-items: center;
    gap: 16px;
    position: relative;
  }
  
  .notification-btn {
    position: relative;
    width: 44px;
    height: 44px;
    background: rgba(255, 255, 255, 0.2);
    border: none;
    border-radius: 50%;
    color: white;
    cursor: pointer;
    display: flex;
    align-items: center;
    justify-content: center;
  }
  
  .notification-btn svg {
    width: 22px;
    height: 22px;
  }
  
  .badge {
    position: absolute;
    top: 6px;
    right: 6px;
    background: #ef4444;
    color: white;
    font-size: 10px;
    font-weight: 600;
    width: 18px;
    height: 18px;
    border-radius: 50%;
    display: flex;
    align-items: center;
    justify-content: center;
  }
  
  .dropdown-menu {
    position: absolute;
    top: 70px;
    left: 0;
    background: white;
    border-radius: 16px;
    box-shadow: 0 10px 30px rgba(0, 0, 0, 0.2);
    min-width: 260px;
    overflow: hidden;
    animation: slideIn 0.3s ease-out;
    z-index: 1001;
  }
  
  @keyframes slideIn {
    from {
      opacity: 0;
      transform: translateY(-10px);
    }
    to {
      opacity: 1;
      transform: translateY(0);
    }
  }
  
  .menu-item {
    width: 100%;
    padding: 14px 18px;
    background: none;
    border: none;
    display: flex;
    align-items: center;
    gap: 12px;
    cursor: pointer;
    font-size: 14px;
    font-weight: 500;
    color: #1e293b;
    transition: background 0.2s;
    text-align: left;
  }
  
  .menu-item svg {
    width: 20px;
    height: 20px;
    color: #64748b;
    flex-shrink: 0;
  }
  
  .menu-item:hover {
    background: #f1f5f9;
  }
  
  .menu-divider {
    height: 1px;
    background: #e2e8f0;
    margin: 8px 0;
  }
  
  .menu-item.logout {
    color: #ef4444;
    font-weight: 600;
  }
  
  .menu-item.logout svg {
    color: #ef4444;
  }
  
  .menu-item.logout:hover {
    background: #fef2f2;
  }
  
  .notifications-panel {
    position: absolute;
    top: 60px;
    right: 0;
    background: white;
    border-radius: 16px;
    box-shadow: 0 10px 30px rgba(0, 0, 0, 0.2);
    width: 340px;
    max-height: 480px;
    overflow-y: auto;
    animation: slideIn 0.3s ease-out;
    z-index: 1001;
  }
  
  .notifications-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 16px 18px;
    border-bottom: 1px solid #e2e8f0;
    position: sticky;
    top: 0;
    background: white;
  }
  
  .notifications-header h4 {
    margin: 0;
    font-size: 16px;
    font-weight: 600;
    color: #1e293b;
  }
  
  .close-notifications {
    background: none;
    border: none;
    color: #64748b;
    cursor: pointer;
    padding: 4px;
    display: flex;
    align-items: center;
    justify-content: center;
    border-radius: 6px;
    transition: all 0.2s;
  }
  
  .close-notifications:hover {
    background: #f1f5f9;
    color: #1e293b;
  }
  
  .close-notifications svg {
    width: 18px;
    height: 18px;
  }
  
  .notification-item {
    display: flex;
    gap: 12px;
    padding: 14px 18px;
    border-bottom: 1px solid #f1f5f9;
    cursor: pointer;
    transition: background 0.2s;
  }
  
  .notification-item:hover {
    background: #f8fafc;
  }
  
  .notification-item:last-child {
    border-bottom: none;
  }
  
  .notification-icon {
    width: 40px;
    height: 40px;
    background: #f1f5f9;
    border-radius: 10px;
    display: flex;
    align-items: center;
    justify-content: center;
    flex-shrink: 0;
  }
  
  .notification-icon.new {
    background: #e0f2f1;
  }
  
  .notification-icon svg {
    width: 20px;
    height: 20px;
    color: #64748b;
  }
  
  .notification-icon.new svg {
    color: #26a69a;
  }
  
  .notification-content {
    flex: 1;
  }
  
  .notification-title {
    margin: 0 0 4px 0;
    font-size: 14px;
    font-weight: 600;
    color: #1e293b;
  }
  
  .notification-text {
    margin: 0 0 6px 0;
    font-size: 13px;
    color: #64748b;
    line-height: 1.4;
  }
  
  .notification-time {
    margin: 0;
    font-size: 12px;
    color: #94a3b8;
  }
  
  .date-section {
    padding: 20px;
    background: white;
    margin: -20px auto 0;
    max-width: 1200px;
    border-radius: 16px;
    box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
  }
  
  .date-section h3 {
    margin: 0;
    font-size: 20px;
    color: #1e293b;
  }
  
  .date-section p {
    margin: 6px 0 0;
    color: #64748b;
    font-size: 14px;
  }
  
  .content {
    padding: 20px;
    max-width: 1200px;
    margin: 0 auto;
  }

  .loading-state {
    text-align: center;
    padding: 3rem 1rem;
    color: #64748b;
  }

  .empty-state {
    text-align: center;
    padding: 3rem 1rem;
    color: #64748b;
  }

  .empty-state svg {
    width: 64px;
    height: 64px;
    margin: 0 auto 1rem;
    opacity: 0.3;
  }

  .empty-state h3 {
    margin: 0 0 0.5rem 0;
    color: #1e293b;
    font-size: 1.25rem;
  }

  .empty-state p {
    margin: 0;
    font-size: 0.95rem;
  }
  
  .bottom-nav {
    position: fixed;
    bottom: 0;
    left: 0;
    right: 0;
    background: white;
    display: flex;
    justify-content: space-around;
    padding: 8px 8px 20px;
    box-shadow: 0 -2px 10px rgba(0, 0, 0, 0.1);
  }
  
  .nav-item {
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 4px;
    background: none;
    border: none;
    color: #94a3b8;
    cursor: pointer;
    padding: 8px 12px;
    border-radius: 12px;
    transition: all 0.2s;
    font-size: 11px;
  }
  
  .nav-item svg {
    width: 24px;
    height: 24px;
  }
  
  .nav-item.active {
    color: #26a69a;
    background: #e0f2f1;
  }
  
  @media (max-width: 768px) {
    .date-section {
      margin: -20px 16px 0;
    }
    
    .header {
      padding: 20px 20px 30px;
    }
  }
  
  @media (min-width: 768px) {
    .app-container {
      padding-bottom: 0;
    }
    
    .bottom-nav {
      position: relative;
      max-width: 1200px;
      margin: 20px auto 0;
      border-radius: 16px;
      padding: 12px;
      box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
    }
  }
  
  @media (max-width: 375px) {
    .header {
      padding: 16px 16px 24px;
    }
    
    .profile-info h2 {
      font-size: 16px;
    }
    
    .profile-info p {
      font-size: 12px;
    }
    
    .date-section {
      padding: 16px;
    }
    
    .date-section h3 {
      font-size: 18px;
    }
    
    .nav-item {
      padding: 6px 8px;
      font-size: 10px;
    }
    
    .nav-item svg {
      width: 20px;
      height: 20px;
    }
  }
</style>