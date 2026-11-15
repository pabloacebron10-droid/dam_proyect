# DAM Proyect — Fase 1b: Fotos, Posición, Consultas, Isolates y Navegación

Proyecto intermodular de 2.º de **Desarrollo de Aplicaciones Multiplataforma (DAM)**.

**Módulos Evaluados:**
- **0489 PMDM:** Programación Multimedia y Dispositivos Móviles (`RA2.b`, `RA2.d`, `RA2.g`, `RA2.j`, `RA2.k`, `RA2.l`, `RA2.m`, `RA2.n`).
- **0486 AD:** Acceso a Datos (`RA4.b`, `RA4.d`, `RA4.e`, `RA4.f`, `RA4.g`, `RA4.i`).
- **0490 PSP:** Programación de Servicios y Procesos (`RA2.a`, `RA2.c`, `RA2.e`).

🌐 **URL Pública en Firebase Hosting:**  
👉 **[https://proyectodam-56a61.web.app](https://proyectodam-56a61.web.app)** *(y [https://proyectodam-56a61.firebaseapp.com](https://proyectodam-56a61.firebaseapp.com))*

---

## 1. Descripción del Proyecto

`dam_proyect` es una aplicación multiplataforma (Android y Web) desarrollada con **Flutter** y **Dart**, conectada a **Firebase (Authentication con Email/Password y Google Sign-In, Cloud Firestore)**, mapas interactivos **OpenStreetMap (`flutter_map`)**, posicionamiento **GPS real (`geolocator`)** y concurrencia real con **`Isolates`**.

Toda la persistencia de fotografías se almacena como **miniatura en formato Base64 (`< 300 KB`) dentro del propio documento de Firestore**, funcionando al 100 % en el plan gratuito (Spark) y contra la **Firebase Emulator Suite** local sin gastar cuota.

---

## 2. Bloque 1: Entrar con Google, Huellas SHA, Cliente OAuth y `.gitignore`

### Ficheros de Configuración Excluidos del Repositorio (`.gitignore`)
Para evitar exponer claves de API o identificadores de cliente OAuth en GitHub (*"una clave subida a GitHub es una clave quemada"*), los ficheros sensibles están excluidos en [.gitignore](file:///c:/Proyectos%20Flutter/dam_proyect/.gitignore):
```gitignore
android/app/google-services.json
lib/firebase_options.dart
ios/Runner/GoogleService-Info.plist
```
En su lugar, el repositorio incluye las plantillas limpias:
- [android/app/google-services.json.example](file:///c:/Proyectos%20Flutter/dam_proyect/android/app/google-services.json.example)
- [lib/firebase_options.dart.example](file:///c:/Proyectos%20Flutter/dam_proyect/lib/firebase_options.dart.example)

### Huellas Digitales SHA-1 / SHA-256 y Configuración del Cliente OAuth
Para que el inicio de sesión con Google (`google_sign_in`) funcione en Android y navegador Web:
1. **Extracción de las huellas digitales del keystore de depuración:**
   Ejecutando `keytool` sobre `~/.android/debug.keystore` (o `./gradlew signingReport` desde `android/`):
   ```bash
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
   ```
   Formato de las huellas registradas en la consola para el equipo de desarrollo (valores enmascarados por seguridad):
   - **SHA-1:** `AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99:AA:BB:CC:DD` *(extraída de `debug.keystore` local)*
   - **SHA-256:** `00:11:22:33:44:55:66:77:88:99:AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99:AA:BB:CC:DD:EE:FF`
2. **Registro en Firebase Console y Cliente OAuth 2.0:**
   - En *Firebase Console > Configuración del proyecto > Tus aplicaciones > App Android (`com.example.dam_proyect`)*, se añaden las huellas `SHA-1` y `SHA-256`.
   - En *Authentication > Sign-in method*, se habilita el proveedor **Google**, lo cual genera automáticamente el **ID de cliente OAuth 2.0 para Android y para Web** en Google Cloud Console y dentro de `google-services.json`.
   - Para navegador Web y Firebase Hosting, los dominios `localhost` y `proyectodam-56a61.web.app` quedan autorizados en *Authentication > Settings > Authorized domains*.
3. **Vinculación con el perfil de Firestore y manejo de cancelación ([auth_service.dart](file:///c:/Proyectos%20Flutter/dam_proyect/lib/services/auth_service.dart) y [login_screen.dart](file:///c:/Proyectos%20Flutter/dam_proyect/lib/screens/login_screen.dart)):**
   - Si el usuario cierra la ventana emergente o cancela la selección de cuenta (`googleUser == null` o `popup-closed-by-user`), `signInWithGoogle()` devuelve `null` y la interfaz muestra un `SnackBar` avisando de la cancelación sin producir errores ni colgar la pantalla.
   - Si el acceso tiene éxito, `FirestoreService.syncGoogleUserProfile()` comprueba si ya existe el documento en `profiles/{uid}`: **si entra alguien nuevo, le crea el perfil** con su nombre, correo y foto; **si ya existía, recupera su perfil** respetando sus datos personalizados.

---

## 3. Bloque 2: Las 4 Consultas de Firestore, Índices y Decisión `snapshots()` vs `get()`

### Colección de 20+ Documentos y las 4 Consultas en Pantalla
La colección `destinations` cuenta con al menos **20 documentos** estructurados (con `GeoPoint`, `Timestamp`, `categoria`, `rating`, `imagenUrl` Base64/URL y `creadorId`). En la pantalla **Destinos Grid** ([grid_explore_screen.dart](file:///c:/Proyectos%20Flutter/dam_proyect/lib/screens/grid_explore_screen.dart)) y en [firestore_service.dart](file:///c:/Proyectos%20Flutter/dam_proyect/lib/services/firestore_service.dart) se pueden ejecutar en vivo las 4 consultas:
1. **`where` con dos condiciones (`queryDestinationsByCategoryAndMinRating`):**
   ```dart
   _destinationsRef
       .where('categoria', isEqualTo: categoria)
       .where('rating', isGreaterThanOrEqualTo: minRating)
       .orderBy('rating', descending: true)
       .get();
   ```
2. **`orderBy` con `limit` (`queryTopRatedDestinations`):**
   ```dart
   _destinationsRef.orderBy('rating', descending: true).limit(5).get();
   ```
3. **Rango sobre una fecha `Timestamp` (`queryDestinationsByDateRange`):**
   ```dart
   _destinationsRef
       .where('fechaCreacion', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
       .where('fechaCreacion', isLessThanOrEqualTo: Timestamp.fromDate(end))
       .orderBy('fechaCreacion', descending: true)
       .get();
   ```
4. **Paginación con cursor `startAfterDocument` (`queryDestinationsPaginated`):**
   ```dart
   Query<Destino> query = _destinationsRef.orderBy('titulo').limit(pageSize);
   if (lastDocument != null) {
     query = query.startAfterDocument(lastDocument);
   }
   ```

Los índices compuestos requeridos por estas consultas están declarados en el fichero [firestore.indexes.json](file:///c:/Proyectos%20Flutter/dam_proyect/firestore.indexes.json) del repositorio (no creados a mano en la consola).

### Por qué cada pantalla usa `snapshots()` (Tiempo Real) o `get()` (Lectura Única)

Escuchar toda la base de datos con `snapshots()` de forma indiscriminada multiplica el consumo de lecturas de Firestore, drena batería manteniendo sockets abiertos y rompe los cursores de paginación. Por ello, **cada pantalla toma una decisión explícita**:

| Pantalla / Operación | Método Elegido | Justificación Técnica |
|---|---|---|
| **Chat Individual (`ChatScreen`)** | **`snapshots()`** | En una conversación de mensajería instantánea el usuario necesita recibir los mensajes entrantes del interlocutor al instante en pantalla sin tener que pulsar un botón de refresco. Además, las suscripciones `StreamSubscription` se cancelan rigurosamente en `dispose()`. |
| **Bandeja de Conversaciones (`HomeScreen` - Pestaña Chats)** | **`snapshots()`** | Permite actualizar en vivo el indicador de mensajes no leídos y el último mensaje recibido mientras el usuario está en la pantalla principal. |
| **Directorio de Contactos (`HomeScreen` - Pestaña Contactos)** | **`get()`** | La lista de usuarios registrados cambia con poca frecuencia; basta una lectura puntual al cargar la sección (con botón de recarga/reintento), ahorrando lecturas continuas innecesarias. |
| **Catálogo y 4 Consultas (`GridExploreScreen`)** | **`get()`** | Las 4 consultas responden a preguntas concretas a petición del usuario (cambiar filtro, pedir Top 5, elegir rango de fechas o pulsar *"Cargar siguiente página"* con `startAfterDocument`). Usar `snapshots()` en una lista paginada invalidaría el cursor `lastDocument` cada vez que cambiase un documento. |
| **Mapa de Exploración (`MapExploreScreen`)** | **`get()`** | Los marcadores geográficos (`GeoPoint`) de los destinos se leen una vez al abrir el mapa y se pasan al `Isolate` para calcular las distancias respecto al usuario. |
| **Mi Perfil (`ProfileScreen`) y Nuevo Mensaje (`NewMessageScreen`)** | **`get()`** | Al abrir el formulario de edición de perfil o al comprobar si existe un correo destinatario (`getProfileByEmail`), solo se necesita el estado actual del documento en ese instante. |

---

## 4. Bloque 3: Modificar (`update`), Borrar (`delete`) y Reglas de Seguridad

- En **Destinos Grid** ([grid_explore_screen.dart](file:///c:/Proyectos%20Flutter/dam_proyect/lib/screens/grid_explore_screen.dart)) y en **Chat** ([chat_screen.dart](file:///c:/Proyectos%20Flutter/dam_proyect/lib/screens/chat_screen.dart)), el usuario puede editar (`update`) y borrar (`delete`) **únicamente los documentos creados por él mismo** (`creadorId == currentUser.uid`).
- Antes de ejecutar `delete()`, se muestra siempre un `AlertDialog` modal de confirmación. Si la operación falla, se captura la excepción y se informa en pantalla.
- **Lo ajeno no se puede tocar:** En la interfaz, los documentos de otros usuarios se muestran con la etiqueta *"Documento ajeno"* y no ofrecen botones de edición ni borrado. Además, las reglas de seguridad en [firestore.rules](file:///c:/Proyectos%20Flutter/dam_proyect/firestore.rules) lo impiden a nivel de servidor aunque alguien intentara invocar el SDK directamente:
  ```javascript
  match /destinations/{destinationId} {
    allow read: if isSignedIn();
    allow create: if isSignedIn();
    allow update, delete: if isSignedIn() && resource.data.creadorId == request.auth.uid;
  }
  ```

---

## 5. Bloque 4: Cámara/Galería, Compresión en `Isolate` y el Límite de 1 MB de Firestore

### Permisos Declarados y Denegación Tratada
- Declarados en Android ([AndroidManifest.xml](file:///c:/Proyectos%20Flutter/dam_proyect/android/app/src/main/AndroidManifest.xml): `CAMERA`, `READ_MEDIA_IMAGES`, `READ_EXTERNAL_STORAGE`) y en iOS ([Info.plist](file:///c:/Proyectos%20Flutter/dam_proyect/ios/Runner/Info.plist): `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription`).
- Si el usuario deniega el permiso de cámara o galería, se captura la `PlatformException` y se muestra un cuadro de diálogo explicando qué permiso falta y cómo activarlo en los Ajustes del sistema sin colgar la app.

### Por qué Cloud Firestore tiene un límite de 1 MB por documento y por qué se comprime antes
1. **El límite físico de 1 MiB (`1.048.576 bytes`) de Firestore:** Cloud Firestore es una base de datos documental optimizada para consultas rápidas e indexación en memoria. Por diseño arquitectónico, **cada documento individual tiene un tamaño máximo estricto de 1 MiB (1 MB)**, sumando el nombre de todas las claves, metadatos (`GeoPoint`, `Timestamp`, `Strings`) y el contenido de los campos.
2. **El peso de una foto actual y la penalización del Base64:** Una fotografía tomada con la cámara de un móvil actual ocupa entre **3 MB y 8 MB** en JPEG original. Además, al codificar bytes binarios en texto **Base64** (que representa cada 3 bytes binarios mediante 4 caracteres ASCII), el tamaño resultante **aumenta un ~33 % adicional**.
3. **Por qué es obligatorio comprimir antes a `< 300 KB`:** Si intentásemos guardar una foto de cámara directamente en Base64 dentro del documento de perfil o destino, superaría ampliamente el límite de 1 MB y Firestore abortaría la operación con el error `INVALID_ARGUMENT: maximum size exceeded`. Al redimensionar la imagen a miniatura (`<= 480 px`) y comprimirla en JPEG dentro del `Isolate` por debajo de `200 KB` binarios (`< 270 KB` ya codificada en Base64, siempre **`< 300 KB`**), garantizamos que el documento completo ocupe menos de una tercera parte del límite de 1 MB, cargue de forma instantánea en listas y mapas y sea viable para sincronización offline en la Fase 2.

---

## 6. Bloque 5: Comparativa de Tecnologías de Localización (GPS, Red y Proveedor Combinado)

| Característica | 1. GPS por Satélite (`GNSS`) | 2. Localización por Red (`Wi-Fi / Antenas Móviles`) | 3. Proveedor Combinado (`Fused Location Provider`) |
|---|---|---|---|
| **Cómo funciona** | Calcula la posición por trilateración de señales de radiofrecuencia emitidas por satélites (GPS, Galileo, GLONASS). | Triangula la posición usando los identificadores de celdas de telefonía móvil (Cell ID) y las direcciones MAC de redes Wi-Fi cercanas. | Combina algorítmicamente el chip GPS, redes Wi-Fi, antenas móviles y los sensores inerciales del dispositivo (acelerómetro, giroscopio, brújula). |
| **Precisión habitual** | **Muy alta:** entre `3 y 10 metros` en exteriores despejados. | **Media / Baja:** entre `20 y 50 metros` con Wi-Fi urbano; de `200 metros a 2 km` solo con antenas celulares. | **Adaptativa y óptima:** `3 a 15 metros` en exteriores y `15 a 40 metros` en interiores. |
| **Consumo de batería** | **Muy alto.** Mantener encendido el receptor GNSS y procesar efemérides drena la batería rápidamente. | **Muy bajo.** Reutiliza los barridos de red Wi-Fi y la conexión celular que el sistema operativo ya realiza. | **Eficiente e inteligente.** Desactiva el GPS cuando el acelerómetro detecta que el usuario está quieto o bajo techo, ahorrando batería. |
| **Tiempo de primera fijación (TTFF)** | **Lento (`5 a 30 segundos`).** Requiere línea de visión directa al cielo; en interiores suele fallar por `TimeoutException`. | **Instantáneo (`< 1 - 2 segundos`).** Funciona perfectamente dentro de edificios y sótanos con Wi-Fi. | **Inmediato (`< 1 segundo`).** Entrega al instante una posición aproximada de red y la refina en segundos con el GPS. |
| **Cuándo usar cada una** | Aplicaciones de navegación paso a paso en carretera, rutas de senderismo en montaña o topografía a cielo abierto sin cobertura móvil. | Aplicaciones de clima por ciudad, recomendaciones generales de barrio o apps en segundo plano donde prima no gastar batería. | **Uso general recomendado en apps móviles modernas** (como `dam_proyect`): mapas urbanos, buscadores «cerca de mí» y etiquetado geográfico de contenidos. |

En [location_service.dart](file:///c:/Proyectos%20Flutter/dam_proyect/lib/services/location_service.dart) se emplea `geolocator` pidiendo el permiso en el momento oportuno y tratando de forma específica **permiso denegado**, **denegación permanente**, **GPS apagado** y **tiempo de espera agotado (`TimeoutException` de 12 s)**, guardando la coordenada leída como `GeoPoint` junto con su `Timestamp` tanto en `profiles` como en `destinations`.

---

## 7. Bloque 6 y PSP (`0490 RA2.a, 2.c, 2.e`): Qué va en `Isolate`, qué NO y por qué

### Qué se ejecuta en un `Isolate` en este proyecto
1. **Compresión y redimensionado de fotografías ([image_isolate_service.dart](file:///c:/Proyectos%20Flutter/dam_proyect/lib/services/image_isolate_service.dart)):** Decodificar un mapa de bits de varios megapíxeles, reescalarlo píxel a píxel con interpolación y codificarlo en JPEG en bucle hasta bajar de `300 KB` es una tarea **intensiva en CPU (*CPU-bound*)** que toma entre `150 ms y 800 ms`. Si se ejecutara en el hilo principal (*UI Isolate*), bloquearía el renderizado a `60 fps` (un fotograma dura `16.6 ms`), congelando el desplazamiento de la pantalla.
2. **Cálculo Haversine y ordenación de la lista «Cerca de mí» ([distance_isolate_service.dart](file:///c:/Proyectos%20Flutter/dam_proyect/lib/services/distance_isolate_service.dart)):** Recibe la posición del usuario y los `GeoPoint` de los documentos en un `Isolate.spawn`, calcula la distancia esférica para cada uno, comunica el porcentaje de progreso (`0% ... 100%`) por `SendPort`/`ReceivePort` y devuelve la lista ordenada de menor a mayor distancia.

### Qué NO va en un `Isolate` y por qué
- **Operaciones de entrada/salida y red (*I/O-bound*):** Las consultas a Cloud Firestore (`get()`, `snapshots()`), la autenticación OAuth o las peticiones HTTP a Nominatim **no deben meterse en un `Isolate`**, porque ya son asíncronas no bloqueantes gestionadas por el *Event Loop* y el sistema operativo mientras esperan respuesta de red.
- **Actualización de Widgets (`setState`, `BuildContext`, `Navigator`) y Plugins con canales nativos directos:** Solo el *Root Isolate* tiene acceso al árbol de Widgets de Flutter; el `Isolate` trabajador únicamente envía mensajes serializables (`double`, `Map`, `Uint8List`) a través de su `SendPort`.

### Por qué ordenar 20 documentos NO necesita un `Isolate` en un caso real (y por qué lo hacemos aquí)
Siendo rigurosos desde el punto de vista de sistemas (`0490 PSP`): calcular 20 fórmulas de Haversine y ejecutar `List.sort` sobre **20 documentos** consume apenas **`~0.1 ms` de CPU**, muy por debajo del presupuesto de `16.6 ms` de un fotograma. En cambio, levantar un `Isolate.spawn`, reservar su memoria aislada (*heap* propio) y copiar la lista de entrada/salida por `SendPort` tiene un coste fijo (*overhead*) de **`5 a 15 ms`**.
- **En producción:** Para 20 documentos sería más rápido hacerlo en el hilo principal; el `Isolate` de distancias solo empieza a ser rentable cuando la colección supera los **`5.000 - 10.000` puntos geográficos**.
- **Por qué se hace aquí en un `Isolate`:** Se implementa deliberadamente con `Isolate.spawn` y comunicación de progreso por `ReceivePort` para **medirlo empíricamente, demostrar que la interfaz no se congela al mover el mapa durante el cálculo y acreditar el dominio de la comunicación entre hilos (`0490 PSP RA2.a, RA2.c, RA2.e`)**.

---

## 8. Bloque 7: Ejecución con Emuladores (`--dart-define`) y Datos Exportados

### Datos de Prueba Exportados en el Repositorio (`./firebase_emulator_data`)
El repositorio incluye la carpeta [firebase_emulator_data](file:///c:/Proyectos%20Flutter/dam_proyect/firebase_emulator_data) con los datos de prueba exportados de **Auth** (usuarios `alumno@dam.es` / `123456` y `compañero@dam.es` / `123456`) y **Firestore** (perfiles con `GeoPoint`, `Timestamp` y miniatura Base64, mensajes y los **20 destinos**).

### Arrancar los Emuladores Importando los Datos con UN SOLO COMANDO
```bash
firebase emulators:start --import=./firebase_emulator_data --export-on-exit=./firebase_emulator_data
```

### Arrancar la Aplicación Conectada a los Emuladores (`--dart-define`)
La conexión a los emuladores se activa exclusivamente mediante bandera de compilación (`bool.fromEnvironment('USE_EMULATOR')` en [lib/main.dart](file:///c:/Proyectos%20Flutter/dam_proyect/lib/main.dart)), nunca con un booleano escrito a mano:
```bash
# En navegador Chrome contra emuladores locales:
flutter run -d chrome --dart-define=USE_EMULATOR=true

# En emulador Android contra emuladores locales (usa automáticamente 10.0.2.2):
flutter run -d android --dart-define=USE_EMULATOR=true
```

---

## 9. Tabla de Pruebas en Android y en Navegador Web

| Caso de Prueba | Qué se verifica | Resultado en Emulador Android | Resultado en Navegador (Chrome) |
|---|---|---|---|
| **1. Acceso con Google (Éxito y Cancelación)** | Cerrar selector muestra aviso de cancelación; elegir cuenta inicia sesión y crea/recupera `profiles/{uid}`. | ✅ Correcto (`GoogleSignIn` nativo + `SnackBar` al cancelar) | ✅ Correcto (`signInWithPopup` + `SnackBar` al cerrar ventana) |
| **2. Las 4 Consultas sobre 20+ Documentos** | Funcionan `where` (2 cond.), `orderBy`+`limit(5)`, rango de fechas `Timestamp` y paginación `startAfterDocument`. | ✅ Correcto (20 docs cargados y filtrados en cuadrícula) | ✅ Correcto (20 docs cargados y paginados de 6 en 6) |
| **3. Editar y Borrar Propios / Bloqueo de Ajenos** | `update` y `delete` con `AlertDialog` en documentos propios; documentos ajenos sin botones y bloqueados por `firestore.rules`. | ✅ Correcto (confirma antes de borrar; impide tocar ajenos) | ✅ Correcto (confirma antes de borrar; impide tocar ajenos) |
| **4. Cámara / Galería y Compresión en `Isolate`** | Selecciona foto, muestra barra de progreso `%` del `Isolate` sin congelar el scroll y guarda Base64 `< 300 KB` en Firestore. | ✅ Correcto (miniatura `~45 KB < 300 KB` visible en lista y detalle) | ✅ Correcto (miniatura `< 300 KB` codificada en Base64) |
| **5. Permiso de Cámara / Galería Denegado** | Al rechazar el permiso, no se cuelga la pantalla y muestra diálogo indicando cómo habilitarlo en Ajustes. | ✅ Correcto (diálogo modal explicativo de permiso denegado) | ✅ Correcto (control de cancelación/denegación del navegador) |
| **6. Posición GPS Real (`geolocator`)** | Lee coordenadas, centra el mapa y guarda `GeoPoint` + `Timestamp` tipados en el documento de Firestore. | ✅ Correcto (`GeoPoint` y `Timestamp` guardados y leídos) | ✅ Correcto (`GeoPoint` y `Timestamp` guardados y leídos) |
| **7. Permiso Localización Denegado / GPS Apagado / Timeout** | Al denegar el permiso o apagar el GPS, muestra `AlertDialog` con botón para abrir Ajustes o Reintentar sin colgar la UI. | ✅ Correcto (detecta GPS apagado y permiso denegado con diálogo) | ✅ Correcto (detecta permiso bloqueado en navegador con diálogo) |
| **8. Mapa `flutter_map` y «Cerca de mí» en `Isolate`** | Atribución OpenStreetMap visible, 1 marcador por doc, detalle al tocar marcador y lista «Cerca de mí» ordenada en `Isolate` con progreso. | ✅ Correcto (20 marcadores, atribución visible y lista ordenada por km) | ✅ Correcto (20 marcadores, atribución visible y lista ordenada por km) |
| **9. Trabajo sin Conexión / Fallo de Red** | Al cortar la red o simular fallo, las pantallas muestran estado de error con botón **"Reintentar"** y Firestore sirve caché local. | ✅ Correcto (widget de error y recuperación con botón Reintentar) | ✅ Correcto (widget de error y recuperación con botón Reintentar) |
| **10. Emuladores (`--dart-define`) y Hosting Web** | Conecta a Auth (`9099`) y Firestore (`8080`) con `--dart-define=USE_EMULATOR=true` y abre desde URL pública de Firebase Hosting. | ✅ Correcto (`10.0.2.2:9099` y `10.0.2.2:8080`) | ✅ Correcto (`localhost` y publicado en `proyectodam-56a61.web.app`) |

---

## 10. Bitácora de Uso de Inteligencia Artificial

El registro transparente del uso de asistentes de IA durante el proyecto se encuentra detallado en el fichero [IA.md](file:///c:/Proyectos%20Flutter/dam_proyect/IA.md).
