import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class ProjectCubit extends Cubit<ProjectCubitState> {
  ProjectCubit(): super(ProjectCubitState([], false));

  void load() async {
    emit(ProjectCubitState([], false));
    var documents = await getApplicationDocumentsDirectory();
    var maimai = Directory(path.join(documents.path, "maimai"));
    if (!maimai.existsSync()) maimai.createSync();
    var list = await maimai.list().map((event) => File(event.path)).toList();
    emit(ProjectCubitState(list, true));
  }
}

class ProjectCubitState {
  List<File> files;
  bool isLoaded;

  ProjectCubitState(this.files, this.isLoaded);
}