# Sprint 14.0 — Configuración empresarial

**Versión:** 1.2.0+1200  
**Fecha:** 24-07-2026

## Implementado

- Sustitución del placeholder de Configuración por un módulo funcional.
- Parámetros de empresa, faena y coordinador.
- Preferencias de notificaciones y respaldo local.
- Preparación visual y persistente de URL API y sincronización automática.
- Persistencia mediante `SharedPreferences` sin alterar los datos operacionales existentes.
- Restauración segura de valores predeterminados.
- Diseño adaptable para escritorio y web.

## Alcance técnico

Se incorporaron las capas `domain`, `data` y `presentation` para Configuración. La conexión real a API y la sincronización siguen pendientes y se muestran explícitamente como no operativas.
