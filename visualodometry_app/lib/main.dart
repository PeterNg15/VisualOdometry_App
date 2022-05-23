import 'dart:html' as html;

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:visualodometry_app/camera_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:motion_sensors/motion_sensors.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;
import 'package:flutter/foundation.dart'
    show consolidateHttpClientResponseBytes, kIsWeb;
import 'package:visualodometry_app/storage_service.dart';

import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:intl/intl.dart';

import 'dart:js' as js;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (!kIsWeb) {
    runApp(const App());
  } else {
    runApp(const Web());
  }
}

class Web extends StatelessWidget {
  // ignore: use_key_in_widget_constructors
  const Web();

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Computer Vision Laboratory',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MyWeb(),
    );
    //return const MaterialApp(home: MyWeb());
  }
}

class MyWeb extends StatefulWidget {
  // ignore: use_key_in_widget_constructors
  const MyWeb();

  @override
  State<MyWeb> createState() => _MyWebState();
}

class _MyWebState extends State<MyWeb> {
  final Storage storage = Storage();

  /*Get list of files*/
  late Future<Future<ListResult>> futureFiles;
  late Future<ListResult> futureVidFiles;
  late Future<ListResult> futureCSVFiles;

  @override
  void initState() {
    super.initState();
    futureVidFiles = FirebaseStorage.instance.ref('video').listAll();
    futureCSVFiles = FirebaseStorage.instance.ref('orientation').listAll();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Computer Vision Laboratory'),
          backgroundColor: Colors.redAccent,
        ),
        body: FutureBuilder<ListResult>(
            future: futureVidFiles,
            builder: ((context, snapshot) {
              if (snapshot.hasData) {
                final files = snapshot.data!.items;
                return ListView.builder(
                  itemCount: files.length,
                  itemBuilder: (context, index) {
                    final file = files[index];
                    DateTime fileDate = DateTime.now();
                    file.getMetadata().then((value) {
                      fileDate = value.timeCreated!;
                    });
                    return ListTile(
                      ///title: Text(
                      ///DateFormat('dd MMMM yyyy, h:mm:ss').format(fileDate)),
                      title: Text(file.name),
                      trailing: IconButton(
                          icon: const Icon(
                            Icons.download,
                            color: Colors.black,
                          ), //downloadFile(file),
                          onPressed: () async {
                            await downloadFile(file);
                          }),
                    );
                  },
                );
              } else if (snapshot.hasError) {
                return const Center(child: Text("Error"));
              } else {
                return const Center(child: CircularProgressIndicator());
              }
            })));
  }
}

Future<void> downloadFile(Reference ref) async {
  // 1) set url
  String downloadURL = await firebase_storage.FirebaseStorage.instance
      .ref(ref.fullPath.toString())
      .getDownloadURL();
  // 2) request
  // html.AnchorElement anchorElement =
  //     html.AnchorElement(href: downloadURL, target = "_blank");
  // anchorElement.download = downloadURL;
  // anchorElement.click();

  js.context.callMethod('open', [downloadURL]);
}

