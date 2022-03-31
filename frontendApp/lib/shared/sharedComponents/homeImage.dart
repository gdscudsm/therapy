import 'package:flutter/material.dart';

class HomeImage extends StatelessWidget {
  HomeImage(this.image);
  String image;
  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.16,
      margin: EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
          image: DecorationImage(
              image: AssetImage(
                image,
              ),
              fit: BoxFit.contain),
          borderRadius: BorderRadius.all(Radius.circular(40))),
    );
  }
}
