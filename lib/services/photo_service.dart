import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class PhotoService {
  Future<String> saveWorkerPhoto({
    required String workerId,
    required String sourcePath,
  }) async {
    final dir = await getApplicationDocumentsDirectory();
    final photosDir = Directory(p.join(dir.path, 'worker_photos'));
    if (!photosDir.existsSync()) {
      await photosDir.create(recursive: true);
    }

    final destPath = p.join(photosDir.path, '$workerId.jpg');
    await File(sourcePath).copy(destPath);
    return destPath;
  }

  File? photoFile(String? path) {
    if (path == null || path.isEmpty) return null;
    final file = File(path);
    return file.existsSync() ? file : null;
  }
}
