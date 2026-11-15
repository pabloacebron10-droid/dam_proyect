# Registro de Uso de Inteligencia Artificial (IA.md)

**Proyecto:** `dam_proyect` — Fase 1b  
**Curso:** 2.º DAM (`0486 AD`, `0489 PMDM`, `0490 PSP`)

---

## 1. Propósito del Uso de IA
Durante el desarrollo de la Fase 1b se ha empleado un asistente de IA generativa como apoyo de ingeniería de software para:
1. **Auditoría frente a la rúbrica oficial:** Identificación de brechas funcionales en los 7 bloques de evaluación (`AUDITORIA_PROYECTO_FASE1B.md`).
2. **Programación concurrente con `Isolates` (0490 PSP):** Diseño del paso de mensajes mediante `ReceivePort` y `SendPort` en `ImageIsolateService` (compresión de fotografías a `< 300 KB`) y `DistanceIsolateService` (cálculo geodésico Haversine con envío de porcentaje de progreso).
3. **Consultas avanzadas e índices de Cloud Firestore (0486 AD):** Estructuración de las 4 consultas tipadas con `withConverter`, paginación mediante cursor `startAfterDocument`, definición de `firestore.indexes.json` y reglas de seguridad en `firestore.rules`.
4. **Geolocalización y gestión de permisos (0489 PMDM):** Tratamiento exhaustivo de estados de `geolocator` (`serviceDisabled`, `permissionDenied`, `permissionDeniedForever`, `TimeoutException`) y documentación comparativa de tecnologías GPS, Red y Proveedor Combinado.

---

## 2. Revisión y Validación Humana
Todo el código generado o refactorizado ha sido verificado mediante:
- Análisis estático sin errores ni advertencias (`flutter analyze`).
- Pruebas unitarias automatizadas de los servicios con `Isolate` (`flutter test`).
- Pruebas funcionales manuales en emulador Android y navegador Google Chrome.
