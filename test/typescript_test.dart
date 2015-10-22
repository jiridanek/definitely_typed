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

      parseString('declare var v: {};');
      parseString('declare var v: { new(): void };');

      parseString('declare var ANGLE_instanced_arrays: {\n'
          '    prototype: ANGLE_instanced_arrays;\n'
          '//    new(): ANGLE_instanced_arrays;\n'
          '    VERTEX_ATTRIB_ARRAY_DIVISOR_ANGLE: number;\n'
          '};');

      parseString('interface AriaRequestEventInit extends EventInit {}');
    });
  });

  group('generate stuff', () {
    test('generate stuff', () {
      expectGeneratedString('declare var name;', '@Js()external get name;\n');
      expectGeneratedString('declare var name;\ndeclare var status;',
          '@Js()external get name;\n@Js()external get status;\n');
      expectGeneratedString(
          'declare var name: string;', '@Js()external String get name;\n');
    });
  });

  group('from dom.d.ts', () {
    test('can lex n lines', () {
      var n = -1;
      var tokens = lexFromFile('dom.generated.d.ts_de52865', n);
    });
    test('can parse n lines', () {
      var n = 224; // 57 61 179 183 190 196 224 254 270
      var tree = parseFromFile('dom.generated.d.ts_de52865', n);
    });
    test('can put first n lines through the whole process', () {
      var n = 5;
      var code = generateFromFile('dom.generated.d.ts_de52865', n);
    });
  });
}
