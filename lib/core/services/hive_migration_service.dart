// lib/core/services/hive_migration_service.dart
// Veloura — Hive schema migration + corruption recovery

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kSchemaVersion = 2;
const _kSchemaKey     = 'hive_schema_version';

class HiveMigrationService {
  HiveMigrationService._();
  static final HiveMigrationService instance = HiveMigrationService._();

  static const _boxes = [
    'veloura_messages',
    'veloura_memories',
    'veloura_mood',
    'veloura_pairing',
  ];

  Future<void> runMigrations() async {
    try {
      final prefs  = await SharedPreferences.getInstance();
      final stored = prefs.getInt(_kSchemaKey) ?? 0;
      if (stored < _kSchemaVersion) {
        if (kDebugMode) debugPrint('Hive migration: v$stored → v$_kSchemaVersion');
        await _migrate(from: stored);
        await prefs.setInt(_kSchemaKey, _kSchemaVersion);
        if (kDebugMode) debugPrint('Hive migration complete ✓');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Hive migration error: $e');
    }
  }

  Future<void> _migrate({required int from}) async {
    if (from < 1) await _migrateV0toV1();
    if (from < 2) await _migrateV1toV2();
  }

  Future<void> _migrateV0toV1() async {
    if (kDebugMode) debugPrint('Hive v0→v1: initial stamp');
  }

  Future<void> _migrateV1toV2() async {
    if (kDebugMode) debugPrint('Hive v1→v2: validating JSON integrity');
    for (final boxName in _boxes) {
      try {
        if (!Hive.isBoxOpen(boxName)) continue;
        final box      = Hive.box(boxName);
        final toDelete = <dynamic>[];
        for (final entry in box.toMap().entries) {
          try {
            if (entry.value is String) {
              jsonDecode(entry.value as String);
            }
          } catch (_) {
            toDelete.add(entry.key);
          }
        }
        for (final key in toDelete) {
          await box.delete(key);
        }
        if (toDelete.isNotEmpty) {
          if (kDebugMode) debugPrint('$boxName: removed ${toDelete.length} corrupt entries');
        }
      } catch (e) {
        if (kDebugMode) debugPrint('Migration error in $boxName: $e');
      }
    }
  }

  Future<void> resetAllBoxes() async {
    for (final boxName in _boxes) {
      try {
        if (Hive.isBoxOpen(boxName)) await Hive.box(boxName).clear();
      } catch (_) {}
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kSchemaKey, _kSchemaVersion);
  }

  Future<Map<String, int>> validateIntegrity() async {
    final result = <String, int>{};
    for (final boxName in _boxes) {
      try {
        result[boxName] = Hive.isBoxOpen(boxName)
            ? Hive.box(boxName).length : -1;
      } catch (_) {
        result[boxName] = -1;
      }
    }
    return result;
  }
}
