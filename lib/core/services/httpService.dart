import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class HttpService {
  static final String baseUrl = 'europe-west3-therapy-d63b9.cloudfunctions.net';
  static final String baseStreamUrl = 'rtmp://itsmushi.me/live';

  Uri getApiUrl(String url, {Map<String, dynamic>? queryParameters}) {
    return Uri.https(baseUrl, url, queryParameters);
  }

  Future<http.Response> httpPost(String url, body,
      {Map<String, dynamic>? queryParameters, bool useToken = true}) async {
    Uri apiUrl = getApiUrl(url, queryParameters: queryParameters);

    return http.post(
      apiUrl,
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode(body),
    );
  }

  Future<http.Response> httpPut(String url, body,
      {Map<String, dynamic>? queryParameters, bool useToken = true}) async {
    Uri apiUrl = getApiUrl(url, queryParameters: queryParameters);

    return http.put(
      apiUrl,
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode(body),
    );
  }

  Future<http.Response> httpPatch(String url, body,
      {Map<String, dynamic>? queryParameters, bool useToken = true}) async {
    Uri apiUrl = getApiUrl(url, queryParameters: queryParameters);

    return http.patch(
      apiUrl,
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode(body),
    );
  }

  Future<http.Response> httpDelete(String url,
      {Map<String, dynamic>? queryParameters, bool useToken = true}) async {
    Uri apiUrl = getApiUrl(url, queryParameters: queryParameters);

    return await http.delete(
      apiUrl,
      headers: {
        "Content-Type": "application/json",
      },
    );
  }

  Future<http.Response> httpGet(String url,
      {Map<String, dynamic>? queryParameters, bool useToken = true}) async {
    Uri apiUrl = getApiUrl(url, queryParameters: queryParameters);

    return await http.get(
      apiUrl,
      headers: {
        "Content-Type": "application/json",
      },
    );
  }

  Future<http.Response> httpGetPagination(
    String url,
    Map<String, dynamic> queryParameters,
  ) async {
    Map<String, String?> dataQueryParameters = {
      "totalPages": "true",
      "pageSize": "1",
      "fields": "none",
    };
    dataQueryParameters.addAll(queryParameters as Map<String, String?>);
    return await this.httpGet(url, queryParameters: dataQueryParameters);
  }

  // @override
  // String toString() {
  //   return '$baseUrl => $username : $password';
  // }
}
