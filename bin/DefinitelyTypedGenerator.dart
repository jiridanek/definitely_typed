// Copyright (c) 2015, <your name>. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

/// The dts2dart library.
library dts2dart;

import '../packages/analyzer/src/generated/element.dart';
import '../packages/source_gen/source_gen.dart';
import '../packages/path/path.dart' as path;
import '../lib/definitely_typed.dart';

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
  generateForAnnotatedElement(Element element, DefinitelyTyped annotation) {
    if (path.isAbsolute(annotation.path)) {
      throw 'must be relative path to the source file';
    }

    var f = new File(annotation.path);
    var s = f.readAsLinesSync(encoding: UTF8);
    var ss = new Stream<String>.fromIterable(s);
    var l = new codeblob.Lexer(ss);
    var ls = l.lex(s.join(' '));
    var p = new codeblob.Parser();
    var ps = p.parse(ls);
    var v = new codeblob.CodeGeneratingVisitor();
    ps.accept(v);
    return v.w.toString();
  }
}
