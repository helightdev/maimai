import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:maimai/dogs.g.dart';
import 'package:maimai/views/main.dart';
export 'dogs.g.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initialiseDogs();
  runApp(const MaiMaiApp());
}

class MaiMaiApp extends StatelessWidget {
  const MaiMaiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'MaiMai',
        theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.indigo, brightness: Brightness.dark),
            useMaterial3: true,
            textTheme: GoogleFonts.nunitoTextTheme()),
        home: MainView());
  }
}