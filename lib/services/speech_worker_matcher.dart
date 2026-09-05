import '../models/worker.dart';

class SpeechWorkerMatcher {
  Worker? matchTranscript(String transcript, List<Worker> workers) {
    final normalized = _normalize(transcript);
    if (normalized.isEmpty || workers.isEmpty) return null;

    Worker? best;
    var bestScore = 0;

    for (final worker in workers) {
      final name = _normalize(worker.name);
      if (name.isEmpty) continue;

      if (normalized == name) return worker;
      if (normalized.contains(name) || name.contains(normalized)) {
        final score = name.length + 100;
        if (score > bestScore) {
          bestScore = score;
          best = worker;
        }
        continue;
      }

      for (final token in normalized.split(' ')) {
        if (token.length < 2) continue;
        if (name.contains(token) || token.contains(name)) {
          final score = token.length;
          if (score > bestScore) {
            bestScore = score;
            best = worker;
          }
        }
      }

      final distance = _levenshtein(normalized, name);
      final threshold = (name.length / 2).ceil();
      if (distance <= threshold) {
        final score = 50 - distance;
        if (score > bestScore) {
          bestScore = score;
          best = worker;
        }
      }
    }

    return best;
  }

  String _normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  int _levenshtein(String a, String b) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;

    final rows = a.length + 1;
    final cols = b.length + 1;
    final matrix = List.generate(rows, (_) => List<int>.filled(cols, 0));

    for (var i = 0; i < rows; i++) {
      matrix[i][0] = i;
    }
    for (var j = 0; j < cols; j++) {
      matrix[0][j] = j;
    }

    for (var i = 1; i < rows; i++) {
      for (var j = 1; j < cols; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1,
          matrix[i][j - 1] + 1,
          matrix[i - 1][j - 1] + cost,
        ].reduce((left, right) => left < right ? left : right);
      }
    }

    return matrix[a.length][b.length];
  }
}
