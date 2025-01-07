import 'dart:async';

import 'package:flutter/rendering.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:googleapis/drive/v3.dart';
import 'package:recoverbull_dart/src/storage/storage_interface.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

typedef SignInCallback = Future<GoogleSignInAccount?> Function();

/// Handles backup storage operations using Google Drive.
class GoogleDriveStorage extends BackupStorage {
  static final _google = GoogleSignIn(scopes: [DriveApi.driveFileScope]);
  final DriveApi _driveApi;
  final GoogleSignInAccount _account;
  String? _backupFolderId;
  GoogleDriveStorage(this._driveApi, this._account, String recoveryPath)
      : super(recoveryPath);
  // {
  //   _apiKey = dotenv.env['GOOGLE_DRIVE_API'];
  //   if (_apiKey == null) {
  //     throw Exception(
  //         'GOOGLE_DRIVE_API key not found in environment variables');
  //   }
  // }

  /// Connects to Google Drive and creates a new [GoogleDriveStorage] instance
  static Future<GoogleDriveStorage> connect(
      SignInCallback signInCallback, String path) async {
    try {
      final isSignedIn = await _google.isSignedIn();
      GoogleSignInAccount? account;
      if (!isSignedIn) {
        account = await signInCallback();
        if (account == null) {
          throw GoogleDriveException('Google Sign In cancelled or failed');
        }
      }
      final authHeaders = await account!.authHeaders;
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
        }
        ..folderColorRgb =
            '#666666'; // Grey color to be less noticeable in Drive 😅

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
      // Remove default permissions
      final permissions = await _driveApi.permissions.list(folderId);
      for (final permission in permissions.permissions ?? []) {
        if (permission.id != null) {
          await _driveApi.permissions.delete(folderId, permission.id!);
        }
      }

      // Add restricted permission for the owner
      await _driveApi.permissions.create(
        Permission()
          ..role = 'writer'
          ..type = 'user'
          ..emailAddress = _account.email,
        folderId,
        emailMessage: 'RecoverBull secure backup folder - DO NOT DELETE',
      );
    } catch (e) {
      throw GoogleDriveException('Failed to set folder permissions: $e');
    }
  }

  /// Updates an existing backup file
  Future<void> _updateBackup(String fileId, List<int> data) async {
    final file = File()
      ..appProperties = {
        'last_updated': DateTime.now().toIso8601String(),
        'protected': 'true',
      };

    await _driveApi.files.update(
      file,
      fileId,
      uploadMedia: Media(Stream.value(data), data.length),
    );
  }

  /// Creates a new backup file with protection metadata
  Future<void> _createBackup(String fileName, List<int> data) async {
    final file = File()
      ..name = fileName
      ..parents = [_backupFolderId!]
      ..appProperties = {
        'type': 'bullbitcoin_backup',
        'recovery_path': recoveryPath,
        'timestamp': DateTime.now().toIso8601String(),
        'protected': 'true',
      };

    await _driveApi.files.create(
      file,
      uploadMedia: Media(Stream.value(data), data.length),
    );
  }

  @override
  Future<void> writeMetaData(List<int> data, String fileName) async {
    try {
      final existing = await _findBackupMetadata(fileName);

      if (existing.isNotEmpty) {
        await _updateBackup(existing.first.id!, data);
      } else {
        await _createBackup(fileName, data);
      }

      debugPrint('Successfully saved backup: $fileName');
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

  /// Finds a specific backup file
  Future<List<File>> _findBackupMetadata(String fileName) async {
    try {
      final response = await _driveApi.files.list(
        q: "name = '$fileName' and '$_backupFolderId' in parents and trashed = false",
        spaces: 'drive',
        $fields: 'files(id, name, createdTime, modifiedTime, appProperties)',
      );

      return response.files ?? [];
    } catch (e) {
      throw GoogleDriveException('Error finding backup: $e');
    }
  }

  /// Disconnects from Google Drive.
  static Future<void> disconnect() async {
    try {
      await _google.disconnect();
    } catch (e) {
      throw GoogleDriveException('Error disconnecting from Google Drive: $e');
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
