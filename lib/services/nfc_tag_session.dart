import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:nfc_manager/ndef_record.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/nfc_manager_android.dart';
import 'package:nfc_manager/nfc_manager_ios.dart';
import 'package:nfc_manager_ndef/nfc_manager_ndef.dart';

import '../features/checkin/tag_decision.dart';

class NfcTagSession {
  Completer<TagSessionResult>? _pending;
  bool _settled = false;
  DateTime? _started;

  Future<bool> isEnabled() async {
    if (kIsWeb) return false;
    if (defaultTargetPlatform != TargetPlatform.iOS &&
        defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }
    try {
      final availability = await NfcManager.instance.checkAvailability();
      return availability == NfcAvailability.enabled;
    } catch (_) {
      return false;
    }
  }

  Future<TagSessionResult> listen() async {
    final started = DateTime.now();
    _started = started;
    if (!await isEnabled()) {
      return TagSessionResult(
        unavailable: true,
        elapsed: DateTime.now().difference(started),
      );
    }

    _settled = false;
    final pending = Completer<TagSessionResult>();
    _pending = pending;
    try {
      await NfcManager.instance.startSession(
        pollingOptions: {
          NfcPollingOption.iso14443,
          NfcPollingOption.iso15693,
        },
        alertMessageIos: 'Hold phone near the pod',
        invalidateAfterFirstReadIos: true,
        onDiscovered: (tag) async {
          if (_settled) return;
          final result = await _describe(tag, started);
          _finish(result);
          try {
            await NfcManager.instance.stopSession();
          } catch (_) {}
        },
        onSessionErrorIos: (error) {
          if (_settled) return;
          _finish(_fromIosError(error, started));
        },
      );
    } catch (_) {
      _finish(
        TagSessionResult(
          unavailable: true,
          elapsed: DateTime.now().difference(started),
        ),
      );
    }
    return pending.future;
  }

  Future<void> cancel() async {
    final started = _started ?? DateTime.now();
    _finish(
      TagSessionResult(
        cancelled: true,
        elapsed: DateTime.now().difference(started),
      ),
    );
    try {
      await NfcManager.instance.stopSession();
    } catch (_) {}
  }

  void _finish(TagSessionResult result) {
    if (_settled) return;
    _settled = true;
    final pending = _pending;
    if (pending != null && !pending.isCompleted) {
      pending.complete(result);
    }
  }

  TagSessionResult _fromIosError(NfcReaderSessionErrorIos error, DateTime started) {
    final elapsed = DateTime.now().difference(started);
    switch (error.code) {
      case NfcReaderErrorCodeIos.readerSessionInvalidationErrorUserCanceled:
        return TagSessionResult(cancelled: true, elapsed: elapsed);
      case NfcReaderErrorCodeIos.readerSessionInvalidationErrorSessionTimeout:
      case NfcReaderErrorCodeIos.readerSessionInvalidationErrorSystemIsBusy:
      case NfcReaderErrorCodeIos.readerTransceiveErrorTagConnectionLost:
        return TagSessionResult(holdCloser: true, elapsed: elapsed);
      default:
        return TagSessionResult(elapsed: elapsed);
    }
  }

  Future<TagSessionResult> _describe(NfcTag tag, DateTime started) async {
    final technologies = <String>[];
    String? identifier;
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final mifare = MiFareIos.from(tag);
      final iso15693 = Iso15693Ios.from(tag);
      final iso7816 = Iso7816Ios.from(tag);
      if (mifare != null) technologies.add('MiFare');
      if (iso15693 != null) technologies.add('ISO15693');
      if (iso7816 != null) technologies.add('ISO7816');
      if (NdefIos.from(tag) != null) technologies.add('NDEF');
      final bytes = mifare?.identifier ??
          iso15693?.identifier ??
          iso7816?.identifier;
      identifier = _hex(bytes);
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      final android = NfcTagAndroid.from(tag);
      if (android != null) {
        technologies.addAll(android.techList.map(_shortTech));
        identifier = _hex(android.id);
      }
    }

    var textRecordCount = 0;
    var hadOtherRecord = false;
    String? text;
    try {
      final ndef = Ndef.from(tag);
      final message = ndef == null
          ? null
          : (ndef.cachedMessage ?? await ndef.read());
      for (final record in message?.records ?? const <NdefRecord>[]) {
        final decoded = _textRecord(record);
        if (decoded == null) {
          hadOtherRecord = true;
        } else {
          textRecordCount += 1;
          text ??= decoded;
        }
      }
    } catch (_) {
      textRecordCount = 0;
      text = null;
    }

    return TagSessionResult(
      technologies: technologies,
      identifier: identifier,
      text: text,
      textRecordCount: textRecordCount,
      hadOtherRecord: hadOtherRecord,
      elapsed: DateTime.now().difference(started),
    );
  }
}

String? _textRecord(NdefRecord record) {
  final isText = record.typeNameFormat == TypeNameFormat.wellKnown &&
      record.type.length == 1 &&
      record.type.first == 0x54;
  if (!isText || record.payload.isEmpty) return null;
  final status = record.payload.first;
  final languageLength = status & 0x3F;
  final start = 1 + languageLength;
  if (start > record.payload.length) return null;
  final bytes = record.payload.sublist(start);
  try {
    if ((status & 0x80) != 0) return _utf16Be(bytes).trim();
    return utf8.decode(bytes).trim();
  } catch (_) {
    return null;
  }
}

String _utf16Be(List<int> bytes) {
  final codes = <int>[];
  for (var i = 0; i + 1 < bytes.length; i += 2) {
    codes.add((bytes[i] << 8) | bytes[i + 1]);
  }
  return String.fromCharCodes(codes);
}

String? _hex(List<int>? bytes) {
  if (bytes == null || bytes.isEmpty) return null;
  return bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
}

String _shortTech(String name) {
  final slash = name.lastIndexOf('.');
  return slash == -1 ? name : name.substring(slash + 1);
}
