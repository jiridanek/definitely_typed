import 'package:unittest/unittest.dart';

import 'dart:async';

import 'package:dts2dart/typescript/generators.dart';
import 'package:dts2dart/typescript/lexer.dart';
import 'package:dts2dart/typescript/parser.dart';

import 'package:dts2dart/typescript/typescript.dart';

List<Token> lexString(String s) {
  var stream = new Stream.fromIterable(s.split('\n'));
  var l = new Lexer(stream);
  var tokens = l.lex(s);
  return tokens;
}

expectLexedString(String s, List<Token> ts) {
  var eof = new Token(TokenType.EOF, '');
  if (ts.isEmpty || ts.last != eof) {
    ts.add(eof);
  }
  expect(lexString(s), ts);
}

parseString(s) {
  var tokens = lexString(s);
  var p = new Parser();
  var ast = p.parse(tokens);
  return ast;
}

expectParsedString(s, e) {
  var treePrinter = new TreePrinterVisitor();
  for (var node in parseString(s)) {
    node.accept(treePrinter);
  }
  expect(treePrinter.w.toString(), e);
}

expectGeneratedString(s, e) {
  var codeGenerator = new CodeGeneratingVisitor();
  for (var node in parseString(s)) {
    node.accept(codeGenerator);
  }
  expect(codeGenerator.w.toString(), e);
}

