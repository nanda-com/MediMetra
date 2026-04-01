class ReminderProvider extends StateNotifier<List<Reminder>> {
  ReminderProvider() : super([]);

  void addReminder(Reminder r) {
    state = [...state, r];
  }
}
