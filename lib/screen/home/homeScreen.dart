import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:therapy/appStates/googleSignInState.dart';
import 'package:therapy/core/helperFunctions.dart';
import 'package:therapy/screen/camera/cameraScreen.dart';
import 'package:therapy/screen/registerLoginScreen.dart';
import 'package:therapy/shared/sharedComponents/loader.dart';

import '../../app.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);
  static String routeName = "HomeScreen";

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(MyApp.appName),
          actions: [
            ElevatedButton.icon(
              icon: FaIcon(FontAwesomeIcons.user),
              label: Text("Logout"),
              onPressed: () {
                final provider =
                    Provider.of<GoogleSignInState>(context, listen: false);
                provider.logout();
                Navigator.of(context)
                    .pushReplacementNamed(RegisterLoginScreen.routeName);
              },
            ),
          ],
        ),
        body: StreamBuilder(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              print("progressinggg");
              return Center(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.2,
                  height: MediaQuery.of(context).size.height * 0.1,
                  child: Loader(),
                ),
              );
            } else if (snapshot.hasData) {
              final user = FirebaseAuth.instance.currentUser;
              Helper.setInStore("uid", user?.uid);
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundImage: NetworkImage(user!.photoURL!),
                    ),
                    SizedBox(
                      height: 30,
                    ),
                    Text("Name " + user.displayName!),
                    SizedBox(
                      height: 30,
                    ),
                    Text("Email " + user.email!),
                    Text("uid" + user.uid),
                    ElevatedButton(
                        onPressed: () {
                          Navigator.of(context)
                              .pushNamed(CameraScreen.routeName);
                        },
                        child: Text("To Camera"))
                  ],
                ),
              );
            } else if (snapshot.hasError) {
              return Center(
                child: Text("Something went Wrong"),
              );
            } else {
              return Center(
                child: Text("Go to sign Up"),
              );
            }
          },
        ));
  }
}
