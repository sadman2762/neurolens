import 'package:shared_preferences/shared_preferences.dart';

class LocalProfileService {
  static const String _nameKey = 'neurolens_local_profile_name';

  final SharedPreferencesAsync _preferences =
      SharedPreferencesAsync();

  Future<String?> getName() async {
    final value = await _preferences.getString(_nameKey);
    final name = value?.trim();

    if (name == null || name.isEmpty) {
      return null;
    }

    return name;
  }

  Future<void> saveName(String name) async {
    final trimmedName = name.trim();

    if (trimmedName.isEmpty) {
      throw ArgumentError('Name cannot be empty.');
    }

    await _preferences.setString(
      _nameKey,
      trimmedName,
    );
  }

  Future<void> clearName() async {
    await _preferences.remove(_nameKey);
  }
}