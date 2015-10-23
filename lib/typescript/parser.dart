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

  // TypeParameters:
  //   < TypeParameterList >
  _TypeParameters() {
    lookFor('<');
    var typeParameterList = _TypeParameterList();
    expect('>');
    return typeParameterList;
  }

  // TypeParameterList:
  //   TypeParameter
  //   TypeParameterList , TypeParameter
  _TypeParameterList() {
    return parseListOf(_TypeParameter, ',');
  }

  // TypeParameter:
  //   BindingIdentifier Constraint(opt)
  _TypeParameter() {
    var bindingIdentifier = _BindingIdentifier();
    var constraint = tryParse(_Constraint);
    return [bindingIdentifier, constraint];
  }

  // Constraint:
  //   extends Type
  _Constraint() {
    lookFor('extends');
    return _Type();
  }

  // TypeArguments:
  //   < TypeArgumentList >
  _TypeArguments() {
    lookFor('<');
    var typeArgumentList = _TypeArgumentList();
    expect('>');
  }

  // TypeArgumentList:
  //   TypeArgument
  //   TypeArgumentList , TypeArgument
  _TypeArgumentList() {
    return parseListOf(_Type, ',');
  }

  // TypeArgument:
  //   Type

  // Type:
  //   UnionOrIntersectionOrPrimaryType
  //   FunctionType
  //   ConstructorType
  _Type() {
    //FIXME(jirka): this is essentially unbounded lookahead for =>
    //TODO(jirka): it is hard to distinguish parenthesized type and function type
    var t = peek();
    if (t.value == '(') {
      // FIXME: function type does not have to start with (
      var i;
      var stack = 1;
      for (i = 1; stack > 0; i++) {
        t = lookahead(i);
        if (t.value == '(') {
          stack++;
        } else if (t.value == ')') {
          stack--;
        }
      }
      t = lookahead(i);
      if (t.value == '=>') {
        return _FunctionType();
      }
    }

//    var functionType = tryParse(_FunctionType);
//    if (functionType != null) {
//      return functionType;
//    }
    return _UnionOrIntersectionOrPrimaryType();
  }

  //
  _FunctionOrParenthesizedType() {
    lookFor('(');
  }

  // UnionOrIntersectionOrPrimaryType:
  //   UnionType
  //   IntersectionOrPrimaryType
  _UnionOrIntersectionOrPrimaryType() {
    var list = parseListOf(_IntersectionOrPrimaryType, '|');
    return (list.length == 1) ? list.first : list;
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
      _ParenthesizedType,
      _PredefinedType,
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
    var typename = _TypeName();
    var typeArguments = tryParse(_TypeArguments);
    return typename;
  }

  // TODO:

  // ObjectType:
  //   { TypeBody(opt) }
  _ObjectType() {
    lookFor('{');
    List typeBody;
    var t = peek();
    if (t.value != '}') {
      typeBody = _TypeBody();
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

    // _MethodSignature
    var callSignature = tryParse(_CallSignature);
    if (callSignature != null) {
      return new MethodSignature(name, nullable, callSignature);
    }

    // _PropertySignature
    var typeAnnotation = tryParse(_TypeAnnotation);
    return new PropertySignature(name, nullable, typeAnnotation);
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
    return expectOneOf([
      _BindingIdentifier,
      () {
        // { e.g. new: { declare:
        var t = peek();
        if (t.type == TokenType.KEYWORD) {
          consume();
          return t.value;
        }
        throw new LookaheadError();
      }
    ]);
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

//  RequiredParameterList:
//   RequiredParameter
//   RequiredParameterList , RequiredParameter

//  RequiredParameter:
//   AccessibilityModifier(opt) BindingIdentifierOrPattern TypeAnnotation(opt)
//   BindingIdentifier : StringLiteral

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

//  OptionalParameterList:
//   OptionalParameter
//   OptionalParameterList , OptionalParameter

//  OptionalParameter:
//   AccessibilityModifier(opt) BindingIdentifierOrPattern ? TypeAnnotation(opt)
//   AccessibilityModifier(opt) BindingIdentifierOrPattern TypeAnnotation(opt) Initializer
//   BindingIdentifier ? : StringLiteral

//  RestParameter:
//   ... BindingIdentifier TypeAnnotation(opt)

  _ParameterList() {
    return parseListOf(_Parameter, ',');
  }

  _Parameter() {
    var t = peek();
    if (t.value == '...') {
      consume();
      var identifier = _BindingIdentifier();
      var typeAnnotation = tryParse(_TypeAnnotation);
      return new RequiredParameter(identifier, typeAnnotation);
    }
    var identifierOrPattern = _BindingIdentifierOrPattern();
    var isOptional = false;
    t = peek();
    if (t.value == '?') {
      consume();
      isOptional = true;
    }
    t = lookahead(1);
    if (t.type == TokenType.STRING) {
      expect(':');
      var stringLiteral = next().value;
      return new RequiredParameter(identifierOrPattern, stringLiteral);
    }
    var typeAnnotation = tryParse(_TypeAnnotation);
    return new RequiredParameter(identifierOrPattern, typeAnnotation);
  }

  _BindingIdentifierOrPattern() {
    return _BindingIdentifier();
  }

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

  // TypeAliasDeclaration:
  //   type BindingIdentifier TypeParameters(opt) = Type ;
  _TypeAliasDeclaration() {
    lookFor('type');
    var bindingIdentifier = _BindingIdentifier();
    var typeParameters = tryParse(_TypeParameters);
    expect('=');
    var type = _Type();
    expect(';');
    return;
  }

  //****
  // A.5 Interfaces
  //****

  // InterfaceDeclaration:
  //   interface BindingIdentifier TypeParameters(opt) InterfaceExtendsClause(opt) ObjectType
  _InterfaceDeclaration() {
    lookFor('interface');
    var bindingIdentifier = _BindingIdentifier();
    var typeParameters = tryParse(_TypeParameters);
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
    return parseListOf(_ClassOrInterfaceType, ',');
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
    return expectOneOf([
      _InterfaceDeclaration,
      _AmbientDeclaration /*, _TypeAliasDeclaration*/
    ]);
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
        } else if (t.value == 'function') {
          result = _AmbientFunctionDeclaration();
        }
        break;
      case TokenType.IDENTIFIER:
        if (t.value == 'type') {
          //FIXME: this is not what's in the grammar
          result = _TypeAliasDeclaration();
        }
        break;
      default:
        throw new ParsingError("${contextForError()}");
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
    return parseListOf(_AmbientBinding, ',');
  }

  // AmbientBinding:
  //   BindingIdentifier TypeAnnotation(opt)
  _AmbientBinding() {
    var identifier = _BindingIdentifier();
    var annotation = tryParse(_TypeAnnotation);
    return new AmbientBinding(identifier, annotation);
  }

  // AmbientFunctionDeclaration:
  //   function BindingIdentifier CallSignature ;
  _AmbientFunctionDeclaration() {
    lookFor('function');
    var bindingIdentifier = _BindingIdentifier();
    var callSignature = _CallSignature();
    expect(';');
    return new AmbientFunctionDeclaration(bindingIdentifier, callSignature);
  }

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
    throw new ParsingError('${contextForError()}');
  }

  //TODO(jirka): consider something for tryParse(() => lookFor())
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

  parseListOf(f, String sep) {
    var list = [];
    var seps = sep.split('');
    list.add(f());
    for (var t = peek(); seps.contains(t.value); t = peek()) {
      consume();
      list.add(f());
    }
    return list;
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