main() {
  group('toString', () {
    test('Token', () {
      expect(new Token(TokenType.EOF, '').toString(), '<EOF>');
      expect(new Token(TokenType.KEYWORD, 'keyword').toString(),
          '<KEYWORD keyword>');
      expect(new Token(TokenType.IDENTIFIER, 'string').toString(),
          '<IDENTIFIER string>');
    });
  });
  group('lex', () {
    test('eof', () {
      expectLexedString('', [new Token(TokenType.EOF, '')]);
    });

    test('lineComment', () {
      expectLexedString('//', []);
    });
    test('block comment', () {
      expectLexedString('/**block\ncomment*/', []);
    });

    test('whitespace', () {
      expectLexedString(' ', [new Token(TokenType.EOF, '')]);
    });
    test('char whitespace', () {
      expectLexedString('; ', [new Token(TokenType.CHAR, ';')]);
    });

    test('chars', () {
      for (var char in Lexemes.chars) {
        expectLexedString(char, [new Token(TokenType.CHAR, char)]);
      }
    });
    test('keywords', () {
      for (var keyword in Lexemes.keywords) {
        expectLexedString(keyword, [new Token(TokenType.KEYWORD, keyword)]);
      }
    });
    test('identifiers', () {
      var identifier = 'myIdentifier';
      expectLexedString(
          identifier, [new Token(TokenType.IDENTIFIER, identifier)]);

      var validIdentifiers = 'a aa A AA a_a a1'.split(' ');
      for (var identifier in validIdentifiers) {
        expectLexedString(
            identifier, [new Token(TokenType.IDENTIFIER, identifier)]);
      }
    });
    test('operators', () {
      for (var operator in Lexemes.operators) {
        expectLexedString(operator, [new Token(TokenType.OPERATOR, operator)]);
      }
    });
    // let's strip quotes for now; ivy keeps them, wonder why
    test('string literals', () {
      expectLexedString(
          '"a string"', [new Token(TokenType.STRING, 'a string')]);
    });

    test('twoChars', () {
      var t = new Token(TokenType.CHAR, ';');
      expectLexedString('; ;', [t, t]);
    });
    test('twoKeywords', () {
      var t = new Token(TokenType.KEYWORD, 'declare');
      expectLexedString('declare declare', [t, t]);
    });
    test('twoIdentifiers', () {
      var t = new Token(TokenType.IDENTIFIER, 'myIdentifier');
      expectLexedString('myIdentifier myIdentifier', [t, t]);
    });
    test('charIdentifier', () {
      var c = new Token(TokenType.CHAR, ':');
      var i = new Token(TokenType.IDENTIFIER, 'myIdentifier');
      expectLexedString(': myIdentifier', [c, i]);
    });
    test('multiple lines of input', () {
      var t = new Token(TokenType.CHAR, ';');
      expectLexedString(';\n;', [t, t]);
    });
  });

  group('lex stuff', () {
    test('declare var name', () {
      expectLexedString('declare var name: string', [
        new Token(TokenType.KEYWORD, 'declare'),
        new Token(TokenType.KEYWORD, 'var'),
        new Token(TokenType.IDENTIFIER, 'name'),
        new Token(TokenType.CHAR, ':'),
        new Token(TokenType.IDENTIFIER,
            'string'), // FIXME: or should I consider it a KEYWORD?
      ]);
    });
    test('declare var name; declare var status', () {
      expectLexedString('declare var name;\ndeclare var status;', [
        new Token(TokenType.KEYWORD, 'declare'),
        new Token(TokenType.KEYWORD, 'var'),
        new Token(TokenType.IDENTIFIER, 'name'),
        new Token(TokenType.CHAR, ';'),
        new Token(TokenType.KEYWORD, 'declare'),
        new Token(TokenType.KEYWORD, 'var'),
        new Token(TokenType.IDENTIFIER, 'status'),
        new Token(TokenType.CHAR, ';'),
      ]);
    });
  });

  group('parser', () {
    test('parse stuff', () {
      parseString('declare var name');

      expectParsedString('declare var name;', '<declare <var name>>');
      expectParsedString('declare var name;\ndeclare var status;',
          '<declare <var name>><declare <var status>>');
      expectParsedString(
          'declare var name: string;', '<declare <var name: <type string>>>');
      parseString('declare var name: (string);');
      parseString('declare var name, age;');

      parseString('declare var name: string[];');
      parseString('declare var name: EventTarget;');

      parseString('interface Algorithm {\n'
          '    name?: string;\n'
          '}');
      parseString('interface EventListener {'
          '    (evt: Event): void;'
          '}');
      parseString('interface I { f() }');
      parseString('interface I { f(arg: string): void }');
      parseString('interface I { f(arg1, arg2) }');
      parseString('interface I {addEventListener(type: "cached");}');
      parseString('interface I { aEL(l: (ev: E) => any);}');
      parseString('interface I {aEL(uC?: boolean);}');
      parseString(
          'interface I {addEventListener(type: "cached", listener: (ev: Event) => any, useCapture?: boolean): void;}');

      parseString('interface ATL {[index: number]: AudioTrack;}');

      parseString('interface CRC2D {fS: string | CG;}');
      parseString('interface CRC2D {fS: string | CG | CP;}');

      parseString('interface I {f(...optionalParams: any[]): void;}');

      parseString('declare var v: {};');
      parseString('declare var v: { new(): void };');

      parseString('interface I {f(x: NodeListOf<Element>);}');

      parseString('declare var ANGLE_instanced_arrays: {\n'
          '    prototype: ANGLE_instanced_arrays;\n'
          '//    new(): ANGLE_instanced_arrays;\n'
          '    VERTEX_ATTRIB_ARRAY_DIVISOR_ANGLE: number;\n'
          '};');

      parseString('interface AriaRequestEventInit extends EventInit {}');
      parseString('interface A extends B, C {}');
      parseString('interface A<B extends C> extends D {}');

      parseString('interface A { declare: string; }');

      parseString('declare type A = B;');

      parseString('declare function f();');
    });
  });

  group('generate stuff', () {
    test('generate stuff', () {
      expectGeneratedString('declare var name;', '@JS()external get name;\n');
      expectGeneratedString('declare var name;\ndeclare var status;',
          '@JS()external get name;\n@JS()external get status;\n');
      expectGeneratedString(
          'declare var name: string;', '@JS()external String get name;\n');
    });
    test('interface declaration', () {
      expectGeneratedString('interface I {}', '@JS()class I{}');
      expectGeneratedString('interface I {a}',
          '@JS()class I{external get a;external factory I({a});}');

      expectGeneratedString('interface I {a: string}',
          '@JS()class I{external String get a;external factory I({String a});}');
      expectGeneratedString('interface I {a: string[]}',
          '@JS()class I{external List< String> get a;external factory I({List< String> a});}');
      expectGeneratedString('interface I {f: () => any}',
          '@JS()class I{external get f;external factory I({dynamic f()});}');

      //expectGeneratedString('interface A extends B {}', '@JS()class I extends B{}');
      expectGeneratedString(
          'interface I {getSegmentsAtEvent: (event: Event) => {}[];}',
          '@JS()class I{external get getSegmentsAtEvent;external factory I({ List getSegmentsAtEvent(Event event)});}');
      expectGeneratedString(
          'interface I {addData: (valuesArray: CircularChartData, index?: number) => void;}',
          '@JS()class I{external get addData;external factory I({void addData(CircularChartData valuesArray, num  index)});}');

      // broken tests ///

      expectGeneratedString('interface i {segments: Array<CircularChartData>;}',
          '@JS()class i{external List get segments;external factory i({ List });}');
      expectGeneratedString('interface I {f()}', '@JS()class I{}');
      expectGeneratedString(
          'declare var Chart: {'
          '    new (context: CanvasRenderingContext2D): Chart;'
          '    defaults: {'
          '        global: ChartSettings;'
          '    }'
          '};',
          '@JS()external get Chart;\n');
    });
  });

  group('from dom.d.ts', () {
    skip_test('can lex n lines', () {
      var n = -1;
      var tokens = lexFromFile('dom.generated.d.ts_de52865', n);
    });
    skip_test('can parse n lines', () {
      var n =
          -1; // 57 61 179 183 190 196 224 254 270 427 441 1067 1145 1237 3029 3227 12514 12549 12728
      var tree = parseFromFile('dom.generated.d.ts_de52865', n);
    });
    test('can put first n lines through the whole process', () {
      var n = 5;
      var code = generateFromFile('dom.generated.d.ts_de52865', n);
    });
  });
  group('from chart.d.ts', () {
    test('generate', () {
      var n = -1; // 22 27 77 132 190 200
      var code = generateFromFile('../lib/chartjs/chart.d.ts_24253c8', n);
    });
  });
}
