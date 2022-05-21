import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:firebase_core/firebase_core.dart' as firebase_core;
import 'dart:io';
import 'package:path/path.dart';

/*Resources:
https://www.youtube.com/watch?v=sM-WMcX66FI&t=608s&ab_channel=MaxonFlutter
*/
class Storage {
  final firebase_storage.FirebaseStorage storage =
      firebase_storage.FirebaseStorage.instance;
  Future<void> uploadFile(String filePath, String fileName) async {
    File file = File(filePath);

    try {
      await storage.ref('video/$fileName').putFile(file);
    } on firebase_core.FirebaseException catch (e) {
      print(e);
    }
  }

  Future<void> uploadCSV(File csvFile, String fileName) async {
    try {
      await storage.ref('orientation/$fileName').putFile(csvFile);
    } on firebase_core.FirebaseException catch (e) {
      print(e);
    }
  }

  Future<firebase_storage.ListResult> listFiles() async {
    firebase_storage.ListResult results = await storage.ref('video').listAll();

    results.items.forEach((firebase_storage.Reference ref) {
      print('Found file: $ref');
    });
    return results;
  }
}
