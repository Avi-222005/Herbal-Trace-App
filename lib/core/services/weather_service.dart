import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {
  // Using OpenWeatherMap API - Free tier allows 1000 calls/day
  // You'll need to register at https://openweathermap.org/api and get an API key
  static const String _apiKey = 'YOUR_API_KEY_HERE'; // Replace with your API key
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5/weather';

  /// Fetches current weather data for given coordinates
  /// Returns a map with temperature (in Celsius) and humidity (in %)
  Future<Map<String, double>?> getWeatherData({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final url = Uri.parse(
        '$_baseUrl?lat=$latitude&lon=$longitude&appid=$_apiKey&units=metric',
      );

      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        return {
          'temperature': (data['main']['temp'] as num).toDouble(),
          'humidity': (data['main']['humidity'] as num).toDouble(),
        };
      } else {
        print('Weather API Error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching weather data: $e');
      return null;
    }
  }

  /// Alternative: Using Open-Meteo API (No API key required, free)
  Future<Map<String, double>?> getWeatherDataFree({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final url = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=$latitude&longitude=$longitude&current=temperature_2m,relative_humidity_2m',
      );

      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final current = data['current'];
        
        return {
          'temperature': (current['temperature_2m'] as num).toDouble(),
          'humidity': (current['relative_humidity_2m'] as num).toDouble(),
        };
      } else {
        print('Weather API Error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching weather data: $e');
      return null;
    }
  }
}
