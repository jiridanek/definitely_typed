# definitely_typed.dart

## Motivation

 * https://typescript.codeplex.com adds a static typing scheme to JavaScript.
 * http://definitelytyped.org provides a large repository of TypeScript definition files for JavaScript libraries.
 * https://github.com/dart-lang/sdk/tree/master/pkg/js adds frictionless and typed interoperability with JavaScript APIs to Dart

Lets use TypeScript definitions (e.g. from DefinitelyTyped) to generate package:js declarations in Dart.

## Example

Given a `example/dom.generated.d.ts` containing

    declare var name: string;
    
and a dart file `example/dom.dart`,

    @DefinitelyTyped('example/dom.d.ts')
    library dts2dart.example.example;

    import 'package:definitely_typed/definitely_typed.dart';

    part 'dom.g.dart';
    
the script `bin/build.dart` generates `example/dom.g.dart`.

    $ dart bin/build.dart

    @Js()
    external String get name;
    
Test it with

    $ pub run test example --platform dartium,chrome
    
See the `example` folder [in the repository](https://github.com/jirkadanek/definitely_typed).

## Similar efforts

### in other languages

 * https://github.com/andrewray/DefinitelyMaybeTyped (a year ago) brings Typescript definition files to js_of_ocaml
 * https://github.com/frenchy64/typescript-parser (2 years ago) TypeScript type declaration parser for ClojureScript

### in the Dart-o-sphere

There is probably going to be a significant functionality overlap with https://github.com/angular/ts2dart (written in TypeScript, not Dart; can it transpile itself?).

#### Bugs that definitely_typed.dart solves

 * https://github.com/dart-lang/sdk/issues/23423
 * https://github.com/dart-lang/sdk/issues/20215
 * https://github.com/dart-lang/sdk/issues/20189
 * https://stackoverflow.com/questions/29606183/automate-javascript-interop-in-dart
 
It might be a good idea to preserve documentation comments when lexing and parsing
 
 * https://github.com/dart-lang/sdk/issues/22948

## Overview

### TypeScript side

Declaration source files have a suffix `.d.ts` and contain only type definitions (see section 3 in TypeScript 1.6 specification) and ambient declarations (section 1.1 of the specification). See http://www.typescriptlang.org/Handbook#writing-dts-files to get a feel for it.

### Dart side (still WIP)

package:js provides a Js() annotation and there is an external keyword in dart 1.13-dev. Analyzer can typecheck calls to declared objects and dart2js generates efficient code that accesses them. See https://pub.dartlang.org/packages/js for the details.

## This repository (wIP; not much Work done yet)

### Goals

Write everything in Dart. Create a vertical slice of the following functionality

  - given a JavaScript file and a corresponding .t.ds file
  - parse the .d.ts
  - turn it into @Js external Dart code
  - write it out
  - use it to call something in the JavaScript file from Dart

then add features; then possibly break it into components: .t.ds parser, a source_gen generator class; add some more features; ... ???

### Non-goals

  - good error messages for .d.ts: use tested .d.ts files; write .d.ts files in an IDE that hints at errors as you make them; test with the TypeScript compiler.

### Supported features

For now see the example and tests. What is being tested works and vice versa.

## Designs

### Name

  - dts2dart, after ts2dart
  - DefinitelyTyped or DefinitelyTyped.dart, after DefinitelyTyped
  
I come to dislike dts2dart. It does not type well. Annotating with @DefinitelyTyped('filepath.d.ts') reads almost like a link, (at).

### Parsing .d.ts

  - Option 1: Do it in Dart. a) Use relevant parts of ts2dart, either as it is or try transpiling it to Dart. b) write something yourself
  - Option 2: Use something in some other language, make it dump the AST in say JSON, load the AST
  
I am going with 1a) using code at https://github.com/robpike/ivy and https://github.com/unclebob/CC_SMC for inspiration.

### User experience

  - Option 1: https://github.com/dart-lang/source_gen and annotation that specifies what .d.ts I want to use; How to get the .d.ts?
  - Option 2: generate Dart code for all DefinitelyTyped .d.ts files and upload everything to Dart Pub
  
Option 1 is more concrete regarding what needs doing. I will be pursuing that.

### When it is done 

  - can parse https://github.com/Microsoft/TypeScript/blob/master/src/lib/dom.generated.d.ts
  - can parse all DefinitelyTyped .d.ts files