import 'package:dts2dart/typescript/ast.dart';

class TreePrinterVisitor extends Visitor {
  var w = new StringBuffer();

  @override
  void visit(Node node) {
    switch (node.runtimeType) {
      case AmbientVariableDeclaration:
        visitAmbientVariableDeclaration(node);
        break;
      case AmbientBinding:
        visitAmbientBinding(node);
        break;
      case PredefinedType:
        visitPredefinedType(node);
        break;
      default:
        throw new ArgumentError('unknown type ${node.runtimeType} of ${node}');
    }
  }

  void visitPredefinedType(Node node) {
    w.write('<type ${node.type}>');
  }

  void visitAmbientBinding(Node node) {
    w.write('${node.identifier}');
    if (node.annotation != null) {
      w.write(': ');
      node.annotation.accept(this);
    }
  }

  void visitAmbientVariableDeclaration(Node node) {
    w.write('<declare ');
    for (var binding in node.bindings) {
      w.write('<var ');
      binding.accept(this);
      w.write('>');
    }
    w.write('>');
  }
}

class CodeGeneratingVisitor extends Visitor {
  var w = new StringBuffer();

  void visit(Node node) {
    switch (node.runtimeType) {
      case AmbientVariableDeclaration:
        visitAmbientVariableDeclaration(node as AmbientVariableDeclaration);
        break;
      case AmbientBinding:
        visitAmbientBinding(node as AmbientBinding);
        break;
      case PredefinedType:
        visitPredefinedType(node as PredefinedType);
        break;
      case ArrayType:
        visitArrayType(node as ArrayType);
        break;
      case FunctionType:
        visitFunctionType(node);
        break;
      case ObjectType:
        visitObjectType(node);
        break;
      case InterfaceDeclaration:
        visitInterfaceDeclaration(node as InterfaceDeclaration);
        break;
      case PropertySignature:
        visitPropertySignature(node as PropertySignature);
        break;
      case TypeReference:
        visitTypeReference(node as TypeReference);
        break;
      default:
        throw new ArgumentError('unknown type ${node.runtimeType}');
    }
  }

  visitObjectType(ObjectType node) {
  }

  void visitPropertySignature(PropertySignature node) {
  }

  void visitFunctionType(FunctionType node) {
    return;
    var returnType = node.returnType;
    var parameterList = newVisitNode(node.parameterList);
    //TODO(jirka): to produce a meaningful string I need to know the name
    w.write([returnType].join(' '));
  }

  void visitTypeReference(TypeReference node) {
    String typename = node.typename;
    if (typename == 'Array') {
      typename = ' List';
    }
    w.write(typename);
  }

  void visitInterfaceDeclaration(InterfaceDeclaration n) {
    w.write('@JS()class ${n.binding}{');
    if (n.type is ObjectType) {
      var l = n.type as ObjectType;
      var m = l.typeBody;
      if (m != null) {
        var hasProperties = false;
        for (var nn in m) {
          switch (nn.runtimeType) {
            case MethodSignature:
              break;
            case PropertySignature:
              hasProperties = true;
              var n = nn as PropertySignature;
              var type = ' ';
              if (n.type.runtimeType != FunctionType) {
                type = newVisitNode(n.type);
              }
              w.write('external${type}get ${n.name};');
              break;
          }
        }

        var propertySignatures = [];
        for (var nn in m) {
          switch (nn.runtimeType) {
            case MethodSignature:
              break;
            case PropertySignature:
              propertySignatures.add(nn);
              break;
          }
        }

        if (hasProperties) {
          w.write('external factory ${n.binding}({');
          var first = true;
          for (PropertySignature n in propertySignatures) {
            if (!first) {
              w.write(',');
            }
            first = false;
            if (n.type.runtimeType != FunctionType) {
              var type = newVisitNode(n.type).trimLeft();
              w.write(('${type}${n.name}'));
            } else {
              var m = n.type as FunctionType;
              if (m.returnType != null) {
                m.returnType.accept(this);
              }
              w.write(' ${n.name}(');
              var first = true;
              if (m.parameterList != null) {
                for (RequiredParameter parameter in m.parameterList) {
                  if (!first) {
                    w.write(',');
                  }
                  first = false;
                  var type;
                  if (parameter.typeAnnotation.runtimeType == String) {
                    type = parameter.typeAnnotation;
                  } else {
                    type = newVisitNode(parameter.typeAnnotation).trimRight();
                  }
                  w.write('${type} ${parameter.identifierOrPattern}');
                }
              }
              w.write(')');
            }
          }
          w.write('});');
        }
      }
    }
    w.write('}');
  }

  void visitArrayType(ArrayType n) {
    w.write(' List');
    if (n.type != null && n.type.runtimeType != ObjectType) {
      w.write('<');
    }
    if (n.type.runtimeType != String) {
      n.type.accept(this);
    } else {
      w.write(' ${n.type}');
    }
    if (n.type != null && n.type.runtimeType != ObjectType) {
      w.write('>');
    }
  }

  void visitPredefinedType(PredefinedType n) {
    var type;
    switch (n.type) {
      case 'string':
        type = ' String';
        break;
      case 'number':
        type = ' num';
        break;
      case 'boolean':
        type = ' bool';
        break;
      case 'any':
        type = 'dynamic';
        break;
      default:
        type = n.type;
    }
    w.write('${type}');
  }

  void visitAmbientBinding(AmbientBinding n) {
    if (n.annotation != null) {
      n.annotation.accept(this);
    }
    w.write(' get ${n.identifier}');
  }

  void visitAmbientVariableDeclaration(AmbientVariableDeclaration n) {
    for (var binding in n.bindings) {
      w.write('@JS()external');
      binding.accept(this);
      w.write(';\n');
    }
  }

  String newVisitNode(node) {
    if (node != null) {
      var v = new CodeGeneratingVisitor();
      node.accept(v);
      return '${v.w.toString()} ';
    }
    return ' ';
  }
}
