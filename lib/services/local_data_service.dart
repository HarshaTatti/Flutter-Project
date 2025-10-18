import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/personal_data.dart';

/// Service to manage local data storage and retrieval
/// All data stays on the device - no external servers
class LocalDataService {
  static const String _personalDataKey = 'personal_data';
  static const String _chatHistoryKey = 'chat_history';

  /// Initialize with sample data if no data exists
  Future<void> initializeSampleData() async {
    final prefs = await SharedPreferences.getInstance();

    if (!prefs.containsKey(_personalDataKey)) {
      final sampleData = PersonalData(
        name: 'Prakash',
        email: 'Prakash@gmail.com',
        phone: '+1-555-0123',
        address: '123 Privacy Street, pippara City, India',
        dateOfBirth: '2006-03-27',
        occupation: 'Software Engineer',
        preferences: {
          'favoriteColor': 'Blue',
          'favoriteFood': 'Pizza',
          'language': 'English',
        },
        interests: ['Reading', 'Coding', 'Hiking', 'Photography'],
      );
      await savePersonalData(sampleData);
    }
  }

  /// Save personal data locally
  Future<void> savePersonalData(PersonalData data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_personalDataKey, jsonEncode(data.toJson()));
  }

  /// Get personal data from local storage
  Future<PersonalData?> getPersonalData() async {
    final prefs = await SharedPreferences.getInstance();
    final dataString = prefs.getString(_personalDataKey);

    if (dataString == null) return null;

    return PersonalData.fromJson(jsonDecode(dataString));
  }

  /// Update specific field in personal data
  Future<void> updateField(String field, dynamic value) async {
    final data = await getPersonalData();
    if (data == null) return;

    Map<String, dynamic> json = data.toJson();
    json[field] = value;

    await savePersonalData(PersonalData.fromJson(json));
  }

  /// Clear all local data
  Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_personalDataKey);
    await prefs.remove(_chatHistoryKey);
  }

  /// Save chat history
  Future<void> saveChatHistory(List<Map<String, dynamic>> messages) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_chatHistoryKey, jsonEncode(messages));
  }

  /// Get chat history
  Future<List<Map<String, dynamic>>> getChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyString = prefs.getString(_chatHistoryKey);

    if (historyString == null) return [];

    return List<Map<String, dynamic>>.from(jsonDecode(historyString));
  }
}
