# Guía de Instalación y Despliegue

## Sistema de Control de Asistencia - Agua Potable Tolata Chico

---

## 1. Requisitos del Sistema

### Software Necesario

- **Flutter SDK**: 3.x o superior
- **Dart**: 3.x o superior
- **Node.js**: 18.x o superior (para Firebase Functions)
- **Firebase CLI**: Última versión
- **Android Studio**: Latest (para desarrollo Android)
- **Git**: Para control de versiones

### Plataformas Soportadas

- Android (API 21+)
- iOS (12.0+)

---

## 2. Configuración de Firebase

### 2.1 Crear Proyecto en Firebase Console

1. Accede a [Firebase Console](https://console.firebase.google.com/)
2. Haz clic en "Agregar proyecto"
3. Ingresa el nombre: `asistencia-agua-tolata`
4. Desactiva Google Analytics (opcional)
5. Crea el proyecto

### 2.2 Habilitar Servicios

#### Authentication
1. En el panel izquierdo, ve a "Authentication"
2. Haz clic en "Comenzar"
3. En la pestaña "Método de inicio de sesión", habilita "Correo electrónico/contraseña"
4. Guarda los cambios

#### Cloud Firestore
1. Ve a "Cloud Firestore"
2. Haz clic en "Crear base de datos"
3. Selecciona "Comenzar en modo de producción"
4. Elige la ubicación más cercana (South America)

#### Firebase Storage
1. Ve a "Storage"
2. Haz clic en "Comenzar"
3. Acepta las reglas de seguridad predeterminadas

#### Firebase Cloud Messaging
1. Ve a "Cloud Messaging"
2. Activa la opción

### 2.3 Configurar Roles de Usuario

En Firestore, crea una colección `usuarios` con la siguiente estructura:

```json
{
  "uid": "user_uid",
  "email": "admin@ejemplo.com",
  "nombre": "Administrador",
  "rol": "admin",
  "createdAt": "2024-01-01T00:00:00Z"
}
```

### 2.4 Descargar Configuración

#### Android
1. Ve a "Configuración del proyecto" (ícono de engranaje)
2. En "Tus apps", selecciona Android
3. Descarga `google-services.json`
4. Copia el archivo en: `android/app/google-services.json`

#### iOS
1. Selecciona iOS en lugar de Android
2. Descarga `GoogleService-Info.plist`
3. Copia en: `ios/Runner/GoogleService-Info.plist`

---

## 3. Configuración del Proyecto Flutter

### 3.1 Clonar el Proyecto

```bash
git clone <repository-url>
cd asistencia_agua_potable
```

### 3.2 Instalar Dependencias

```bash
flutter pub get
```

### 3.3 Configurar Firebase Functions

```bash
cd functions
npm install
cd ..
```

### 3.4 Desplegar Firebase

```bash
# Desplegar reglas de Firestore
firebase deploy --only firestore:rules

# Desplegar Storage rules
firebase deploy --only storage:rules

# Desplegar Functions
firebase deploy --only functions
```

---

## 4. Ejecución

### 4.1 Modo Desarrollo

```bash
flutter run
```

### 4.2 Construir APK Debug

```bash
flutter build apk --debug
```

El APK se generará en: `build/app/outputs/flutter-apk/app-debug.apk`

### 4.3 Construir APK Release

```bash
flutter build apk --release
```

---

## 5. Configuración Inicial

### 5.1 Primer Usuario Administrador

1. Ejecuta la aplicación
2. En la consola de Firebase, crea un documento en la colección `usuarios`:
   - `uid`: Genera un UUID
   - `email`: Tu correo
   - `nombre`: Tu nombre
   - `rol`: "admin"
   - `createdAt`: Fecha actual

3. En Authentication, crea el usuario con el mismo correo y contraseña

### 5.2 Configuración del Sistema

En Firestore, crea un documento en `configuraciones` con ID `default`:

```json
{
  "uid": "default",
  "horaLimite": "08:00",
  "multaRetraso": 10.0,
  "multaFalta": 25.0,
  "nombreInstitucion": "Asociación de Agua Potable Tolata Chico"
}
```

---

## 6. Estructura de Colecciones

### Colecciones Principales

```
usuarios/
  └── {uid}
      - email
      - nombre
      - rol (admin/operador)
      - createdAt

socios/
  └── {uid}
      - nombreCompleto
      - ci
      - telefono
      - direccion
      - estado (boolean)
      - fechaRegistro
      - qrCode
      - fotoUrl

asistencias/
  └── {uid}
      - socioId
      - socioNombre
      - socioCi
      - tipo (asistencia/retraso/falta)
      - fechaHora
      - operadorId

multas/
  └── {uid}
      - socioId
      - socioNombre
      - tipo (retraso/falta)
      - monto
      - estado (pendiente/pagado)
      - fecha
      - observaciones
      - idPago

pagos/
  └── {uid}
      - socioId
      - socioNombre
      - monto
      - fecha
      - observaciones
      - multasIds

configuraciones/
  └── default
      - horaLimite
      - multaRetraso
      - multaFalta
      - nombreInstitucion
```

---

## 7. Solución de Problemas

### Error: No se encontró google-services.json
1. Descarga el archivo desde Firebase Console
2. Colócalo en `android/app/google-services.json`

### Error: Permisos de cámara denied
1. Ve a Configuración > Apps > Control de Asistencia > Permisos
2. Habilita "Cámara"

### Error: Timeout en Firebase Functions
1. Verifica tu conexión a internet
2. Revisa los logs en Firebase Console > Functions

### Error: FIRPermissionDenied
1. Verifica que FCM esté habilitado en Firebase Console

---

## 8. Mantenimiento

### Actualizar Functions
```bash
cd functions
# Edita index.js
firebase deploy --only functions
```

### Actualizar App
```bash
flutter build apk --release
# Copia el APK a los dispositivos
```

### Respaldar Base de Datos
Usa la función de exportación de Firestore en Firebase Console

---

## 9. Contacto

Para soporte técnico:
- Email: admin@aguapotable-tolatachico.com
- Teléfono: +591 XXXXXXXX

---

**Versión**: 1.0.0
**Fecha**: Mayo 2026
**Desarrollado por**: Equipo de Desarrollo