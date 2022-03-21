import 'package:flutter/material.dart';
import 'package:therapy/core/services/streamUrlService.dart';

class StreamUrlState with ChangeNotifier {
  Future<bool?>? sendStreamUrl(streamUrl, userUid) async {
    try {
      print("start to communicate with the server now...");
      var result = await StreamUrlService().sendStreamUrl(streamUrl, userUid);
      print("result are here");
      return result;
    } on Exception catch (e) {
      // TODO
      print("exception occured");
      print(e.toString());
      return null;
    }
  }
}
