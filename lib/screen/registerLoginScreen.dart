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
      appBar: AppBar(
        title: Text(MyApp.appName),
      ),
      body: Container(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(
                children: <Widget>[
                  Text(
                    "Login screen",
                    style:
                        TextStyle(fontSize: 20.0, fontWeight: FontWeight.w900),
                  ),
                  ElevatedButton.icon(
                    icon: FaIcon(
                      FontAwesomeIcons.google,
                      color: Colors.red,
                    ),
                    label: Text("Sing in with Google"),
                    onPressed: () {
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
