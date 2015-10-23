@TestOn('browser')
import 'package:js/js.dart';
import 'package:test/test.dart';

@JS('window.Blob')
class Blob {
  external Blob([List]);
}

@JS('window.Blob')
class RenamedBlob {
  external RenamedBlob([List]);
}

main() {
  test('canCreateBlobNoArgs', () {
    new Blob();
  });
  test('canCreateBlobEmptyList', () {
    new Blob([]);
  });

  test('canCreateRenamedBlobNoArgs', () {
    new RenamedBlob();
  });
  test('canCreateRenamedBlobEmptyList', () {
    new RenamedBlob([]);
  });
}