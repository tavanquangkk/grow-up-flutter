import 'dart:convert';
import 'package:grow_up/core/utils/apis/auth_api_service.dart';
import 'package:grow_up/core/config/api_config.dart';
import 'package:http/http.dart' as http;

class HomePageApiService {
  /// 環境に応じてbaseURLを自動で切り替える
  /// 実機(iOS/Android): 開発用PCのIPアドレスを使用
  /// シミュレータ/デスクトップ: localhostを使用
  static String get baseUrl => ApiConfig.workshopBaseUrl;

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

  static Future<List> getMyWorkshops() async {
    // 1. GetでResponseを取得
    var response = await ApiService.getWithAuth("$baseUrl/workshops/me");

    // 2. 問題がなければ、Json型に変換したデータを格納
    var jsonResponse = _response(response);
    // 3. 自分の勉強会情報をリスト形式でデータを格納
    print(jsonResponse["data"]);
    return jsonResponse["data"];
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

  static Future<Map<String, dynamic>> updateWorkshop({
    required String id,
    required String name,
    required String description,
    required String date,
  }) async {
    try {
      final token = await ApiService.getToken();

      // 日付をサーバーが期待する形式に変換
      String formattedDate = date;
      if (date.contains('T')) {
        // ISO 8601形式の場合、'Z'を追加
        if (!date.endsWith('Z')) {
          formattedDate = date.replaceAll('.000', '') + 'Z';
        }
      }

      print(
        'Update Request Body: ${jsonEncode({'name': name, 'description': description, 'date': formattedDate})}',
      );

      final response = await http.put(
        Uri.parse("$baseUrl/workshops/$id"),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': name,
          'description': description,
          'date': formattedDate, // フォーマットされた日付として送信
        }),
      );

      print('Update Response Status: ${response.statusCode}');
      print('Update Response Body: ${response.body}');

      // レスポンスボディが空の場合の処理
      if (response.body.isEmpty) {
        if (response.statusCode == 200) {
          return {'status': 'success', 'message': '勉強会を更新しました'};
        } else {
          // 403エラーの場合、詳細なエラーメッセージを提供
          if (response.statusCode == 403) {
            throw Exception(
              '編集権限がありません。この勉強会は他のユーザーによって作成されたか、編集期限が過ぎている可能性があります。',
            );
          }
          throw Exception('サーバーエラー: ${response.statusCode}');
        }
      }

      final jsonResponse = jsonDecode(response.body);

      // ステータスコードが200でない場合はエラーとして扱う
      if (response.statusCode != 200) {
        // 403エラーの場合、サーバーからのメッセージを確認
        if (response.statusCode == 403) {
          String errorMsg = jsonResponse['message'] ?? '編集権限がありません';
          throw Exception(errorMsg);
        }
        throw Exception(jsonResponse['message'] ?? '勉強会の更新に失敗しました');
      }

      return jsonResponse;
    } catch (e) {
      print('Update Workshop Error: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> deleteWorkshop({
    required String id,
  }) async {
    try {
      final token = await ApiService.getToken();
      print('Delete Request for Workshop ID: $id');

      final response = await http.delete(
        Uri.parse("$baseUrl/workshops/$id"),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('Delete Response Status: ${response.statusCode}');
      print('Delete Response Body: ${response.body}');

      // レスポンスボディが空の場合の処理
      if (response.body.isEmpty) {
        if (response.statusCode == 200 || response.statusCode == 204) {
          return {'status': 'success', 'message': '勉強会を削除しました'};
        } else {
          // 403エラーの場合、詳細なエラーメッセージを提供
          if (response.statusCode == 403) {
            throw Exception('削除権限がありません。この勉強会は他のユーザーによって作成された可能性があります。');
          }
          if (response.statusCode == 404) {
            throw Exception('勉強会が見つかりません。すでに削除されている可能性があります。');
          }
          throw Exception('サーバーエラー: ${response.statusCode}');
        }
      }

      final jsonResponse = jsonDecode(response.body);

      // ステータスコードが成功でない場合はエラーとして扱う
      if (response.statusCode != 200 && response.statusCode != 204) {
        // 403エラーの場合、サーバーからのメッセージを確認
        if (response.statusCode == 403) {
          String errorMsg = jsonResponse['message'] ?? '削除権限がありません';
          throw Exception(errorMsg);
        }
        if (response.statusCode == 404) {
          String errorMsg = jsonResponse['message'] ?? '勉強会が見つかりません';
          throw Exception(errorMsg);
        }
        throw Exception(jsonResponse['message'] ?? '勉強会の削除に失敗しました');
      }

      return jsonResponse.containsKey('status')
          ? jsonResponse
          : {'status': 'success', 'message': '勉強会を削除しました'};
    } catch (e) {
      print('Delete Workshop Error: $e');
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

  // ================= Skills APIs =================
  static Future<List<Map<String, dynamic>>> getSkillsList() async {
    final response = await ApiService.getWithAuth("$baseUrl/skills");
    final jsonResponse = _response(response);
    final data = jsonResponse['data'];
    if (data is List) {
      return data
          .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }
    return [];
  }

  static Future<void> addLearningSkill(String skillName) async {
    try {
      final token = await ApiService.getToken();
      final response = await http.post(
        Uri.parse("$baseUrl/users/me/learnSkills"),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(skillName), // raw string body (JSON string)
      );
      if (response.statusCode != 200 && response.statusCode != 201) {
        String msg;
        if (response.body.isNotEmpty) {
          try {
            msg = (jsonDecode(response.body)['message'] ?? 'スキル追加に失敗しました')
                .toString();
          } catch (_) {
            msg = 'スキル追加に失敗しました (${response.statusCode})';
          }
        } else {
          msg = 'スキル追加に失敗しました (${response.statusCode})';
        }
        throw Exception(msg);
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> addTeachableSkill(String skillName) async {
    try {
      final token = await ApiService.getToken();
      final response = await http.post(
        Uri.parse("$baseUrl/users/me/teachableSkills"),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(skillName), // raw string body (JSON string)
      );
      if (response.statusCode != 200 && response.statusCode != 201) {
        String msg;
        if (response.body.isNotEmpty) {
          try {
            msg = (jsonDecode(response.body)['message'] ?? 'シェアスキル追加に失敗しました')
                .toString();
          } catch (_) {
            msg = 'シェアスキル追加に失敗しました (${response.statusCode})';
          }
        } else {
          msg = 'シェアスキル追加に失敗しました (${response.statusCode})';
        }
        throw Exception(msg);
      }
    } catch (e) {
      rethrow;
    }
  }

  // フォロー中のユーザー一覧を取得
  static Future<List<dynamic>> getFollowingUsers() async {
    try {
      final token = await ApiService.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/users/me/followings'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final data = _response(response);
      if (data['status'] == 'success') {
        return data['data'] ?? [];
      } else {
        throw Exception(data['message'] ?? 'フォロー中一覧の取得に失敗しました');
      }
    } catch (e) {
      rethrow;
    }
  }

  // フォロワーのユーザー一覧を取得
  static Future<List<dynamic>> getFollowerUsers() async {
    try {
      final token = await ApiService.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/users/me/followers'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final data = _response(response);
      if (data['status'] == 'success') {
        return data['data'] ?? [];
      } else {
        throw Exception(data['message'] ?? 'フォロワー一覧の取得に失敗しました');
      }
    } catch (e) {
      rethrow;
    }
  }
}
