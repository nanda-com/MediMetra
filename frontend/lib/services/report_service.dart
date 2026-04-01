import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'api_service.dart';

class ReportService {

  /// Uploads an image cross-platform seamlessly (Mobile/Web) bypassing dart:io File restrictions.
  Future<Map<String, dynamic>?> uploadReport(XFile file) async {
    try {
      final token = await FirebaseAuth.instance.currentUser?.getIdToken();
      
      var request = http.MultipartRequest(
        'POST', 
        Uri.parse('${ApiService.baseUrl}/reports/upload')
      );

      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      // Extract bytes directly so we can securely upload without File paths failing on Flutter Web
      final bytes = await file.readAsBytes();
      request.files.add(
        http.MultipartFile.fromBytes(
          'file', 
          bytes, 
          filename: file.name
        )
      );

      if (kDebugMode) {
        print("Dispatching Medical Report to backend Gemini AI...");
      }
      
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return json.decode(response.body);
      } else {
        throw Exception("Server Error uploading report: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      if (kDebugMode) {
        print("Upload Exception Triggered: $e");
      }
      return null;
    }
  }
}
