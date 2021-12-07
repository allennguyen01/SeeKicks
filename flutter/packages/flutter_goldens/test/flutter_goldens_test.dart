// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:async';
import 'dart:core';
import 'dart:io';
import 'dart:typed_data';

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_goldens/flutter_goldens.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:platform/platform.dart';
import 'package:process/process.dart';

import 'json_templates.dart';

const String _kFlutterRoot = '/flutter';

// 1x1 transparent pixel
const List<int> _kTestPngBytes =
<int>[137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82, 0, 0, 0,
  1, 0, 0, 0, 1, 8, 6, 0, 0, 0, 31, 21, 196, 137, 0, 0, 0, 11, 73, 68, 65, 84,
  120, 1, 99, 97, 0, 2, 0, 0, 25, 0, 5, 144, 240, 54, 245, 0, 0, 0, 0, 73, 69,
  78, 68, 174, 66, 96, 130];

// 1x1 colored pixel
const List<int> _kFailPngBytes =
<int>[137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82, 0, 0, 0,
  1, 0, 0, 0, 1, 8, 6, 0, 0, 0, 31, 21, 196, 137, 0, 0, 0, 13, 73, 68, 65, 84,
  120, 1, 99, 249, 207, 240, 255, 63, 0, 7, 18, 3, 2, 164, 147, 160, 197, 0,
  0, 0, 0, 73, 69, 78, 68, 174, 66, 96, 130];

Future<void> testWithOutput(String name, Future<void> body(), String expectedOutput) async {
  test(name, () async {
    final StringBuffer output = StringBuffer();
    void _recordPrint(Zone self, ZoneDelegate parent, Zone zone, String line) {
      output.write(line);
    }
    await runZoned<Future<void>>(body, zoneSpecification: ZoneSpecification(print: _recordPrint));
    expect(output.toString(), expectedOutput);
  });
}

