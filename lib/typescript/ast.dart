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

class TypeScriptType {
  PredefinedType type;
  TypeScriptType(this.type);
}

class ArrayType extends TypeScriptType {
  ArrayType(type) : super(type);
}

class ObjectType {
  var typeBody;
  ObjectType(this.typeBody);
}

class InterfaceDeclaration {
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

class AmbientBinding extends Node {
  var identifier;
  var annotation;

  AmbientBinding(this.identifier, this.annotation);
}

class AmbientVariableDeclaration extends Node {
  List bindings;

  AmbientVariableDeclaration(this.bindings);
}
