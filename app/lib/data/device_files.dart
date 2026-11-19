import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart' show PlatformException;
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

  @override
  Future<List<int>?> pickBackup() async {
    final List<PlatformFile> files;
    try {
      files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
      );
    } on PlatformException catch (e) {
      // 삼성 휴대폰에서 파일 선택 창의 '다운로드' 메뉴로 고르면 시스템 미디어 저장소가
      // 접근을 거부해(SecurityException) 파일을 읽지 못한다. 저장소 경로로 고르면 된다.
      if (e.code == 'unknown_path')
        throw const BackupPickException.unreadable();
      rethrow;
    }
    if (files.isEmpty) return null;
    final path = files.first.path;
    if (path == null) throw const BackupPickException.unreadable();
    return File(path).readAsBytes();
  }

  @override
  Future<Directory> tempDir() => getTemporaryDirectory();
}

/// 고른 파일을 시스템이 넘겨주지 않았을 때. 사용자가 다르게 고르면 해결된다.
class BackupPickException implements Exception {
  const BackupPickException.unreadable()
    : message =
          '이 경로로는 파일을 열 수 없어요.\n'
          "파일 선택 창 왼쪽 메뉴의 '다운로드' 대신 "
          "'내 휴대폰(내장 메모리) › Download' 폴더로 들어가서 골라 주세요.";

  final String message;

  @override
  String toString() => 'BackupPickException: $message';
}
