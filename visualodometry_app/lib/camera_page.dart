import 'dart:io';

import 'package:flutter/material.dart';
// import 'package:flutter_camera/flutter_camera.dart';
import 'package:peter_flutter_camera/peter_flutter_camera.dart';
import 'package:visualodometry_app/storage_service.dart';

/*Resources:
https://www.youtube.com/watch?v=-p9ir46omGo&ab_channel=DestinyEd
*/

//ignore: must_be_immutable
class CameraPage extends StatefulWidget {
  int interval;
  int groupValue;
  CameraPage({Key? key, required this.interval, required this.groupValue})
      : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _CameraPageState createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  //Variables for the sensor
  @override
  Widget build(BuildContext context) {
    return FlutterCamera(
      //Sensor
      interval: widget.interval,
      groupValue: widget.groupValue,
      //Camera stuff
      color: const Color.fromARGB(104, 0, 0, 0),
      onVideoRecorded: (value, csvPath) async {
        final path = value.path;
        final Storage storage = Storage();
        storage.uploadFile(path, value.name);
        //dispose();
      },
    );
    // return Container();
  }
}
