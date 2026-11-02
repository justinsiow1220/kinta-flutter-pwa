import 'dart:async';
import 'dart:html' as html;

/// Browser connectivity hint used to trigger a prompt sync attempt in the PWA.
class KintaConnectivityListener {
  StreamSubscription<html.Event>? _onlineSubscription;

  bool get isOnline => html.window.navigator.onLine ?? true;

  void listenForOnline(void Function() onOnline) {
    _onlineSubscription ??= html.window.onOnline.listen((_) => onOnline());
  }

  void dispose() {
    _onlineSubscription?.cancel();
    _onlineSubscription = null;
  }
}
