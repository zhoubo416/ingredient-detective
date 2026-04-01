import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_health_profile.dart';

class UserHealthProfileService {
  static const _genderKey = 'userHealth.gender';
  static const _heightKey = 'userHealth.heightCm';
  static const _weightKey = 'userHealth.weightKg';
  static const _conditionsKey = 'userHealth.conditions';

  Future<UserHealthProfile> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    return UserHealthProfile(
      gender: prefs.getString(_genderKey) ?? '',
      heightCm: prefs.getDouble(_heightKey),
      weightKg: prefs.getDouble(_weightKey),
      healthConditions: prefs.getStringList(_conditionsKey) ?? const [],
    );
  }

  Future<void> saveProfile(UserHealthProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_genderKey, profile.gender);

    if (profile.heightCm == null) {
      await prefs.remove(_heightKey);
    } else {
      await prefs.setDouble(_heightKey, profile.heightCm!);
    }

    if (profile.weightKg == null) {
      await prefs.remove(_weightKey);
    } else {
      await prefs.setDouble(_weightKey, profile.weightKg!);
    }

    await prefs.setStringList(_conditionsKey, profile.healthConditions);
  }
}
