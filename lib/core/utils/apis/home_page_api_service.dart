import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:grow_up/core/utils/apis/auth_api_service.dart';
import 'package:http/http.dart' as http;

class HomePageApiService {
  static const String baseUrl = "http://localhost:8080/api/v1";

  static dynamic _response(http.Response response) {
    switch (response.statusCode) {
      case 200:
        var responseJson = jsonDecode(response.body);
        return responseJson;
      case 400:
        // 400 Bad Request : 一般的なクライアントエラー
        throw Exception('一般的なクライアントエラーです');
      case 401:
        // 401 Unauthorized : アクセス権がない、または認証に失敗
        throw Exception('アクセス権限がない、または認証に失敗しました');
      case 403:
        // 403 Forbidden ： 閲覧権限がないファイルやフォルダ
        throw Exception('閲覧権限がないファイルやフォルダです');
      case 500:
        // 500 何らかのサーバー内で起きたエラー
        throw Exception('何らかのサーバー内で起きたエラーです');
      case 301:
        // 500 何らかのサーバー内で起きたエラー
        throw Exception('権限がないぜー');
      default:
        // それ以外の場合
        throw Exception('何かしらの問題が発生しています');
    }
  }

  static Future<List> getUpComingWorkshops() async {
    // 1. GetでResponseを取得
    var response = await ApiService.getWithAuth("$baseUrl/workshops");

    // 2. 問題がなければ、Json型に変換したデータを格納
    var jsonResponse = _response(response);
    // 3. 本の情報をリスト形式でデータを格納
    print(jsonResponse["data"]);
    return jsonResponse["data"];
  }

  static Future<List> getRecommendedUsers() async {
    // 1. GetでResponseを取得
    var response = await ApiService.getWithAuth("$baseUrl/users/recommend");

    // 2. 問題がなければ、Json型に変換したデータを格納
    var jsonResponse = _response(response);
    // 3. オススメユーザー情報をリスト形式でデータを格納
    print(jsonResponse["data"]);
    return jsonResponse["data"];
  }

  static Future<Map<String, dynamic>> getUserProfile(String userId) async {
    // 1. GetでResponseを取得
    var response = await ApiService.getWithAuth("$baseUrl/users/$userId");

    // 2. 問題がなければ、Json型に変換したデータを格納
    var jsonResponse = _response(response);
    // 3. ユーザープロフィール情報を返す
    print(jsonResponse);
    return jsonResponse;
  }

  static Future<Map<String, dynamic>> createWorkshop({
    required String name,
    required String description,
    required String date,
  }) async {
    try {
      final token = await ApiService.getToken();
      print(
        'Request Body: ${jsonEncode({'name': name, 'description': description, 'date': date})}',
      );

      final response = await http.post(
        Uri.parse("$baseUrl/workshops"),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': name,
          'description': description,
          'date': int.parse(date), // 数値として送信
        }),
      );

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      // レスポンスボディが空の場合の処理
      if (response.body.isEmpty) {
        if (response.statusCode == 200 || response.statusCode == 201) {
          return {'status': 'success', 'message': '勉強会を作成しました'};
        } else {
          throw Exception('サーバーエラー: ${response.statusCode}');
        }
      }

      final jsonResponse = jsonDecode(response.body);

      // ステータスコードが200または201でない場合もエラーとして扱う
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception(jsonResponse['message'] ?? '勉強会の作成に失敗しました');
      }

      return jsonResponse;
    } catch (e) {
      print('Create Workshop Error: $e');
      rethrow;
    }
  }

  static Future<int> getFileLength() async {
    int listSize = 0;
    await getUpComingWorkshops().then((value) {
      // first return removed
      listSize = value.length;
    });
    return listSize;
  }
}
