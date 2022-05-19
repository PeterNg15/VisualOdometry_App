import 'dart:io';
import 'package:flutter/material.dart';
// import 'package:flutter_camera/flutter_camera.dart';
import 'package:peter_flutter_camera/peter_flutter_camera.dart';
import 'package:visualodometry_app/storage_service.dart';

/*Resources:
https://www.youtube.com/watch?v=-p9ir46omGo&ab_channel=DestinyEd
*/

class CameraPage extends StatefulWidget {
  const CameraPage({Key? key}) : super(key: key);

  @override
  _CameraPageState createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  @override
  Widget build(BuildContext context) {
    return FlutterCamera(
      color: Color.fromARGB(100, 0, 0, 0),
      onImageCaptured: (value) {
        final path = value.path;
        print("::::::::::::::::::::::::::::::::: $path");
        if (path.contains('.jpg')) {
          showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  content: Image.file(File(path)),
                );
              });
        }
      },
      onVideoRecorded: (value) async {
        final path = value.path;
        final Storage storage = Storage();
        storage.uploadFile(path, value.name).then((value) => print('Done'));
        print('::::::::::::::::::::::::;; dkdkkd $path');

        ///Show video preview .mp4
      },
    );
    // return Container();
  }
}
