import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:therapy/app.dart';
import 'package:therapy/appStates/streamUrlState.dart';
import 'package:therapy/core/helperFunctions.dart';
import 'package:therapy/core/models/exerciseResponseModel.dart';
import 'package:therapy/screen/camera/components/feedback.dart';
import 'package:video_stream/camera.dart';
import 'package:wakelock/wakelock.dart';

import 'components/feedback.dart';

class CameraScreen extends StatefulWidget {
  static String routeName = "CameraScreen";

  @override
  _CameraScreenState createState() {
    return _CameraScreenState();
  }
}

Future<void> initCameras() async {
  try {
    cameras = await availableCameras();
  } on CameraException catch (e) {
    logError(e.code, e.description);
  }
}

/// Returns a suitable camera icon for [direction].
IconData getCameraLensIcon(CameraLensDirection direction) {
  switch (direction) {
    case CameraLensDirection.back:
      return Icons.camera_rear;
    case CameraLensDirection.front:
      return Icons.camera_front;
    case CameraLensDirection.external:
      return Icons.camera;
  }
}

void logError(String code, String message) =>
    print('Error: $code\nError Message: $message');

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  CameraController? controller;
  String? userId;

  bool get isStreaming => controller!.value.isStreamingVideoRtmp;
  bool isVisible = true;
  Timer? _timer;

  @override
  initState() {
    super.initState();
    Helper.getFromStore("uid").then((uid) => {
          setState(() {
            userId = uid;
            therapy = FirebaseFirestore.instance
                .collection("users")
                .doc(uid)
                .collection('liveComments')
                .snapshots();
          })
        });
    initCameras().then((value) => {
          setState(() {
            controller = CameraController(
              cameras[0],
              ResolutionPreset.low,
            );
          })
        });
    WidgetsBinding.instance!.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance!.removeObserver(this);
    Wakelock.disable();
    super.dispose();
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    // App state changed before we got the chance to initialize.
    if (!controller!.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.paused) {
      isVisible = false;
      if (isStreaming) {
        await pauseVideoStreaming();
      }
    } else if (state == AppLifecycleState.resumed) {
      isVisible = true;
      if (controller != null) {
        if (isStreaming) {
          await resumeVideoStreaming();
        } else {
          onNewCameraSelected(controller!.description);
        }
      }
    }
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  Stream<QuerySnapshot>? therapy;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(MyApp.appName),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
              flex: 1,
              // child:
              child: StreamBuilder<QuerySnapshot>(
                stream: therapy,
                builder: (BuildContext contenxt,
                    AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.hasError) {
                    return Text('Something went wrong');
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Text("Loading");
                  }
                  final data = snapshot.requireData;
                  print(data.docs.last.data());
                  // ExerciseResponse =
                  //     ExerciseResponse.fromJson(data.docs.last.data().toString());
                  // String message = data.docs.last.data();

                  return CustomFeedback(
                      feedback: "feedback" + data.size.toString());
                },
              )
              // CustomFeedback(feedback: "feedback")

              ),
          Expanded(
            flex: 6,
            child: Container(
              child: Padding(
                padding: const EdgeInsets.all(1.0),
                child: Center(
                  child: _cameraPreviewWidget(),
                ),
              ),
              decoration: BoxDecoration(
                color: Colors.black,
                border: Border.all(
                  color:
                      controller != null && controller!.value.isRecordingVideo
                          ? controller!.value.isStreamingVideoRtmp
                              ? Colors.redAccent
                              : Colors.orangeAccent
                          : controller != null &&
                                  controller!.value.isStreamingVideoRtmp
                              ? Colors.blueAccent
                              : Colors.grey,
                  width: 3.0,
                ),
              ),
            ),
          ),
          _captureControlRowWidget(),
          Padding(
            padding: const EdgeInsets.all(5.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                _cameraTogglesRowWidget(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<String?> startVideoStreaming() async {
    String? _streamUrl;
    await stopVideoStreaming();
    if (controller == null) {
      return null;
    }
    if (!controller!.value.isInitialized) {
      showInSnackBar('Error: select a camera first.');
      return null;
    }

    if (controller!.value.isStreamingVideoRtmp) {
      return null;
    }

    try {
      Helper.getStreamUrl().then((value) async => {
            _streamUrl = value,
            await controller!
                .startVideoStreaming(value!, androidUseOpenGL: true),
            await Provider.of<StreamUrlState>(context, listen: false)
                .sendStreamUrl(value, userId)
          });
    } on CameraException catch (e) {
      _showCameraException(e);
      return null;
    }
    return _streamUrl;
  }

  /// Display the preview from the camera (or a message if the preview is not available).
  Widget _cameraPreviewWidget() {
    if (controller == null || !controller!.value.isInitialized) {
      return const Text(
        'Tap a camera',
        style: TextStyle(
          color: Colors.white,
          fontSize: 24.0,
          fontWeight: FontWeight.w900,
        ),
      );
    } else {
      return AspectRatio(
        aspectRatio: controller!.value.aspectRatio,
        child: CameraPreview(controller!),
      );
    }
  }

  /// Display the control bar with buttons to take pictures and record videos.
  Widget _captureControlRowWidget() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      mainAxisSize: MainAxisSize.max,
      children: <Widget>[
        IconButton(
          icon: const Icon(Icons.watch),
          color: Colors.blue,
          onPressed: controller != null &&
                  controller!.value.isInitialized &&
                  !controller!.value.isStreamingVideoRtmp
              ? onVideoStreamingButtonPressed
              : null,
        ),
        IconButton(
          icon: controller != null && controller!.value.isStreamingPaused
              ? Icon(Icons.play_arrow)
              : Icon(Icons.pause),
          color: Colors.blue,
          onPressed: controller != null &&
                  controller!.value.isInitialized &&
                  (controller!.value.isStreamingVideoRtmp)
              ? (controller != null && (controller!.value.isStreamingPaused)
                  ? onResumeButtonPressed
                  : onPauseButtonPressed)
              : null,
        ),
        IconButton(
          icon: const Icon(Icons.stop),
          color: Colors.red,
          onPressed: controller != null &&
                  controller!.value.isInitialized &&
                  (controller!.value.isRecordingVideo ||
                      controller!.value.isStreamingVideoRtmp)
              ? onStopButtonPressed
              : null,
        )
      ],
    );
  }

  /// Display a row of toggle to select the camera (or a message if no camera is available).
  Widget _cameraTogglesRowWidget() {
    final List<Widget> toggles = <Widget>[];

    if (cameras.isEmpty) {
      return const Text('No camera found');
    } else {
      for (CameraDescription cameraDescription in cameras) {
        toggles.add(
          SizedBox(
            width: 90.0,
            child: RadioListTile<CameraDescription>(
              title: Icon(getCameraLensIcon(cameraDescription.lensDirection)),
              groupValue: controller!.description,
              value: cameraDescription,
              onChanged: controller!.value.isRecordingVideo
                  ? null
                  : onNewCameraSelected,
            ),
          ),
        );
      }
    }

    return Row(children: toggles);
  }

  String timestamp() => DateTime.now().millisecondsSinceEpoch.toString();

  FutureOr<dynamic> showInSnackBar(String? message) {
    _scaffoldKey.currentState!.showSnackBar(SnackBar(content: Text(message!)));
  }

  void onNewCameraSelected(CameraDescription? cameraDescription) async {
    if (controller != null) {
      await stopVideoStreaming();
      await controller!.dispose();
    }
    controller = CameraController(
      cameraDescription,
      ResolutionPreset.low,
      enableAudio: true,
      androidUseOpenGL: true,
    );

    // If the controller is updated then update the UI.
    controller!.addListener(() async {
      if (mounted) setState(() {});
      if (controller!.value.hasError) {
        showInSnackBar('Camera error ${controller!.value.errorDescription}');
        if (_timer != null) {
          _timer!.cancel();
          _timer = null;
        }
        Wakelock.disable();
      }
    });

    try {
      await controller!.initialize();
    } on CameraException catch (e) {
      _showCameraException(e);
    }

    if (mounted) {
      setState(() {});
    }
  }

  void onVideoStreamingButtonPressed() {
    startVideoStreaming().then((String? url) {
      if (mounted) setState(() {});
      if (url != null) showInSnackBar('Streaming video to $url');
      Wakelock.enable();
    });
  }

  void onStopButtonPressed() {
    if (this.controller!.value.isStreamingVideoRtmp) {
      stopVideoStreaming().then((_) {
        if (mounted) setState(() {});
      });
    } else {}
    Wakelock.disable();
  }

  void onPauseButtonPressed() {}

  void onResumeButtonPressed() {}

  void onStopStreamingButtonPressed() {
    stopVideoStreaming().then((_) {
      if (mounted) setState(() {});
    });
  }

  void onPauseStreamingButtonPressed() {
    pauseVideoStreaming().then((_) {
      if (mounted) setState(() {});
      showInSnackBar('Video streaming paused');
    });
  }

  void onResumeStreamingButtonPressed() {
    resumeVideoStreaming().then((_) {
      if (mounted) setState(() {});
      showInSnackBar('Video streaming resumed');
    });
  }

  Future<void> stopVideoStreaming() async {
    if (!controller!.value.isInitialized) {
      return;
    }
    if (!controller!.value.isStreamingVideoRtmp) {
      return;
    }

    try {
      await controller!.stopVideoStreaming();
    } on CameraException catch (e) {
      _showCameraException(e);
      return null;
    }
  }

  Future<void> pauseVideoStreaming() async {
    if (!controller!.value.isStreamingVideoRtmp) {
      return null;
    }

    try {
      await controller!.pauseVideoStreaming();
    } on CameraException catch (e) {
      _showCameraException(e);
      rethrow;
    }
  }

  Future<void> resumeVideoStreaming() async {
    if (!controller!.value.isStreamingVideoRtmp) {
      return null;
    }

    try {
      await controller!.resumeVideoStreaming();
    } on CameraException catch (e) {
      _showCameraException(e);
      rethrow;
    }
  }

  void _showCameraException(CameraException e) {
    print("this errorr");
    logError(e.code, e.description);
    showInSnackBar('Error: ${e.code}\n${e.description}');
  }
}

List<CameraDescription> cameras = [];
