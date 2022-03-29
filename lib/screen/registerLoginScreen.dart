import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:therapy/app.dart';
import 'package:therapy/appStates/googleSignInState.dart';
import 'package:therapy/screen/home/homeScreen.dart';

class RegisterLoginScreen extends StatelessWidget {
  const RegisterLoginScreen({Key? key}) : super(key: key);
  static String routeName = "RegisterLoginScreen";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(
                children: <Widget>[
                  Text(
                    "Let's get Started",
                    style: TextStyle(
                        fontSize: 20.0,
                        fontWeight: FontWeight.w900,
                        color: Colors.white),
                  ),
                  SizedBox(
                    height: 30,
                  ),
                  GestureDetector(
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 36, vertical: 20),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Login with Google  ',
                            style: TextStyle(fontSize: 20, color: Colors.white),
                          ),
                          FaIcon(
                            FontAwesomeIcons.google,
                            color: Colors.green,
                          ),
                        ],
                      ),
                      decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.white,
                          ),
                          borderRadius: BorderRadius.all(Radius.circular(60))),
                    ),
                    onTap: () {
                      final provider = Provider.of<GoogleSignInState>(context,
                          listen: false);
                      provider.googleLogin();
                      Navigator.of(context).pushNamed(HomeScreen.routeName);
                    },
                  ),

                  SizedBox(height: 200.0),
                  // SignInButtonWidget(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
