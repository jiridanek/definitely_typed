import 'package:dts2dart/typescript/ast.dart';
import 'package:dts2dart/typescript/lexer.dart';

class Parser {
  int pos = 0;
  List<Token> tokens;

  List<Node> parse(List<Token> tokens) {
    this.tokens = tokens;

    List<Node> nodes = [];
    for (var t = peek(); t.type != TokenType.EOF; t = peek()) {
      nodes.add(_NamespaceElement());
    }
    consume(); // the EOF
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
    //FIXME(jirka): it is hard to distinguish parenthesized type and function type
    var functionType = tryParse(_FunctionType);
    if (functionType != null) {
      return functionType;
    }
    return _UnionOrIntersectionOrPrimaryType();
  }

  // UnionOrIntersectionOrPrimaryType:
  //   UnionType
  //   IntersectionOrPrimaryType
  _UnionOrIntersectionOrPrimaryType() {
    var union = [];
    union.add(_IntersectionOrPrimaryType());
    //return result;
    while (true) {
      var isUnion = tryParse(() => lookFor('|')) != null;
      if (isUnion) {
        union.add(_IntersectionOrPrimaryType());
      } else {
        return (union.length == 1) ? union.first : union;
      }
    }
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
    var type = expectOneOf([
      /*_ParenthesizedType, */ _PredefinedType,
      _ObjectType,
      _TypeReference,
      //_TupleType,
    ]);

    // array modifier
    var t = peek();
    if (t.value == '[') {
      //TODO(jirka): arrays of arrays? array of set of arrays? ...
      expect('[');
      expect(']');
      type = new ArrayType(type);
    }
    return type;
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
      return new PredefinedType(t.value);
    }
    throw new LookaheadError();
  }

  // TypeReference:
  // TypeName [no LineTerminator here] TypeArguments(opt)
  _TypeReference() {
    return _TypeName();
  }

  // TODO:

  // ObjectType:
  //   { TypeBody(opt) }
  _ObjectType() {
    lookFor('{');
    List typeBody;
    var t = peek();
    if (t.value != '}') {
      // safer than try catch
      //try {
      typeBody = _TypeBody();
      //} on LookaheadError catch(_) {}
    }
    expect('}');
    return new ObjectType(typeBody);
  }

  // TypeBody:
  //   TypeMemberList ;opt
  //   TypeMemberList ,opt
  _TypeBody() {
    var typeMemberList = _TypeMemberList();
    var t = peek();
    if (t.value == ';' || t.value == ',') {
      consume();
    }
    return typeMemberList;
  }

  // TypeMemberList:
  //   TypeMember
  //   TypeMemberList ; TypeMember
  //   TypeMemberList , TypeMember
  _TypeMemberList() {
    var list = [];
    while (true) {
      list.add(_TypeMember());
      var t = peek();
      if (t.value == ';' || t.value == ',') {
        consume();
        t = peek();
        if (t.value == '}') {
          // HACK: the ;} should be matched as part of an enclosing _TypeBody
          break;
        }
      } else {
        break;
      }
    }
    return list;
  }

  // TypeMember:
  //   PropertySignature
  //   CallSignature
  //   ConstructSignature
  //   IndexSignature
  //   MethodSignature
  _TypeMember() {
    var result = tryParse(_CallSignature);
    if (result != null) {
      return result;
    }
    result = tryParse(_IndexSignature);
    if (result != null) {
      return result;
    }

    /* */ _PropertySignature;
    /* or */
    _MethodSignature;

    var name = tryParse(_PropertyName);
    if (name == null) {
      throw new LookaheadError();
    }

    var t = peek();
    var nullable;
    if (t.value == '?') {
      nullable = true;
      consume();
    }

    // _PropertySignature

    var typeAnnotation = tryParse(_TypeAnnotation);
    if (typeAnnotation != null) {
      return new PropertySignature(name, nullable, typeAnnotation);
    }

    // _MethodSignature

    var callSignature = tryParse(_CallSignature);
    if (callSignature != null) {
      return new MethodSignature(name, nullable, callSignature);
    }
  }

  // ArrayType:
  //   PrimaryType [no LineTerminator here] [ ]
  _ArrayType() {
    throw ('implemented in _PrimaryType');
  }

  //TupleType:
  //   [ TupleElementTypes ]
