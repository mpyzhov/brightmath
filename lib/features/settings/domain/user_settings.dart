import 'package:flutter/material.dart';

@immutable
class UserSettings {
  const UserSettings({
    required this.languageCode,
    required this.soundEnabled,
    required this.hapticsEnabled,
  });

  final String languageCode;
  final bool soundEnabled;
  final bool hapticsEnabled;

  factory UserSettings.defaults() {
    return const UserSettings(
      languageCode: 'en',
      soundEnabled: true,
      hapticsEnabled: true,
    );
  }

  UserSettings copyWith({
    String? languageCode,
    bool? soundEnabled,
    bool? hapticsEnabled,
  }) {
    return UserSettings(
      languageCode: languageCode ?? this.languageCode,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
    );
  }
}
