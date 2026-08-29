import 'package:http/http.dart' as http;

/// Checks internet connectivity by sending a HEAD request to Google.
/// Returns true if a response is received within 3 seconds.
/// We use [http] which is already in pubspec — no extra package needed.
Future<bool> hasInternet() async {
  try {
    final response = await http
        .head(Uri.parse('https://www.gstatic.com/generate_204'))
        .timeout(const Duration(seconds: 3));
    return response.statusCode == 204;
  } catch (_) {
    return false;
  }
}
