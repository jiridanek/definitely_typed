import 'dart:async';

import 'package:dts2dart/typescript/typescript.dart';

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

  /// current position in the input
  int pos = 0;
  var tokens = [];

  // for now lets load the whole file into a string
  String s;

  Lexer(this.input);

  List<Token> lex(String s) {
    tokens = [];

    this.s = s;

    while (true) {
      consumeWhitespace();

      if (s == '' || pos >= s.length) {
        tokens.add(new Token(TokenType.EOF, ''));
        return tokens;
      }
      var operator =
          new RegExp('(${Lexemes.operators.map(escapeRegex).join(')|(')})')
              .matchAsPrefix(s, pos);
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
        lexStringConst();
        continue;
      }
      var lineComment = new RegExp(r'//').matchAsPrefix(s, pos);
      if (lineComment != null) {
        pos += 2;
        lexComment();
        continue;
      }
      var blockComment = new RegExp(r'/\*').matchAsPrefix(s, pos);
      if (blockComment != null) {
        pos += 2;
        lexBlockComment();
        continue;
      }
      var nextWord =
          new RegExp(r'[A-Za-z_][A-Za-z0-9_]*').matchAsPrefix(s, pos);
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

  void lexBlockComment() {
    while (pos < s.length) {
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

  void lexComment() {
    while (pos < s.length && s[pos] != '\n') {
      pos++;
    }
  }

  consumeWhitespace() {
    while (pos < s.length &&
        (s[pos].matchAsPrefix(' ') != null ||
            s[pos].matchAsPrefix('\n') != null)) {
      pos++;
    }
  }

  lexStringConst() {
    var p = pos;
    var c = s[p];
    pos++;
    while (pos < s.length) {
      if (s[pos] == c) {
        tokens.add(new Token(TokenType.STRING, s.substring(p + 1, pos)));
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
