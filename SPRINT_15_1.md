# Sprint 15.1 — Infraestructura SQLite verificable

**Versión:** 1.3.1+1301

## Objetivo
Crear y hacer visible físicamente la base de datos local de LogiFaena en Windows.

## Ruta Windows

```text
%LOCALAPPDATA%\LogiFaena Enterprise\data\logifaena_enterprise.db
```

## Validación
1. Ejecutar `flutter run -d windows`.
2. Abrir Configuración y revisar “Base de datos local”.
3. Confirmar que indique “SQLite activo y archivo creado”.
4. Ejecutar en PowerShell:

```powershell
Get-Item "$env:LOCALAPPDATA\LogiFaena Enterprise\data\logifaena_enterprise.db"
```

## Correcciones adicionales
- El proceso de migración espera las escrituras antes de finalizar.
- El menú lateral posee un ancestro Material y ya no debe emitir el aviso de ListTile.
