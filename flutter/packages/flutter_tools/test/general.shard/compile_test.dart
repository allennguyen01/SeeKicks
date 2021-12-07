// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/compile.dart';

import '../src/common.dart';

void main() {
  testWithoutContext('StdoutHandler can produce output message', () async {
    final StdoutHandler stdoutHandler = StdoutHandler(logger: BufferLogger.test());
    stdoutHandler.handler('result 12345');
    expect(stdoutHandler.boundaryKey, '12345');
    stdoutHandler.handler('12345');
    stdoutHandler.handler('12345 message 0');
    final CompilerOutput output = await stdoutHandler.compilerOutput.future;
    expect(output.errorCount, 0);
    expect(output.outputFilename, 'message');
  });

  testWithoutContext('TargetModel values', () {
    expect(TargetModel('vm'), TargetModel.vm);
    expect(TargetModel.vm.toString(), 'vm');

    expect(TargetModel('flutter'), TargetModel.flutter);
    expect(TargetModel.flutter.toString(), 'flutter');

    expect(TargetModel('flutter_runner'), TargetModel.flutterRunner);
    expect(TargetModel.flutterRunner.toString(), 'flutter_runner');

    expect(TargetModel('dartdevc'), TargetModel.dartdevc);
    expect(TargetModel.dartdevc.toString(), 'dartdevc');

    expect(() => TargetModel('foobar'), throwsAssertionError);
  });

  testWithoutContext('toMultiRootPath maps different URIs', () async {
    expect(toMultiRootPath(Uri.parse('file:///a/b/c'), 'scheme', <String>['/a/b'], false), 'scheme:///c');
    expect(toMultiRootPath(Uri.parse('file:///d/b/c'), 'scheme', <String>['/a/b'], false), 'file:///d/b/c');
    expect(toMultiRootPath(Uri.parse('file:///a/b/c'), 'scheme', <String>['/d/b', '/a/b'], false), 'scheme:///c');
    expect(toMultiRootPath(Uri.parse('file:///a/b/c'), null, <String>[], false), 'file:///a/b/c');
    expect(toMultiRootPath(Uri.parse('org-dartlang-app:///a/b/c'), null, <String>[], false), 'org-dartlang-app:///a/b/c');
    expect(toMultiRootPath(Uri.parse('org-dartlang-app:///a/b/c'), 'scheme', <String>['/d/b'], false), 'org-dartlang-app:///a/b/c');
  });

  testWithoutContext('buildModeOptions removes matching product define', () {
    expect(buildModeOptions(BuildMode.debug, <String>['dart.vm.product=true']), <String>[
      '-Ddart.vm.profile=false',
      '--enable-asserts',
    ]);
  });
}
