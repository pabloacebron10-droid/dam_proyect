# dam_proyect

**Autor:** Pablo Acebron  
**Repositorio:** [dam_proyect en GitHub](https://github.com/pabloacebron10-droid/dam_proyect)  
**Etapa:** 2.º DAM — Fase 1: El arranque de la aplicación  
**Módulos:** 0486 AD y 0489 PMDM

## 1. Descripción del proyecto

`dam_proyect` es una aplicación multiplataforma desarrollada con Flutter y Dart. Su objetivo es ofrecer una aplicación navegable que permita gestionar perfiles, enviar mensajes y explorar información relacionada con viajes.

La aplicación integra Firebase para la autenticación y el almacenamiento de datos. Se ha probado tanto en un emulador Android como en un navegador web.

Las principales funcionalidades son:

- Pantalla inicial (*splash*).
- Onboarding que se muestra únicamente la primera vez, con opción para saltarlo.
- Registro e inicio de sesión.
- Gestión del perfil del usuario.
- Exploración y consulta de información relacionada con viajes.
- Creación y envío de mensajes.
- Chat y comunicación mediante mensajes.
- Navegación entre las distintas pantallas.
- Lectura y escritura de datos en Firebase.

## 2. Tecnologías utilizadas

- **Flutter:** desarrollo de la interfaz multiplataforma.
- **Dart:** lenguaje de programación.
- **Firebase Authentication:** gestión de la autenticación de usuarios.
- **Cloud Firestore:** almacenamiento y consulta de perfiles y mensajes.
- **Firebase Storage:** servicio integrado en la aplicación mediante la capa de servicios para operaciones de almacenamiento de archivos.
- **FlutterFire:** configuración e integración de Firebase con Flutter.
- **Git y GitHub:** control de versiones y alojamiento del repositorio.

## 3. Estructura del proyecto

El código está organizado en modelos, pantallas y servicios para separar las responsabilidades de la aplicación.

```text
lib/
├── firebase_options.dart
├── main.dart
├── models/
│   ├── mensaje.dart
│   ├── perfil.dart
│   └── trip_preferences.dart
├── screens/
│   ├── chat_screen.dart
│   ├── home_screen.dart
│   ├── login_screen.dart
│   ├── map_explore_screen.dart
│   ├── newmessage_screen.dart
│   ├── onboarding_screen.dart
│   ├── profile_screen.dart
│   ├── register_screen.dart
│   ├── splash_screen.dart
│   ├── trip_detail_screen.dart
│   └── trip_wizard_screen.dart
└── services/
    ├── auth_service.dart
    ├── firestore_service.dart
    ├── onboarding_service.dart
    └── storage_service.dart
```

### Responsabilidad de cada carpeta

- **`models/`:** contiene las clases que representan los datos de la aplicación, como los mensajes, los perfiles y las preferencias de viaje.
- **`screens/`:** contiene las pantallas con las que interactúa el usuario.
- **`services/`:** agrupa la lógica para trabajar con autenticación, Firestore, onboarding y almacenamiento.
- **`main.dart`:** contiene el punto de entrada y la configuración principal de la aplicación.
- **`firebase_options.dart`:** contiene las opciones de configuración generadas para conectar Flutter con Firebase.

Esta organización facilita el mantenimiento del código, evita concentrar toda la lógica en un único archivo y permite ampliar la aplicación en futuras fases.

## 4. Requisitos previos

Para ejecutar el proyecto se necesita:

- Flutter instalado.
- Dart, incluido en la instalación de Flutter.
- Git.
- Android Studio y un emulador Android, si se quiere ejecutar en Android.
- Un navegador compatible, para ejecutar la versión web.
- Acceso al proyecto de Firebase utilizado por la aplicación.
- La configuración de Firebase necesaria para cada plataforma.

Para comprobar la instalación de Flutter:

```bash
flutter doctor
```

## 5. Instalación y ejecución

### 5.1. Descargar el repositorio

Clonar el repositorio y acceder a la carpeta del proyecto:

```bash
git clone https://github.com/pabloacebron10-droid/dam_proyect.git
cd dam_proyect
```

### 5.2. Instalar las dependencias

Ejecutar:

```bash
flutter pub get
```

### 5.3. Configurar Firebase

El proyecto utiliza FlutterFire para la integración con Firebase.

El archivo `firebase_options.dart` contiene las opciones de configuración utilizadas por la aplicación. Para ejecutar el proyecto en un equipo nuevo, es necesario disponer de la configuración correspondiente al proyecto de Firebase y comprobar que las aplicaciones Android y web estén configuradas cuando corresponda.

También se deben habilitar los métodos de autenticación utilizados y comprobar que Cloud Firestore esté disponible.

**Seguridad y configuración:**

- No incluir contraseñas, claves privadas ni credenciales de administración en el repositorio.
- Revisar los archivos de configuración de cada plataforma antes de publicarlos.
- No utilizar las reglas de prueba de Firestore en producción.
- Configurar reglas que permitan únicamente las operaciones autorizadas.

### 5.4. Ejecutar en Android

Iniciar un emulador desde Android Studio y comprobar los dispositivos disponibles:

```bash
flutter devices
```

Ejecutar la aplicación:

```bash
flutter run
```

Si hay varios dispositivos conectados, seleccionar el emulador correspondiente.

### 5.5. Ejecutar en navegador

Para iniciar la aplicación en Chrome:

```bash
flutter run -d chrome
```

La configuración de Firebase y las dependencias utilizadas deben ser compatibles con la plataforma web.

## 6. Firebase y gestión de datos

### 6.1. Autenticación

La autenticación permite gestionar el acceso de los usuarios a la aplicación.

Las operaciones de autenticación se organizan en `services/auth_service.dart`, mientras que las pantallas de acceso y registro se encuentran en:

- `screens/login_screen.dart`
- `screens/register_screen.dart`

La aplicación contempla el registro, el inicio de sesión y el cierre de sesión, así como la gestión de errores de autenticación.

### 6.2. Cloud Firestore

La aplicación utiliza Cloud Firestore para guardar y consultar información.

Las colecciones utilizadas son:

- **`profiles`:** información de los perfiles de usuario.
- **`messages`:** información de los mensajes enviados.

El acceso a los datos se organiza en `services/firestore_service.dart`.

Durante las pruebas se ha comprobado el envío de mensajes y que la información de los perfiles y los mensajes queda guardada en Firebase.

### 6.3. Modelos y conversión tipada

Los modelos de datos se encuentran en la carpeta `models/`:

- `mensaje.dart`
- `perfil.dart`
- `trip_preferences.dart`

El proyecto utiliza `withConverter` para trabajar con datos tipados en Firestore, convirtiendo los documentos a los modelos correspondientes y los modelos a los datos que se guardan.

Esta estrategia facilita el tratamiento de los datos y reduce la necesidad de trabajar directamente con mapas sin tipar.

### 6.4. Almacenamiento de archivos

La lógica de almacenamiento se organiza en `services/storage_service.dart`.

La configuración y el uso de Firebase Storage deben mantenerse vinculados al proyecto de Firebase correspondiente y a sus reglas de acceso.

## 7. Navegación de la aplicación

Las rutas declaradas en la configuración de la aplicación permiten acceder a las pantallas principales:

| Ruta | Pantalla |
|---|---|
| `/splash` | `SplashScreen` |
| `/login` | `LoginScreen` |
| `/onboarding` | `OnboardingScreen` |
| `/homescreen` | `HomeScreen` |
| `/register` | `RegisterScreen` |
| `/newmessage` | `NewMessageScreen` |

Además, el proyecto contiene pantallas para el chat, el perfil, la exploración del mapa, el detalle de un viaje y el asistente para configurar un viaje.

La navegación se configura mediante las rutas de `MaterialApp`, facilitando la organización del recorrido entre pantallas.

## 8. Onboarding

El onboarding está implementado en `screens/onboarding_screen.dart` y utiliza `services/onboarding_service.dart` para gestionar el estado de visualización.

Se ha comprobado que las pantallas de introducción se muestran únicamente la primera vez y que existe una opción para saltarlas.

## 9. Pruebas realizadas

La aplicación se ha probado en un emulador Android y en un navegador web. Las pruebas funcionales indicadas se han realizado satisfactoriamente y se han demostrado en vídeo.

| Prueba | Resultado |
|---|---|
| Inicio de la aplicación | Correcto |
| Carga de imagen del splash | Correcto |
| Onboarding y opción para saltarlo | Correcto |
| Registro e inicio de sesión | Correcto |
| Gestión de errores de autenticación | Correcto |
| Cierre de sesión | Correcto |
| Navegación entre pantallas | Correcto |
| Lectura y escritura en Firestore | Correcto |
| Guardado de perfiles en Firebase | Correcto |
| Envío y almacenamiento de mensajes | Correcto |
| Estados de carga, vacío y error | Correcto |
| Ejecución en emulador Android | Correcto |
| Ejecución en navegador web | Correcto |

La tabla se complementa con la memoria de pruebas y las capturas que se entregan en el PDF de la Fase 1.

## 10. Control de versiones

El proyecto se encuentra alojado en GitHub:

[https://github.com/pabloacebron10-droid/dam_proyect](https://github.com/pabloacebron10-droid/dam_proyect)

El historial cuenta con al menos 15 commits con mensajes descriptivos, que permiten identificar los cambios realizados durante el desarrollo.

El profesor está invitado al repositorio para poder revisar el código y su evolución.

## 11. Uso de inteligencia artificial

El uso de asistentes de inteligencia artificial debe documentarse en el archivo `IA.md`, indicando las tareas en las que se han utilizado, las sugerencias aprovechadas y las modificaciones realizadas por el alumno.


## 12. Autoría

**Autor:** Pablo Acebron.

Este proyecto constituye la base de la aplicación que se ampliará en las siguientes fases del proyecto de DAM, incorporando nuevas funcionalidades sobre la estructura actual.
