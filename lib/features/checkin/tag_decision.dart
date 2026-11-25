import 'test_tag_line.dart';

class TagSessionResult {
  const TagSessionResult({
    this.cancelled = false,
    this.unavailable = false,
    this.holdCloser = false,
    this.technologies = const [],
    this.identifier,
    this.text,
    this.textRecordCount = 0,
    this.hadOtherRecord = false,
    required this.elapsed,
  });

  final bool cancelled;
  final bool unavailable;
  final bool holdCloser;
  final List<String> technologies;
  final String? identifier;
  final String? text;
  final int textRecordCount;
  final bool hadOtherRecord;
  final Duration elapsed;
}

enum TagAction { cancel, save, reject, diagnostic }

class TagDecision {
  const TagDecision(this.action, {this.message, this.line});

  final TagAction action;
  final String? message;
  final TestTagLine? line;
}

TagDecision interpretTagRead({
  required bool podDiagnostics,
  required TagSessionResult result,
}) {
  if (result.cancelled) return const TagDecision(TagAction.cancel);
  if (result.unavailable) {
    return const TagDecision(TagAction.reject, message: nfcUnavailableMessage);
  }
  if (result.holdCloser) {
    return const TagDecision(TagAction.reject, message: holdCloserMessage);
  }
  if (podDiagnostics) {
    return TagDecision(TagAction.diagnostic, message: podDiagnostic(result));
  }
  if (result.textRecordCount != 1 || result.hadOtherRecord) {
    if (result.textRecordCount == 0 && !result.hadOtherRecord) {
      return const TagDecision(TagAction.reject, message: noTagFoundMessage);
    }
    return const TagDecision(TagAction.reject, message: notSingleTextMessage);
  }
  final line = parseTestTagLine(result.text ?? '');
  if (!line.saves) {
    return TagDecision(TagAction.reject, message: line.message);
  }
  return TagDecision(TagAction.save, line: line);
}

String podDiagnostic(TagSessionResult result) {
  if (result.technologies.isEmpty &&
      (result.text == null || result.text!.isEmpty)) {
    return noTagFoundMessage;
  }
  final tech = result.technologies.isEmpty
      ? 'tag'
      : result.technologies.join(', ');
  final id = result.identifier == null ? '' : ' · ${result.identifier}';
  return 'Saw $tech$id';
}
