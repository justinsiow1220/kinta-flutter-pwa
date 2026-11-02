/// Fallback for platforms without browser connectivity events.
class KintaConnectivityListener {
  bool get isOnline => true;

  void listenForOnline(void Function() onOnline) {}

  void dispose() {}
}
