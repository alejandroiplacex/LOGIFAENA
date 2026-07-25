# Sprint 13.1 — Consolidación de baseline

## Objetivo
Dejar el proyecto maestro coherente, limpio y preparado para evolucionar hacia persistencia robusta y arquitectura cliente/servidor.

## Cambios aplicados
1. Versión actualizada a `1.1.0+1100`.
2. README profesional y ejecutable.
3. Roadmap alineado con el código real.
4. CHANGELOG consolidado.
5. Documentación LM-000 a LM-014 incorporada como baseline inicial.
6. Contratos técnicos agregados para almacenamiento, conectividad y sincronización.
7. Limpieza de archivos generados o dependientes del equipo local.

## Decisiones técnicas
- SharedPreferences continúa operativo para no romper los módulos existentes.
- La migración a SQLite se realizará en un sprint separado con pruebas de migración.
- ASP.NET Core, PostgreSQL y JWT permanecen como arquitectura objetivo.

## Validación requerida en equipo con Flutter

```bash
flutter pub get
flutter analyze
flutter test
flutter run -d windows
```
