import 'package:maimai/models.conv.g.dart';
import 'package:maimai/models.dart';
import 'package:dogs_core/dogs_core.dart';
export 'package:maimai/models.conv.g.dart';
export 'package:maimai/models.dart';

Future initialiseDogs() async {
  var engine =
      DogEngine.hasValidInstance ? DogEngine.instance : DogEngine(false);
  engine
      .registerAllConverters([MemeTemplateConverter(), SizedImageConverter()]);
  engine.setSingleton();
}
