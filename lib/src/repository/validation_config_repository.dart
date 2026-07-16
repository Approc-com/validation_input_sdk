import 'dart:io';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../models/validation_models.dart';
import '../utils/semver.dart';

typedef ConfigListener = void Function(ValidationConfig config);

class ValidationConfigRepository {
  ValidationConfigRepository({
    required this.assetPath,
    String? defaultValidationJsonFileUrl,
    String? remoteUrl,
    this.httpClient,
    this.subdirectory = 'validation',
  }) : defaultValidationJsonFileUrl = defaultValidationJsonFileUrl ?? remoteUrl;

  final String assetPath;
  final String? defaultValidationJsonFileUrl;
  final http.Client? httpClient;
  final String subdirectory;

  ValidationConfig? _active;
  ConfigListener? onConfigUpdated;

  ValidationConfig get active {
    if (_active == null) {
      throw StateError('Call init() before reading active config');
    }
    return _active!;
  }

  bool get isInitialized => _active != null;

  Future<void> init() async {
    final dir = await _dir();
    await dir.create(recursive: true);

    await _applyPendingIfExists(dir);

    final activeFile = File('${dir.path}/validation.json');
    if (await activeFile.exists()) {
      _active = ValidationConfig.parse(await activeFile.readAsString());
      return;
    }

    final bundled = await rootBundle.loadString(assetPath);
    await _atomicWrite(activeFile, bundled);
    _active = ValidationConfig.parse(bundled);
  }

  Future<SyncOutcome> sync({
    required String localValidationFileVersion,
    String? validationJsonFileUrl,
  }) async {
    if (_active == null) await init();
    final url = _resolveValidationJsonFileUrl(validationJsonFileUrl);
    if (url == null) {
      return const SyncOutcome(status: SyncStatus.upToDate);
    }

    try {
      final client = httpClient ?? http.Client();
      final response = await client.get(Uri.parse(url));
      if (response.statusCode != 200) {
        return SyncOutcome(
          status: SyncStatus.fetchFailed,
          message: 'HTTP ${response.statusCode}',
        );
      }

      final remote = ValidationConfig.parse(response.body);
      if (!Semver.isValid(remote.version) || !Semver.isValid(_active!.version)) {
        return const SyncOutcome(status: SyncStatus.invalidRemote);
      }

      if (!Semver.isGreater(remote.version, _active!.version)) {
        return SyncOutcome(status: SyncStatus.upToDate, remoteVersion: remote.version);
      }

      if (remote.sync.forceValidationFileUpdate &&
          Semver.isLess(
            localValidationFileVersion,
            remote.sync.minValidationFileVersionAllowed,
          )) {
        return SyncOutcome(
          status: SyncStatus.localValidationFileBelowMinAllowed,
          remoteVersion: remote.version,
          message:
              'Local validation $localValidationFileVersion < min allowed '
              '${remote.sync.minValidationFileVersionAllowed}',
        );
      }

      final dir = await _dir();
      if (remote.sync.applyPolicy == 'immediate') {
        await _atomicWrite(File('${dir.path}/validation.json'), response.body);
        _active = remote;
        onConfigUpdated?.call(remote);
        return SyncOutcome(status: SyncStatus.updated, remoteVersion: remote.version);
      }

      await _atomicWrite(
        File('${dir.path}/validation_pending.json'),
        response.body,
      );
      return SyncOutcome(
        status: SyncStatus.pendingNextLaunch,
        remoteVersion: remote.version,
      );
    } catch (e) {
      return SyncOutcome(status: SyncStatus.fetchFailed, message: '$e');
    }
  }

  String? _resolveValidationJsonFileUrl(String? validationJsonFileUrl) {
    final override = validationJsonFileUrl?.trim();
    if (override != null && override.isNotEmpty) return override;
    final fallback = defaultValidationJsonFileUrl?.trim();
    if (fallback != null && fallback.isNotEmpty) return fallback;
    return null;
  }

  Future<void> _applyPendingIfExists(Directory dir) async {
    final pending = File('${dir.path}/validation_pending.json');
    if (!await pending.exists()) return;

    final active = File('${dir.path}/validation.json');
    await _atomicWrite(active, await pending.readAsString());
    await pending.delete();
  }

  Future<Directory> _dir() async {
    final support = await getApplicationSupportDirectory();
    return Directory('${support.path}/$subdirectory');
  }

  Future<void> _atomicWrite(File target, String content) async {
    final tmp = File('${target.path}.tmp');
    await tmp.writeAsString(content);
    if (await target.exists()) await target.delete();
    await tmp.rename(target.path);
  }
}
