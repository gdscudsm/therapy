import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:provider/provider.dart';
import 'package:therapy/appStates/googleSignInState.dart';
import 'package:therapy/appStates/sampleState.dart';
import 'package:therapy/appStates/streamUrlState.dart';
import 'package:therapy/screen/camera/cameraScreen.dart';
import 'package:therapy/screen/exerciceInstruction/exerciseInstruction.dart';
import 'package:therapy/screen/home/homeScreen.dart';

import 'package:therapy/screen/registerLoginScreen.dart';
import 'package:therapy/screen/splash/splashScreen.dart';

class MyApp extends StatefulWidget {
  static String appName = "therapy";
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      // DeviceOrientation.portraitDown,
    ]);
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: SampleState()),
        ChangeNotifierProvider.value(value: GoogleSignInState()),
        ChangeNotifierProvider.value(value: StreamUrlState()),
      ],
      child: MaterialApp(
        title: 'therapy',
        theme: ThemeData(
          // textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
          primarySwatch: Colors.deepOrange,
        ),
        debugShowCheckedModeBanner: false,
        home: SafeArea(
          child: SplashScreen(),
        ),
        routes: {
          RegisterLoginScreen.routeName: (_) => RegisterLoginScreen(),
          HomeScreen.routeName: (_) => HomeScreen(),
          CameraScreen.routeName: (_) => CameraScreen(),
          ExerciseInstructionScreen.routeName: (_) =>
              ExerciseInstructionScreen()
        },
      ),
    );
  }
}
