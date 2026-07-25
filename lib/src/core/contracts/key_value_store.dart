/// Contrato mínimo para preferencias y valores simples.
/// Permite desacoplar la aplicación de SharedPreferences y facilitar pruebas.
abstract interface class KeyValueStore {
  String? readString(String key);
  bool readBool(String key, {bool fallback = false});
  Future<void> writeString(String key, String value);
  Future<void> writeBool(String key, bool value);
  Future<void> remove(String key);
}
