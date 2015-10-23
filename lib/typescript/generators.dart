import 'package:dts2dart/typescript/ast.dart';

class TreePrinterVisitor extends Visitor {
  var w = new StringBuffer();

  @override
  void visit(Node node) {
    switch (node.runtimeType) {
      case AmbientVariableDeclaration:
        w.write('<declare ');
        for (var binding in node.bindings) {
          w.write('<var ');
          binding.accept(this);
          w.write('>');
        }
        w.write('>');
        break;
      case AmbientBinding:
        w.write('${node.identifier}');
        if (node.annotation != null) {
          w.write(': ');
          node.annotation.accept(this);
        }
        break;
      case PredefinedType:
        w.write('<type ${node.type}>');
        break;
      default:
        throw new ArgumentError('unknown type ${node.runtimeType} of ${node}');
    }
  }
}

class CodeGeneratingVisitor extends Visitor {
  var w = new StringBuffer();

  void visit(Node node) {
    switch (node.runtimeType) {
      case AmbientVariableDeclaration:
        var n = node as AmbientVariableDeclaration;
        for (var binding in n.bindings) {
          w.write('@JS()external');
          binding.accept(this);
          w.write(';\n');
        }
        break;
      case AmbientBinding:
        var n = node as AmbientBinding;
        if (n.annotation != null) {
          n.annotation.accept(this);
        }
        w.write(' get ${n.identifier}');
        break;
      case PredefinedType:
        var n = node as PredefinedType;
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
        break;
      case ArrayType:
        var n = node as ArrayType;
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
        break;
      case FunctionType:
        break;
      case ObjectType:
        var n = node as ObjectType;
        n.typeBody;
        break;
      case InterfaceDeclaration:
        var n = node as InterfaceDeclaration;
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
                  if (n.type.runtimeType == String) {
                    if (n.type == 'Array') {
                      type = ' List ';
                    }
                  } else if (n.type.runtimeType != FunctionType) {
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
                if (n.type.runtimeType == String) {
                  var type = n.type;
                  if (type == 'Array') {
                    type = 'List';
                  }
                  w.write(' List ');
                } else if (n.type.runtimeType != FunctionType) {
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
                        type = newVisitNode(parameter.typeAnnotation);
                      }
                      w.write('${type} ${parameter.identifierOrPattern}');
                    }
                  }
                  w.write(')');
                }
                //w.write(',');
              }
              w.write('});');
            }
          }
        }
        w.write('}');
        break;
      default:
        throw new ArgumentError('unknown type ${node.runtimeType}');
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
