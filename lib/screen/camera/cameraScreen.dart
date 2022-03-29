import 'dart:async';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:therapy/app.dart';
import 'package:therapy/appStates/streamUrlState.dart';
import 'package:therapy/core/helperFunctions.dart';
import 'package:therapy/core/models/exerciseResponseModel.dart';
import 'package:therapy/screen/camera/components/feedback.dart';
import 'package:therapy/shared/sharedComponents/customToast.dart';
import 'package:video_stream/camera.dart';
import 'package:wakelock/wakelock.dart';

import '../../shared/sharedComponents/customButton.dart';
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

void logError(String code, String message) =>
    print('Error: $code\nError Message: $message');

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  CameraController? controller;
  String? userId;
  TextStyle _feedbackStyle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
  );

  showAlertDialog(BuildContext context) {
    // set up the buttons
    CollectionReference handCollection =
        FirebaseFirestore.instance.collection('users');
    Widget cancelButton = CustomClientButton(
      text: 'Left',
      clickHandler: (context) => {
        handCollection
            .doc(userId)
            .set({'paralysedHand': 'Left'}, SetOptions(merge: true))
            .then((value) => {
                  isHandSelected = true,
                  Navigator.pop(context),
                  onNewCameraSelected(cameras[1])
                })
            .catchError((error) {
              isHandSelected = true;
              CustomToast.error(context);
              Navigator.pop(context);
            }),
      },
    );
    Widget continueButton = CustomClientButton(
        text: 'Right',
        clickHandler: (context) => {
              handCollection
                  .doc(userId)
                  .set({'paralysedHand': 'Right'}, SetOptions(merge: true))
                  .then((value) => {
                        Navigator.pop(context),
                        isHandSelected = true,
                        onNewCameraSelected(cameras[1])
                      })
                  .catchError((error) {
                    CustomToast.error(context);
                    isHandSelected = true;
                    Navigator.pop(context);
                  }),
            });
    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      content: Text("Which are hand are hand are you doing exercise for?"),
      actions: [cancelButton, continueButton],
    );
    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  bool get isStreaming => controller!.value.isStreamingVideoRtmp;
  bool isVisible = true;
  Timer? _timer;
  bool isHandSelected = false;

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
    isHandSelected
        ? null
        : Future.delayed(Duration.zero, () => showAlertDialog(context));
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(MyApp.appName),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
              flex: 2,
              // child:
              child: Container(
                margin: EdgeInsets.only(top: 14, left: 12, right: 12),
                child: StreamBuilder<QuerySnapshot>(
                  stream: therapy,
                  builder: (BuildContext contenxt,
                      AsyncSnapshot<QuerySnapshot> snapshot) {
                    if (snapshot.hasError) {
                      return Text(
                        'Something went wrong',
                        style: _feedbackStyle,
                      );
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Text(
                        "Loading",
                        style: _feedbackStyle,
                      );
                    }
                    final data = snapshot.requireData;
                    // print(data.docs);
                    // print(data.docs.last.data());

                    if (data.docs.length == 0) {
                      return Text(
                        'Your feedback will appear here',
                        style: _feedbackStyle,
                      );
                    }

                    Map<String, dynamic> result =
                        data.docChanges.last.doc.data() as Map<String, dynamic>;

                    return AutoSizeText(
                      "feedback" + result["message"] == "null"
                          ? result["error"].message
                          : result["message"],
                      maxFontSize: 20,
                      maxLines: 4,
                      style: _feedbackStyle,
                    );
                  },
                ),
              )),
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
                border: Border.all(
                  color:
                      controller != null && controller!.value.isRecordingVideo
                          ? controller!.value.isStreamingVideoRtmp
                              ? Colors.cyan
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
          Expanded(child: _captureControlRowWidget()),
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
      Helper.getStreamUrl().then((streamUrl) async => {
            _streamUrl = streamUrl,
            controller!
                .startVideoStreaming(streamUrl!, androidUseOpenGL: true)
                .then((v) async {
              Future.delayed(Duration(seconds: 6)).then((val) async {
                Provider.of<StreamUrlState>(context, listen: false)
                    .sendStreamUrl(streamUrl, userId);
              });
            }),
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
          icon: const Icon(Icons.play_circle_outline_rounded),
          color: Colors.cyan,
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
          color: Colors.cyan,
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
