# CHANGELOG — LogiFaena Enterprise

## 1.3.1+1301 — Sprint 15.1

- SQLite de Windows usa una ruta estable bajo `%LOCALAPPDATA%\LogiFaena Enterprise\data`.
- Inicialización y migración heredada ahora esperan correctamente las escrituras.
- Configuración muestra estado, ruta y tamaño real de la base local.
- Se imprime en consola la ruta efectiva de `logifaena_enterprise.db`.
- Corregido aviso de `ListTile` sin ancestro `Material` en el menú lateral.


## 1.1.0+1100 — Sprint 13.1 — 2026-07-24

### Agregado
- Estructura oficial `Documentacion/LM` con documentos LM-000 a LM-014.
- Contratos base para desacoplar persistencia y conectividad futura.
- Modelo inicial de operaciones pendientes de sincronización.
- Documento de entrega Sprint 13.1 y revisión maestra.

### Actualizado
- README reemplazado por documentación real del proyecto.
- Roadmap corregido según módulos ya implementados.
- Versionado unificado en `pubspec.yaml`.
- Alcance actual y arquitectura objetivo claramente separados.

### Limpieza
- Eliminados artefactos generados y configuraciones locales del ZIP: `build/`, `.dart_tool/`, `android/local.properties` y archivos temporales del IDE.

### Sin cambios funcionales destructivos
- Se mantiene el almacenamiento actual basado en SharedPreferences.
- No se incorporan todavía SQLite, API, PostgreSQL ni JWT ejecutables.

## Historial anterior

El historial detallado de los sprints previos se conserva en los archivos de entrega y documentos existentes del repositorio.

## [1.2.0+1200] - 2026-07-24 — Sprint 14.0

### Agregado
- Módulo funcional de Configuración empresarial.
- Modelo `AppSettings` y repositorio local de configuración.
- Parámetros de empresa, faena, coordinador, respaldo, notificaciones, API y sincronización.
- Acción para restaurar parámetros predeterminados sin borrar información operacional.

### Cambiado
- Configuración deja de ser una pantalla provisional.
- Versión del proyecto actualizada a 1.2.0+1200.

### Pendiente
- Migración de entidades operacionales a SQLite.
- Backend ASP.NET Core, PostgreSQL, JWT y sincronización real.

## [1.2.1+1201] - Sprint 14.1
### Corregido
- Navegación vertical mediante teclado en la pantalla Configuración.
- Compatibilidad con Flecha arriba, Flecha abajo, Page Up, Page Down, Home y End.
- Barra de desplazamiento visible y asociada a un controlador dedicado.
- Las teclas de dirección conservan su comportamiento normal mientras se edita un campo de texto.

## 1.3.0+1300 — Sprint 15.0
- Integración real de SQLite para plataformas nativas.
- Migración automática de colecciones guardadas anteriormente.
- Persistencia de trabajadores, pasajes, hoteles, traslados e historial.
- Creación de tablas de auditoría y cola de sincronización.
- Corrección de `test/widget_test.dart` para usar `LogiFaenaApp`.
