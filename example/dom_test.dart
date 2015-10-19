@TestOn('browser')
import 'dom.dart' as dom;

import 'dart:js' as js;
import 'package:test/test.dart';

main() {
  group('dom.name', () {
    test('jsSetDartGet', () {
      js.context['name'] = 'aName';
      expect(dom.name, 'aName');
    });
  });
}
