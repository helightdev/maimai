import 'package:dogs_core/dogs_core.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:maimai/source/image.dart';
import 'package:picasso/picasso.dart';
import 'package:picasso/src/utils.dart';

class MaiMaiStickerTool extends PicassoTool {
  final String? name;
  final IconData icon;
  final List<SizedImage> presets;

  const MaiMaiStickerTool(
      {this.name, this.icon = Icons.sticky_note_2, required this.presets});

  @override
  PicassoToolDisplay getDisplay(PicassoEditorState state) =>
      PicassoToolDisplay(name ?? state.translations.stickerName, icon);

  @override
  void initialise(BuildContext context, PicassoEditorState state) {
    DefaultAssetBundle.of(context).loadString("assets/stickers.json").then((value) {
      var graph = dogs.jsonSerializer.deserialize(value);
      presets.addAll((dogs.convertIterableFromGraph(graph, SizedImage, IterableKind.list) as List).cast<SizedImage>());
    });
  }

  @override
  void invoke(BuildContext context, PicassoEditorState state) {
    showModalBottomSheet(
        context: context,
        builder: (context) => _StickerDialog(state: state, tool: this));
  }
}

class MaiMaiStickerLayer extends PicassoLayer {
  final SizedImage sticker;

  MaiMaiStickerLayer(this.sticker) : super(renderOutput: true);

  @override
  Widget build(
      BuildContext context, TransformData data, PicassoCanvasState state) {
    return Image(
        image: sticker.image,
        width: sticker.dimensions.width * data.scale,
        height: sticker.dimensions.height * data.scale,
        fit: BoxFit.cover);
  }

  @override
  Size? calculateSize(Size canvas, TransformData data) => Size(
      sticker.dimensions.width * data.scale,
      sticker.dimensions.height * data.scale);
}

class _StickerDialog extends StatelessWidget {
  final MaiMaiStickerTool tool;
  final PicassoEditorState state;

  const _StickerDialog({required this.state, required this.tool});

  Widget buildPresetTile(BuildContext context, int index) {
    var preset = tool.presets[index];
    Widget preview = Image(
        image: preset.image,
        width: 128,
        height: 128,
        fit: BoxFit.contain,
        loadingBuilder: tileImageLoadingBuilder);
    return _StickerTile(
        preview: preview,
        callback: () {
          _add(preset, context);
        });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: SizedBox(
        height: 128,
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: Column(mainAxisAlignment: MainAxisAlignment.center,children: [
               IconButton(onPressed: () async {
                 var file = await ImageSource.getFile();
                 if (file == null) return;
                 var memoryImage = MemoryImage(file.bytes);
                 var img = await loadImageFromProvider(memoryImage);
                 var sizedImage = SizedImage(memoryImage, Size(img.width.toDouble(), img.height.toDouble()));
                 if (context.mounted) _add(sizedImage, context);
               }, icon: const Icon(Icons.upload)),
                IconButton(onPressed: () async {
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
                          var response = await ImageSource.getUrl(str);
                          if (ctx.mounted) {
                            var sizedImage = SizedImage(MemoryImage(response.bytes), response.dimensions);
                            _add(sizedImage, ctx);
                            var i = 0;
                            Navigator.popUntil(ctx, (route) {
                              return ++i == 2;
                            });
                          }
                        },
                      ));
                }, icon: const Icon(Icons.link)),
              ]),
            ),
            Expanded(
              child: ListView.builder(
                key: const ValueKey(#StickerDialogPresetPreview),
                scrollDirection: Axis.horizontal,
                itemBuilder: buildPresetTile,
                itemCount: tool.presets.length,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _add(SizedImage sizedImage, BuildContext context) {
    var layer = MaiMaiStickerLayer(sizedImage);
    var canvasRect =
    Rect.fromPoints(Offset.zero, state.canvas.canvasSizeOffset);
    var transform = scaleToRatioContain(
        canvasRect,
        const TransformData(x: 0, y: 0, scale: 1, rotation: 0),
        layer,
        0.2);
    transform = makeCentered(canvasRect, transform, layer);
    state.canvas.addLayer(layer, transform);
    if (context.mounted) Navigator.pop(context);
  }
}

class _StickerTile extends StatelessWidget {
  final Widget preview;
  final void Function() callback;

  const _StickerTile({Key? key, required this.preview, required this.callback})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: GestureDetector(
        onTap: callback,
        child: Container(
          width: 128,
          height: 128,
          alignment: Alignment.center,
          child: preview,
        ),
      ),
    );
  }
}
