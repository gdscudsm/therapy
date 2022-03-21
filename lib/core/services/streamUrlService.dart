import 'package:therapy/core/services/httpService.dart';

class StreamUrlService {
  Future<bool> sendStreamUrl(String streamUrl, String userUid) async {
    HttpService http = new HttpService();
    String url = '/measure_paralysis';

    var response = await http.httpPost(
      url,
      {"source": streamUrl, "uid": userUid},
    );
    print("start to communicate with the server");
    print(response.statusCode);
    print(response.body);
    print("that was the message");

    if (response.statusCode == 201) {
      return true;
    } else {
      return false;
    }
  }
}
