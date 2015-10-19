import 'package:unittest/unittest.dart';
import 'dart:async';
import 'dart:io';
import 'dart:convert';

class Lexemes {
  // https://github.com/Microsoft/TypeScript/issues/2536
  static final chars = '<>()[]{}=|&?:;,.'.split('');
  static final operators = '=> ...'.split(' ');

  //TODO: not complete

  // contextual keywords: any number boolean string symbol void //TODO: not complete // lets treat them as identifiers for now
  static final keywords = 'extends new private public protected function interface '
      'declare var let const function class constructor static namespace export module' //section A.11
      .split(' ');
}

lexString(String s, List<Token> ts) {
  var stream = new Stream.fromIterable(s.split('\n'));
  var l = new Lexer(stream);
  var k = l.lex(s);
  var eof = new Token(TokenType.EOF, '');
  if (ts.isEmpty || ts.last != eof) {
    ts.add(eof);
  }
  expect(k, ts);
}

main() {
  // can I use Streams to abstract reading files and strings character by character,
  // with reasonable buffering? (reading the whole file into memory seems unsophisticated)
  // Stream of Tokens is a good output for a Lexer too
  group('streamingInput', () {
    //TODO: move this to VM-only tests // read something not Linux  specific
    // https://www.dartlang.org/dart-by-example/#using-a-stream-to-read-a-file
    test('streamFile', () async {
      // Uint8List -> String -> String
      var stream = new File('/proc/partitions')
          .openRead()
          .transform(UTF8.decoder)
          .transform(new LineSplitter());
      var first = await stream.first;
      expect(first.runtimeType, String);
    });
    test('streamString', () async {
      var string = 'first line\nsecond line';
      var stream = new Stream.fromIterable(string.split('\n'));
      expect(await stream.first, 'first line');
    });
  });

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
      lexString('', [new Token(TokenType.EOF, '')]);
    });

    test('lineComment', () {
      lexString('//', []);
    });
    test('block comment', () {
      lexString('/**block\ncomment*/', []);
    });

    test('whitespace', () {
      lexString(' ', [new Token(TokenType.EOF, '')]);
    });
    test('char whitespace', () {
      lexString('; ', [new Token(TokenType.CHAR, ';')]);
    });

    test('chars', () {
      for (var char in Lexemes.chars) {
        lexString(char, [new Token(TokenType.CHAR, char)]);
      }
    });
    test('keywords', () {
      for (var keyword in Lexemes.keywords) {
        lexString(keyword, [new Token(TokenType.KEYWORD, keyword)]);
      }
    });
    test('identifiers', () {
      var identifier = 'myIdentifier';
      lexString(identifier, [new Token(TokenType.IDENTIFIER, identifier)]);

      var validIdentifiers = 'a aa A AA a_a a1'.split(' ');
      for (var identifier in validIdentifiers) {
        lexString(identifier, [new Token(TokenType.IDENTIFIER, identifier)]);
      }
    });
    test('operators', () {
      for (var operator in Lexemes.operators) {
        lexString(operator, [new Token(TokenType.OPERATOR, operator)]);
      }
    });
    // let's strip quotes for now; ivy keeps them, wonder why
    test('string literals', () {
      lexString('"a string"', [new Token(TokenType.STRING, 'a string')]);
    });

    test('twoChars', () {
      var t = new Token(TokenType.CHAR, ';');
      lexString('; ;', [t, t]);
    });
    test('twoKeywords', () {
      var t = new Token(TokenType.KEYWORD, 'declare');
      lexString('declare declare', [t, t]);
    });
    test('twoIdentifiers', () {
      var t = new Token(TokenType.IDENTIFIER, 'myIdentifier');
      lexString('myIdentifier myIdentifier', [t, t]);
    });
    test('charIdentifier', () {
      var c = new Token(TokenType.CHAR, ':');
      var i = new Token(TokenType.IDENTIFIER, 'myIdentifier');
      lexString(': myIdentifier', [c, i]);
    });
    test('multiple lines of input', () {
      var t = new Token(TokenType.CHAR, ';');
      lexString(';\n;', [t, t]);
    });
  });

  group('lexStuff', () {
    test('name', () {
      lexString('declare var name: string', [
        new Token(TokenType.KEYWORD, 'declare'),
        new Token(TokenType.KEYWORD, 'var'),
        new Token(TokenType.IDENTIFIER, 'name'),
        new Token(TokenType.CHAR, ':'),
        new Token(TokenType.IDENTIFIER,
            'string'), // FIXME: or should I consider it a KEYWORD?
      ]);
    });
    test('name status', () {
      lexString('declare var name;\ndeclare var status;', [
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
    test('parseStuff', () {
      expectParsedString('declare var name;', '<declare <var name>>');
      expectParsedString('declare var name;\ndeclare var status;',
          '<declare <var name>><declare <var status>>');
      expectParsedString(
          'declare var name: string;', '<declare <var name: <type string>>>');
      parseString('declare var name: (string);');
      parseString('declare var name, age;');
    });
    test('generateStuff', () {
      expectCodeString('declare var name;', '@Js()external get name;\n');
      //expectCodeString('declare var name;\ndeclare var status;', '@Js()external get name;\n@Js()external get status;\n');
      expectCodeString(
          'declare var name: string;', '@Js()external String get name;\n');
    });
  });

  group('from dom.d.ts', () {
    test('can lex n lines', () {
      var n = -1;
      var tokens = lexFromFile('dom.generated.d.ts_de52865', n);
      //print(tokens);
    });
    test('can put first n lines through the whole process', () {
      var n = 5;
      var code = generateCodeFromFile('dom.generated.d.ts_de52865', n);
      print(code);
      //expect(code, '@Js()external String get name;\n@Js()external String get status;\n');
    });
  });
}

expectParsedString(s, e) {
  var treePrinter = new TreePrinterVisitor();
  for (var node in parseString(s)) {
    node.accept(treePrinter);
  }
  expect(treePrinter.w.toString(), e);
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

expectCodeString(s, e) {
  var codeGenerator = new CodeGeneratingVisitor();
  for (var node in parseString(s)) {
    node.accept(codeGenerator);
  }
  expect(codeGenerator.w.toString(), e);
}

parseString(s) {
  var l = new Lexer(new Stream.fromIterable(s.split('\n')));
  var tokens = l.lex(s);
  var p = new Parser();
  var ast = p.parse(tokens);
  return ast;
}

String generateCodeFromFile(String path, [int nlines = -1]) {
  var ls = lexFromFile(path, nlines);
  var p = new Parser();
  var ps = p.parse(ls);
  var v = new CodeGeneratingVisitor();
  for (var n in ps) {
    n.accept(v);
  }
  return v.w.toString();
}

enum TokenType { EOF, CHAR, IDENTIFIER, KEYWORD, OPERATOR, STRING }

class Token {
  TokenType type;
  String value;

  Token(this.type, this.value);

  bool operator ==(o) {
    return type == o.type && value == o.value;
  }

  @override
  String toString() {
    switch (type) {
      case TokenType.EOF:
        return '<EOF>';
      default:
        return '<${type.toString().split('.')[1]} $value>';
    }
  }
}

class Lexer {
  Stream<String> input;
  int pos = 0;
  var tokens = [];

  // current position in the input
  Lexer(this.input);

  List<Token> lex(String s) {
    tokens = [];

    while (true) {
      consumeWhitespace(s);

      if (s == '' || pos >= s.length) {
        tokens.add(new Token(TokenType.EOF, ''));
        return tokens;
      }
      var operator = new RegExp('(${Lexemes.operators.map(escapeRegex).join(')|(')})').matchAsPrefix(s, pos);
      if (operator != null) {
        tokens.add(new Token(TokenType.OPERATOR, operator.group(0)));
        pos += operator.group(0).length;
        continue;
      }
      if (Lexemes.chars.contains(s[pos])) {
        tokens.add(new Token(TokenType.CHAR, s[pos]));
        pos++;
        continue;
      }
      if (s[pos] == '\"') {
        lexStringConst(s);
        continue;
      }
      var lineComment = new RegExp(r'//').matchAsPrefix(s, pos);
      if (lineComment != null) {
        pos += 2;
        lexComment(s);
        continue;
      }
      var blockComment = new RegExp(r'/\*').matchAsPrefix(s, pos);
      if (blockComment != null) {
        pos += 2;
        lexBlockComment(s);
        continue;
      }
      var nextWord = new RegExp(r'[A-Za-z_][A-Za-z0-9_]*').matchAsPrefix(s, pos);
      if (nextWord != null) {
        if (Lexemes.keywords.contains(nextWord.group(0))) {
          tokens.add(new Token(TokenType.KEYWORD, nextWord.group(0)));
        } else {
          tokens.add(new Token(TokenType.IDENTIFIER, nextWord.group(0)));
        }
        pos += nextWord.group(0).length;
        continue;
      }
      throw ('invalid char: ${s[pos]} in "${s.substring(max(0, pos-15), min(pos+5, s.length))}"');
    }
  }

  void lexBlockComment(String s) {
    while(pos < s.length) {
      if (s[pos] == '*') {
        pos++;
        if (pos < s.length && s[pos] == '/') {
          pos++;
          return;
        }
        continue;
      }
      pos++;
    }
  }

  void lexComment(String s) {
    while (pos < s.length && s[pos] != '\n') {
      pos++;
    }
  }

  consumeWhitespace(String s) {
    while (pos < s.length &&
        (s[pos].matchAsPrefix(' ') != null ||
            s[pos].matchAsPrefix('\n') != null)) {
      pos++;
    }
  }

  lexStringConst(String s) {
    var p = pos;
    var c = s[p];
    pos++;
    while (pos < s.length) {
      if (s[pos] == c) {
        tokens.add(new Token(TokenType.STRING, s.substring(p+1, pos)));
        pos++;
        return;
      }
      pos++;
    }
  }
}

String escapeRegex(String r) {
  r = r.replaceAll('.', '\\.');
  return r;
}

class ParsingError extends StateError {
  ParsingError(e) : super(e);
}

class LookaheadError extends Error {}

abstract class Visitor {
  var w = new StringBuffer();

  void visit(Node node);
}

max(a, b) {
  if (a <= b) {
    return b;
  }
  return a;
}

min(a, b) {
  if (a < b) {
    return a;
  }
  return b;
}

class TreePrinterVisitor extends Visitor {
  var w = new StringBuffer();

  @override
  void visit(Node node) {
    switch (node.runtimeType) {
      case AmbientVariableDeclaration:
        w.write('<declare ');
        for (var binding in node.bindings) {
          w.write('<var ');
          binding.accept(this);
          w.write('>');
        }
        w.write('>');
        break;
      case AmbientBinding:
        w.write('${node.identifier}');
        if (node.annotation != null) {
          w.write(': ');
          node.annotation.accept(this);
        }
        break;
      case PredefinedType:
        w.write('<type ${node.type}>');
        break;
      default:
        throw new ArgumentError('unknown type ${node.runtimeType} of ${node}');
    }
  }
}

class CodeGeneratingVisitor extends Visitor {
  var w = new StringBuffer();

  void visit(Node node) {
    switch (node.runtimeType) {
      case AmbientVariableDeclaration:
        for (var binding in node.bindings) {
          w.write('@Js()external');
          binding.accept(this);
          w.write(';\n');
        }
        break;
      case AmbientBinding:
        if (node.annotation != null) {
          node.annotation.accept(this);
        }
        w.write(' get ${node.identifier}');
        break;
      case PredefinedType:
        var type = node.type;
        if (type == 'string') {
          type = 'String';
        }
        w.write(' ${type}');
        break;
      default:
        throw new ArgumentError('unknown type ${node.runtimeType}');
    }
  }
}

class Node {
  accept(Visitor v) {
    v.visit(this);
  }
}

class Parser {
  int pos = 0;
  List<Token> tokens;

  List<Node> parse(List<Token> tokens) {
    this.tokens = tokens;

    List<Node> nodes = [];
    for (var t = peek(); t.type != TokenType.EOF; t = peek()) {
      nodes.add(_AmbientDeclaration());
    }
    consume();
    return nodes;
  }

  //****
  // A.1 Types
  //****

  //TODO:

  // Type:
  //   UnionOrIntersectionOrPrimaryType
  //   FunctionType
  //   ConstructorType
  _Type() {
    return _UnionOrIntersectionOrPrimaryType();
  }

  // UnionOrIntersectionOrPrimaryType:
  //   UnionType
  //   IntersectionOrPrimaryType
  _UnionOrIntersectionOrPrimaryType() {
    return _IntersectionOrPrimaryType();
  }

  // IntersectionOrPrimaryType:
  //   IntersectionType
  //   PrimaryType
  _IntersectionOrPrimaryType() {
    return _PrimaryType();
  }

  // PrimaryType:
  //   ParenthesizedType
  //   PredefinedType
  //   TypeReference
  //   ObjectType
  //   ArrayType
  //   TupleType
  //   TypeQuery
  _PrimaryType() {
    return expectOneOf([_ParenthesizedType, _PredefinedType]);
  }

  // ParenthesizedType:
  //   ( Type )
  _ParenthesizedType() {
    lookFor('(');
    var type = _Type();
    expect(')');
    return type;
  }

  // PredefinedType:
  //   any
  //   number
  //   boolean
  //   string
  //   symbol
  //   void
  _PredefinedType() {
    final t = peek();
    if ('any number boolean string symbol void'.split(' ').contains(t.value)) {
      consume();
    } else {
      throw LookaheadError;
    }
    return new PredefinedType(t.value);
  }

  // TODO:

  // TypeAnnotation:
  //   : Type
  _TypeAnnotation() {
    lookFor(':');
    return _Type();
  }

  //TODO:

  //****
  // A.10 Ambients
  //****

  // AmbientDeclaration:
  //   declare AmbientVariableDeclaration
  //   declare AmbientFunctionDeclaration
  //   declare AmbientClassDeclaration
  //   declare AmbientEnumDeclaration
  //   declare AmbientNamespaceDeclaration
  _AmbientDeclaration() {
    var result;
    lookFor('declare');
    final t = peek();
    switch (t.type) {
      case TokenType.KEYWORD:
        if ([_var, _let, _const].contains(t)) {
          result = _AmbientVariableDeclaration();
        }
        break;
      default:
        throw ParsingError;
    }
    return result;
  }

  void consume() {
    pos++;
  }

  peek() {
    return tokens[pos];
  }

  next() {
    return tokens[pos++];
  }

  expect(var o) {
    final t = peek();
    print(o);
    print(t);
    print(pos);
    print(tokens);
    if (o.runtimeType == String) {
      if (t.value == o) {
        consume();
      } else {
        throw new ParsingError();
      }
    }
  }

  expectOneOf(list) {
    for (var f in list) {
      try {
        return f();
      } on LookaheadError catch (_) {}
    }
    throw ParsingError;
  }

  lookFor(s) {
    final t = peek();
    if (t.value != s) {
      throw new LookaheadError();
    }
    consume();
  }

  // AmbientVariableDeclaration:
  //   var AmbientBindingList ;
  //   let AmbientBindingList ;
  //   const AmbientBindingList ;
  _AmbientVariableDeclaration() {
    consume();
    var bindings = _AmbientBindingList();
    expect(';');
    return new AmbientVariableDeclaration(bindings);
  }

  // AmbientBindingList:
  //   AmbientBinding
  //   AmbientBindingList , AmbientBinding
  _AmbientBindingList() {
    var bindings = [];
    while (true) {
      bindings.add(_AmbientBinding());
      final t = peek();
      if (t.value != ',') {
        break;
      }
      consume();
    }
    return bindings;
  }

  // AmbientBinding:
  //   BindingIdentifier TypeAnnotation(opt)
  _AmbientBinding() {
    var identifier = _BindingIdentifier();
    var annotation;
    try {
      annotation = _TypeAnnotation();
    } on LookaheadError catch (_) {}
    return new AmbientBinding(identifier, annotation);
  }

  // AmbientFunctionDeclaration:
  //   function BindingIdentifier CallSignature ;

  // TODO

  _BindingIdentifier() {
    return expectIdentifier();
  }

  expectIdentifier() {
    final t = next();
    if (t.type != TokenType.IDENTIFIER) {
      throw new ParsingError('expected IDENTIFIER, got $t');
    }
    return t.value;
  }

  final _declare = new Token(TokenType.KEYWORD, 'declare');
  final _var = new Token(TokenType.KEYWORD, 'var');
  final _let = new Token(TokenType.KEYWORD, 'let');
  final _const = new Token(TokenType.KEYWORD, 'const');
}

class PredefinedType extends Node {
  String type;

  PredefinedType(this.type);
}

class AmbientBinding extends Node {
  var identifier;
  var annotation;

  AmbientBinding(this.identifier, this.annotation);
}

class AmbientVariableDeclaration extends Node {
  List bindings;

  AmbientVariableDeclaration(this.bindings);
}
