import 'dart:ui';

import 'package:dogs_core/dogs_core.dart';
import 'package:maimai/source/image.dart';
import 'package:picasso/picasso.dart';

@serializable
class MemeTemplate {
  String name;
  SizedImage image;

  MemeTemplate(this.name, this.image);
}

@linkSerializer
class SizedImageConverter extends DogConverter<SizedImage> with StructureEmitter<SizedImage> {

  @override
  SizedImage convertFromGraph(DogGraphValue value, DogEngine engine) {
    var map = value.asList!.coerceNative();
    return SizedImage(ProviderSerializer.deserialize(map[0]), Size((map[1] as num).toDouble(), (map[2] as num).toDouble()));
  }

  @override
  DogGraphValue convertToGraph(SizedImage value, DogEngine engine) {
    var list = [
      ProviderSerializer.serialize(value.image),
      value.dimensions.width,
      value.dimensions.height,
    ];
    return DogGraphValue.fromNative(list);
  }

  @override
  DogStructure get structure => DogStructure.synthetic("SizedImage");
}