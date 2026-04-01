import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  // Automatically detects if we're on Web or Emulator
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8000';
    } else {
      return 'http://10.0.2.2:8000';
    }
  }

  // Helper method to retrieve the Firebase ID token
  Future<String?> _getToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Force refresh if you need the latest claims, else use false
      return await user.getIdToken();
    }
    return null;
  }

  // Example GET request structured to pass the Token securely
  Future<dynamic> get(String endpoint) async {
    final String url = '$baseUrl$endpoint';
    final token = await _getToken();

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load data: ${response.statusCode}');
    }
  }

  // Example POST
  Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    final String url = '$baseUrl$endpoint';
    final token = await _getToken();

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: json.encode(body),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to post data: ${response.statusCode}');
    }
  }
}
