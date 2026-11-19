import 'dart:io';
import 'dart:math';

import 'package:path/path.dart' as p;

/// 기록 사진. 앱 폴더의 photos/ 안에 두고, 기록에는 파일 이름만 저장한다.
/// (전체 경로를 저장하면 앱을 다시 설치하거나 복원했을 때 경로가 달라진다.)
class PhotoStore {
  PhotoStore(this.dir);

  final Directory dir;
  final _random = Random();

  File file(String name) => File(p.join(dir.path, p.basename(name)));

  /// 고른 사진을 앱 폴더로 복사하고 새 파일 이름을 돌려준다.
  Future<String> add(String sourcePath) async {
    await dir.create(recursive: true);
    final ext = p.extension(sourcePath).toLowerCase();
    final name =
        '${DateTime.now().millisecondsSinceEpoch}_'
        '${_random.nextInt(1 << 32).toRadixString(16)}'
        '${ext.isEmpty ? '.jpg' : ext}';
    await File(sourcePath).copy(file(name).path);
    return name;
  }

  /// 백업에서 꺼낸 사진을 같은 이름으로 넣는다.
  Future<void> put(String name, List<int> bytes) async {
    await dir.create(recursive: true);
    await file(name).writeAsBytes(bytes, flush: true);
  }

  /// 어떤 기록에도 쓰이지 않는 사진을 지운다. 앱을 켤 때 부른다.
  /// (기록을 지운 직후에는 '되돌리기'가 있어 바로 지우지 않는다.)
  Future<int> removeUnused(Set<String> used) async {
    if (!await dir.exists()) return 0;
    var removed = 0;
    await for (final entity in dir.list()) {
      if (entity is File && !used.contains(p.basename(entity.path))) {
        await entity.delete();
        removed++;
      }
    }
    return removed;
  }
}
