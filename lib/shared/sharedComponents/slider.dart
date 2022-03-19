import 'package:flutter/material.dart';
import 'package:slide_to_act/slide_to_act.dart';

class CustomSlider extends StatelessWidget {
  Function(BuildContext context) onSlide;
  String slideText;

  CustomSlider({required this.onSlide, required this.slideText});

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        final GlobalKey<SlideActionState> _key = GlobalKey();
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: SlideAction(
            key: _key,
            onSubmit: () {
              Future.delayed(
                  Duration(seconds: 1),
                  () => {
                        onSlide(context),
                        _key.currentState!.reset(),
                      });
            },
            sliderRotate: false,
            alignment: Alignment.centerRight,
            outerColor: Color.fromRGBO(245, 25, 161, 1),
            child: Container(
              margin: EdgeInsets.only(left: 20),
              child: Text(
                slideText,
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                ),
              ),
            ),
            sliderButtonIcon: Icon(Icons.forward),
          ),
        );
      },
    );
  }
}
