// Automatic FlutterFlow imports
// Imports other custom actions
// Imports custom functions
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the `</>` button on the right!
import 'package:package_info_plus/package_info_plus.dart';

Future<String> getAppVersion() async {
  // Get information about the current app package deployment
  PackageInfo packageInfo = await PackageInfo.fromPlatform();

  // Return the live version string (like 1.0.3)
  return packageInfo.version;
}
