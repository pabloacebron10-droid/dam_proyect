
# DAM Proyect — Fase 1: El arranque de la aplicación

Proyecto de 2.º de Desarrollo de Aplicaciones Multiplataforma (DAM).

**Módulos:** 0486 Acceso a Datos (AD), 0489 Programación Multimedia y Dispositivos Móviles (PMDM) y 0490 Programación de Servicios y Procesos (PSP).

## 1. Descripción del proyecto

`dam_proyect` es una aplicación desarrollada con Flutter y Dart. Esta primera fase establece la estructura inicial, la entrada a la aplicación, el acceso de usuarios, la conexión con Firebase, el almacenamiento de datos y la navegación entre pantallas.

El objetivo es disponer de un prototipo navegable que pueda ejecutarse y probarse tanto en Android como en un navegador web.

## 2. Tecnologías utilizadas

- Flutter y Dart.
- Android Studio.
- Firebase Authentication para el registro y el acceso, si está configurado.
- Cloud Firestore para el almacenamiento de datos, si está configurado.
- Git y GitHub para el control de versiones.

## 3. Estructura del proyecto

El código de la aplicación se organiza en carpetas según la responsabilidad de cada elemento:

```text
lib/
├── main.dart
├── models/
├── screens/
└── services/
```

- **`main.dart`:** punto de entrada de la aplicación y configuración general de Flutter.
- **`models/`:** clases que representan los datos utilizados por la aplicación.
- **`screens/`:** pantallas e interfaces que ve e utiliza el usuario.
- **`services/`:** lógica para acceder a Firebase, gestionar la autenticación y realizar operaciones con los datos.

Esta separación facilita el mantenimiento, evita mezclar la interfaz con el acceso a datos y permite reutilizar la lógica de los servicios.

> Esta estructura es orientativa: debe coincidir con las carpetas que existan realmente en el repositorio.

## 4. Requisitos previos

Para ejecutar el proyecto en un equipo limpio se necesita:

- Flutter instalado y añadido al PATH.
- Dart incluido con Flutter.
- Android Studio y, para las pruebas Android, un emulador configurado.
- Google Chrome u otro navegador compatible con Flutter Web.
- Git.
- Acceso a Firebase y los archivos de configuración necesarios, si el proyecto utiliza sus servicios.

Comprobar la instalación:

```bash
flutter doctor
flutter --version
git --version
```

## 5. Cómo descargar y arrancar el proyecto

Clonar el repositorio:

```bash
git clone URL_DEL_REPOSITORIO
cd dam_proyect
```

Instalar las dependencias:

```bash
flutter pub get
```

Comprobar posibles errores de análisis:

```bash
flutter analyze
```

Ejecutar en Chrome:

```bash
flutter run -d chrome
```

Ejecutar en Android:

1. Abrir Android Studio.
2. Iniciar un emulador Android o conectar un dispositivo con depuración USB.
3. Comprobar los dispositivos disponibles:

```bash
flutter devices
```

4. Ejecutar la aplicación:

```bash
flutter run
```

Si Firebase está integrado, antes de ejecutar la aplicación deben instalarse los archivos de configuración correspondientes y comprobarse que el proyecto de Firebase utilizado es el correcto.

## 6. Pantallas y navegación

La aplicación utiliza rutas declaradas en `MaterialApp` para organizar la navegación.

Las pantallas previstas para esta fase son:

- **Splash:** presentación inicial mientras se comprueba el estado de la aplicación.
- **Onboarding:** explicación inicial de la aplicación para nuevos usuarios.
- **Login:** acceso mediante correo electrónico y contraseña.
- **Registro:** creación de una cuenta.
- **Home:** pantalla principal después del acceso.
- **Secciones de contenido:** pantallas para consultar los datos de la aplicación.

La lista anterior debe ajustarse a las pantallas y rutas implementadas realmente.

El splash debe contemplar los estados de carga y error de la imagen. Si la imagen remota no se puede descargar, la aplicación debe mostrar una alternativa y continuar funcionando.

El onboarding debe mostrarse únicamente la primera vez, permitir saltarlo y guardar la preferencia de que ya se ha completado.

## 7. Firebase y persistencia

La aplicación puede utilizar los siguientes servicios de Firebase:

- **Firebase Authentication:** registro, inicio de sesión y cierre de sesión.
- **Cloud Firestore:** lectura y escritura de perfiles y contenido.

La configuración debe estar vinculada al proyecto de Firebase correspondiente. No se deben publicar credenciales privadas, claves de cuentas de servicio ni archivos locales sensibles.

