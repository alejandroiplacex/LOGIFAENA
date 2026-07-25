# LogiFaena Enterprise — Sprint 12.1

## Núcleo del Motor Logístico

Esta versión introduce la entidad central `Operation` y separa la lógica
de negocio de las pantallas.

### Componentes incorporados

- `Operation`
- `OperationStatus`
- `Provider`
- `Vehicle`
- `OperationNote`
- `LogisticsAlert`
- `OperationEngine`
- `OperationRepository`
- `OperationValidator`
- Prueba unitaria inicial del motor

### Responsabilidades del OperationEngine

1. Crear una operación en memoria.
2. Relacionar trabajadores con pasajes, hoteles y traslados mediante `workerId`.
3. Recalcular el estado operacional de cada trabajador.
4. Generar alertas de pasajes, alojamiento, traslados, conductores y capacidad.
5. Calcular el Índice de Preparación Operacional.
6. Determinar el estado general de la operación.

### Compatibilidad

No se eliminó ni reemplazó ningún módulo existente del Sprint 11.1.
La nueva arquitectura queda preparada para integrar el importador multihoja
en el siguiente incremento, sin trasladar reglas de negocio a la interfaz.
