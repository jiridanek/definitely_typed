// Copyright (c) 2015, <your name>. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

@TestOn("browser")
import 'package:test/test.dart';
import "package:js/js.dart";
import 'dart:js';


@Js("JSON.stringify")
external String stringify(var o);

@Js()
class JSON {
  external static String stringify(var o);
}

// https://developer.mozilla.org/en-US/docs/Web/API/Blob/Blob

@Js("window.Blob")
class MapBlob {
  external MapBlob(var o1, var o2);

  external get size;
}

@Js("Blob")
class Blob {
  external Blob([List, BlobOptions]);

  external get size;
}


@Js()
class BlobOptions {
  external String get type;

  external String get endings;

  external factory BlobOptions({String type, String endings});
}

void main() {
  group('PackageJs', () {
    test('canCallToJs', () {
      expect(stringify(42), "42");
    });
    test('canCallStaticMethod', () {
      expect(JSON.stringify(43), "43");
    });
  });


  group("blob", () {
    test('newEempty', () {
      var blob = new Blob([]);
      expect(blob.size, 0);
    });
    test('newFromArray', () {
      var blob = new Blob(['Indescribable... Indestructible! Nothing Can Stop It!']);
      expect(blob.size, 53);
    });
    test('newFromArrayWithOptions', () {
      var blob = new Blob(['text'], new BlobOptions(type: 'text/plain', endings:'native'));
      expect(blob.size, 4);
    });

//   test('newFromArrayWithOptions', () {
//      expect(new Blob(['text'], new BlobOptions(type: 'text/plain', endings:'invalidString')),
//        throwsA(new isInstanceOf<TypeError>()));
//            //"Failed to construct 'Blob': The 'endings' property must be either 'transparent' or 'native'."));
//    });
  });

  group("map blob", () {
    test('newFromArrayWithOptionsMapBlob', () {
      var blob = new MapBlob(['text'], {'type': 'text/plain', 'endings':'invalidStringValue'});
      //expect(stringify(new JsObject.jsify({'a': 'b'})), '{"a":"b""}');
    });
  });
}
