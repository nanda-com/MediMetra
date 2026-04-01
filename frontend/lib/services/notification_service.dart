import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'api_service.dart';

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final ApiService _apiService = ApiService();

  /// Call this when your app starts up or right after the user logs in
  Future<void> initialize() async {
    try {
      // 1. Request permission for iOS/Web (Android doesn't strictly need this for basic push)
      NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        if (kDebugMode) {
          print('User granted notification permissions.');
        }
        
        // 2. Retrieve the raw FCM Device Token
        String? token = await _fcm.getToken();
        if (token != null) {
          if (kDebugMode) {
            print('Retrieved FCM Token: $token');
          }
          
          // 3. Dispatch the token to your FastAPI Backend
          await registerTokenWithBackend(token);
        }

        // 4. Attach a listener in case the token changes periodically (Firebase rotates these)
        _fcm.onTokenRefresh.listen((newToken) {
          registerTokenWithBackend(newToken);
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Warning: Firebase Messaging failed to initialize or obtain token: $e');
      }
    }
  }

  Future<void> registerTokenWithBackend(String token) async {
    try {
      // Calls your new POST /notifications/register-token endpoint
      await _apiService.post('/notifications/register-token', {
        'fcm_token': token
      });
      if (kDebugMode) {
        print('System: Successfully synced new FCM Token to FastAPI backend.');
      }
    } catch (e) {
      if (kDebugMode) {
        print('System: Failed to sync fcm token to backend: $e');
      }
    }
  }
}