### Archivos de configuración

Dependiendo de la plataforma y del método de configuración, pueden ser necesarios:

- `android/app/google-services.json` para Android.
- `lib/firebase_options.dart` si se utiliza FlutterFire CLI.
- Configuración web de Firebase cuando sea necesaria para la plataforma web.

La presencia de estos archivos depende de cómo se haya configurado el proyecto. Los archivos generados con identificadores de aplicación o configuración pública de Firebase no equivalen por sí solos a una contraseña privada. Deben revisarse igualmente las reglas de Firestore, las restricciones de las claves y los archivos que contienen secretos.

Los archivos privados y locales no deben subirse al repositorio. Se debe revisar `.gitignore` y documentar los pasos necesarios para obtener la configuración en un equipo nuevo.

### Modelos y conversión de datos

Los datos deben representarse mediante clases del directorio `models/`.

Cuando se trabaje con Firestore, se utilizarán conversores tipados mediante `withConverter` para transformar los documentos en objetos Dart y convertir los objetos en documentos al escribirlos.

Las colecciones, los modelos y los campos concretos deben documentarse una vez comprobados en el código y en Firebase.

## 8. Gestión de recursos

Los servicios que abran suscripciones a Firestore deben cancelarlas cuando ya no se necesiten, por ejemplo, en `dispose()` de la pantalla que las mantiene.

Al cerrar sesión se debe cerrar la sesión de Firebase Authentication y evitar que queden escuchas o recursos activos innecesarios.

La implementación concreta debe comprobarse en el código antes de considerar completado este apartado.

## 9. Pruebas de funcionamiento

La aplicación debe probarse en Android y en navegador.

La siguiente tabla es una plantilla para registrar las pruebas realizadas. Hay que completar el resultado después de ejecutar cada prueba.

| Prueba | Resultado esperado | Resultado obtenido |
|---|---|---|
| Arranque en Chrome | La aplicación se inicia sin quedarse en blanco. | Pendiente |
| Arranque en Android | La aplicación se inicia en el emulador. | Pendiente |
| Carga de imagen del splash | Se muestra la imagen remota. | Pendiente |
| Error de imagen | Se muestra una alternativa visible. | Pendiente |
| Primera apertura | Se presenta el onboarding. | Pendiente |
| Saltar onboarding | Se accede al siguiente flujo. | Pendiente |
| Apertura posterior | No se repite el onboarding si ya se completó. | Pendiente |
| Registro válido | Se crea la cuenta. | Pendiente |
| Correo ya registrado | Se muestra un mensaje de error comprensible. | Pendiente |
| Contraseña débil | Se muestra un mensaje de error comprensible. | Pendiente |
| Credenciales incorrectas | Se informa del fallo de acceso. | Pendiente |
| Cierre de sesión | Se cierra la sesión y se vuelve al acceso. | Pendiente |
| Lectura de Firestore | Se muestran los datos almacenados. | Pendiente |
| Colección vacía | Se muestra un estado vacío. | Pendiente |
| Error de conexión | Se muestra un estado de error recuperable. | Pendiente |
| Navegación entre secciones | Las rutas llevan a las pantallas correctas. | Pendiente |

### Diferencias entre plataformas

Registrar aquí las diferencias observadas entre el emulador Android y Chrome: permisos, configuración de Firebase, comportamiento de imágenes, dimensiones de pantalla o cualquier otro problema reproducible.

No se debe afirmar que ambas plataformas funcionan correctamente hasta haber realizado las pruebas.

## 10. Control de versiones

El proyecto utiliza Git para registrar los cambios durante el desarrollo.

Consultar el historial:

```bash
git log --oneline
```

La entrega de esta fase requiere un mínimo de 15 commits con mensajes descriptivos que permitan identificar los cambios realizados durante el proceso.

El repositorio debe incluir al profesor como colaborador invitado, según las instrucciones de la actividad.

## 11. Uso de inteligencia artificial

El uso de herramientas de inteligencia artificial se documentará en `IA.md`, indicando qué herramientas se han utilizado, para qué tareas y qué cambios se han revisado o probado.

La persona que entrega el proyecto debe poder explicar el código y las decisiones de implementación.

## 12. Estado de la fase

Este README describe el procedimiento de instalación, ejecución y validación. Los apartados de Firebase, navegación, persistencia y pruebas deben actualizarse para reflejar el estado real del proyecto.

La entrega de la fase incluye el repositorio, la documentación, las evidencias de ejecución y un PDF corto con capturas y una tabla de pruebas.
