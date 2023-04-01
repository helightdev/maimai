import 'dart:async';
import 'dart:io';

import 'package:duffer/duffer.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:maimai/bloc/project.dart';
import 'package:maimai/main.dart';
import 'package:maimai/tools/text.dart';
import 'package:path_provider/path_provider.dart';
import 'package:picasso/picasso.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:path/path.dart' as path;

import '../tools/sticker.dart';

class MaiMaiEditor extends StatelessWidget {
  final SizedImage image;
  final Size? dimensionOverrides;
  final CanvasSaveData? save;
  final String id;
  String? fileName;

  MaiMaiEditor(
      {required this.id,
      this.fileName,
      this.save,
      required this.image,
      this.dimensionOverrides,
      super.key});

  GlobalKey<PicassoEditorState> editorKey = GlobalKey();
  GlobalKey<ScaffoldState> scaffoldKey = GlobalKey();

  bool isExiting = false;

  FocusNode shortcutNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    var dimensions = dimensionOverrides ?? image.dimensions;
    var mq = MediaQuery.of(context);
    var theme = Theme.of(context);
    return WillPopScope(
      onWillPop: () async {
        if (scaffoldKey.currentState!.isDrawerOpen) {
          scaffoldKey.currentState!.closeDrawer();
        } else {
          scaffoldKey.currentState!.openDrawer();
        }
        return false;
      },
      child: Focus(
        focusNode: shortcutNode,
        autofocus: true,
        onKeyEvent: (result,event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.escape) {
              if (scaffoldKey.currentState!.isDrawerOpen) {
                scaffoldKey.currentState!.closeDrawer();
              } else {
                scaffoldKey.currentState!.openDrawer();
              }
            }

            if (event.physicalKey == PhysicalKeyboardKey.keyI) {
              editorKey.currentState!.tools
                  .firstWhere((element) => element is ImageTool)
                  .invoke(context, editorKey.currentState!);
            } else if (event.physicalKey == PhysicalKeyboardKey.keyL) {
              editorKey.currentState!.tools
                  .firstWhere((element) => element is LayersTool)
                  .invoke(context, editorKey.currentState!);
            } else if (event.physicalKey == PhysicalKeyboardKey.keyT) {
              editorKey.currentState!.tools
                  .firstWhere((element) => element is MaiMaiTextTool)
                  .invoke(context, editorKey.currentState!);
            } else if (event.physicalKey == PhysicalKeyboardKey.keyS) {
              editorKey.currentState!.tools
                  .firstWhere((element) => element is MaiMaiStickerTool)
                  .invoke(editorKey.currentContext!, editorKey.currentState!);
            }
          }
          return KeyEventResult.handled;
        },
        child: Scaffold(
          key: scaffoldKey,
          resizeToAvoidBottomInset: false,
          drawer: _buildDrawer(context, theme),
          body: SizedBox(
            width: mq.size.width,
            height: mq.size.height,
            child: Builder(builder: (context) {
              return PicassoEditor(
                key: editorKey,
                saveData: save,
                settings: CanvasSettings(
                    width: dimensions.width, height: dimensions.height),
                tools: [
                  ImageTool(image),
                  LayersTool(),
                  MaiMaiTextTool(
                      style: GoogleFonts.anton(
                          color: Colors.white,
                          shadows: TextToolUtils.getBorder(width: 3, blur: 3))),
                  MaiMaiStickerTool(presets: List.empty(growable: true))
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  ListTileTheme _buildDrawer(BuildContext context, ThemeData theme) {
    var titleSmall = theme.textTheme.titleSmall?.copyWith(color: Colors.white);
    var titleLarge = theme.textTheme.titleLarge?.copyWith(color: Colors.white);
    return ListTileTheme(
      data: ListTileTheme.of(context).copyWith(titleTextStyle: titleSmall),
      child: Drawer(
        child: Builder(builder: (ctx) {
          return StatefulBuilder(
            builder: (context,setState) {
              var canvas = editorKey.currentState!.canvas;
              var snapPosition = canvas.widget.settings.snapPosition;
              var layerPromotion = canvas.widget.settings.layerPromotion;
              return Column(
                children: [
                  DrawerHeader(
                      child: Column(
                    children: [
                      Text(
                        "MaiMai Editor",
                        style: titleLarge,
                      ),
                      Text(
                        "by HelightDev",
                        style: titleSmall,
                      ),
                      const Spacer(),
                      buildGithubLink(titleSmall, theme)
                    ],
                  )),
                  ListTile(
                    leading: const Icon(Icons.save),
                    title: const Text("Save Project"),
                    onTap: () async {
                      await saveEditor(context);
                      scaffoldKey.currentState!.closeDrawer();
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                          content: Text(
                            "Saved project as $fileName at Documents/maimai",
                            style: const TextStyle(color: Colors.white),
                          ),
                          backgroundColor: Colors.indigo,
                        ));
                      }
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.ios_share),
                    title: const Text("Export Project"),
                    onTap: () async {
                      Navigator.pop(ctx);
                      try {
                        var state = editorKey.currentState!;
                        var output = await state.canvas.getRenderOutput();
                        if (context.mounted) {
                          await onRenderOutput(context, output);
                          if (context.mounted) Navigator.pop(context);
                        }
                      } catch (e, st) {
                        showErrorBanner(context, e, st);
                      }
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.menu_open),
                    title: const Text("Return To Menu"),
                    onTap: () async {
                      BlocProvider.of<ProjectCubit>(context, listen: false).load();
                      Navigator.pop(ctx);
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.delete_outline),
                    title: const Text("Delete Project"),
                    onTap: () async {
                      var cubit =
                          BlocProvider.of<ProjectCubit>(context, listen: false);
                      var documents = await getApplicationDocumentsDirectory();
                      var maimai = Directory(path.join(documents.path, "maimai"));
                      if (fileName != null) {
                        var file = File(path.join(maimai.path, fileName));
                        file.deleteSync();
                      }
                      cubit.load();
                      if (context.mounted) {
                        Navigator.pop(ctx);
                        Navigator.pop(context);
                      }
                    },
                  ),
                  Spacer(),
                  Divider(),
                  ListTile(
                    leading: const Icon(Icons.grid_4x4),
                    title: const Text("Snap To Grid"),
                    selected: snapPosition,
                    onTap: () {
                      canvas.widget.settings.snapPosition = !snapPosition;
                      canvas.scheduleRebuild();
                      setState(() {});
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.arrow_upward),
                    title: const Text("Promote Layers"),
                    selected: layerPromotion,
                    onTap: () {
                      canvas.widget.settings.layerPromotion = !layerPromotion;
                      canvas.scheduleRebuild();
                      setState(() {});
                    },
                  )
                ],
              );
            }
          );
        }),
      ),
    );
  }

  Future<ByteBuf> saveEditor(BuildContext context) async {
    try {
      if (fileName == null) {
        var name = await promptFileName(context);
        if (!name.endsWith(".bin")) name = "$name.bin";
        fileName = name;
      }

      var documents = await getApplicationDocumentsDirectory();
      var maimai = Directory(path.join(documents.path, "maimai"));
      var file = File(path.join(maimai.path, fileName));

      var dimensions = dimensionOverrides ?? image.dimensions;
      var byteBuf = Unpooled.buffer();
      byteBuf.writeLPString(id);
      byteBuf.writeSize(dimensions);
      await byteBuf.writeSizedImage(image);
      var saveData =
          await PicassoSaveSystem.instance.save(editorKey.currentState!.canvas);
      byteBuf.writeLPBuffer(saveData);

      byteBuf.markReaderIndex();
      await file.writeAsBytes(byteBuf.readAvailableBytes(), flush: true);
      byteBuf.resetReaderIndex();
      return byteBuf;
    } catch (e, st) {
      showErrorBanner(context, e, st);
      return Unpooled.fixed(0);
    }
  }

  Future<String> promptFileName(BuildContext context) {
    var completer = Completer<String>();
    showModalBottomSheet(
        context: context,
        builder: (ctx) => TextField(
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              controller: TextEditingController(text: "$id.bin"),
              decoration: const InputDecoration(
                  prefix: Padding(
                padding: EdgeInsets.only(left: 16.0),
                child:
                    Text("File Name: ", style: TextStyle(color: Colors.white)),
              )),
              onSubmitted: (str) async {
                completer.complete(str);
                Navigator.pop(ctx);
              },
            ));
    return completer.future;
  }

  Future onRenderOutput(BuildContext context, RenderOutput output) async {
    var filename = "maimai-$id";
    await FileSaver.instance.saveFile(
        name: filename,
        ext: "png",
        mimeType: MimeType.png,
        bytes: output.image.readAvailableBytes());
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Saved meme as $filename.png in your download folder.",
            style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.indigo,
      ));
    }
  }
}

MouseRegion buildGithubLink(TextStyle? titleSmall, ThemeData theme) {
  return MouseRegion(
    cursor: SystemMouseCursors.click,
    child: GestureDetector(
      onTap: () {
        launchUrlString("https://github.com/helightdev/maimai");
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset("assets/github-mark-white.svg",
              width: 16, height: 16),
          const SizedBox(
            width: 8,
          ),
          Text(
            "Star me on GitHub!",
            style: titleSmall?.copyWith(
                color: theme.colorScheme.primary),
          )
        ],
      ),
    ),
  );
}