/*APP*/

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: MyApp());
  }
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  //Variables for the sensor
  Vector3 _accelerometer = Vector3.zero();
  Vector3 _magnetometer = Vector3.zero();
  Vector3 _userAaccelerometer = Vector3.zero();
  Vector3 _gyroscope = Vector3.zero();
  Vector3 _orientation = Vector3.zero();
  Vector3 _absoluteOrientation = Vector3.zero();
  Vector3 _absoluteOrientation2 = Vector3.zero();
  double? _screenOrientation = 0;

  int? _groupValue = 3;
  int? _currInterval = 16666;

  @override
  //Functions for sensor
  void initState() {
    super.initState();
    motionSensors.gyroscope.listen((GyroscopeEvent event) {
      setState(() {
        _gyroscope.setValues(event.x, event.y, event.z);
      });
    });
    motionSensors.accelerometer.listen((AccelerometerEvent event) {
      setState(() {
        _accelerometer.setValues(event.x, event.y, event.z);
      });
    });
    motionSensors.userAccelerometer.listen((UserAccelerometerEvent event) {
      setState(() {
        _userAaccelerometer.setValues(event.x, event.y, event.z);
      });
    });
    motionSensors.magnetometer.listen((MagnetometerEvent event) {
      setState(() {
        _magnetometer.setValues(event.x, event.y, event.z);
        var matrix =
            motionSensors.getRotationMatrix(_accelerometer, _magnetometer);
        _absoluteOrientation2.setFrom(motionSensors.getOrientation(matrix));
      });
    });
    motionSensors.isOrientationAvailable().then((available) {
      if (available) {
        motionSensors.orientation.listen((OrientationEvent event) {
          setState(() {
            _orientation.setValues(event.yaw, event.pitch, event.roll);
          });
        });
      }
    });
    motionSensors.absoluteOrientation.listen((AbsoluteOrientationEvent event) {
      setState(() {
        _absoluteOrientation.setValues(event.yaw, event.pitch, event.roll);
      });
    });
    motionSensors.screenOrientation.listen((ScreenOrientationEvent event) {
      setState(() {
        _screenOrientation = event.angle;
      });
    });
  }

  void setUpdateInterval(int? groupValue, int interval) {
    motionSensors.accelerometerUpdateInterval = interval;
    motionSensors.userAccelerometerUpdateInterval = interval;
    motionSensors.magnetometerUpdateInterval = interval;
    motionSensors.gyroscopeUpdateInterval = interval;
    motionSensors.orientationUpdateInterval = interval;
    motionSensors.absoluteOrientationUpdateInterval = interval;
    setState(() {
      _groupValue = groupValue;
      _currInterval = interval;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Computer Vision Laboratory'),
        backgroundColor: Colors.redAccent,
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('Refresh Rate'),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Radio(
                  value: 1,
                  groupValue: _groupValue,
                  onChanged: (dynamic value) => setUpdateInterval(
                      value, Duration.microsecondsPerSecond ~/ 1),
                ),
                const Text("1 FPS"),
                Radio(
                  value: 2,
                  groupValue: _groupValue,
                  onChanged: (dynamic value) => setUpdateInterval(
                      value, Duration.microsecondsPerSecond ~/ 30),
                ),
                const Text("30 FPS"),
                Radio(
                  value: 3,
                  groupValue: _groupValue,
                  onChanged: (dynamic value) => setUpdateInterval(
                      value, Duration.microsecondsPerSecond ~/ 60),
                ),
                const Text("60 FPS"),
              ],
            ),
            const Text('Gyroscope'),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                Text(_gyroscope.x.toStringAsFixed(4)),
                Text(_gyroscope.y.toStringAsFixed(4)),
                Text(_gyroscope.z.toStringAsFixed(4)),
              ],
            ),
            const Text('Orientation'),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                Text(degrees(_orientation.x).toStringAsFixed(4)),
                Text(degrees(_orientation.y).toStringAsFixed(4)),
                Text(degrees(_orientation.z).toStringAsFixed(4)),
              ],
            ),
            const Text('Absolute Orientation'),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                Text(degrees(_absoluteOrientation.x).toStringAsFixed(4)),
                Text(degrees(_absoluteOrientation.y).toStringAsFixed(4)),
                Text(degrees(_absoluteOrientation.z).toStringAsFixed(4)),
              ],
            ),
            const Text('Orientation (accelerometer + magnetometer)'),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                Text(degrees(_absoluteOrientation2.x).toStringAsFixed(4)),
                Text(degrees(_absoluteOrientation2.y).toStringAsFixed(4)),
                Text(degrees(_absoluteOrientation2.z).toStringAsFixed(4)),
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Navigator.push(
          //     context,
          //     CupertinoPageRoute(builder: (context) => const CameraPage()));
          _currInterval = (_currInterval == 0 || _currInterval == null
              ? 16666
              : _currInterval);
          _groupValue =
              (_groupValue == 0 || _groupValue == null ? 3 : _groupValue);
          Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => CameraPage(
                  groupValue: _groupValue!, interval: _currInterval!)));
        },
        label: const Text('Capture Video'),
      ),
    );
  }
}
