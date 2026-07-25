# LogiFaena Enterprise

Plataforma Flutter para la coordinación logística de personal de faena: trabajadores, pasajes, alojamiento, traslados, agenda, alertas y reportes.

## Estado de esta entrega

- Versión de aplicación: **1.2.0+1200**
- Sprint acumulado: **13.1**
- Baseline anterior: 1.0.1+1001 / Sprint 13.0
- Arquitectura actual: cliente Flutter con funcionamiento local
- Arquitectura objetivo: Flutter Windows/Android + ASP.NET Core + PostgreSQL + JWT + sincronización offline

## Funcionalidades disponibles

- Inicio de sesión y sesión local persistente.
- Centro de Operaciones responsive.
- Gestión de personal e importación Excel multihoja.
- Pasajes, hoteles, traslados y agenda.
- Alertas operacionales y reportes.
- Motor logístico y cálculo de preparación operacional.
- Persistencia local basada actualmente en SharedPreferences.

## Ejecutar el proyecto

```bash
flutter pub get
flutter analyze
flutter test
flutter run -d windows
```

Para Android, conecte un dispositivo o emulador y ejecute `flutter run`.

## Estructura principal

- `lib/`: aplicación Flutter.
- `test/`: pruebas automatizadas.
- `Recursos/`: plantillas y archivos Excel de prueba.
- `Documentacion/LM/`: documentación maestra LM-000 a LM-014.
- `docs/`: roadmap, changelog y documentos de sprint.

## Advertencia de alcance

La API ASP.NET Core, PostgreSQL, JWT, auditoría centralizada y sincronización cliente/servidor están definidos como arquitectura objetivo, pero todavía no forman parte ejecutable de esta entrega.
