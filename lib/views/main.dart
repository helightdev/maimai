import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:dogs_core/dogs_core.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:maimai/main.dart';
import 'package:maimai/tools/sticker.dart';
import 'package:maimai/tools/text.dart';
import 'package:picasso/picasso.dart';
import 'package:uuid/uuid.dart';

import '../source/image.dart';

class MainView extends StatefulWidget {
  MainView({Key? key}) : super(key: key);

  @override
  State<MainView> createState() => _MainViewState();
}

class _MainViewState extends State<MainView> {
  List<MemeTemplate>? templates;

  @override
  void initState() {
    super.initState();
    DefaultAssetBundle.of(context).loadString("assets/templates.json").then((value) {
      setState(() {
        var graph = dogs.jsonSerializer.deserialize(value);
        templates = (dogs.convertIterableFromGraph(graph, MemeTemplate, IterableKind.list) as List).cast<MemeTemplate>();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
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
            ButtonBar(
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
                      if (context.mounted) await _openEditor(img.bytes, context);
                    },
                    child: const Text(
                      "Upload File",
                    )),
              ],
            ),
          ],
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
              if (context.mounted) _openEditor(img.bytes, context, true);
            }
          },
        ));
  }

  SizedBox _buildTemplates(MediaQueryData mq) {
    if (templates == null) {
      return SizedBox(
        width: mq.size.width / 2,
        height: 250,
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
    }

    return SizedBox(
              width: mq.size.width / 2,
              height: 250,
              child: ScrollConfiguration(
                behavior: _ColumnRowScrollBehaviour(),
                child: ListView.builder(
                  itemBuilder: (context, i) =>
                      templates![i].tileImage((p0) async {
                        var img = await ImageSource.getProvider(p0.image.image);
                        if (context.mounted) _openEditor(img.bytes, context, true);
                      }),
                  itemCount: templates!.length,
                  scrollDirection: Axis.horizontal,
                ),
              ));
  }

  Future<void> _openEditor(Uint8List? bytes, BuildContext context,
      [bool useSize = false]) async {
    var img = await loadImageFromProvider(MemoryImage(bytes!));
    var filename = "maimai-${const Uuid().v4()}";

    double width = 1080;
    double height = 1080;
    if (useSize) {
      width = img.width.toDouble();
      height = img.height.toDouble();
    }

    if (context.mounted) {
      showPicassoEditorDialog(
          context: context,
          image: img,
          callback: (output) async {
            await FileSaver.instance.saveFile(
                name: filename,
                ext: "png",
                mimeType: MimeType.png,
                bytes: output.image.asUint8List());
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(
                      "Saved meme as $filename.png in your download folder.")));
            }
          },
          tools: [
            MaiMaiTextTool(
                style: GoogleFonts.anton(
                    color: Colors.white,
                    shadows: TextToolUtils.getBorder(width: 3, blur: 3))),
            MaiMaiStickerTool(presets: List.empty(growable: true))
          ],
          settings: CanvasSettings(width: width, height: height));
    }
  }
}

class _ColumnRowScrollBehaviour extends MaterialScrollBehavior {
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
        width: max((200 / image.dimensions.height) * image.dimensions.width, 200),
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
                    borderRadius: BorderRadius.circular(10)
                ),
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

