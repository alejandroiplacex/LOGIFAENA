# Sprint 15.0 — Persistencia SQLite real

**Versión:** 1.3.0+1300

## Implementado

- SQLite como almacenamiento local principal en plataformas nativas.
- Archivo `logifaena_enterprise.db` en el directorio de soporte de la aplicación.
- Migración automática desde SharedPreferences en el primer inicio.
- Persistencia SQLite para trabajadores, pasajes, hoteles, traslados e historial de importación.
- Modo WAL, claves foráneas y transacciones de escritura.
- Tablas base para auditoría y futura cola de sincronización.
- Compatibilidad Web conservada mediante SharedPreferences.
- Corrección del test Flutter obsoleto que todavía buscaba `MyApp`.

## Prueba recomendada

1. Ejecutar `flutter pub get`.
2. Ejecutar `flutter analyze` y `flutter test`.
3. Ejecutar en Windows o Android.
4. Importar Excel, cerrar completamente y volver a abrir.
5. Confirmar que los registros permanecen.
