import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  const apiKey = 'AIzaSyCUOY1S34pIvaeQFIeA5f6c8b6FGwLiIms';
  const email = 'test_backend_script3@gmail.com';
  const password = 'password123';
  const backendUrl = 'https://collecta-app.onrender.com/api';

  print('1. Signing up with Firebase Auth REST API...');
  final signUpRes = await http.post(
    Uri.parse('https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$apiKey'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'email': email,
      'password': password,
      'returnSecureToken': true,
    }),
  );

  if (signUpRes.statusCode != 200) {
    print('❌ Firebase Sign Up failed: ${signUpRes.body}');
    return;
  }
  
  final signUpData = jsonDecode(signUpRes.body);
  final idToken = signUpData['idToken'];
  print('Token: $idToken');
}
