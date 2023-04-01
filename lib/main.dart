import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:maimai/bloc/project.dart';
import 'package:maimai/bloc/templates.dart';
import 'package:maimai/dogs.g.dart';
import 'package:maimai/tools/sticker.dart';
import 'package:maimai/tools/text.dart';
import 'package:maimai/views/main.dart';
import 'package:picasso/picasso.dart';
export 'dogs.g.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  PicassoSaveSystem.registerSerializer(MaiMaiStickerLayerSerializer());
  PicassoSaveSystem.registerSerializer(MaiMaiTextLayerSerializer());
  await initialiseDogs();
  runApp(const MaiMaiApp());
}

class MaiMaiApp extends StatelessWidget {
  const MaiMaiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ProjectCubit>(create: (context) => ProjectCubit()..load()),
        BlocProvider<TemplateCubit>(create: (context) => TemplateCubit()..load(context)),
      ],
      child: MaterialApp(
          title: 'MaiMai',
          theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                  seedColor: Colors.indigo, brightness: Brightness.dark),
              useMaterial3: true,
              textTheme: GoogleFonts.nunitoTextTheme()),
          home: MainView()),
    );
  }
}

void showErrorBanner(BuildContext context, dynamic e, StackTrace st) {
  ScaffoldMessenger.of(context).showMaterialBanner(MaterialBanner(
    content: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(e.toString(),
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        Text(
          st.toString(),
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.normal),
          maxLines: 5,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    ),
    actions: [
      TextButton(
          onPressed: () {
            ScaffoldMessenger.of(context).clearMaterialBanners();
          },
          child: const Text(
            "Copy & Close",
            style: TextStyle(color: Colors.white),
          ))
    ],
    backgroundColor: Colors.redAccent,
  ));
}
