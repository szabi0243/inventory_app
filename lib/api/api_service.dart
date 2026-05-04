import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const baseUrl = "http://YOUR_BACKEND_URL";

  static Future<bool> send(String endpoint, Map data) async {
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/$endpoint"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(data),
      );
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (_) {
      return false;
    }
  }
}