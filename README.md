# Proyecto Flutter — Fase 1

Aplicación desarrollada como proyecto de 2.º de DAM.

Esta primera fase tiene como objetivo construir la base de la aplicación: estructura del proyecto, interfaz inicial, navegación, autenticación, conexión con Firebase y acceso a datos mediante Firestore.

## Estado del proyecto

**Fase actual:** Fase 1 — Arranque de la aplicación

El proyecto se encuentra actualmente en la fase inicial de configuración.

### Objetivos de esta fase

* Crear la estructura base de la aplicación.
* Separar pantallas, modelos y servicios.
* Implementar una pantalla de splash.
* Implementar un onboarding inicial.
* Conectar la aplicación con Firebase.
* Implementar registro, inicio y cierre de sesión.
* Crear y utilizar datos almacenados en Firestore.
* Implementar navegación entre las diferentes pantallas.
* Crear una barra de navegación inferior.
* Mostrar información procedente de Firestore en listas y cuadrículas.
* Gestionar los estados de carga, vacío y error.
* Probar la aplicación en Android y navegador.

---

## Tecnologías utilizadas

* **Flutter**
* **Dart**
* **Firebase**
* **Firebase Authentication**
* **Cloud Firestore**
* **Git / GitHub**
* **Android Studio**

---

## Estructura del proyecto

La aplicación se organizará separando las diferentes responsabilidades:

```text
lib/
├── models/
├── screens/
├── services/
└── main.dart
```

### `main.dart`

Será el punto de entrada de la aplicación y contendrá la configuración principal de Flutter y de la aplicación.

### `screens/`

Contendrá las diferentes pantallas de la aplicación.

Por ejemplo:

```text
screens/
├── splash_screen.dart
├── onboarding_screen.dart
├── login_screen.dart
├── register_screen.dart
└── home_screen.dart
```

La separación de las pantallas permite mantener el código organizado y facilita modificar o ampliar la interfaz.

### `models/`

Contendrá las clases que representan los datos utilizados por la aplicación.

Por ejemplo, un perfil de usuario se representará mediante una clase Dart en lugar de trabajar directamente con mapas de datos.

### `services/`

Contendrá la lógica relacionada con servicios externos o con operaciones que no pertenecen directamente a la interfaz.

Por ejemplo:

* autenticación mediante Firebase Authentication;
* lectura y escritura en Firestore;
* otras operaciones relacionadas con datos.

Esta separación permite que las pantallas no tengan que encargarse directamente de toda la lógica de acceso a datos.

---

# Puesta en marcha

## Requisitos

Para ejecutar el proyecto es necesario tener instalado:

* Flutter SDK
* Dart SDK incluido con Flutter
* Android Studio
* Android SDK
* Git

También es necesario disponer de un dispositivo Android/emulador o de un navegador compatible para ejecutar la aplicación.

## Comprobar Flutter

Desde una terminal:

```bash
flutter doctor
```

El comando permite comprobar que Flutter y las herramientas necesarias están correctamente configuradas.

También se pueden comprobar los dispositivos disponibles mediante:

```bash
flutter devices
```

## Ejecutar el proyecto

Clonar el repositorio:

```bash
git clone <URL_DEL_REPOSITORIO>
```

Entrar en la carpeta del proyecto:

```bash
cd <dam_proyect>
```

Instalar las dependencias:

```bash
flutter pub get
```

Ejecutar la aplicación:

```bash
flutter run
```

También se podrá ejecutar específicamente en Chrome:

```bash
flutter run -d chrome
```

---

# Configuración de Firebase

La aplicación utilizará Firebase para la autenticación y el almacenamiento de datos.

La configuración de Firebase se añadirá durante la Fase 1.

Los archivos de configuración generados por Firebase deberán tratarse según las indicaciones de seguridad del proyecto y no se subirán al repositorio cuando contengan información que deba mantenerse fuera del control de versiones.

La configuración exacta necesaria y los pasos para realizarla se documentarán aquí cuando Firebase esté conectado al proyecto.

---

# Navegación

La aplicación utilizará rutas declaradas en `MaterialApp`.

El objetivo es evitar crear directamente las pantallas durante la navegación y centralizar la definición de las rutas.

La navegación se documentará conforme se vayan creando las diferentes pantallas.

---

# Pruebas

La aplicación se probará en:

* Emulador Android.
* Navegador web.

Durante el desarrollo se registrarán las pruebas realizadas, el resultado esperado y el resultado obtenido.

También se documentarán las diferencias encontradas entre Android y navegador.

---

# Historial de desarrollo

El desarrollo se realizará mediante Git utilizando commits pequeños y descriptivos.

Los commits deberán indicar claramente qué cambio se ha realizado.

Ejemplo:

```text
chore: crear proyecto Flutter inicial
feat: crear estructura de carpetas
feat: añadir pantalla de splash
```

El historial permitirá comprobar la evolución del proyecto durante las diferentes sesiones de trabajo.

---

# Uso de inteligencia artificial

Durante el desarrollo se podrán utilizar herramientas de inteligencia artificial como apoyo al aprendizaje y a la programación.

El uso de IA se documentará en el archivo:

```text
IA.md
```

En dicho archivo se indicará qué herramientas se han utilizado y para qué partes del proyecto.

La persona responsable del proyecto deberá comprender y poder explicar el código incluido en la entrega.

---

# Autor

**Alumno:** Pablo Acebrón

**Curso:** 2.º DAM

**Proyecto:** dam_proyect

**Curso académico:** 2026/2027
