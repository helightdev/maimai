import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:maimai/main.dart';
import 'package:picasso/picasso.dart';
import 'package:http/http.dart' as http;

class ImageSource {

  static Future<SourcedImage> getUrl(String str) async {
    var url = Uri.parse(str);
    var response = await http.get(url);
    var bytes = response.bodyBytes;
    var img = await loadImageFromProvider(MemoryImage(bytes));
    return SourcedImage(bytes, Size(img.width.toDouble(), img.height.toDouble()));
  }

  static Future<SourcedImage> getProvider(ImageProvider provider) async {
    var img = await loadImageFromProvider(provider);
    var data = await img.toByteData(format: ImageByteFormat.png);
    var bytes = data!.buffer.asUint8List();
    return SourcedImage(bytes, Size(img.width.toDouble(), img.height.toDouble()));
  }

  static Future<SourcedImage?> getFile() async {
    var file = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true
    );
    if (file == null) return null;
    var bytes = file.files.first.bytes!;
    var img = await loadImageFromProvider(MemoryImage(bytes));
    return SourcedImage(bytes, Size(img.width.toDouble(), img.height.toDouble()));
  }

  static Future<SourcedImage> getSizedImage(SizedImage image) async {
    var img = await getProvider(image.image);
    return SourcedImage(img.bytes, image.dimensions);
  }
}

class SourcedImage {

  Uint8List bytes;
  Size dimensions;

  SourcedImage(this.bytes, this.dimensions);
}

class ProviderSerializer {

  static String? serialize(ImageProvider provider) {
    if (provider is MemoryImage) {
      return base64Encode(provider.bytes);
    } else if (provider is NetworkImage) {
      return provider.url;
    }
    return null;
  }

  static ImageProvider deserialize(String str) {
    if (str.startsWith("http://") || str.startsWith("https://")) {
      return NetworkImage(str);
    } else {
      return MemoryImage(base64Decode(str));
    }
  }
}