import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image/image.dart' as img;

class MainPage extends StatelessWidget {
  MainPage({super.key});

  final MainGetx getx = Get.put(MainGetx());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Obx(
          () => Text(
            '${getx.xInt.value} / ${getx.xLength.value}',
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: getx.onPick,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class MainGetx extends GetxController {
  RxInt xInt = 0.obs;
  RxInt xLength = 0.obs;

  Future<List<File>> doPick() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['webp'],
      allowMultiple: true,
    );

    if (result != null && result.files.isNotEmpty) {
      List<String> selectedPaths = result.paths.whereType<String>().where((path) => path.toLowerCase().endsWith('.webp')).toList();
      List<File> files = selectedPaths.map((path) => File(path)).toList();
      return files;
    }

    return [];
  }

  Future<Uint8List?> doWebpToPng(File webpFile) async {
    Uint8List bytes = await webpFile.readAsBytes();
    img.Image? image = img.decodeWebP(bytes);
    if (image == null) return null;
    Uint8List pngBytes = img.encodePng(image);
    String newPath = webpFile.path.replaceAll('.webp', '.png');
    File pngFile = File(newPath)..writeAsBytesSync(pngBytes);
    Uint8List uint = await pngFile.readAsBytes();
    return uint;
  }

  Future<File> doSaveImageFile(Uint8List bytes, String filename) async {
    String dirPath = '/storage/emulated/0/Download';
    File file = File('$dirPath/$filename.png');

    await file.writeAsBytes(bytes);
    return file;
  }

  void onPick() async {
    List<File> xListRawData = await doPick();
    xLength.value = xListRawData.length;
    for (int i = 0; i < xListRawData.length; i++) {
      File xFile = xListRawData[i];
      Uint8List? xUint = await doWebpToPng(xFile);
      if (xUint == null) return;
      String xName = DateTime.now().microsecondsSinceEpoch.toString();
      await doSaveImageFile(xUint, xName);
      xInt.value = xInt.value + 1;
    }
    xInt.value = 0;
    xLength.value = 0;
    Get.dialog(
      AlertDialog(
        title: const Text('Convert Done!'),
        actions: [
          ElevatedButton(
            onPressed: Get.back,
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
