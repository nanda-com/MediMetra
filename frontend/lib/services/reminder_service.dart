import 'api_service.dart';

class ReminderService {
  final ApiService _apiService = ApiService();

  Future<void> createReminder(Map<String, dynamic> data) async {
    await _apiService.post("/reminders", data);
  }

  Future<List<dynamic>> getReminders() async {
    return await _apiService.get("/reminders");
  }
}

