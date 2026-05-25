import 'dart:convert';

import 'package:flutter/services.dart';

class DatabaseManifest {
  const DatabaseManifest({
    required this.databaseVersion,
    required this.createScripts,
    required this.initialContentScripts,
    required this.upgrades,
  });

  final int databaseVersion;
  final List<String> createScripts;
  final List<String> initialContentScripts;
  final List<DatabaseUpgradeScripts> upgrades;

  static const assetPath = 'assets/database/manifest.json';

  static Future<DatabaseManifest> load({AssetBundle? bundle}) async {
    final source = await (bundle ?? rootBundle).loadString(assetPath);
    final json = jsonDecode(source) as Map<String, Object?>;
    return DatabaseManifest(
      databaseVersion: json['databaseVersion'] as int,
      createScripts: _stringList(json['createScripts']),
      initialContentScripts: _stringList(json['initialContentScripts']),
      upgrades: ((json['upgrades'] as List<Object?>?) ?? const [])
          .map((entry) {
            final data = entry as Map<String, Object?>;
            return DatabaseUpgradeScripts(
              version: data['version'] as int,
              scripts: _stringList(data['scripts']),
            );
          })
          .toList(growable: false),
    );
  }

  List<String> upgradeScriptsFor(int oldVersion, int newVersion) {
    final scripts = <String>[];
    for (final upgrade in upgrades) {
      if (upgrade.version > oldVersion && upgrade.version <= newVersion) {
        scripts.addAll(upgrade.scripts);
      }
    }
    return scripts;
  }

  static List<String> _stringList(Object? value) {
    return ((value as List<Object?>?) ?? const []).cast<String>().toList(
      growable: false,
    );
  }
}

class DatabaseUpgradeScripts {
  const DatabaseUpgradeScripts({required this.version, required this.scripts});

  final int version;
  final List<String> scripts;
}
