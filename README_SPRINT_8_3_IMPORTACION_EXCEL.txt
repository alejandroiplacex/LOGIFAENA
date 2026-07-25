LOGIFAENA SPRINT 8.3 - IMPORTACION MASIVA EXCEL

NOVEDADES
- Boton Importar Excel en Personal.
- Lectura de archivos .xlsx.
- Reconoce la hoja Trabajadores.
- Valida RUT chileno, duplicados y campos obligatorios.
- Vista previa y resumen antes de guardar.
- Importacion persistente con SharedPreferences.

PRUEBA RECOMENDADA
1. flutter clean
2. flutter pub get
3. flutter run -d chrome
4. Abrir Personal > Importar Excel.
5. Seleccionar LogiFaena_100_Trabajadores_Prueba.xlsx.
6. Confirmar que muestre 100 leidos y 100 listos para importar.
7. Importar y recargar con F5 para comprobar persistencia.
