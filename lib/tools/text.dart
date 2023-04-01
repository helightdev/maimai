import 'dart:async';

import 'package:duffer/duffer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:picasso/picasso.dart';

class MaiMaiTextTool extends PicassoTool {
  final String? name;
  final IconData icon;
  final TextStyle? style;

  const MaiMaiTextTool({this.name,
    this.icon = Icons.text_fields,
    this.style = const TextStyle(
        color: Colors.white, shadows: TextToolUtils.impactOutline)});

  @override
  PicassoToolDisplay getDisplay(PicassoEditorState state) =>
      PicassoToolDisplay(name ?? state.translations.textName, icon);

  @override
  void initialise(BuildContext context, PicassoEditorState state) {}


  @override
  void lateInitialise(BuildContext context, PicassoEditorState state) {
    state.canvas.findLayersOfType<MaiMaiTextLayer>().forEach((element) {
      element.associatedTool = this;
      element.setDirty(state.canvas);
    });
  }

  @override
  void invoke(BuildContext context, PicassoEditorState state) {
    requestText(context, state).then((value) {
      if (value.$1.replaceAll(" ", "") == "") return;
      var layer = MaiMaiTextLayer(value.$1, value.$2, this, true);
      var transform = makeCentered(state.canvas.rect,
          const TransformData(x: 0, y: 0, scale: 2, rotation: 0), layer);
      state.canvas.addLayer(layer, transform);
    });
  }

