# DAM Proyect — Fase 1b: Fotos, Posición, Consultas y Navegación

Proyecto de 2.º de **Desarrollo de Aplicaciones Multiplataforma (DAM)**.

**Módulos Evaluados:**
- **0489 PMDM:** Programación Multimedia y Dispositivos Móviles (RA2.b, RA2.d, RA2.g, RA2.j, RA2.k, RA2.l, RA2.m, RA2.n).
- **0486 AD:** Acceso a Datos (RA4.b, RA4.d, RA4.e, RA4.f, RA4.g, RA4.i).
- **0490 PSP:** Programación de Servicios y Procesos (RA2.a, RA2.c, RA2.e).

---

## 1. Descripción del Proyecto

`dam_proyect` es una aplicación móvil y web desarrollada con **Flutter** y **Dart**, que integra autenticación y almacenamiento en tiempo real mediante **Firebase (Authentication, Cloud Firestore y Firebase Storage)**, mapas interactivos con **OpenStreetMap (flutter_map)** y geolocalización.

La aplicación permite la interacción entre usuarios a través de mensajería instantánea en tiempo real, personalización de perfiles con fotografías de cámara/galería, un asistente inteligente de planificación de viajes y la exploración de destinos turísticos en vista de mapa y en vista de cuadrícula.

---

## 2. Configuración de Firebase y Ficheros Excluidos

### Ficheros de Configuración Necesarios
Para conectar la aplicación con Firebase en un entorno de desarrollo o producción, se requieren los siguientes ficheros de configuración según la plataforma:
- **Android:** `android/app/google-services.json` (contiene el ID del proyecto, número de proyecto y clave API de Google Services para Android).
- **iOS:** `ios/Runner/GoogleService-Info.plist` (configuración del paquete de la app de iOS).
- **Flutter / Multiplataforma:** `lib/firebase_options.dart` (fichero generado automáticamente mediante FlutterFire CLI con las claves de plataforma).

### Por qué NO deben subirse al Repositorio Git
Estos ficheros contienen **claves de API públicas, identificadores de proyecto y credenciales de cliente OAuth**. Subir estos archivos a un repositorio público o compartido implica:
1. **Riesgo de Seguridad:** Exposición indeseada de la cuota del proyecto de Firebase y posibilidad de uso no autorizado por terceros.
2. **Buenas Prácticas de Desarrollo:** Cada entorno (desarrollo, pruebas, producción) debe poseer su propio proyecto de Firebase aislado.

Por esta razón, estos ficheros han sido incluidos explícitamente en el archivo `.gitignore`:
```gitignore
# Firebase configuration files (contienen claves de API y credenciales de proyecto)
android/app/google-services.json
lib/firebase_options.dart
ios/Runner/GoogleService-Info.plist
```

### Cómo configurar el proyecto en un equipo nuevo
Para que el proyecto compile y funcione en una máquina limpia:
1. Revisa las plantillas de ejemplo incluidas en el repositorio:
   - `android/app/google-services.json.example`
   - `lib/firebase_options.dart.example`
