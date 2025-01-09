import 'dart:async';

import 'package:flutter/rendering.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:googleapis/drive/v3.dart';
import 'package:recoverbull_dart/src/storage/storage_interface.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

/// Handles backup storage operations using Google Drive.
class GoogleDriveStorage extends BackupStorage {
  final DriveApi _driveApi;
  final GoogleSignInAccount _account;
  String? _backupFolderId;
  GoogleDriveStorage(this._driveApi, this._account, String recoveryPath)
      : super(recoveryPath);

  /// Connects to Google Drive and creates a new [GoogleDriveStorage] instance
  static Future<GoogleDriveStorage> connect(
      GoogleSignInAccount? account, String path) async {
    try {
      if (account == null) {
        throw GoogleDriveException('Google Sign In cancelled or failed');
      }
      final authHeaders = await account.authHeaders;
      final authenticateClient = _GoogleAuthClient(authHeaders);
      final driveApi = DriveApi(authenticateClient);

      final storage = GoogleDriveStorage(driveApi, account, path);
      await storage._initializeBackupFolder();
      return storage;
    } catch (e) {
      throw GoogleDriveException('Error connecting to Google Drive: $e');
    }
  }

  /// Initializes the secure backup folder
  Future<void> _initializeBackupFolder() async {
    try {
      // Create hidden folder name from recovery path
      final hiddenFolderName = '.${recoveryPath.split('/').first}';
      final existing = await _driveApi.files.list(
        q: "name = '$hiddenFolderName' and mimeType = 'application/vnd.google-apps.folder' and trashed = false",
        spaces: 'drive',
        $fields: 'files(id)',
      );
      if (existing.files?.isNotEmpty == true) {
        _backupFolderId = existing.files!.first.id;
        return;
      }
      // Create new hidden backup folder
      final folderMetadata = File()
        ..name = hiddenFolderName
        ..mimeType = 'application/vnd.google-apps.folder'
        ..appProperties = {
          'type': 'bullbitcoin_backup',
          'path': recoveryPath,
          'created': DateTime.now().toIso8601String(),
        };
      final folder = await _driveApi.files.create(folderMetadata);
      _backupFolderId = folder.id;

      // Set restricted permissions
      await _setFolderPermissions(folder.id!);

      debugPrint('Initialized secure backup folder: $hiddenFolderName');
    } catch (e) {
      throw GoogleDriveException('Failed to initialize backup folder: $e');
    }
  }

  /// Sets restricted permissions to prevent accidental deletion
  Future<void> _setFolderPermissions(String folderId) async {
    try {
      // Add restricted permission for the owner
      await _driveApi.permissions.create(
        Permission()
          ..allowFileDiscovery = false
          ..role = 'writer'
          ..type = 'user'
          ..emailAddress = _account.email,
        folderId,
      );
    } catch (e) {
      throw GoogleDriveException('Failed to set folder permissions: $e');
    }
  }

  /// Creates a new backup file with protection metadata
  Future<void> _createBackup(String fileName, List<int> data) async {
    final file = File()
      ..name = fileName
      ..parents = [_backupFolderId!]
      ..appProperties = {
        'recovery_path': recoveryPath,
        'timestamp': DateTime.now().toIso8601String(),
      };
    await _driveApi.files.create(
      file,
      uploadMedia: Media(Stream.value(data), data.length),
    );
  }

  @override
  Future<bool> writeMetaData(List<int> data, String fileName) async {
    try {
      await _createBackup(fileName, data);
      debugPrint('Successfully saved backup: $fileName');
      return true;
    } catch (e) {
      throw GoogleDriveException('Failed to write backup: $e');
    }
  }

  @override
  Future<List<int>> readMetaDataContent(File file) async {
    try {
      if (file.id == null) {
        throw GoogleDriveException('Invalid backup file ID');
      }

      // Verify it's a valid backup file
      final isValid = file.appProperties?['type'] == 'bullbitcoin_backup' &&
          file.appProperties?['recovery_path'] == recoveryPath;

      if (!isValid) {
        throw GoogleDriveException('Invalid or unauthorized backup file');
      }

      final media = await _driveApi.files.get(
        file.id!,
        downloadOptions: DownloadOptions.fullMedia,
      ) as Media;

      return await _readMediaStream(media);
    } catch (e) {
      throw GoogleDriveException('Error reading backup content: $e');
    }
  }

  // Reads a media stream into a byte array
  Future<List<int>> _readMediaStream(Media media) async {
    final completer = Completer<List<int>>();
    final bytes = <int>[];

    media.stream.listen(
      bytes.addAll,
      onError: (error) => completer.completeError(
          GoogleDriveException('Error streaming backup data: $error')),
      onDone: () => completer.complete(bytes),
      cancelOnError: true,
    );

    return completer.future;
  }

  @override

  /// Reads all metadata files from Google Drive
  Future<List<File>> readAllMetaDataFiles() async {
    if (_backupFolderId == null) {
      throw GoogleDriveException('Backup folder not initialized');
    }
    try {
      final response = await _driveApi.files.list(
        q: "'$_backupFolderId' in parents and trashed = false",
        spaces: 'drive',
        $fields: 'files(id, name, createdTime, modifiedTime, appProperties)',
        orderBy: 'modifiedTime desc',
      );

      if (response.files == null || response.files!.isEmpty) {
        debugPrint('No metadata files found');
        return [];
      }

      return response.files ?? [];
    } catch (e) {
      throw GoogleDriveException('Failed to list backups: $e');
    }
  }
}

/// Custom HTTP client for Google authentication.
class _GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();
  _GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _client.send(request..headers.addAll(_headers));
  }

  @override
  void close() {
    _client.close();
    super.close();
  }
}

/// Custom exception for Google Drive operations.
class GoogleDriveException implements Exception {
  final String message;
  GoogleDriveException(this.message);

  @override
  String toString() => 'GoogleDriveException: $message';
}
