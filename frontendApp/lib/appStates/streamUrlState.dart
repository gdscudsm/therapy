import 'package:flutter/material.dart';
import 'package:therapy/core/services/streamUrlService.dart';

class StreamUrlState with ChangeNotifier {
  Future<bool>? sendStreamUrl(streamUrl, userUid) async {
    try {
      return StreamUrlService().sendStreamUrl(streamUrl, userUid).then((value) {
        return value;
      }).catchError((onError) {});
    } on Exception catch (e) {
      // TODO
      print("exception occured");
      print(e.toString());
      return false;
    }
  }
}
