import 'DefinitelyTypedGenerator.dart';
import 'package:source_gen/source_gen.dart';

main(List<String> args) async {
  var msg = await build(args, const [const DefinitelyTypedGenerator()],
      librarySearchPaths: ['example', 'lib/chartjs']);
  print(msg);
}
