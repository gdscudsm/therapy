import 'package:flutter/material.dart';
import 'package:therapy/screen/camera/cameraScreen.dart';
import 'package:therapy/shared/sharedComponents/customButton.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class ExerciseInstructionScreen extends StatefulWidget {
  const ExerciseInstructionScreen({Key? key}) : super(key: key);

  static String routeName = "exerciseInstructionScreen";

  @override
  State<ExerciseInstructionScreen> createState() =>
      _ExerciseInstructionScreenState();
}

class _ExerciseInstructionScreenState extends State<ExerciseInstructionScreen> {
  YoutubePlayerController _controller = YoutubePlayerController(
    initialVideoId: YoutubePlayer.convertUrlToId(
        "https://www.youtube.com/watch?v=zngOY3T7zno")!,
    flags: YoutubePlayerFlags(
      autoPlay: false,
      mute: false,
    ),
  );
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          child: YoutubePlayer(
            controller: _controller,
            showVideoProgressIndicator: true,
            // videoProgressIndicatorColor: Colors.amber,
            // progressColors: ProgressColors(
            //   playedColor: Colors.amber,
            //   handleColor: Colors.amberAccent,
            // ),
            // onReady: () {
            //   _controller.addListener(listener);
            // },
          ),
        ),
        CustomClientButton(
          text: "Go to Exercise",
          clickHandler: (context) {
            Navigator.of(context).pushNamed(CameraScreen.routeName);
          },
        )
      ]),
    );
  }
}
