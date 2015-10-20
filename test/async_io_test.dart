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
}
