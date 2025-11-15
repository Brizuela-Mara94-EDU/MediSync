# Panel de Administración - MediSync

## 📋 Descripción

Panel administrativo completo para gestionar Usuarios, Pacientes y Médicos en MediSync. Permite crear, editar y eliminar registros con todos los datos necesarios para el sistema.

## 🎯 Funcionalidades

### 1. **Gestión de Usuarios**
- ✅ Crear nuevos usuarios con todos los datos
- ✅ Editar información de usuarios existentes
- ✅ Cambiar contraseñas
- ✅ Activar/Desactivar usuarios
- ✅ Eliminar usuarios (elimina también registros relacionados en cascada)

**Campos disponibles:**
- Nombre y Apellido
- DNI (único)
- Fecha de Nacimiento
- Email (único)
- Teléfono
- Rol (paciente, medico, admin)
- Estado (activo/inactivo)
- Contraseña (hash seguro con bcrypt)

### 2. **Gestión de Pacientes**
- ✅ Crear registros de pacientes vinculados a usuarios
- ✅ Editar información médica específica
- ✅ Eliminar registros de pacientes
- ✅ Visualizar todos los datos del usuario asociado

**Campos específicos:**
- Domicilio
- Obra Social
- Grupo Sanguíneo (A+, A-, B+, B-, AB+, AB-, O+, O-)

### 3. **Gestión de Médicos**
- ✅ Crear registros de médicos vinculados a usuarios
- ✅ Editar información profesional
- ✅ Eliminar registros de médicos
- ✅ Validación de matrícula única

**Campos específicos:**
- Matrícula Profesional (único)
- Especialidad

## 🚀 Cómo Acceder

### Desde la página de Login:
1. En la pantalla de inicio de sesión
2. Hacer clic en el botón **"Panel de Administración"** (ícono de engranaje) en la parte inferior

### Desde la página de Registro:
1. En la pantalla de registro
2. Hacer clic en el botón **"Panel de Administración"** (ícono de engranaje) en la parte inferior

## 📝 Instrucciones de Configuración

### 1. Ejecutar función SQL en Supabase

Antes de usar el panel, debes ejecutar la siguiente función SQL en el **SQL Editor de Supabase**:

```sql
-- Ver archivo: FUNCION_ACTUALIZAR_CONTRASENA.sql
```

Esta función permite actualizar contraseñas de forma segura desde el panel de administración.

**Pasos:**
1. Ir a tu proyecto de Supabase
2. Abrir **SQL Editor**
3. Copiar y pegar el contenido de `FUNCION_ACTUALIZAR_CONTRASENA.sql`
4. Ejecutar la consulta

### 2. Verificar permisos RLS

El panel utiliza las políticas de Row Level Security (RLS) que ya tienes configuradas. Asegúrate de que las políticas permitan operaciones CRUD:

- `Permitir todas las operaciones en usuarios`
- `Permitir todas las operaciones en pacientes`
- `Permitir todas las operaciones en medicos`

## 🎨 Características del Panel

### Interfaz
- 📊 Tablas con datos organizados y paginación automática
- 🔍 Vista clara de todos los campos
- 🎯 Badges de colores para roles y estados
- 📱 Diseño responsive para móviles y tablets

### Funcionalidades CRUD

#### **Crear**
- Modals con formularios completos
- Validación de campos obligatorios
- Mensajes de error descriptivos
- Validación de unicidad (DNI, Email, Matrícula)

#### **Editar**
- Pre-carga de datos existentes
- Actualización parcial de campos
- Cambio de contraseña opcional
- Confirmación de cambios

#### **Eliminar**
- Confirmación antes de eliminar
- Eliminación en cascada de registros relacionados
- Mensajes de éxito/error

### Navegación
- 🔄 Tabs para cambiar entre Usuarios, Pacientes y Médicos
- ⬅️ Botón "Volver" para regresar al login
- 📍 Indicador visual de sección activa

## 🔐 Seguridad

- Contraseñas hasheadas con bcrypt (10 rounds)
- Función RPC con `SECURITY DEFINER` para operaciones de base de datos
- Validación de entrada en frontend
- Manejo seguro de errores

## 📦 Componentes Creados

```
src/lib/pages/admin/
├── AdminPanel.svelte          # Panel principal con navegación
├── UsuariosCRUD.svelte        # CRUD completo de usuarios
├── PacientesCRUD.svelte       # CRUD completo de pacientes
└── DoctoresCRUD.svelte        # CRUD completo de médicos
```

## 🎯 Flujo de Trabajo

### Crear Usuario → Paciente/Médico

1. **Crear Usuario**
   - Ir a tab "Usuarios"
   - Clic en "Nuevo Usuario"
   - Completar formulario (seleccionar rol: paciente/medico)
   - Guardar

2. **Crear Registro Específico**
   - Si el rol es "paciente": ir a tab "Pacientes"
   - Si el rol es "medico": ir a tab "Médicos"
   - Clic en "Nuevo Paciente/Médico"
   - Seleccionar el usuario creado
   - Completar datos específicos
   - Guardar

### Notas Importantes

- ⚠️ Solo se pueden crear pacientes/médicos para usuarios que ya existen
- ⚠️ Un usuario puede tener UN SOLO registro de paciente O médico
- ⚠️ Al eliminar un usuario, se eliminan automáticamente sus registros relacionados
- ⚠️ La matrícula del médico debe ser única
- ⚠️ DNI y Email deben ser únicos

## 🐛 Solución de Problemas

### Error: "La matrícula ya está registrada"
- Verificar que la matrícula no esté en uso por otro médico
- Usar un formato diferente (ej: "MP 12345" en lugar de "12345")

### Error: "El correo electrónico o DNI ya está registrado"
- Verificar que no exista otro usuario con el mismo email o DNI
- Revisar en la tabla de usuarios

### No aparecen usuarios en el selector
- Asegurarse de crear primero un usuario con el rol correcto
- Verificar que el usuario no tenga ya un registro de paciente/médico

## 📊 Estructura de Datos

```
usuarios
├── id_usuario (UUID, PK)
├── email (UNIQUE)
├── contrasena (HASH)
├── rol (paciente|medico|admin)
├── nombre
├── apellido
├── dni (UNIQUE)
├── fecha_nacimiento
├── telefono
└── activo (BOOLEAN)

pacientes
├── id_paciente (UUID, PK)
├── id_usuario (UUID, FK → usuarios, UNIQUE)
├── domicilio
├── obra_social
└── grupo_sanguineo

medicos
├── id_medico (UUID, PK)
├── id_usuario (UUID, FK → usuarios, UNIQUE)
├── matricula (UNIQUE)
└── especialidad
```

## 🎨 Colores del Panel

- **Admin**: Amarillo (`#fef3c7`)
- **Médico**: Azul (`#dbeafe`)
- **Paciente**: Verde (`#d1fae5`)
- **Activo**: Verde (`#d1fae5`)
- **Inactivo**: Rojo (`#fee2e2`)
- **Grupo Sanguíneo**: Amarillo (`#fef3c7`)
- **Matrícula**: Azul (`#dbeafe`)

## 💡 Mejoras Futuras

- [ ] Búsqueda y filtrado de registros
- [ ] Exportar datos a CSV/Excel
- [ ] Paginación para grandes cantidades de datos
- [ ] Historial de cambios
- [ ] Roles de administración con permisos específicos
- [ ] Carga masiva de usuarios desde archivo
