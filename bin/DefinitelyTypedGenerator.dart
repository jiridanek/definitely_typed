// Copyright (c) 2015, <your name>. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

/// The dts2dart library.
library dts2dart;

import 'package:analyzer/src/generated/element.dart';
import 'package:source_gen/source_gen.dart';
import 'package:path/path.dart' as path;
import 'package:dts2dart/definitely_typed.dart';

import 'dart:io';
import 'dart:convert';
import 'dart:async';
import '../test/lexer_test.dart' as codeblob;

class DefinitelyTypedGenerator extends GeneratorForAnnotation<DefinitelyTyped> {
  final AssociatedFileSet associatedFileSet;

  const DefinitelyTypedGenerator(
      {AssociatedFileSet associatedFileSet: AssociatedFileSet.sameDirectory})
      : this.associatedFileSet = associatedFileSet;

  @override
  generateForAnnotatedElement(Element element, DefinitelyTyped annotation) async {
    if (path.isAbsolute(annotation.path)) {
      throw 'must be relative path to the source file';
    }

    return codeblob.generateCodeFromFile(annotation.path);
  }
}
