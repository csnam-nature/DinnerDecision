import 'dart:io';

import 'package:file_selector/file_selector.dart';
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

  /// 백업 파일(zip)을 골라 내용을 읽는다. 취소하면 null.
  Future<List<int>?> pickBackup();

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

  /// 백업 파일 종류. 메신저·드라이브에서 받은 zip은 형식이 다르게 저장되기도 해서
  /// 몇 가지를 같이 허용한다. 내용은 [Backup.decode]가 확인한다.
  static const _zip = XTypeGroup(
    label: '백업 파일 (zip)',
    extensions: ['zip'],
    mimeTypes: [
      'application/zip',
      'application/x-zip-compressed',
      'application/x-zip',
      'application/octet-stream',
    ],
    uniformTypeIdentifiers: ['public.zip-archive', 'com.pkware.zip-archive'],
  );

  @override
  Future<List<int>?> pickBackup() async {
    // 경로 대신 내용을 바로 받는다. 파일 제공 앱에 따라 경로를 못 주는 경우가 있다.
    final file = await openFile(acceptedTypeGroups: const [_zip]);
    return file?.readAsBytes();
  }

  @override
  Future<Directory> tempDir() => getTemporaryDirectory();
}
