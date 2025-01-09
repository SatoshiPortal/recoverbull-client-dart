import 'package:googleapis/drive/v3.dart';

abstract class BackupStorage {
  final String recoveryPath;
  BackupStorage(this.recoveryPath);
  Future<bool> writeMetaData(List<int> data, String fileName);
  Future<List<int>> readMetaDataContent(File file);
  Future<List<File>> readAllMetaDataFiles();
}
