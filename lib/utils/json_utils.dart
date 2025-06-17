import 'dart:convert';
import 'package:http/http.dart' as http;

class JsonUtils {
  /// 統一的 JSON 解析方法，自動處理 UTF-8 編碼問題
  static dynamic safeJsonDecode(http.Response response) {
    try {
      // 首先嘗試直接解析 response.body
      return json.decode(response.body);
    } catch (e) {
      print('直接解析失敗，嘗試 UTF-8 解碼: $e');
      try {
        // 如果直接解析失敗，嘗試 UTF-8 解碼
        return json.decode(utf8.decode(response.body.runes.toList()));
      } catch (e2) {
        print('UTF-8 解碼也失敗: $e2');
        throw FormatException('無法解析 JSON 回應: ${e2.toString()}');
      }
    }
  }

  /// 統一的 JSON 解析方法，支援字串輸入
  static dynamic safeJsonDecodeString(String jsonString) {
    try {
      return json.decode(jsonString);
    } catch (e) {
      print('JSON 字串解析失敗: $e');
      throw FormatException('無法解析 JSON 字串: ${e.toString()}');
    }
  }
} 