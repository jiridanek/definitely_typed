import 'dart:async';
import 'dart:io';

import 'package:dts2dart/typescript/lexer.dart';
import 'package:dts2dart/typescript/parser.dart';
import 'package:dts2dart/typescript/generators.dart';

class Lexemes {
  // https://github.com/Microsoft/TypeScript/issues/2536
  static final chars = '<>()[]{}=|&?:;,.'.split('');
  static final operators = '=> ...'.split(' ');

  //TODO: not complete

  // contextual keywords: any number boolean string symbol void //TODO: not complete // lets treat them as identifiers for now
  static final keywords = 'new extends private public protected function interface '
      'declare var let const function class constructor static namespace export module' //section A.11
      .split(' ');
}

List<Token> lexFromFile(String path, int nlines) {
  var f = new File(path);
  var s = f.readAsLinesSync();
  if (nlines != -1) {
    s = s.take(nlines);
  }
  var ss = new Stream.fromIterable(s);
  var l = new Lexer(ss);
  var ts = l.lex(s.join('\n'));
  return ts;
}

parseFromFile(String path, int nlines) {
  var ls = lexFromFile(path, nlines);
  var p = new Parser();
  var ps = p.parse(ls);
  return ps;
}

String generateFromFile(String path, [int nlines = -1]) {
  var ps = parseFromFile(path, nlines);
  var v = new CodeGeneratingVisitor();
  for (var n in ps) {
    n.accept(v);
  }
  return v.w.toString();
}