2. Descarga tu propio `google-services.json` desde la [Consola de Firebase](https://console.firebase.google.com/) y colócalo en `android/app/google-services.json`.
3. Alternativamente, ejecuta el comando oficial de la CLI de FlutterFire en la raíz del proyecto:
   ```bash
   flutterfire configure
   ```
   Esto generará un nuevo `lib/firebase_options.dart` vinculado a tu proyecto de Firebase.

---

## 3. Arquitectura del Código y Explicación por Módulos

El código sigue una arquitectura limpia en capas (**Modelos, Servicios y Pantallas**) que separa la interfaz gráfica de la lógica de acceso a datos y autenticación.

```text
lib/
├── main.dart                       # Punto de entrada y enrutador por nombre (onGenerateRoute)
├── firebase_options.dart.example   # Plantilla de configuración de Firebase
├── models/                         # Clases de modelo de datos tipadas
│   ├── mensaje.dart                # Modelo de mensaje de chat con Timestamp y estado de lectura
│   ├── perfil.dart                 # Modelo de perfil de usuario (soporta URL e imagen Base64)
│   └── trip_preferences.dart       # Modelos TripPreferences y TripWizardArgs para el asistente
├── services/                       # Capa de servicios y lógica de datos
│   ├── auth_service.dart           # Servicio Firebase Auth con mapeo de errores en español
│   ├── firestore_service.dart      # Persistencia NoSQL tipada mediante withConverter
│   ├── storage_service.dart        # Subida a Firebase Storage con fallback a Base64
│   └── onboarding_service.dart     # Persistencia local con SharedPreferences
└── screens/                        # Pantallas e interfaces de usuario
    ├── splash_screen.dart          # Comprobación de estado de entrada y redirección
    ├── onboarding_screen.dart      # Guía inicial deslizante (PageView) con botón saltar
    ├── login_screen.dart           # Formulario de inicio de sesión
    ├── register_screen.dart        # Formulario de registro y creación automática de perfil
    ├── home_screen.dart            # Pantalla principal con barra inferior de 3 secciones
    ├── chat_screen.dart            # Chat en tiempo real con cancelación de StreamSubscription
    ├── newmessage_screen.dart      # Búsqueda por email y envío de nuevos mensajes
    ├── map_explore_screen.dart     # Mapa interactivo OpenStreetMap (flutter_map) con geocodificación
    ├── grid_explore_screen.dart    # Sección 3: Vista en cuadrícula (GridView) de destinos
    ├── profile_screen.dart         # Edición de perfil, cámara/galería y compresión de fotos
    ├── trip_wizard_screen.dart     # Asistente por pasos para personalización de viajes
    └── trip_detail_screen.dart     # Generación dinámica de recomendaciones de viajes
```

---

## 4. Explicación Detallada de Decisiones Técnicas y Código

### A. Sistema de Rutas con Nombre (`onGenerateRoute` & `arguments`)
- **Problema anterior:** La navegación construía widgets llamando directamente a `MaterialPageRoute(builder: (context) => ChatScreen(contacto: ...))` repartidos en múltiples lugares.
- **Solución implementada:** Se ha centralizado la navegación en `lib/main.dart` utilizando `onGenerateRoute`.
- **Funcionamiento:** Las pantallas navegan invocando `Navigator.pushNamed(context, '/chat', arguments: contacto)`. El generador de rutas extrae `settings.arguments` con verificación de tipos (`as Perfil`, `as TripPreferences`, `as TripWizardArgs`), garantizando un desacoplamiento total entre pantallas y facilitando futuras integraciones de enlaces profundos (Deep Links).

### B. Barra Inferior con 3 Secciones y Estados de Error en Pantalla
La pantalla principal (`HomeScreen`) incluye una barra inferior de tres destinos (`NavigationBar`):
1. **Sección 1: Social (`Icons.people`):** Pestañas internas para conversiones activas (Chats), directorio de usuarios (Contactos) y edición del perfil personal.
2. **Sección 2: Explorar (`Icons.map`):** Mapa vectorial OpenStreetMap con búsqueda de ciudades (API Nominatim), centrado del usuario y ajuste de radio de acción.
3. **Sección 3: Destinos Grid (`Icons.grid_view`):** Catálogo interactivo organizado en una cuadrícula de 2 columnas (`GridView.builder`) con filtrado por categorías.

#### Gestión de Estados en Pantalla (Carga, Éxito, Vacío y Error)
Todas las secciones gestionan explícitamente cuatro estados de interfaz:
- **Carga:** Muestra un indicador `CircularProgressIndicator` centrado.
- **Éxito:** Muestra la lista, mapa o cuadrícula de datos.
- **Vacío:** Muestra un mensaje informativo si no existen registros.
- **Error con Reintento:** Si falla la conexión a Firestore o la API de mapas, la pantalla muestra un widget de error con icono descriptivo, mensaje claro y un botón **"Reintentar"** que vuelve a solicitar los datos.
- **Simulación de Errores:** Se ha integrado un botón con icono de insecto (`bug_report_outlined`) en la barra de herramientas para permitir probar en pantalla el estado de error y su recuperación con 1 clic durante la evaluación.

### C. Consultas Firestore: Lectura Única (`get()`) vs Tiempo Real (`snapshots()`)
- **`snapshots()` (Escuchas en tiempo real):** Utilizadas en `getReceivedMessages` y `getSentMessages` dentro de `ChatScreen` y `HomeScreen`. Al tratarse de mensajería instantánea, se requiere que los nuevos mensajes aparezcan automáticamente en pantalla sin intervención del usuario.
- **`get()` (Lectura puntual):** Utilizada en `getProfileByEmail`, `getProfileByUid` y `getAllProfiles`. Se lee el documento de forma puntual al iniciar sesión o buscar un usuario para optimizar el consumo de la cuota de Firestore.
- **Cancelación en `dispose()`:** Todas las suscripciones `StreamSubscription` mantenidas en los estados de los widgets son canceladas de forma explícita en el método `dispose()` para evitar fugas de memoria y consumo de red innecesario.

### D. Procesamiento de Fotos de Perfil y Fallback a Base64
- La aplicación permite capturar o seleccionar fotos desde la cámara y la galería usando `image_picker`.
- Intenta subir la imagen procesada a **Firebase Storage**.
- Si Firebase Storage no estuviera disponible (reglas estrictas o trabajo offline), la app convierte automáticamente la miniatura a una cadena **Base64** (`data:image/jpeg;base64,...`) almacenándola dentro del propio documento de Firestore, asegurando que la foto de perfil se muestre siempre correctamente tanto en Android como en navegador web.

---

## 5. Instrucciones de Compilación y Ejecución

### Requisitos Previos
- Flutter SDK (versión 3.x o superior).
- Android Studio con emulador Android configurado.
- Navegador Google Chrome para ejecución web.

### Pasos para Ejecutar
1. Instalar dependencias del proyecto:
   ```bash
   flutter pub get
   ```
2. Comprobar que no existen advertencias de análisis estático:
   ```bash
   flutter analyze
   ```
3. Ejecutar en navegador Google Chrome:
   ```bash
   flutter run -d chrome
   ```
4. Ejecutar en emulador Android:
   ```bash
   flutter run -d android
   ```

---

## 6. Tabla de Pruebas de Funcionamiento

| Prueba | Resultado Esperado | Resultado Obtenido |
|---|---|---|
| **Arranque en Chrome** | La app inicia correctamente mostrando el Splash. | ✅ Correcto |
| **Arranque en Android** | La app inicia en el emulador sin errores. | ✅ Correcto |
| **Paso por Onboarding** | Muestra 3 diapositivas desglosables y guarda el estado en `SharedPreferences`. | ✅ Correcto |
| **Rutas con Nombre** | Navega a `/chat`, `/trip_wizard` y `/trip_detail` pasando argumentos tipados. | ✅ Correcto |
| **Barra Inferior (3 Secciones)** | Navega entre Social, Mapa y Cuadrícula Grid sin reiniciar el estado. | ✅ Correcto |
| **Vista en Cuadrícula** | La 3.ª sección rindea tarjetas en `GridView.builder` de 2 columnas. | ✅ Correcto |
| **Estado de Error en Pantalla** | Muestra el widget de error y el botón "Reintentar" funciona para recuperar la interfaz. | ✅ Correcto |
| **Foto de Perfil (Cámara/Galería)** | Selecciona foto y actualiza en Firestore (URL Storage o Base64). | ✅ Correcto |
| **Mensajería Tiempo Real** | Los mensajes se envían y reciben mediante `snapshots()` ordenados cronológicamente. | ✅ Correcto |
| **Cierre de Sesión** | Cierra la sesión en Firebase Auth y vuelve a la pantalla `/login`. | ✅ Correcto |

---

## 7. Historial de Commits

El desarrollo se ha registrado mediante commits claros y explicativos que documentan cada evolución del proyecto:

1. `docs(firebase): excluir ficheros de configuracion sensibles de git y anadir plantillas .example`
2. `refactor(navigation): implementar rutas con nombre (named routes) y paso de argumentos`
3. `feat(ui): anadir tercera seccion a la barra inferior con vista en cuadricula (GridView) y estados de error con reintento`
4. `docs(code): documentar clases, servicios y pantallas con explicaciones de funcionamiento y diseno`
5. `docs(readme): actualizar README con documentacion de Firebase, arquitectura, rutas y tabla de pruebas`

---

## 8. Uso de Inteligencia Artificial

El uso de asistentes de IA para asistencia en refactorizaciones, diseño de arquitectura y documentación se encuentra registrado de forma transparente en el archivo `IA.md`.
