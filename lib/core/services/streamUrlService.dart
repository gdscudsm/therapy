import 'package:therapy/core/services/httpService.dart';

class StreamUrlService {
  Future<bool> sendStreamUrl(String streamUrl, String userUid) async {
    HttpService http = new HttpService();
    String url = '';

    var response = await http.httpPost(
      url,
      {"source": streamUrl, "uid": userUid},
    );

    if (response.statusCode == 201) {
      return true;
    } else {
      return false;
    }
  }
}
