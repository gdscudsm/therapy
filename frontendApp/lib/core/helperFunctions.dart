import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:therapy/core/services/httpService.dart';

class Helper {
  static final storage = new FlutterSecureStorage();
  static Future<String?> getFromStore(_key) async {
    String? value = await storage.read(key: _key);
    return value;
  }

  static Future setInStore(_key, _val) async {
    await storage.write(key: _key, value: _val);
  }

  static Future getStreamUrl() async {
    String? url = HttpService.baseStreamUrl;
    String? uid = await getFromStore("uid");
    return url + "/" + uid!;
  }
}
//STORAGE KEYS
//uid
//streamUrl