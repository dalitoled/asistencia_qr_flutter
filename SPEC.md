# Sistema de Control de Asistencia - Asociación de Agua Potable Tolata Chico

## 1. Información del Proyecto

- **Nombre**: Control Asistencia Agua Potable Tolata Chico
- **Tipo**: Aplicación móvil empresarial (Flutter + Firebase)
- **Plataforma**: Android (primario), compatible con iOS
- **Usuario objetivo**: Administradores y operadores de la asociación

## 2. Especificación Técnica

### 2.1 Stack Tecnológico

**Frontend:**
- Flutter 3.x (última versión estable)
- Dart 3.x
- Riverpod 2.x (State Management)
- GoRouter (Navegación)
- Material Design 3

**Backend:**
- Firebase Authentication
- Cloud Firestore
- Firebase Storage
- Firebase Cloud Messaging
- Firebase Functions
- Firebase Analytics
- Firebase Crashlytics

### 2.2 Arquitectura - Clean Architecture

```
lib/
├── core/
│   ├── constants/
│   ├── errors/
│   ├── theme/
│   └── utils/
├── models/
├── repositories/
├── services/
├── providers/
├── screens/
├── widgets/
├── routes/
└── firebase/
```

## 3. Especificación UI/UX

### 3.1 Paleta de Colores

**Colores Primarios:**
- Primary: #1565C0 (Azul institucional)
- Primary Variant: #0D47A1
- Secondary: #26A69A (Verde azulado)

**Colores Neutros:**
- Background: #FAFAFA
- Surface: #FFFFFF
- Error: #D32F2F
- Success: #388E3C
- Warning: #F57C00

**Modo Oscuro:**
- Background: #121212
- Surface: #1E1E1E
- Primary: #90CAF9

### 3.2 Tipografía

- Headlines: Roboto Bold
- Body: Roboto Regular
- Captions: Roboto Light

### 3.3 Layout

- Navigation: Bottom Navigation Bar (5 tabs)
- Responsive: Adaptable a múltiples tamaños de pantalla
- Animaciones: Transiciones suaves (300ms)

## 4. Módulos y Funcionalidades

### 4.1 Autenticación

**Pantallas:**
- Splash Screen (carga de Firebase)
- Login Screen
- Recuperación de contraseña

**Funcionalidades:**
- Login con email/password
- Logout
- Sesión persistente (SharedPreferences + SecureStorage)
- Validaciones de email y contraseña

**Roles:**
- Administrador (acceso completo)
- Operador (solo registro de asistencia)

### 4.2 Socios (CRUD)

**Modelo de Datos:**
```dart
class Socio {
  String uid;
  String nombreCompleto;
  String ci;
  String? telefono;
  String? direccion;
  bool estado; // activo/inactivo
  DateTime fechaRegistro;
  String? qrCode;
  String? fotoUrl;
}
```

**Funcionalidades:**
- Crear socio (con generación automática de QR)
- Editar socio
- Eliminar socio (soft delete)
- Buscar por nombre, CI, teléfono
- Filtrar por estado
- Ver historial de asistencia
- Ver historial de pagos

### 4.3 Generación de QR

- QR único por socio (UUID codificado)
- qr_flutter para generación visual
- QR contiene: socio_id + timestamp + hash
- Opciones: compartir, descargar PDF

### 4.4 Escaneo QR y Asistencia

**Tipo de Registro:**
- ASISTENCIA: Antes de hora límite
- RETRASO: Después de hora límite
- FALTA: No registrado (generado automáticamente)

**Configuraciones:**
- Hora límite configurable (default: 08:00)
- Multa por retraso configurable
- Multa por falta configurable

**Flujo de Escaneo:**
1. Abrir cámara
2. Escanear QR
3. Validar QR válido
4. Verificar si ya registró hoy
5. Determinar tipo (asistencia/retraso)
6. Registrar en Firestore
7. Mostrar confirmación visual
8. Reproducir sonido

### 4.5 Multas y Pagos

**Modelo Multa:**
```dart
class Multa {
  String id;
  String socioId;
  String tipo; // 'retraso' | 'falta'
  double monto;
  String estado; // 'pendiente' | 'pagado'
  DateTime fecha;
  String? observaciones;
  String? idPago;
}
```

**Modelo Pago:**
```dart
class Pago {
  String id;
  String socioId;
  double monto;
  DateTime fecha;
  String? observaciones;
  List<String> multasIds;
}
```

### 4.6 Dashboard

**Estadísticas:**
- Total socios activos
- Asistencia de hoy
- Retrasos de hoy
- Faltas de hoy
- Total multas pendientes
- Total recaudado este mes

**Gráficos (fl_chart):**
- Asistencia semanal (barras)
- Tendencia mensual (línea)
- Distribución de multas (pie)

### 4.7 Reportes

**Tipos de Reporte:**
- Por socio (historial completo)
- Por fecha (rango seleccionado)
- Por mes (resumen mensual)
- Por tipo (asistencia/retraso/falta)

**Exportación:**
- PDF con formato institucional
- Excel (.xlsx) con Syncfusion

### 4.8 Registros Recientes

- Lista de últimas 50 actividades
- Tipo de actividad (asistencia/retraso/falta/pago)
- Fecha y hora
- Socio relacionado

## 5. Estructura de Base de Datos (Firestore)

### Collections Principales:

```
usuarios/
  {uid}
    - email
    - rol
    - nombre
    - createdAt

socios/
  {uid}
    - nombreCompleto
    - ci
    - telefono
    - direccion
    - estado
    - fechaRegistro
    - qrCode
    - fotoUrl

asistencias/
  {uid}
    - socioId
    - socioNombre
    - tipo (asistencia/retraso/falta)
    - fechaHora
    - operadorId

pagos/
  {uid}
    - socioId
    - monto
    - fecha
    - observaciones

multas/
  {uid}
    - socioId
    - tipo
    - monto
    - estado
    - fecha
    - observaciones

configuraciones/
  {uid}
    - horaLimite
    - multaRetraso
    - multaFalta
    - nombreInstitucion
    - logoUrl
```

## 6. Firebase Functions

### Funciones Automáticas:

1. **generarFaltasDiarias**: Ejecuta a medianoche para generar faltantes
2. **notificarDeudas**: Envía notificación a socios con multas pendientes
3. **calcularMultas**: Calcula multas según configuración

## 7. Reglas de Seguridad (Firestore)

### Roles y Permisos:

**Administrador:**
- Lectura/escritura completa

**Operador:**
- Lectura de socios
- Crear asistencia
- Solo lectura de reportes

## 8. Funcionalidades Extra

- Búsqueda avanzada condebounce
- Paginación infinita
- Pull-to-refresh
- Modo offline (Firestore cache)
- Notificaciones push (FCM)
- Dark mode automático (seguir sistema)
- Animaciones de transición

## 9. Requisitos de Rendimiento

- Tiempo de inicio < 3 segundos
- Escaneo QR < 500ms
- Carga de listas < 1 segundo
- Animaciones 60fps

## 10. Checklist de Entrega

- [ ] Código Flutter completo
- [ ] Configuración firebase_options.dart
- [ ] Firestore Rules
- [ ] Firebase Functions
- [ ] README con guía
- [ ] APK compilado