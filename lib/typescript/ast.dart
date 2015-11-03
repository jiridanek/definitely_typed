abstract class Visitor {
  var w = new StringBuffer();

  void visit(Node node);
}

class Node {
  accept(Visitor v) {
    v.visit(this);
  }
}

class RequiredParameter {
  var identifierOrPattern;
  var typeAnnotation;
  RequiredParameter(this.identifierOrPattern, this.typeAnnotation);
}

class CallSignature {
  var parameterList;
  var typeDeclaration; // TODO: Node or TypeScriptType I guess
  CallSignature(this.parameterList, this.typeDeclaration);
}

class TypeScriptType extends Node {
  var type;
  TypeScriptType(this.type);
}

class ArrayType extends TypeScriptType {
  ArrayType(type) : super(type);
}

class ObjectType extends Node {
  List typeBody;
  ObjectType(this.typeBody);
}

class InterfaceDeclaration extends Node {
  String binding;
  var type;
  InterfaceDeclaration(this.binding, this.type);
}

class PropertySignature {
  String name;
  bool nullable;
  var type; // PredefinedType TypeScriptType ArrayType
  PropertySignature(this.name, this.nullable, this.type);
}

class PredefinedType extends Node {
  String type;

  PredefinedType(this.type);
}

class TypeReference extends Node {
  String typename;
  var typeArguments;
  TypeReference(this.typename, this.typeArguments);
}

class AmbientBinding extends Node {
  var identifier;
  var annotation;

  AmbientBinding(this.identifier, this.annotation);
}

class AmbientVariableDeclaration extends Node {
  List bindings;

  AmbientVariableDeclaration(this.bindings);
}

class AmbientFunctionDeclaration extends Node {
  AmbientFunctionDeclaration(bindings, signature);
}

class IndexSignature {
  var identifier, indexType, typeAnnotation;
  IndexSignature(this.identifier, this.indexType, this.typeAnnotation);
}

class FunctionType extends Node{
  var parameterList;
  var returnType;
  FunctionType(this.parameterList, this.returnType);
}

class MethodSignature {
  var name;
  var nullable;
  var callSignature;
  MethodSignature(this.name, this.nullable, this.callSignature);
}
