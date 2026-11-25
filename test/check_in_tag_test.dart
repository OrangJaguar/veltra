import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:veltra/core/demo_crew.dart';
import 'package:veltra/core/demo_mode.dart';
import 'package:veltra/features/checkin/checkin_scenario.dart';
import 'package:veltra/features/checkin/tag_decision.dart';
import 'package:veltra/features/checkin/test_tag_line.dart';
import 'package:veltra/models/check_in.dart';
import 'package:veltra/repositories/check_in_repository.dart';
import 'package:veltra/services/database_service.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('valid lines save their channels and rejects do not', () {
    final temperature = parseTestTagLine('VELTRA1,TAG01,34.2');
    expect(temperature.saves, isTrue);
    expect(temperature.podId, 'TAG01');
    expect(temperature.foreheadTempC, 34.2);
    expect(temperature.stripVolumeUl, isNull);
    expect(temperature.conductivityUsCm, isNull);

    final full = parseTestTagLine(' VELTRA2, TAG02, 35.1, 12.5, 820 ');
    expect(full.saves, isTrue);
    expect(full.stripVolumeUl, 12.5);
    expect(full.conductivityUsCm, 820);

    expect(parseTestTagLine('HELLO').message, unrelatedTagMessage);
    expect(parseTestTagLine('VELTRA1,TAG01').message, tooFewFieldsMessage);
    expect(
      parseTestTagLine('VELTRA2,TAG02,35.1,12.5').message,
      tooFewFieldsMessage,
    );
    expect(parseTestTagLine('VELTRA9,TAG01,34.2').message, unknownPrefixMessage);
    expect(parseTestTagLine('VELTRA1,TAG01,hot').message, notANumberMessage);
    expect(parseTestTagLine('VELTRA1,,34.2').message, missingPodMessage);
    expect(
      parseTestTagLine('VELTRA2,TAG02,35.1,-1,820').message,
      volumeRangeMessage,
    );
    expect(
      parseTestTagLine('VELTRA1,TAG01,29.9').message,
      temperatureRangeMessage,
    );
    expect(parseTestTagLine('VELTRA1,TAG01,42.0').saves, isTrue);
    expect(parseTestTagLine('VELTRA1,TAG01,42.1').message, temperatureRangeMessage);
  });

  test('a second record and a missed tag do not become a save', () {
    final extra = interpretTagRead(
      podDiagnostics: false,
      result: const TagSessionResult(
        text: 'VELTRA1,TAG01,34.2',
        textRecordCount: 2,
        elapsed: Duration(milliseconds: 400),
      ),
    );
    expect(extra.action, TagAction.reject);
    expect(extra.message, notSingleTextMessage);

    final away = interpretTagRead(
      podDiagnostics: false,
      result: const TagSessionResult(
        holdCloser: true,
        elapsed: Duration(seconds: 20),
      ),
    );
    expect(away.message, holdCloserMessage);

    final pod = interpretTagRead(
      podDiagnostics: true,
      result: const TagSessionResult(
        technologies: ['ISO15693'],
        identifier: 'aabb',
        elapsed: Duration(milliseconds: 300),
      ),
    );
    expect(pod.action, TagAction.diagnostic);
    expect(pod.message, 'Saw ISO15693 · aabb');
    expect(pod.message, isNot(contains('sensor_pod')));
  });

  test('a test tag saves once, keeps the roster honest, and stores no rate', () async {
    final tempDir = await Directory.systemTemp.createTemp('veltra_tag_');
    final service = await DatabaseService.openPath('${tempDir.path}/tag.db');
    final repo = CheckInRepository(service);
    await repo.seedDemoCrew(demoUserId);
    final avery = DemoCrew.workers.first.id;

    final saved = await repo.saveTestTag(
      attemptId: 'tag-1',
      crewId: DemoCrew.crewId,
      workerId: avery,
      windowId: DemoCrew.windowId,
      capturedAt: DateTime.utc(2026, 11, 23, 18),
      assignedPodId: null,
      podId: 'TAG02',
      foreheadTempC: 35.1,
      stripVolumeUl: 12.5,
      conductivityUsCm: 820,
    );
    final again = await repo.saveTestTag(
      attemptId: 'tag-1',
      crewId: DemoCrew.crewId,
      workerId: avery,
      windowId: DemoCrew.windowId,
      capturedAt: DateTime.utc(2026, 11, 23, 18, 2),
      assignedPodId: null,
      podId: 'TAG02',
      foreheadTempC: 35.1,
      stripVolumeUl: 20,
      conductivityUsCm: 900,
    );

    expect(saved.saved, isTrue);
    expect(saved.checkIn?.source, CheckInSources.nfcTestTag);
    expect(saved.checkIn?.sweatRateUlMin, isNull);
    expect(again.checkIn?.id, saved.checkIn?.id);
    expect(await repo.checkInsForWorker(avery), hasLength(1));

    await repo.setWorkerPod(workerId: avery, podId: 'TAG01');
    final mismatch = await repo.saveTestTag(
      attemptId: 'tag-wrong',
      crewId: DemoCrew.crewId,
      workerId: avery,
      windowId: DemoCrew.windowId,
      capturedAt: DateTime.utc(2026, 11, 23, 18, 3),
      assignedPodId: 'TAG01',
      podId: 'TAG02',
      foreheadTempC: 35.1,
      stripVolumeUl: 12.5,
      conductivityUsCm: 820,
    );
    expect(mismatch.saved, isFalse);
    expect(mismatch.message, wrongPodMessage);
    expect(await repo.checkInsForWorker(avery), hasLength(1));

    await repo.resetDemoCrew(demoUserId);
    expect(await repo.checkInsForWorker(avery), isEmpty);
    await service.db.close();
    await tempDir.delete(recursive: true);
  });
}
