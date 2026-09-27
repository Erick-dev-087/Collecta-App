import 'dart:io';

void main() {
  final file = File('C:/Users/Erick/AppData/Local/Pub/Cache/hosted/pub.dev/firebase_admin_sdk-0.5.6/lib/src/app/credential.dart');
  final lines = file.readAsLinesSync();
  var capture = false;
  for (var line in lines) {
    if (line.contains('factory Credential.fromServiceAccountParams')) {
      capture = true;
    }
    if (capture) {
      print(line);
      if (line.contains(') {')) break;
    }
  }
}
