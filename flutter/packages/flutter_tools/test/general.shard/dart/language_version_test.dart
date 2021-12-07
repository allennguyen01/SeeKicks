// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/convert.dart';
import 'package:flutter_tools/src/dart/language_version.dart';
import 'package:package_config/package_config.dart';
import 'package:test/fake.dart';

import '../../src/common.dart';

void main() {
  testWithoutContext('detects language version in comment', () {
    final FileSystem fileSystem = MemoryFileSystem.test();
    final File file = fileSystem.file('example.dart')
      ..writeAsStringSync('''
// Some license

// @dart = 2.9
''');

    expect(determineLanguageVersion(file, null), LanguageVersion(2, 9));
  });

  testWithoutContext('detects language version in comment without spacing', () {
    final FileSystem fileSystem = MemoryFileSystem.test();
    final File file = fileSystem.file('example.dart')
      ..writeAsStringSync('''
// Some license

// @dart=2.9
''');

    expect(determineLanguageVersion(file, null),  LanguageVersion(2, 9));
  });

  testWithoutContext('detects language version in comment with more numbers', () {
    final FileSystem fileSystem = MemoryFileSystem.test();
    final File file = fileSystem.file('example.dart')
      ..writeAsStringSync('''
// Some license

// @dart=2.12
''');

    expect(determineLanguageVersion(file, null), LanguageVersion(2, 12));
  });

  testWithoutContext('does not detect invalid language version', () {
    final FileSystem fileSystem = MemoryFileSystem.test();
    final File file = fileSystem.file('example.dart')
      ..writeAsStringSync('''
// Some license

// @dart
''');

    expect(determineLanguageVersion(file, null), LanguageVersion(2, 12));
  });

  testWithoutContext('detects language version with leading whitespace', () {
    final FileSystem fileSystem = MemoryFileSystem.test();
    final File file = fileSystem.file('example.dart')
      ..writeAsStringSync('''
// Some license

    // @dart = 2.9
''');

    expect(determineLanguageVersion(file, null), LanguageVersion(2, 9));
  });

  testWithoutContext('detects language version with tabs', () {
    final FileSystem fileSystem = MemoryFileSystem.test();
    final File file = fileSystem.file('example.dart')
      ..writeAsStringSync('''
// Some license

//\t@dart = 2.9
''');

    expect(determineLanguageVersion(file, null), LanguageVersion(2, 9));
  });

  testWithoutContext('detects language version with tons of whitespace', () {
    final FileSystem fileSystem = MemoryFileSystem.test();
    final File file = fileSystem.file('example.dart')
      ..writeAsStringSync('''
// Some license

//        @dart       = 2.23
''');

    expect(determineLanguageVersion(file, null), LanguageVersion(2, 23));
  });

  testWithoutContext('does not detect language version in dartdoc', () {
    final FileSystem fileSystem = MemoryFileSystem.test();
    final File file = fileSystem.file('example.dart')
      ..writeAsStringSync('''
// Some license

/// @dart = 2.9
''');

    expect(determineLanguageVersion(file, null), LanguageVersion(2, 12));
  });

  testWithoutContext('does not detect language version in block comment', () {
    final FileSystem fileSystem = MemoryFileSystem.test();
    final File file = fileSystem.file('example.dart')
      ..writeAsStringSync('''
// Some license

/*
// @dart = 2.9
*/
''');

    expect(determineLanguageVersion(file, null), LanguageVersion(2, 12));
  });

  testWithoutContext('does not detect language version in nested block comment', () {
    final FileSystem fileSystem = MemoryFileSystem.test();
    final File file = fileSystem.file('example.dart')
      ..writeAsStringSync('''
// Some license

/*
/*
// @dart = 2.9
*/
*/
''');

    expect(determineLanguageVersion(file, null), LanguageVersion(2, 12));
  });

  testWithoutContext('detects language version after nested block comment', () {
    final FileSystem fileSystem = MemoryFileSystem.test();
    final File file = fileSystem.file('example.dart')
      ..writeAsStringSync('''
// Some license

/* /*
*/
*/
// @dart = 2.9
''');

    expect(determineLanguageVersion(file, null), LanguageVersion(2, 9));
  });

  testWithoutContext('does not crash with unbalanced opening block comments', () {
    final FileSystem fileSystem = MemoryFileSystem.test();
    final File file = fileSystem.file('example.dart')
      ..writeAsStringSync('''
// Some license

/*
/*
*/
// @dart = 2.9
''');

    expect(determineLanguageVersion(file, null), LanguageVersion(2, 12));
  });

  testWithoutContext('does not crash with unbalanced closing block comments', () {
    final FileSystem fileSystem = MemoryFileSystem.test();
    final File file = fileSystem.file('example.dart')
      ..writeAsStringSync('''
// Some license

/*
*/
*/
// @dart = 2.9
''');

    expect(determineLanguageVersion(file, null), LanguageVersion(2, 12));
  });

  testWithoutContext('does not detect language version in single line block comment', () {
    final FileSystem fileSystem = MemoryFileSystem.test();
    final File file = fileSystem.file('example.dart')
      ..writeAsStringSync('''
// Some license

/* // @dart = 2.9 */
''');

    expect(determineLanguageVersion(file, null), LanguageVersion(2, 12));
  });

  testWithoutContext('does not detect language version after import declaration', () {
    final FileSystem fileSystem = MemoryFileSystem.test();
    final File file = fileSystem.file('example.dart')
      ..writeAsStringSync('''
// Some license

import 'dart:ui' as ui;

// @dart = 2.9
''');

    expect(determineLanguageVersion(file, null), LanguageVersion(2, 12));
  });

  testWithoutContext('does not detect language version after part declaration', () {
    final FileSystem fileSystem = MemoryFileSystem.test();
    final File file = fileSystem.file('example.dart')
      ..writeAsStringSync('''
// Some license

part of 'foo.dart';

// @dart = 2.9
''');

    expect(determineLanguageVersion(file, null), LanguageVersion(2, 12));
  });

  testWithoutContext('does not detect language version after library declaration', () {
    final FileSystem fileSystem = MemoryFileSystem.test();
    final File file = fileSystem.file('example.dart')
      ..writeAsStringSync('''
// Some license

library funstuff;

// @dart = 2.9
''');

    expect(determineLanguageVersion(file, null), LanguageVersion(2, 12));
  });

  testWithoutContext('looks up language version from package if not found in file', () {
    final FileSystem fileSystem = MemoryFileSystem.test();
    final File file = fileSystem.file('example.dart')
      ..writeAsStringSync('''
// Some license
''');
    final Package package = Package(
      'foo',
      Uri.parse('file://foo/'),
      languageVersion: LanguageVersion(2, 7),
    );

    expect(determineLanguageVersion(file, package), LanguageVersion(2, 7));
  });

  testWithoutContext('defaults to null safe version if package lookup returns null', () {
    final FileSystem fileSystem = MemoryFileSystem.test();
    final File file = fileSystem.file('example.dart')
      ..writeAsStringSync('''
// Some license
''');
    final Package package = Package(
      'foo',
      Uri.parse('file://foo/'),
      languageVersion: null,
    );

    expect(determineLanguageVersion(file, package), LanguageVersion(2, 12));
  });

  testWithoutContext('Returns null safe error if reading the file throws a FileSystemException', () {
    final Package package = Package(
      'foo',
      Uri.parse('file://foo/'),
      languageVersion: LanguageVersion(2, 7),
    );

    expect(determineLanguageVersion(FakeFile(), package), nullSafeVersion);
  });
}

class FakeFile extends Fake implements File {
  @override
  List<String> readAsLinesSync({ Encoding encoding = utf8ForTesting }) {
    throw const FileSystemException();
  }
}
