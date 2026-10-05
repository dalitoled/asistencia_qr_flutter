# Sistema de Control de Asistencia y Gestión de Socios (Flutter & Firebase)

Aplicación móvil corporativa desarrollada en **Flutter** con backend serverless en **Firebase** para la administración, recaudación y control de asistencia de socios mediante **códigos QR dinámicos** y soporte **offline**.

---

## 📱 Características Principales

- **Control de Asistencia con QR:** Escaneo de alta velocidad con cámara nativa y generación dinámica de credenciales QR únicas por socio.
- **Modo Offline Resiliente:** Persistencia local de datos y cola de sincronización en segundo plano, permitiendo operar sin conexión en zonas rurales.
- **Gestión Integral de Socios:** Módulo CRUD completo de padrón de afiliados y estados de cuenta.
- **Módulo Financiero & Cobranzas:** Registro automático de asistencias, retrasos, cálculo de multas y liquidación de cuotas.
- **Reportería & Exportación:** Generación y exportación de planillas y balances contables en **PDF** y **Excel**.
- **Notificaciones Push:** Integración con **Firebase Cloud Messaging (FCM)** para recordatorios de asambleas y avisos de cobro.
- **Autenticación Segura:** Control de acceso por roles mediante Firebase Authentication.

---

## 🛠️ Stack Tecnológico

- **Framework Móvil:** [Flutter](https://flutter.dev/) (SDK 3.x)
- **Lenguaje:** [Dart](https://dart.dev/)
- **Gestión de Estado:** [Riverpod](https://riverpod.dev/)
- **Navegación:** [GoRouter](https://pub.dev/packages/go_router)
- **Backend & Base de Datos:**
  - Firebase Authentication
  - Cloud Firestore
  - Firebase Cloud Functions (Node.js)
  - Firebase Cloud Storage & FCM

---

## 🚀 Instalación y Puesta en Marcha

```bash
# 1. Clonar el repositorio
git clone https://github.com/dalitoled/control_asistencia_qr_flutter.git
cd control_asistencia_qr_flutter

# 2. Instalar dependencias de Flutter
flutter pub get

# 3. Configurar Firebase
# Asegurar la presencia de firebase_options.dart o google-services.json

# 4. Ejecutar en dispositivo o emulador
flutter run
```

---

## 📬 Contacto

- **Desarrollador:** Daniel Ledezma Castro
- **LinkedIn:** [linkedin.com/in/daniel-ledezma-castro-261337261](https://www.linkedin.com/in/daniel-ledezma-castro-261337261/)
- **Correo:** [ledezmacastrodaniel@gmail.com](mailto:ledezmacastrodaniel@gmail.com)