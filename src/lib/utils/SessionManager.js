// SessionManager.js
// Utilidad para manejar sesiones de usuario en MediSync

/**
 * Guarda la sesión del usuario en localStorage
 */
export function guardarSesion(usuario, datosAdicionales = null) {
  const sesion = {
    id_usuario: usuario.id_usuario,
    email: usuario.email,
    nombre: usuario.nombre,
    apellido: usuario.apellido,
    rol: usuario.rol,
    datosAdicionales,
    timestamp: Date.now(),
    expiresAt: Date.now() + (24 * 60 * 60 * 1000) // 24 horas
  };
  
  localStorage.setItem('medisync_session', JSON.stringify(sesion));
  console.log('✅ Sesión guardada:', sesion);
  return sesion;
}

/**
 * Obtiene la sesión actual del usuario
 */
export function obtenerSesion() {
  try {
    const sesionString = localStorage.getItem('medisync_session');
    if (!sesionString) {
      console.log('No hay sesión activa');
      return null;
    }

    const sesion = JSON.parse(sesionString);
    
    // Verificar si la sesión ha expirado
    if (sesion.expiresAt && Date.now() > sesion.expiresAt) {
      console.log('⚠️ Sesión expirada');
      cerrarSesion();
      return null;
    }

    console.log('✅ Sesión activa:', sesion);
    return sesion;
  } catch (error) {
    console.error('Error al obtener sesión:', error);
    return null;
  }
}

/**
 * Verifica si hay una sesión activa
 */
export function tieneSesionActiva() {
  return obtenerSesion() !== null;
}

/**
 * Obtiene el rol del usuario actual
 */
export function obtenerRolActual() {
  const sesion = obtenerSesion();
  return sesion?.rol || null;
}

/**
 * Verifica si el usuario tiene un rol específico
 */
export function tieneRol(rolEsperado) {
  const rol = obtenerRolActual();
  return rol === rolEsperado;
}

/**
 * Cierra la sesión del usuario
 */
export function cerrarSesion() {
  localStorage.removeItem('medisync_session');
  console.log('✅ Sesión cerrada');
}

/**
 * Actualiza el último acceso del usuario
 */
export function actualizarUltimoAcceso() {
  const sesion = obtenerSesion();
  if (sesion) {
    sesion.timestamp = Date.now();
    localStorage.setItem('medisync_session', JSON.stringify(sesion));
  }
}

/**
 * Obtiene información completa del usuario actual
 */
export function obtenerUsuarioActual() {
  const sesion = obtenerSesion();
  if (!sesion) return null;

  return {
    id: sesion.id_usuario,
    email: sesion.email,
    nombre: sesion.nombre,
    apellido: sesion.apellido,
    nombreCompleto: `${sesion.nombre} ${sesion.apellido}`,
    rol: sesion.rol,
    datosAdicionales: sesion.datosAdicionales
  };
}

/**
 * Redirige según el rol del usuario
 */
export function redirigirSegunRol() {
  const rol = obtenerRolActual();
  
  console.log('🔀 Redirigiendo según rol:', rol);
  
  switch(rol) {
    case 'paciente':
      return 'patient';
    case 'medico':
      return 'doctor';
    case 'admin':
      return 'admin';
    default:
      console.error('❌ Rol no reconocido:', rol);
      return 'login';
  }
}

// Exportar todo como objeto por defecto también
export default {
  guardarSesion,
  obtenerSesion,
  tieneSesionActiva,
  obtenerRolActual,
  tieneRol,
  cerrarSesion,
  actualizarUltimoAcceso,
  obtenerUsuarioActual,
  redirigirSegunRol
};