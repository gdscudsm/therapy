import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:therapy/core/helperFunctions.dart';
import 'package:therapy/screen/camera/cameraScreen.dart';
import 'package:therapy/screen/exerciceInstruction/exerciseInstruction.dart';
import 'package:therapy/shared/sharedComponents/customButton.dart';
import 'package:therapy/shared/sharedComponents/customToast.dart';
import 'package:therapy/shared/sharedComponents/homeImage.dart';
import 'package:therapy/shared/sharedComponents/loader.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);
  static String routeName = "HomeScreen";

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  showAlertDialog(BuildContext context) {
    // set up the buttons
    Widget cancelButton = CustomClientButton(
      text: 'Exercise',
      clickHandler: (context) =>
          {Navigator.of(context).popAndPushNamed(CameraScreen.routeName)},
    );
    Widget continueButton = CustomClientButton(
      text: 'Instrution',
      clickHandler: (context) {
        Navigator.of(context)
            .popAndPushNamed(ExerciseInstructionScreen.routeName);
      },
    );
    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      content:
          Text("Do you want to view instruction or go to exercise directly"),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: false,
        body: StreamBuilder(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
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
              return Container(
                margin: EdgeInsets.symmetric(horizontal: 18),
                height: MediaQuery.of(context).size.height,
                // width: MediaQuery.of(context).size.width * 0.9,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.08,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          height: MediaQuery.of(context).size.height * 0.10,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.all(
                              Radius.circular(36),
                            ),
                          ),
                          child: Image.network(user!.photoURL!),
                        ),
                        Container(
                          height: MediaQuery.of(context).size.height * 0.10,
                          width: MediaQuery.of(context).size.width * 0.6,
                          padding: const EdgeInsets.all(15),
                          child: TextField(
                            // controller: _filter,
                            // onChanged: (_) => {searchTextChangeController()},
                            decoration: new InputDecoration(
                              hintText: 'Search',
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(36)),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.05,
                    ),
                    Text(
                      "For You",
                      style: TextStyle(
                          color: Colors.cyan,
                          fontSize: 30,
                          fontWeight: FontWeight.bold),
                    ),
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.05,
                    ),
                    //
                    Container(
                      height: MediaQuery.of(context).size.height * 0.65,
                      child: Stack(children: [
                        Positioned(
                          left: MediaQuery.of(context).size.width * 0.1,
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width * 0.8,
                            child: GestureDetector(
                              onTap: () => {
                                showAlertDialog(context),
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Expanded(
                                    flex: 1,
                                    child: Text(
                                      "Exercise",
                                      textAlign: TextAlign.right,
                                      style: TextStyle(
                                          fontSize: 28,
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  Expanded(
                                      flex: 2,
                                      child: HomeImage(
                                          "assets/images/homeScreen/exercise.png")),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: MediaQuery.of(context).size.height * 0.14,
                          left: MediaQuery.of(context).size.width * 0.01,
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width * 0.8,
                            child: GestureDetector(
                              onTap: () => {CustomToast.msg("Comming soon")},
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: HomeImage(
                                        "assets/images/homeScreen/news.png"),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Text(
                                      "Health \n News",
                                      textAlign: TextAlign.right,
                                      style: TextStyle(
                                          fontSize: 30,
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: MediaQuery.of(context).size.width * 0.01,
                          top: MediaQuery.of(context).size.height * 0.27,
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width * 0.85,
                            height: MediaQuery.of(context).size.height * 0.18,
                            child: GestureDetector(
                              onTap: () => {CustomToast.msg("Comming soon")},
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Expanded(
                                    flex: 4,
                                    child: Text(
                                      "Appointment",
                                      textAlign: TextAlign.right,
                                      style: TextStyle(
                                          fontSize: 26,
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  Expanded(
                                      flex: 5,
                                      child: Container(
                                        margin:
                                            EdgeInsets.symmetric(horizontal: 4),
                                        decoration: BoxDecoration(
                                          image: DecorationImage(
                                              image: AssetImage(
                                                "assets/images/homeScreen/appointment.png",
                                              ),
                                              fit: BoxFit.cover),
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(40)),
                                        ),
                                      ))
                                ],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: MediaQuery.of(context).size.height * 0.43,
                          left: MediaQuery.of(context).size.width * 0.01,
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width * 0.8,
                            child: GestureDetector(
                              onTap: () => {CustomToast.msg("Comming soon")},
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: HomeImage(
                                        "assets/images/homeScreen/history.png"),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Text(
                                      "History",
                                      textAlign: TextAlign.right,
                                      style: TextStyle(
                                          fontSize: 26,
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ]),
                    ),

                    //
                    // Text("Name " + user.displayName!),
                    // SizedBox(
                    //   height: 30,
                    // ),
                    // Text("Email " + user.email!),
                    // Text("uid" + user.uid),
                    // ElevatedButton(
                    //     onPressed: () {
                    //       showAlertDialog(context);
                    //     },
                    //     child: Text("Exercise"))
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
