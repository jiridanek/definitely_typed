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
        for (var binding in node.bindings) {
          w.write('@JS()external');
          binding.accept(this);
          w.write(';\n');
        }
        break;
      case AmbientBinding:
        if (node.annotation != null) {
          node.annotation.accept(this);
        }
        w.write(' get ${node.identifier}');
        break;
      case PredefinedType:
        var type = node.type;
        if (type == 'string') {
          type = 'String';
        }
        w.write(' ${type}');
        break;
      default:
        throw new ArgumentError('unknown type ${node.runtimeType}');
    }
  }
}
