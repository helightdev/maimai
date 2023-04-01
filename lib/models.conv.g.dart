import 'dart:core';
import 'package:dogs_core/dogs_core.dart' as gen;
import 'package:lyell/lyell.dart' as gen;
import 'dart:core' as gen0;
import 'package:picasso/src/tool.dart' as gen1;
import 'package:maimai/models.dart' as gen2;
import 'package:maimai/models.dart';

class MemeTemplateConverter extends gen.DefaultStructureConverter<gen2.MemeTemplate> {
  @override
  final gen.DogStructure<gen2.MemeTemplate> structure = const gen.DogStructure<gen2.MemeTemplate>(
      'MemeTemplate',
      [
        gen.DogStructureField(gen0.String, gen.TypeToken<gen0.String>(), null, gen.IterableKind.none, 'name', false, false, []),
        gen.DogStructureField(gen1.SizedImage, gen.TypeToken<gen1.SizedImage>(), null, gen.IterableKind.none, 'image', false, true, [])
      ],
      [],
      gen.ObjectFactoryStructureProxy<gen2.MemeTemplate>(_activator, [_name, _image]));

  static dynamic _name(gen2.MemeTemplate obj) => obj.name;
  static dynamic _image(gen2.MemeTemplate obj) => obj.image;
  static gen2.MemeTemplate _activator(List list) => MemeTemplate(list[0], list[1]);
}

class MemeTemplateBuilder extends gen.Builder<gen2.MemeTemplate> {
  MemeTemplateBuilder(super.$src);

  set name(gen0.String value) {
    $overrides['name'] = value;
  }

  set image(gen1.SizedImage value) {
    $overrides['image'] = value;
  }
}

extension MemeTemplateDogsExtension on MemeTemplate {
  MemeTemplate builder(Function(MemeTemplateBuilder builder) func) {
    var builder = MemeTemplateBuilder(this);
    func(builder);
    return builder.build();
  }
}
