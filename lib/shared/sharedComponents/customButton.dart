import 'package:flutter/material.dart';

class CustomClientButton extends StatelessWidget {
  CustomClientButton({required this.text, required this.clickHandler});

  Function(BuildContext context) clickHandler;
  String text;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => {clickHandler(context)},
      child: Text(
        text,
        style: TextStyle(
            fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      ),
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 35),
        // primary: Colors.deepOrange,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18.0),
        ),
      ),
    );
  }
}
