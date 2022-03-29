import 'dart:ui';

import 'package:flutter/material.dart';

class CustomFeedback extends StatelessWidget {
  String feedback;
  CustomFeedback({required this.feedback});

  @override
  Widget build(BuildContext context) {
    return Text(
      feedback,
      style: TextStyle(fontSize: 14),
    );
  }
}
