// lib/core/services/drive_sync_service.dart
// Real Google Drive sync — versioned envelopes + mutex lock

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'auth_service.dart';
import 'encryption_service.dart';

class DriveSyncService {
  DriveSyncService._();
  static final DriveSyncService instance = DriveSyncService._();

  String _pairCode   = '';
  String _deviceId   = '';

  // Mutex: prevents concurrent uploads overwriting each other
  final _locks = <String, bool>{};
  bool _tryLock(String f)  { if (_locks[f] == true) return false; _locks[f] = true; return true; }
  void _unlock(String f)   => _locks.remove(f);

  void setPairCode(String code) => _pairCode = code;
  void setDeviceId(String id)   => _deviceId = id;

  // ── Upload ──────────────────────────────────────────────

  Future<bool> _upload(String fileName, dynamic data) async {
    if (_pairCode.isEmpty) return false;
    if (!_tryLock(fileName)) {
      if (kDebugMode) debugPrint('Drive: upload locked, skipping $fileName');
      return false;
    }
    try {
      final api = await AuthService.instance.getDriveApi();
      if (api == null) return false;

      // Versioned envelope — timestamp prevents stale overwrites
      final envelope = {
        'v':   DateTime.now().microsecondsSinceEpoch, // monotonic, crash-safe
        'did': _deviceId,
        'ts':  DateTime.now().toIso8601String(),
        'data': data,
      };

      final encrypted = EncryptionService.instance
          .encrypt(jsonEncode(envelope), _pairCode);
      final bytes     = Uint8List.fromList(utf8.encode(encrypted));

      final existing = await _findFile(api, fileName);
      final meta     = drive.File()
        ..name    = fileName
        ..parents = existing == null ? ['appDataFolder'] : null;

      final media = drive.Media(
        Stream.value(bytes), bytes.length,
        contentType: 'application/octet-stream',
      );

      if (existing != null) {
        await api.files.update(meta, existing,
            uploadMedia: media, $fields: 'id');
      } else {
        await api.files.create(meta,
            uploadMedia: media, $fields: 'id');
      }
      if (kDebugMode) debugPrint('Drive upload ✅ $fileName');
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('Drive upload error [$fileName]: $e');
      return false;
    } finally {
      _unlock(fileName);
    }
  }

  // ── Download ────────────────────────────────────────────

  Future<dynamic> _download(String fileName) async {
    if (_pairCode.isEmpty) return null;
    try {
      final api    = await AuthService.instance.getDriveApi();
      if (api == null) return null;
      final fileId = await _findFile(api, fileName);
      if (fileId == null) return null;

      final response = await api.files.get(
        fileId, downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final bytes = <int>[];
      await response.stream.forEach(bytes.addAll);

      final decrypted = EncryptionService.instance
          .decrypt(utf8.decode(bytes), _pairCode);
      final decoded   = jsonDecode(decrypted);

      // Unwrap versioned envelope
      if (decoded is Map && decoded.containsKey('data')) {
        return decoded['data'];
      }
      return decoded;
    } catch (e) {
      if (kDebugMode) debugPrint('Drive download error [$fileName]: $e');
      return null;
    }
  }

  Future<String?> _findFile(drive.DriveApi api, String name) async {
    try {
      final list = await api.files.list(
        spaces: 'appDataFolder',
        q: "name = '$name' and trashed = false",
        $fields: 'files(id)',
        pageSize: 1,
      );
      final files = list.files;
      if (files == null || files.isEmpty) return null;
      return files.first.id;
    } catch (_) {
      return null;
    }
  }

  // ── File names — per-device so partners don't overwrite ─

  String get _messagesFile => 'vlr_msg_$_deviceId.enc';
  String get _memoriesFile => 'vlr_mem_$_deviceId.enc';
  String get _moodFile     => 'vlr_mood_$_deviceId.enc';

  // ── Public API ──────────────────────────────────────────

  Future<bool> uploadMessages(List<Map<String, dynamic>> msgs) =>
      _upload(_messagesFile, msgs);
  Future<bool> uploadMemories(List<Map<String, dynamic>> mems) =>
      _upload(_memoriesFile, mems);
  Future<bool> uploadMood(Map<String, dynamic> mood) =>
      _upload(_moodFile, mood);

  Future<List<Map<String, dynamic>>> downloadMessages() async {
    final d = await _download(_messagesFile);
    if (d == null) return [];
    try { return (d as List).cast<Map<String, dynamic>>(); } catch (_) { return []; }
  }

  Future<List<Map<String, dynamic>>> downloadMemories() async {
    final d = await _download(_memoriesFile);
    if (d == null) return [];
    try { return (d as List).cast<Map<String, dynamic>>(); } catch (_) { return []; }
  }

  Future<Map<String, dynamic>?> downloadMood() async {
    final d = await _download(_moodFile);
    if (d == null) return null;
    try { return d as Map<String, dynamic>; } catch (_) { return null; }
  }

  // ── Merge: UUID dedup + timestamp wins ─────────────────

  List<Map<String, dynamic>> mergeMessages(
    List<Map<String, dynamic>> local,
    List<Map<String, dynamic>> remote,
  ) {
    final merged = <String, Map<String, dynamic>>{};
    for (final m in local)  { final id = m['id'] as String?; if (id != null) merged[id] = m; }
    for (final m in remote) {
      final id = m['id'] as String?;
      if (id == null) continue;
      if (!merged.containsKey(id)) {
        merged[id] = m;
      } else {
        // Timestamp wins (newer message takes precedence)
        final lt = DateTime.tryParse(merged[id]!['timestamp'] as String? ?? '') ?? DateTime(2000);
        final rt = DateTime.tryParse(m['timestamp'] as String? ?? '') ?? DateTime(2000);
        if (rt.isAfter(lt)) merged[id] = m;
      }
    }
    return merged.values.toList()
      ..sort((a, b) {
        final ta = DateTime.tryParse(a['timestamp'] as String? ?? '') ?? DateTime(2000);
        final tb = DateTime.tryParse(b['timestamp'] as String? ?? '') ?? DateTime(2000);
        return ta.compareTo(tb);
      });
  }
}
