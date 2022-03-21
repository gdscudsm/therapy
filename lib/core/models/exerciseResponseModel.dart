// To parse this JSON data, do
//
//     final exerciseResponse = exerciseResponseFromJson(jsonString);

import 'package:meta/meta.dart';
import 'dart:convert';

ExerciseResponse exerciseResponseFromJson(String str) =>
    ExerciseResponse.fromJson(json.decode(str));

String exerciseResponseToJson(ExerciseResponse data) =>
    json.encode(data.toJson());

class ExerciseResponse {
  ExerciseResponse({
    required this.error,
    required this.message,
  });

  Error error;
  String message;

  factory ExerciseResponse.fromJson(Map<String, dynamic> json) =>
      ExerciseResponse(
        error: Error.fromJson(json["error"]),
        message: json["message"],
      );

  Map<String, dynamic> toJson() => {
        "error": error.toJson(),
        "message": message,
      };
}

class Error {
  Error({
    required this.message,
    required this.type,
  });

  String message;
  String type;

  factory Error.fromJson(Map<String, dynamic> json) => Error(
        message: json["message"],
        type: json["type"],
      );

  Map<String, dynamic> toJson() => {
        "message": message,
        "type": type,
      };
}
