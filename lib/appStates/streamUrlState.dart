import 'package:flutter/material.dart';
import 'package:therapy/core/services/streamUrlService.dart';

class StreamUrlState with ChangeNotifier {
  Future<bool?>? sendStreamUrl(streamUrl, userUid) async {
    try {
      var result = await StreamUrlService().sendStreamUrl(streamUrl, userUid);
      return result;
    } on Exception catch (e) {
      // TODO
      return null;
    }
  }
}