//  _TupleType() {
//    lookFor('[');
//    var tupleElements;
//    tupleElements.add(_Type());
//    while (true) {
//      var t = peek();
//      if (t.value == ',') {
//        consume();
//        tupleElements.add(_Type());
//      } else {
//        expect(']');
//        return tupleElements;
//      }
//    }
//  }

  //  TupleElementTypes:
  //   TupleElementType
  //   TupleElementTypes , TupleElementType

  //  TupleElementType:
  //   Type

  // TODO:

  // FunctionType:
  //   TypeParameters(opt) ( ParameterListopt ) => Type
  _FunctionType() {
    //var typeParameters = tryParse(_TypeParameters);
    lookFor('(');
    var parameterList = tryParse(_ParameterList);
    expect(')');
    expect('=>');
    var type = _Type();
    return new FunctionType(parameterList, type);
  }

  // TODO:

  // PropertySignature:
  //   PropertyName ?(opt) TypeAnnotation(opt)
  _PropertySignature() {
    var name = _PropertyName();
    var t = peek();
    var nullable;
    if (t.value == '?') {
      nullable = true;
      consume();
    }
    var typeAnnotation;
    try {
      typeAnnotation = _TypeAnnotation();
    } on LookaheadError catch (_) {}
    return new PropertySignature(name, nullable, typeAnnotation);
  }

  //  PropertyName:
  //   IdentifierName
  //   StringLiteral
  //   NumericLiteral
  _PropertyName() {
    //TODO(jirka): requires design, these literals might be a problem for Dart
    return _BindingIdentifier();
    //FIXME
  }

  // TypeAnnotation:
  //   : Type
  _TypeAnnotation() {
    lookFor(':');
    return _Type();
  }

  // CallSignature:
  //   TypeParameters(opt) ( ParameterList(opt) ) TypeAnnotation(opt)
  _CallSignature() {
    lookFor('(');
    var parameterList = tryParse(_ParameterList);
    expect(')');
    var typeAnnotation = tryParse(_TypeAnnotation);
    return new CallSignature(parameterList, typeAnnotation);
  }

// ParameterList:
//   RequiredParameterList
//   OptionalParameterList
//   RestParameter
//   RequiredParameterList , OptionalParameterList
//   RequiredParameterList , RestParameter
//   OptionalParameterList , RestParameter
//   RequiredParameterList , OptionalParameterList , RestParameter
// NOTE(jirka): required, then optional, then rest
  _ParameterList() {
    return _requiredOptionalParameterList();
  }

//  RequiredParameterList:
//   RequiredParameter
//   RequiredParameterList , RequiredParameter
  _requiredOptionalParameterList() {
    var list = [];
    list.add(_requiredOptionalParameter());
    for (var t = peek(); t.value == ','; t = peek()) {
      consume();
      list.add(_requiredOptionalParameter());
    }
    return list;
  }

//  RequiredParameter:
//   AccessibilityModifier(opt) BindingIdentifierOrPattern TypeAnnotation(opt)
//   BindingIdentifier : StringLiteral
  _requiredOptionalParameter() {
    var identifierOrPattern = _BindingIdentifierOrPattern();
    var isOptional = tryParse(() => lookFor('?'));
    var t = lookahead(1);
    if (t.type != TokenType.STRING) {
      var typeAnnotation = tryParse(_TypeAnnotation);
      return new RequiredParameter(identifierOrPattern, typeAnnotation);
    }
    expect(':');
    var stringLiteral = next().value;
    return new RequiredParameter(identifierOrPattern, stringLiteral);
  }

//  AccessibilityModifier:
//   public
//   private
//   protected
  _AccessiblitityModifier() {
    var t = peek();
    if ('public private protected'.split(' ').contains(t.value)) {
      consume();
      return t.value;
    }
    throw new LookaheadError();
  }

//  BindingIdentifierOrPattern:
//   BindingIdentifier
//   BindingPattern
  _BindingIdentifierOrPattern() {
    return _BindingIdentifier();
  }

//  OptionalParameterList:
//   OptionalParameter
//   OptionalParameterList , OptionalParameter

//  OptionalParameter:
//   AccessibilityModifier(opt) BindingIdentifierOrPattern ? TypeAnnotation(opt)
//   AccessibilityModifier(opt) BindingIdentifierOrPattern TypeAnnotation(opt) Initializer
//   BindingIdentifier ? : StringLiteral