  Future<(String, TextStyle)> requestText(BuildContext context,
      PicassoEditorState state,
      [String? initialText]) async {
    var completer = Completer();
    var style = this.style ?? const TextStyle();
    var controller = TextEditingController(text: initialText);
    var mq = MediaQuery.of(context);
    state.widget.dialogFactory.showDialog(context, (context) =>
        StatefulBuilder(
            builder: (context, setState) {
              return KeyboardListener(
                focusNode: FocusNode(),
                onKeyEvent: (event) {
                  if (event is KeyDownEvent) {
                    if (event.logicalKey == LogicalKeyboardKey.enter) {
                      if (RawKeyboard.instance.keysPressed.contains(
                          LogicalKeyboardKey.altLeft)) {
                        completer.complete();
                        Navigator.pop(context);
                      }
                    }
                  }
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      onSubmitted: (string) {
                        completer.complete();
                        Navigator.pop(context);
                      },
                      autofocus: true,
                      minLines: 1,
                      maxLines: 10,
                      controller: controller,
                      decoration: InputDecoration(
                          prefix: const SizedBox(width: 16,),
                          suffix: Padding(
                            padding: const EdgeInsets.only(right: 16.0),
                            child: IconButton(onPressed: () {
                              completer.complete();
                              Navigator.pop(context);
                            }, icon: const Icon(Icons.format_paint)),
                          )
                      ),
                      style: style,
                    ),
                    Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Builder(builder: (context) {
                          var widgets = [
                            _buildColorNodes(context, style, (p0) =>
                                setState(() {
                                  style = p0;
                                }), mq.orientation),
                            _buildFontFeatureNodes(context, style, (p0) =>
                                setState(() {
                                  style = p0;
                                }), mq.orientation)
                          ];
                          if (mq.orientation == Orientation.landscape) {
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: widgets,
                            );
                          } else {
                            return Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: widgets,
                            );
                          }
                        })
                    )
                  ],
                ),
              );
            }
        ));
    await completer.future;
    return (controller.text, style);
  }

  Widget _buildColorNodes(BuildContext context, TextStyle style,
      Function(TextStyle) setStyle, Orientation orientation) {
    return Row(
      mainAxisAlignment: orientation == Orientation.landscape
          ? MainAxisAlignment.start
          : MainAxisAlignment.center,
      children: [
        IconButton(onPressed: () {
          setStyle(style.copyWith(color: Colors.white,
              shadows: TextToolUtils.getBorder(width: 3, blur: 3)));
        }, icon: Container(width: 24, height: 24, decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(90)
        ),)),
        IconButton(onPressed: () {
          setStyle(style.copyWith(color: Colors.black, shadows: []));
        }, icon: Container(width: 24, height: 24, decoration: BoxDecoration(
            color: Colors.black, borderRadius: BorderRadius.circular(90)
        ),)),
        IconButton(onPressed: () {
          setStyle(style.copyWith(color: Colors.red,
              shadows: TextToolUtils.getBorder(width: 3, blur: 3)));
        }, icon: Container(width: 24, height: 24, decoration: BoxDecoration(
            color: Colors.red, borderRadius: BorderRadius.circular(90)
        ),)),
        IconButton(onPressed: () {
          setStyle(style.copyWith(color: Colors.green,
              shadows: TextToolUtils.getBorder(width: 3, blur: 3)));
        }, icon: Container(width: 24, height: 24, decoration: BoxDecoration(
            color: Colors.green, borderRadius: BorderRadius.circular(90)
        ),)),
        IconButton(onPressed: () {
          setStyle(style.copyWith(color: Colors.blue,
              shadows: TextToolUtils.getBorder(width: 3, blur: 3)));
        }, icon: Container(width: 24, height: 24, decoration: BoxDecoration(
            color: Colors.blue, borderRadius: BorderRadius.circular(90)
        ),)),
        IconButton(onPressed: () {
          setStyle(style.copyWith(color: Colors.yellow,
              shadows: TextToolUtils.getBorder(width: 3, blur: 3)));
        }, icon: Container(width: 24, height: 24, decoration: BoxDecoration(
            color: Colors.yellow, borderRadius: BorderRadius.circular(90)
        ),)),
        IconButton(onPressed: () {
          var pickerStyle = style;
          showDialog(
            context: context,
            builder: (context) =>
                AlertDialog(
                  title: const Text('Pick a text color',
                    style: TextStyle(color: Colors.white),),
                  content: SingleChildScrollView(
                    child: Theme(
                      data: ThemeData.dark(useMaterial3: true),
                      child: ColorPicker(
                        pickerColor: pickerStyle.color!,
                        enableAlpha: false,
                        onColorChanged: (color) {
                          pickerStyle = pickerStyle.copyWith(color: color,
                              shadows: color.computeLuminance() >= 0.3
                                  ? TextToolUtils.getBorder(width: 3, blur: 3)
                                  : []);
                        },
                      ),
                    ),
                  ),
                  actions: <Widget>[
                    ElevatedButton(
                      child: const Text('Done'),
                      onPressed: () {
                        setStyle(pickerStyle);
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
          );
        }, icon: const Icon(Icons.colorize))
      ],
    );
  }

  Widget _buildFontFeatureNodes(BuildContext context, TextStyle style,
      Function(TextStyle) setStyle, Orientation orientation) {
    return Row(
      mainAxisAlignment: orientation == Orientation.landscape
          ? MainAxisAlignment.start
          : MainAxisAlignment.center,
      children: [
        ChoiceChip(onSelected: (val) {
          setStyle(style.copyWith(
              fontWeight: val ? FontWeight.bold : FontWeight.normal));
        },
          label: const Text("bold", style: TextStyle(
              fontWeight: FontWeight.bold, color: Colors.white),),
          selected: style.fontWeight == FontWeight.bold,),
        const SizedBox(width: 8,),
        ChoiceChip(onSelected: (val) {
          setStyle(style.copyWith(
              fontStyle: val ? FontStyle.italic : FontStyle.normal));
        },
          label: const Text("italic", style: TextStyle(
              fontStyle: FontStyle.italic, color: Colors.white),),
          selected: style.fontStyle == FontStyle.italic,),
        const SizedBox(width: 8,),
        ChoiceChip(onSelected: (val) {
          setStyle(style.copyWith(
              shadows: val ? TextToolUtils.getBorder(width: 3, blur: 3) : []));
        },
          label: const Text("shadows", style: TextStyle(color: Colors.white,),),
          selected: style.shadows?.isNotEmpty ?? false,),
      ],
    );
  }
}

class MaiMaiTextLayerSerializer extends PicassoLayerSerializer {
  MaiMaiTextLayerSerializer() : super("maimai:text");

  @override
  bool check(PicassoLayer layer) => layer is MaiMaiTextLayer;

  @override
  FutureOr<PicassoLayer> deserialize(ByteBuf buf, PicassoCanvasState state,
      PicassoEditorState? editorState) {
    var text = buf.readLPString();
    var style = buf.readTextStyle();
    return MaiMaiTextLayer(text, style, null, true);
  }

  @override
  FutureOr<void> serialize(PicassoLayer layer, ByteBuf buf,
      PicassoCanvasState state) {
    var textLayer = layer as MaiMaiTextLayer;
    buf.writeLPString(textLayer.text);
    buf.writeTextStyle(textLayer.style ?? const TextStyle());
  }

}

class MaiMaiTextLayer extends PicassoLayer {
  final MaiMaiTextTool? tool;
  final bool editable;

  TextStyle? style;
  String text;

  MaiMaiTextLayer(this.text, this.style, this.tool, this.editable)
      : super(
      flags: LayerFlags.presetDefault ^ (editable ? 0 : LayerFlags.tappable));

  @override
  Size? calculateSize(Size canvas, TransformData data) =>
      TextToolUtils.calculateSize(text, style, data);

  @override
  Widget build(BuildContext context, TransformData data,
      PicassoCanvasState state) {
    return Text(
      text,
      style: style,
      textScaleFactor: data.scale,
      textAlign: TextAlign.center,
    );
  }

  @override
  void onTap(BuildContext context, TransformData data,
      PicassoCanvasState state) async {
    if (tool == null) return;
    var newText = await tool!.requestText(
        context, state.context.findAncestorStateOfType<PicassoEditorState>()!,
        text);
    text = newText.$1;
    style = newText.$2;
    setDirty(state);
  }
}