void main() {
  MemoryFileSystem fs;
  FakePlatform platform;
  MockProcessManager process;
  MockHttpClient mockHttpClient;

  setUp(() {
    fs = MemoryFileSystem();
    platform = FakePlatform(
      environment: <String, String>{'FLUTTER_ROOT': _kFlutterRoot},
      operatingSystem: 'macos'
    );
    process = MockProcessManager();
    mockHttpClient = MockHttpClient();
    fs.directory(_kFlutterRoot).createSync(recursive: true);
  });

  group('SkiaGoldClient', () {
    SkiaGoldClient skiaClient;
    Directory workDirectory;

    setUp(() {
      workDirectory = fs.directory('/workDirectory')
        ..createSync(recursive: true);
      skiaClient = SkiaGoldClient(
        workDirectory,
        fs: fs,
        process: process,
        platform: platform,
        httpClient: mockHttpClient,
      );
    });

    test('auth performs minimal work if already authorized', () async {
      final File authFile = fs.file('/workDirectory/temp/auth_opt.json')
        ..createSync(recursive: true);
      authFile.writeAsStringSync(authTemplate());
      when(process.run(any))
        .thenAnswer((_) => Future<ProcessResult>
        .value(ProcessResult(123, 0, '', '')));
      await skiaClient.auth();

      verifyNever(process.run(
        captureAny,
        workingDirectory: captureAnyNamed('workingDirectory'),
      ));
    });

    test('gsutil is checked when authorization file is present', () async {
      final File authFile = fs.file('/workDirectory/temp/auth_opt.json')
        ..createSync(recursive: true);
      authFile.writeAsStringSync(authTemplate(gsutil: true));
      expect(
        await skiaClient.clientIsAuthorized(),
        isFalse,
      );
    });

    test('throws for error state from auth', () async {
      platform = FakePlatform(
        environment: <String, String>{
          'FLUTTER_ROOT': _kFlutterRoot,
          'GOLD_SERVICE_ACCOUNT' : 'Service Account',
          'GOLDCTL' : 'goldctl',
        },
        operatingSystem: 'macos'
      );

      skiaClient = SkiaGoldClient(
        workDirectory,
        fs: fs,
        process: process,
        platform: platform,
        httpClient: mockHttpClient,
      );

      when(process.run(any))
        .thenAnswer((_) => Future<ProcessResult>
        .value(ProcessResult(123, 1, 'fail', 'fail')));
      final Future<void> test = skiaClient.auth();

      expect(
        test,
        throwsException,
      );
    });

    test('throws for error state from init', () {
      platform = FakePlatform(
        environment: <String, String>{
          'FLUTTER_ROOT': _kFlutterRoot,
          'GOLDCTL' : 'goldctl',
        },
        operatingSystem: 'macos'
      );

      skiaClient = SkiaGoldClient(
        workDirectory,
        fs: fs,
        process: process,
        platform: platform,
        httpClient: mockHttpClient,
      );

      when(process.run(
        <String>['git', 'rev-parse', 'HEAD'],
        workingDirectory: '/flutter',
      )).thenAnswer((_) => Future<ProcessResult>
        .value(ProcessResult(12345678, 0, '12345678', '')));

      when(process.run(
        <String>[
          'goldctl',
          'imgtest', 'init',
          '--instance', 'flutter',
          '--work-dir', '/workDirectory/temp',
          '--commit', '12345678',
          '--keys-file', '/workDirectory/keys.json',
          '--failure-file', '/workDirectory/failures.json',
          '--passfail',
        ],
      )).thenAnswer((_) => Future<ProcessResult>
        .value(ProcessResult(123, 1, 'fail', 'fail')));
      final Future<void> test =  skiaClient.imgtestInit();

      expect(
        test,
        throwsException,
      );
    });

    test('correctly inits tryjob for luci', () async {
      platform = FakePlatform(
        environment: <String, String>{
          'FLUTTER_ROOT': _kFlutterRoot,
          'GOLDCTL' : 'goldctl',
          'SWARMING_TASK_ID' : '4ae997b50dfd4d11',
          'LOGDOG_STREAM_PREFIX' : 'buildbucket/cr-buildbucket.appspot.com/8885996262141582672',
          'GOLD_TRYJOB' : 'refs/pull/49815/head',
        },
        operatingSystem: 'macos'
      );

      skiaClient = SkiaGoldClient(
        workDirectory,
        fs: fs,
        process: process,
        platform: platform,
        httpClient: mockHttpClient,
      );

      final List<String> ciArguments = skiaClient.getCIArguments();

      expect(
        ciArguments,
        equals(
          <String>[
            '--changelist', '49815',
            '--cis', 'buildbucket',
            '--jobid', '8885996262141582672',
          ],
        ),
      );
    });

    test('Creates traceID correctly', () {
      String traceID;
      platform = FakePlatform(
        environment: <String, String>{
          'FLUTTER_ROOT': _kFlutterRoot,
          'GOLDCTL' : 'goldctl',
          'SWARMING_TASK_ID' : '4ae997b50dfd4d11',
          'LOGDOG_STREAM_PREFIX' : 'buildbucket/cr-buildbucket.appspot.com/8885996262141582672',
          'GOLD_TRYJOB' : 'refs/pull/49815/head',
        },
        operatingSystem: 'linux'
      );

      skiaClient = SkiaGoldClient(
        workDirectory,
        fs: fs,
        process: process,
        platform: platform,
        httpClient: mockHttpClient,
      );

      traceID = skiaClient.getTraceID('flutter.golden.1');

      expect(
        traceID,
        equals(',CI=luci,Platform=linux,name=flutter.golden.1,source_type=flutter,'),
      );

      // Browser
      platform = FakePlatform(
        environment: <String, String>{
          'FLUTTER_ROOT': _kFlutterRoot,
          'GOLDCTL' : 'goldctl',
          'SWARMING_TASK_ID' : '4ae997b50dfd4d11',
          'LOGDOG_STREAM_PREFIX' : 'buildbucket/cr-buildbucket.appspot.com/8885996262141582672',
          'GOLD_TRYJOB' : 'refs/pull/49815/head',
          'FLUTTER_TEST_BROWSER' : 'chrome',
        },
        operatingSystem: 'linux'
      );

      skiaClient = SkiaGoldClient(
        workDirectory,
        fs: fs,
        process: process,
        platform: platform,
        httpClient: mockHttpClient,
      );

      traceID = skiaClient.getTraceID('flutter.golden.1');

      expect(
        traceID,
        equals(',Browser=chrome,CI=luci,Platform=linux,name=flutter.golden.1,source_type=flutter,'),
      );

      // Locally - should defer to luci traceID
      platform = FakePlatform(
        environment: <String, String>{
          'FLUTTER_ROOT': _kFlutterRoot,
        },
        operatingSystem: 'macos'
      );

      skiaClient = SkiaGoldClient(
        workDirectory,
        fs: fs,
        process: process,
        platform: platform,
        httpClient: mockHttpClient,
      );

      traceID = skiaClient.getTraceID('flutter.golden.1');

      expect(
        traceID,
        equals(',CI=luci,Platform=macos,name=flutter.golden.1,source_type=flutter,'),
      );
    });

    group('Request Handling', () {
      String expectation;

      setUp(() {
        expectation = '55109a4bed52acc780530f7a9aeff6c0';
      });

      test('image bytes are processed properly', () async {
        final Uri imageUrl = Uri.parse(
          'https://flutter-gold.skia.org/img/images/$expectation.png'
        );
        final MockHttpClientRequest mockImageRequest = MockHttpClientRequest();
        final MockHttpImageResponse mockImageResponse = MockHttpImageResponse(
          imageResponseTemplate()
        );
        when(mockHttpClient.getUrl(imageUrl))
          .thenAnswer((_) => Future<MockHttpClientRequest>.value(mockImageRequest));
        when(mockImageRequest.close())
          .thenAnswer((_) => Future<MockHttpImageResponse>.value(mockImageResponse));

        final List<int> masterBytes = await skiaClient.getImageBytes(expectation);

        expect(masterBytes, equals(_kTestPngBytes));
      });
    });
  });

  group('FlutterGoldenFileComparator', () {
    FlutterPostSubmitFileComparator comparator;

    setUp(() {
      final Directory basedir = fs.directory('flutter/test/library/')
        ..createSync(recursive: true);
      comparator = FlutterPostSubmitFileComparator(
        basedir.uri,
        MockSkiaGoldClient(),
        fs: fs,
        platform: platform,
      );
    });

    test('calculates the basedir correctly from defaultComparator for local testing', () async {
      final MockLocalFileComparator defaultComparator = MockLocalFileComparator();
      final Directory flutterRoot = fs.directory(platform.environment['FLUTTER_ROOT'])
        ..createSync(recursive: true);
      when(defaultComparator.basedir).thenReturn(flutterRoot.childDirectory('baz').uri);

      final Directory basedir = FlutterGoldenFileComparator.getBaseDirectory(
        defaultComparator,
        platform,
        local: true,
      );
      expect(
        basedir.uri,
        fs.directory('/flutter/bin/cache/pkg/skia_goldens/baz').uri,
      );
    });

    test('ignores version number', () {
      final Uri key = comparator.getTestUri(Uri.parse('foo.png'), 1);
      expect(key, Uri.parse('foo.png'));
    });

    group('Post-Submit', () {
      final MockSkiaGoldClient mockSkiaClient = MockSkiaGoldClient();

      setUp(() {
        final Directory basedir = fs.directory('flutter/test/library/')
          ..createSync(recursive: true);
        comparator = FlutterPostSubmitFileComparator(
          basedir.uri,
          mockSkiaClient,
          fs: fs,
          platform: platform,
        );
      });

      group('correctly determines testing environment', () {
        test('returns true for configured Luci', () {
          platform = FakePlatform(
            environment: <String, String>{
              'FLUTTER_ROOT': _kFlutterRoot,
              'SWARMING_TASK_ID' : '12345678990',
              'GOLDCTL' : 'goldctl',
            },
            operatingSystem: 'macos'
          );
          expect(
            FlutterPostSubmitFileComparator.isAvailableForEnvironment(platform),
            isTrue,
          );
        });

        test('returns false - GOLDCTL not present', () {
          platform = FakePlatform(
            environment: <String, String>{
              'FLUTTER_ROOT': _kFlutterRoot,
              'SWARMING_TASK_ID' : '12345678990',
            },
            operatingSystem: 'macos'
          );
          expect(
            FlutterPostSubmitFileComparator.isAvailableForEnvironment(platform),
            isFalse,
          );
        });

        test('returns false - GOLD_TRYJOB active', () {
          platform = FakePlatform(
            environment: <String, String>{
              'FLUTTER_ROOT': _kFlutterRoot,
              'SWARMING_TASK_ID' : '12345678990',
              'GOLDCTL' : 'goldctl',
              'GOLD_TRYJOB' : 'git/ref/12345/head'
            },
            operatingSystem: 'macos'
          );
          expect(
            FlutterPostSubmitFileComparator.isAvailableForEnvironment(platform),
            isFalse,
          );
        });

        test('returns false - on Cirrus', () {
          platform = FakePlatform(
            environment: <String, String>{
              'FLUTTER_ROOT': _kFlutterRoot,
              'CIRRUS_CI': 'true',
              'CIRRUS_PR': '',
              'CIRRUS_BRANCH': 'master',
              'GOLD_SERVICE_ACCOUNT': 'service account...'
            },
            operatingSystem: 'macos'
          );
          expect(
            FlutterPostSubmitFileComparator.isAvailableForEnvironment(platform),
            isFalse,
          );
        });
      });
    });

    group('Pre-Submit', () {
      group('correctly determines testing environment', () {
        test('returns true for Luci', () {
          platform = FakePlatform(
            environment: <String, String>{
              'FLUTTER_ROOT': _kFlutterRoot,
              'SWARMING_TASK_ID' : '12345678990',
              'GOLDCTL' : 'goldctl',
              'GOLD_TRYJOB' : 'git/ref/12345/head'
            },
            operatingSystem: 'macos'
          );
          expect(
            FlutterPreSubmitFileComparator.isAvailableForEnvironment(platform),
            isTrue,
          );
        });

        test('returns false - not on Luci', () {
          platform = FakePlatform(
            environment: <String, String>{
              'FLUTTER_ROOT': _kFlutterRoot,
            },
            operatingSystem: 'macos'
          );
          expect(
            FlutterPreSubmitFileComparator.isAvailableForEnvironment(platform),
            isFalse,
          );
        });

        test('returns false - GOLDCTL missing', () {
          platform = FakePlatform(
            environment: <String, String>{
              'FLUTTER_ROOT': _kFlutterRoot,
              'SWARMING_TASK_ID' : '12345678990',
              'GOLD_TRYJOB' : 'git/ref/12345/head'
            },
            operatingSystem: 'macos'
          );
          expect(
            FlutterPreSubmitFileComparator.isAvailableForEnvironment(platform),
            isFalse,
          );
        });

        test('returns false - GOLD_TRYJOB missing', () {
          platform = FakePlatform(
            environment: <String, String>{
              'FLUTTER_ROOT': _kFlutterRoot,
              'SWARMING_TASK_ID' : '12345678990',
              'GOLDCTL' : 'goldctl',
            },
            operatingSystem: 'macos'
          );
          expect(
            FlutterPreSubmitFileComparator.isAvailableForEnvironment(platform),
            isFalse,
          );
        });

        test('returns false - on Cirrus', () {
          platform = FakePlatform(
            environment: <String, String>{
              'FLUTTER_ROOT': _kFlutterRoot,
              'CIRRUS_CI': 'true',
              'CIRRUS_PR': '',
              'CIRRUS_BRANCH': 'master',
              'GOLD_SERVICE_ACCOUNT': 'service account...'
            },
            operatingSystem: 'macos'
          );
          expect(
            FlutterPostSubmitFileComparator.isAvailableForEnvironment(platform),
            isFalse,
          );
        });
      });
    });

    group('Skipping', () {
      group('correctly determines testing environment', () {
        test('returns true on Cirrus builds', () {
          platform = FakePlatform(
            environment: <String, String>{
              'FLUTTER_ROOT': _kFlutterRoot,
              'CIRRUS_CI' : 'yep',
            },
            operatingSystem: 'macos'
          );
          expect(
            FlutterSkippingFileComparator.isAvailableForEnvironment(platform),
            isTrue,
          );
        });

        test('returns true on irrelevant LUCI builds', () {
          platform = FakePlatform(
            environment: <String, String>{
              'FLUTTER_ROOT': _kFlutterRoot,
              'SWARMING_TASK_ID' : '1234567890',
            },
            operatingSystem: 'macos'
          );
          expect(
            FlutterSkippingFileComparator.isAvailableForEnvironment(platform),
            isTrue,
          );
        });

        test('returns false - no CI', () {
          platform = FakePlatform(
            environment: <String, String>{
              'FLUTTER_ROOT': _kFlutterRoot,
            },
            operatingSystem: 'macos'
          );
          expect(
            FlutterSkippingFileComparator.isAvailableForEnvironment(
              platform),
            isFalse,
          );
        });
      });
    });

    group('Local', () {
      FlutterLocalFileComparator comparator;
      final MockSkiaGoldClient mockSkiaClient = MockSkiaGoldClient();

      setUp(() async {
        final Directory basedir = fs.directory('flutter/test/library/')
          ..createSync(recursive: true);
        comparator = FlutterLocalFileComparator(
          basedir.uri,
          mockSkiaClient,
          fs: fs,
          platform: FakePlatform(
            environment: <String, String>{'FLUTTER_ROOT': _kFlutterRoot},
            operatingSystem: 'macos'
          ),
        );

        when(mockSkiaClient.getExpectationForTest('flutter.golden_test.1'))
          .thenAnswer((_) => Future<String>.value('55109a4bed52acc780530f7a9aeff6c0'));
        when(mockSkiaClient.getExpectationForTest('flutter.new_golden_test.2'))
          .thenAnswer((_) => Future<String>.value(''));
        when(mockSkiaClient.getImageBytes('55109a4bed52acc780530f7a9aeff6c0'))
          .thenAnswer((_) => Future<List<int>>.value(_kTestPngBytes));
        when(mockSkiaClient.cleanTestName('library.flutter.golden_test.1.png'))
          .thenReturn('flutter.golden_test.1');
      });

      test('passes when bytes match', () async {
        expect(
          await comparator.compare(
            Uint8List.fromList(_kTestPngBytes),
            Uri.parse('flutter.golden_test.1.png'),
          ),
          isTrue,
        );
      });

      testWithOutput('passes non-existent baseline for new test, null expectation', () async {
        expect(
          await comparator.compare(
            Uint8List.fromList(_kFailPngBytes),
            Uri.parse('flutter.new_golden_test.1'),
          ),
          isTrue,
        );
      }, 'No expectations provided by Skia Gold for test: library.flutter.new_golden_test.1. '
         'This may be a new test. If this is an unexpected result, check https://flutter-gold.skia.org.\n'
         'Validate image output found at flutter/test/library/'
      );

      testWithOutput('passes non-existent baseline for new test, empty expectation', () async {
        expect(
          await comparator.compare(
            Uint8List.fromList(_kFailPngBytes),
            Uri.parse('flutter.new_golden_test.2'),
          ),
          isTrue,
        );
      }, 'No expectations provided by Skia Gold for test: library.flutter.new_golden_test.2. '
        'This may be a new test. If this is an unexpected result, check https://flutter-gold.skia.org.\n'
        'Validate image output found at flutter/test/library/'
      );

      test('compare properly awaits validation & output before failing.', () async {
        final Completer<bool> completer = Completer<bool>();
        final Future<bool> result = comparator.compare(
          Uint8List.fromList(_kFailPngBytes),
          Uri.parse('flutter.golden_test.1.png'),
        );
        bool shouldThrow = true;
        result.then((_) {
          if (shouldThrow)
            fail('Compare completed before validation completed!');
        });
        await Future<void>.value();
        shouldThrow = false;
        completer.complete(Future<bool>.value(false));
      });

      test('returns FlutterSkippingGoldenFileComparator when network connection is unavailable', () async {
        final MockDirectory mockDirectory = MockDirectory();
        when(mockDirectory.existsSync()).thenReturn(true);
        when(mockDirectory.uri).thenReturn(Uri.parse('/flutter'));

        when(mockSkiaClient.getExpectationForTest(any))
          .thenAnswer((_) => throw const OSError("Can't reach Gold"));
        FlutterGoldenFileComparator comparator = await FlutterLocalFileComparator.fromDefaultComparator(
          platform,
          goldens: mockSkiaClient,
          baseDirectory: mockDirectory,
        );
        expect(comparator.runtimeType, FlutterSkippingFileComparator);

        when(mockSkiaClient.getExpectationForTest(any))
          .thenAnswer((_) => throw const SocketException("Can't reach Gold"));
        comparator = await FlutterLocalFileComparator.fromDefaultComparator(
          platform,
          goldens: mockSkiaClient,
          baseDirectory: mockDirectory,
        );
        expect(comparator.runtimeType, FlutterSkippingFileComparator);
      });
    });
  });
}

class MockProcessManager extends Mock implements ProcessManager {}

class MockSkiaGoldClient extends Mock implements SkiaGoldClient {}

class MockLocalFileComparator extends Mock implements LocalFileComparator {}

class MockDirectory extends Mock implements Directory {}

class MockHttpClient extends Mock implements HttpClient {}

class MockHttpClientRequest extends Mock implements HttpClientRequest {}

class MockHttpClientResponse extends Mock implements HttpClientResponse {
  MockHttpClientResponse(this.response);

  final List<int> response;

  @override
  StreamSubscription<List<int>> listen(
    void onData(List<int> event), {
      Function onError,
      void onDone(),
      bool cancelOnError,
    }) {
    return Stream<List<int>>.fromFuture(Future<List<int>>.value(response))
      .listen(onData, onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }
}

class MockHttpImageResponse extends Mock implements HttpClientResponse {
  MockHttpImageResponse(this.response);

  final List<List<int>> response;

  @override
  Future<void> forEach(void action(List<int> element)) async {
    response.forEach(action);
  }
}
