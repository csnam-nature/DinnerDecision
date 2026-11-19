import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

enum PhotoSource { camera, gallery }

/// 사진 고르기, 파일 공유, 파일 고르기. 테스트에서 바꿔 끼울 수 있게 나눠 둔다.
abstract interface class DeviceFiles {
  /// 고른 사진의 임시 경로. 취소하면 null.
  Future<String?> pickPhoto(PhotoSource source);

  /// 공유 시트로 파일을 보낸다 (드라이브 저장, 카톡 나에게 보내기 등).
  Future<void> share(String path, {required String subject});

  /// 백업 파일(zip)을 고른다. 취소하면 null.
  Future<String?> pickBackup();

  Future<Directory> tempDir();
}

class PlatformDeviceFiles implements DeviceFiles {
  const PlatformDeviceFiles();

  @override
  Future<String?> pickPhoto(PhotoSource source) async {
    final picked = await ImagePicker().pickImage(
      source: source == PhotoSource.camera
          ? ImageSource.camera
          : ImageSource.gallery,
      // 기록용이라 긴 변 1600px, 화질 80%면 충분하다. 한 장에 수백 KB.
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 80,
    );
    return picked?.path;
  }

  @override
  Future<void> share(String path, {required String subject}) async {
    await SharePlus.instance.share(
      ShareParams(files: [XFile(path)], subject: subject, title: subject),
    );
  }

  @override
  Future<String?> pickBackup() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );
    return files.isEmpty ? null : files.first.path;
  }

  @override
  Future<Directory> tempDir() => getTemporaryDirectory();
}
