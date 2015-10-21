//@TestOn('vm') //FIXME(jirka): uncomment when Intelij plugin supports package:test

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:unittest/unittest.dart';

main() {
  // can I use Streams to abstract reading files and strings character by character,
  // with reasonable buffering? (reading the whole file into memory seems unsophisticated)
  // Stream of Tokens is a good output for a Lexer too
  // source_gen generators are async functions
  group('streaming input', () {
    //TODO: read something not Linux specific
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
  group('async', () {
    test('failing async function is not caught in sync test', () {
      asyncFuncThatThrows();
    });
    test('failing async function not caught in async test', () async {
      asyncFuncThatThrows();
    });
    test('sync: have to pass a closure, not invoke it', () {
      expect(
          (() => throw 'an error') /*()*/, throwsA(new isInstanceOf<String>()));
    });
    test('async: just expect on that Future; marking async not necessary', () {
      expect(asyncFuncThatThrows(), throwsA('an error'));
    });
  });
}

asyncFuncThatThrows() async {
  throw 'an error';
}
