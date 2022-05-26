import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:visualodometry_app/camera_page.dart';
import 'firebase_options.dart';
import 'package:motion_sensors/motion_sensors.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:visualodometry_app/storage_service.dart';

import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:firebase_database/firebase_database.dart' as firebase_database;
import 'package:firebase_core/firebase_core.dart';

import 'package:url_launcher/url_launcher.dart' as launcher;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
    runApp(const Web());
  } else {
    await Firebase.initializeApp(
        name: 'from_main', options: DefaultFirebaseOptions.currentPlatform);
    runApp(const App());
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
      debugShowCheckedModeBanner: false,
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

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final dbRef = firebase_database.FirebaseDatabase.instance;
    return Scaffold(
        appBar: AppBar(
          title: const Text('Computer Vision Laboratory'),
          backgroundColor: Colors.redAccent,
        ),
        body: SafeArea(
            child: FirebaseAnimatedList(
                query: dbRef.ref("files").orderByChild('Order'),
                itemBuilder: (BuildContext context,
                    firebase_database.DataSnapshot snapshot,
                    Animation<double> animation,
                    int index) {
                  var value = Map<String, dynamic>.from(snapshot.value as Map);
                  return ListTile(
                    subtitle: Text(value['FileName']),
                    title: Text(value['TimeCreated']),
                    trailing:
                        Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
                      IconButton(
                          icon: const Icon(
                            Icons.video_file,
                            color: Colors.black,
                          ),
                          onPressed: () async {
                            await downloadFile(value['FileName'], [1, 0]);
                          }),
                      IconButton(
                          icon: const Icon(
                            Icons.description,
                            color: Colors.black,
                          ),
                          onPressed: () async {
                            await downloadFile(value['FileName'], [0, 1]);
                          }),
                      IconButton(
                          icon: const Icon(
                            Icons.download,
                            color: Colors.black,
                          ),
                          onPressed: () async {
                            await downloadFile(value['FileName'], [1, 1]);
                          }),
                      IconButton(
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.black,
                          ),
                          onPressed: () async {
                            //delete file from database and storage
                            await deleteFile(value['FileName'], snapshot.key);
                          }),
                    ]),
                  );
                })));
  }
}

Future<void> downloadFile(String fileName, List<int> downloadType) async {
  String downloadURL = await firebase_storage.FirebaseStorage.instance
      .ref("video/$fileName.mp4")
      .getDownloadURL();

  String downloadCSVURL = await firebase_storage.FirebaseStorage.instance
      .ref("orientation/$fileName.csv")
      .getDownloadURL();

  if (downloadType[0] == 1) {
    //Video
    await launcher.launch(downloadURL);
  }
  if (downloadType[1] == 1) {
    //Csv
    await launcher.launch(downloadCSVURL);
  }
}

Future<void> deleteFile(String fileName, dynamic keys) async {
  //Delete from firebase RTDB
  firebase_database.FirebaseDatabase.instance.ref("files").child(keys).remove();
  //Delete mp4
  firebase_storage.FirebaseStorage.instance.ref("video/$fileName.mp4").delete();
  //Delete csv
  firebase_storage.FirebaseStorage.instance.ref("video/$fileName.csv").delete();
}

/*APP*/

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Computer Vision Laboratory',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MyApp(),
    );
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
      if (!mounted) return;
      setState(() {
        _gyroscope.setValues(event.x, event.y, event.z);
      });
    });
    motionSensors.accelerometer.listen((AccelerometerEvent event) {
      if (!mounted) return;
      setState(() {
        _accelerometer.setValues(event.x, event.y, event.z);
      });
    });
    motionSensors.userAccelerometer.listen((UserAccelerometerEvent event) {
      if (!mounted) return;
      setState(() {
        _userAaccelerometer.setValues(event.x, event.y, event.z);
      });
    });
    motionSensors.magnetometer.listen((MagnetometerEvent event) {
      if (!mounted) return;
      setState(() {
        _magnetometer.setValues(event.x, event.y, event.z);
        var matrix =
            motionSensors.getRotationMatrix(_accelerometer, _magnetometer);
        _absoluteOrientation2.setFrom(motionSensors.getOrientation(matrix));
      });
    });
    motionSensors.isOrientationAvailable().then((available) {
      if (!mounted) return;
      if (available) {
        motionSensors.orientation.listen((OrientationEvent event) {
          setState(() {
            _orientation.setValues(event.yaw, event.pitch, event.roll);
          });
        });
      }
    });
    motionSensors.absoluteOrientation.listen((AbsoluteOrientationEvent event) {
      if (!mounted) return;
      setState(() {
        _absoluteOrientation.setValues(event.yaw, event.pitch, event.roll);
      });
    });
    motionSensors.screenOrientation.listen((ScreenOrientationEvent event) {
      if (!mounted) return;
      setState(() {
        _screenOrientation = event.angle;
      });
    });
  }

  void setUpdateInterval(int? groupValue, int interval) {
    if (!mounted) return;
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
                      value, (Duration.microsecondsPerSecond ~/ 1)),
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
