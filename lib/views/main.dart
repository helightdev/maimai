import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:duffer/duffer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:maimai/bloc/project.dart';
import 'package:maimai/bloc/templates.dart';
import 'package:maimai/main.dart';
import 'package:maimai/views/mai_mai_editor.dart';
import 'package:picasso/picasso.dart';
import 'package:uuid/uuid.dart';

import '../source/image.dart';

class MainView extends StatefulWidget {
  const MainView({Key? key}) : super(key: key);

  @override
  State<MainView> createState() => _MainViewState();
}

class _MainViewState extends State<MainView> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var mq = MediaQuery.of(context);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("MaiMai",
                style: GoogleFonts.anton(
                    fontWeight: FontWeight.bold,
                    fontSize: 128,
                    color: Colors.white,
                    shadows: TextToolUtils.getBorder(width: 3, blur: 3))),
            _buildTemplates(mq),
            _buildSaveList(mq),
            const SizedBox(height: 8),
            _buildButtons(context),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("MaiMai Editor by HelightDev", style: TextStyle(color: Colors.white),),

            buildGithubLink(const TextStyle(color: Colors.white), Theme.of(context))
          ],
        ),
      )
    );
  }

  ButtonBar _buildButtons(BuildContext context) {
    return ButtonBar(
      alignment: MainAxisAlignment.center,
      children: [
        FilledButton(
            onPressed: () {
              _fromUrl(context);
            },
            child: const Text(
              "Load from URL",
            )),
        FilledButton(
            onPressed: () async {
              var img = await ImageSource.getFile();
              if (img == null) return;
              if (context.mounted) loadEditorBytes(img.bytes, context);
            },
            child: const Text(
              "Upload File",
            )),
      ],
    );
  }

  Widget _buildSaveList(MediaQueryData mq) {
    return BlocBuilder<ProjectCubit, ProjectCubitState>(
        builder: (context, snapshot) {
      if (!snapshot.isLoaded) {
        return const SizedBox(
          height: 32,
          child: Center(
            child: CircularProgressIndicator(),
          ),
        );
      }
      return SizedBox(
        width: mq.size.width,
        height: 32,
        child: ScrollConfiguration(
          behavior: ColumnRowScrollBehaviour(),
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              const SizedBox(width: 16,),
              ...snapshot.files
                  .map((e) => _buildFileButton(e, context))
                  .toList()
            ],
          ),
        ),
      );
    });
  }

  Padding _buildFileButton(File e, BuildContext context) {
    var actualName = e.path.split("/").last.split("\\").last;
    var fileName = actualName.split(".").first;
    return Padding(
      padding: const EdgeInsets.only(left: 16.0),
      child: SizedBox(
        height: 32,
        child: ElevatedButton.icon(
          onPressed: () async {
            var bytes = await e.readAsBytes();
            if (context.mounted) {
              loadEditorSave(context, bytes.asWrappedBuffer, actualName);
            }
          },
          label: Text(fileName),
          icon: const Icon(Icons.image),
        ),
      ),
    );
  }

  void _fromUrl(BuildContext context) {
    showModalBottomSheet(
        context: context,
        builder: (ctx) => TextField(
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                  prefix: Padding(
                padding: EdgeInsets.only(left: 16.0),
                child: Text("URL: "),
              )),
              onSubmitted: (str) async {
                var img = await ImageSource.getUrl(str);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  if (context.mounted) loadEditorBytes(img.bytes, context);
                }
              },
            ));
  }

  SizedBox _buildTemplates(MediaQueryData mq) => SizedBox(
      width: mq.size.width,
      height: 250,
      child: ScrollConfiguration(
        behavior: ColumnRowScrollBehaviour(),
        child: BlocBuilder<TemplateCubit, TemplateCubitState>(
          builder: (context, state) {
            if (!state.isLoaded) {
              return SizedBox(
                width: mq.size.width / 2,
                height: 250,
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            return ListView.builder(
              itemBuilder: (context, i) =>
                  state.templates[i].tileImage((p0) async {
                var img = await ImageSource.getProvider(p0.image.image);
                if (context.mounted) {
                  loadEditorBytes(img.bytes, context, doPromptCrop: false);
                }
              }),
              itemCount: state.templates.length,
              scrollDirection: Axis.horizontal,
            );
          },
        ),
      ));
}

class ColumnRowScrollBehaviour extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
      };
}

extension MemeTemplateExt on MemeTemplate {
  Widget tileImage(Function(MemeTemplate) callback) {
    return Padding(
      padding: const EdgeInsets.only(right: 16.0),
      child: SizedBox(
        width:
            max((200 / image.dimensions.height) * image.dimensions.width, 200),
        child: GestureDetector(
          onTap: () {
            callback(this);
          },
          child: Column(
            children: [
              Card(
                semanticContainer: true,
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                elevation: 5,
                margin: const EdgeInsets.all(10),
                child: Image(
                  image: image.image,
                  fit: BoxFit.fitHeight,
                  height: 200,
                ),
              ),
              Text(
                name,
                style: const TextStyle(color: Colors.white),
              )
            ],
          ),
        ),
      ),
    );
  }
}

void promptCrop(BuildContext context, Function(bool) callback) {
  showDialog(
      context: context,
      builder: (context) => AlertDialog(
            title: const Text(
              "Crop Image",
              style: TextStyle(color: Colors.white),
            ),
            content: const Text(
                "Do you want to crop the image or retain its original size?",
                style: TextStyle(color: Colors.white)),
            actions: [
              TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    callback(true);
                  },
                  child: const Text("Crop to square")),
              TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    callback(false);
                  },
                  child: const Text("Keep current size"))
            ],
          ));
}

void loadEditorSave(BuildContext context, ByteBuf buf, String fileName) {
  var id = buf.readLPString();
  var dimensions = buf.readSize();
  var image = buf.readSizedImage();
  var buffer = buf.readLPBuffer();
  var save = PicassoSaveSystem.instance.load(buffer);
  showDialog(
      context: context,
      builder: (context) => MaiMaiEditor(
          id: id,
          image: image,
          fileName: fileName,
          dimensionOverrides: dimensions,
          save: save));
}

void loadEditorBytes(Uint8List? bytes, BuildContext context,
    {bool doPromptCrop = true}) async {
  var provider = MemoryImage(bytes!);
  var id = const Uuid().v4();
  var img = await loadImageFromProvider(provider);
  if (context.mounted) {
    if (doPromptCrop) {
      promptCrop(context, (crop) {
        showDialog(
            context: context,
            builder: (context) {
              var imgSize = Size(img.width.toDouble(), img.height.toDouble());
              var squareSize = const Size(1080, 1080);
              return MaiMaiEditor(
                image: SizedImage(provider, imgSize),
                dimensionOverrides: crop ? squareSize : imgSize,
                save: null,
                id: id,
              );
            });
      });
    } else {
      showDialog(
          context: context,
          builder: (context) {
            var imgSize = Size(img.width.toDouble(), img.height.toDouble());
            return MaiMaiEditor(
              image: SizedImage(provider, imgSize),
              dimensionOverrides: imgSize,
              save: null,
              id: id,
            );
          });
    }
  }
}
