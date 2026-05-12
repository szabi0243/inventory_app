import 'package:http/http.dart' as http;

class ApiService {
  static const String apiUrl = "API-URL IDE!!!!!!!!";

  Future<void> sendDataToSql(String code) async {
    final response = await http.post(
      Uri.parse(apiUrl),
      body: {'barcode': code},
    );

    if (response.statusCode == 200) {
      print("Sikeres mentés az adatbázisba!");
    }
  }
}