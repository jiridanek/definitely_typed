@TestOn('browser')
import 'package:js/js.dart';
import 'package:test/test.dart';

@Js('window.Blob')
class Blob {
  external Blob([List]);
}

@Js('window.Blob')
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