import 'package:googleapis/drive/v3.dart';
import 'package:recoverbull_dart/src/storage/storage_interface.dart';

class ICloudStorage extends BackupStorage {
  ICloudStorage(super.recoveryPath);
  @override
  Future<List<File>> readAllMetaDataFiles() {
    // TODO: implement readAllMetaDataFiles
    throw UnimplementedError();
  }

  @override
  Future<List<int>> readMetaDataContent(File file) {
    // TODO: implement readMetaDataContent
    throw UnimplementedError();
  }

  @override
  Future<bool> writeMetaData(List<int> data, String fileName) {
    // TODO: implement writeMetaData
    throw UnimplementedError();
  }
}
