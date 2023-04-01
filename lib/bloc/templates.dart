import 'package:bloc/bloc.dart';
import 'package:dogs_core/dogs_core.dart';
import 'package:flutter/material.dart';
import 'package:maimai/models.dart';

class TemplateCubit extends Cubit<TemplateCubitState> {
  TemplateCubit(): super(TemplateCubitState([], false));

  void load(BuildContext context) async {
    emit(TemplateCubitState([], false));
    var bundle = await DefaultAssetBundle.of(context).loadString("assets/templates.json");
    var graph = dogs.jsonSerializer.deserialize(bundle);
    var templates = (dogs.convertIterableFromGraph(
        graph, MemeTemplate, IterableKind.list
    ) as List).cast<MemeTemplate>();
    emit(TemplateCubitState(templates, true));
  }
}

class TemplateCubitState {
  List<MemeTemplate> templates;
  bool isLoaded;

  TemplateCubitState(this.templates, this.isLoaded);
}