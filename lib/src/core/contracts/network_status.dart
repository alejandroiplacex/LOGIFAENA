/// Estado de conectividad utilizado por la futura sincronización automática.
enum NetworkConnectionState { online, offline, unknown }

abstract interface class NetworkStatus {
  Future<NetworkConnectionState> current();
  Stream<NetworkConnectionState> get changes;
}