//  RestParameter:
//   ... BindingIdentifier TypeAnnotation(opt)

  //TODO:

  //IndexSignature:
  //   [ BindingIdentifier : string ] TypeAnnotation
  //   [ BindingIdentifier : number ] TypeAnnotation
  _IndexSignature() {
    lookFor('[');
    var identifier = expectIdentifier();
    expect(':');
    var indexType =
        expectOneOf([() => lookFor('string'), () => lookFor('number')]);
    expect(']');
    var typeAnnotation = _TypeAnnotation();
    return new IndexSignature(identifier, indexType, typeAnnotation);
  }

  // MethodSignature:
  //   PropertyName ?opt CallSignature
  _MethodSignature() {
    throw ('implemented in higher-up productions');
  }

  // TODO:

  //****
  // A.5 Interfaces
  //****

  // InterfaceDeclaration:
  //   interface BindingIdentifier TypeParameters(opt) InterfaceExtendsClause(opt) ObjectType
  _InterfaceDeclaration() {
    lookFor('interface');
    var bindingIdentifier = _BindingIdentifier();
    var interfaceExtendsClause = tryParse(_InterfaceExtendsClause);
    var objectType = _ObjectType();
    return new InterfaceDeclaration(bindingIdentifier, objectType);
  }

  // InterfaceExtendsClause:
  //   extends ClassOrInterfaceTypeList
  _InterfaceExtendsClause() {
    lookFor('extends');
    return _ClassOrInterfaceTypeList();
  }

  // ClassOrInterfaceTypeList:
  //   ClassOrInterfaceType
  //   ClassOrInterfaceTypeList , ClassOrInterfaceType
  _ClassOrInterfaceTypeList() {
    var typeList = [_ClassOrInterfaceType()];
    while (true) {
      //FIXME(jirka): refactor all such loops into a higher order function
      var t = peek();
      if (t.value == ',') {
        consume();
        typeList.add(_ClassOrInterfaceType());
      } else {
        return typeList;
      }
    }
  }

  // ClassOrInterfaceType:
  //   TypeReference
  _ClassOrInterfaceType() {
    return _TypeReference();
  }

  //*****
  // A.8 Namespaces
  //*****

  // TODO

  // NamespaceElement:
  //   Statement
  //   LexicalDeclaration
  //   FunctionDeclaration
  //   GeneratorDeclaration
  //   ClassDeclaration
  //   InterfaceDeclaration
  //   TypeAliasDeclaration
  //   EnumDeclaration
  //   NamespaceDeclaration
  //   AmbientDeclaration
  //   ImportAliasDeclaration
  //   ExportNamespaceElement
  _NamespaceElement() {
    return expectOneOf([_InterfaceDeclaration, _AmbientDeclaration]);
  }

  _BindingIdentifier() {
    return lookForIdentifier();
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

  // AmbientVariableDeclaration:
  //   var AmbientBindingList ;
  //   let AmbientBindingList ;
  //   const AmbientBindingList ;
  //NOTE(jirka): I am making the ; optional here
  _AmbientVariableDeclaration() {
    consume();
    var bindings = _AmbientBindingList();
    tryParse(() => lookFor(';'));
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

  //*****
  // END-OF-GRAMMAR
  //*****

  _TypeName() {
    return _BindingIdentifier();
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
    if (o.runtimeType == String) {
      if (t.value == o) {
        consume();
      } else {
        throw new ParsingError(
            'expecting ${o} encountered ${t} in ${contextForError()}');
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

  bool lookFor(s) {
    final t = peek();
    if (t.value != s) {
      throw new LookaheadError();
    }
    consume();
    return true;
  }

  lookahead(int n) {
    return tokens[pos + n];
  }

  expectIdentifier() {
    final t = next();
    if (t.type == TokenType.IDENTIFIER) {
      return t.value;
    }
    throw new ParsingError(
        'expected IDENTIFIER, got $t in ${contextForError()}');
  }

  lookForIdentifier() {
    final t = peek();
    if (t.type == TokenType.IDENTIFIER) {
      consume();
      return t.value;
    }
    throw new LookaheadError();
  }

  tryParse(f) {
    try {
      return f();
    } on LookaheadError catch (_) {}
  }

  contextForError() {
    var from = max(0, pos - 10);
    var to = min(tokens.length - 1, pos + 5);
    return tokens.sublist(from, to);
  }

  final _declare = new Token(TokenType.KEYWORD, 'declare');
  final _var = new Token(TokenType.KEYWORD, 'var');
  final _let = new Token(TokenType.KEYWORD, 'let');
  final _const = new Token(TokenType.KEYWORD, 'const');
}

class ParsingError extends StateError {
  ParsingError(e) : super(e);
}

class LookaheadError extends Error {}

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
