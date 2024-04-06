import 'dart:async' show Future;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:csv/csv.dart';


void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: WeatherApp(),
    );
  }
}

class WeatherData {
  final String name;
  final String latitude;
  final String longitude;
  final String stationId;
  final String average;

  WeatherData({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.stationId,
    required this.average,
  });
}

class WeatherDataService {
  static Future<WeatherData?> fetchWeatherData(String STATION) async {
    try {
      final response = await http.get(
          Uri.parse('https://noaa-normals-pds.s3.amazonaws.com/normals-monthly/2006-2020/access/$STATION.csv'));

      if (response.statusCode == 200) {
        final List<List<dynamic>> csvData =
            CsvToListConverter().convert(response.body, eol: "\n");

        // Extracting weather data
        String name = csvData[1][5].toString();
        String latitude = csvData[1][2].toString();
        String longitude = csvData[1][3].toString();
        String stationId = csvData[1][0].toString();

        // Calculating average temperature
        double totalTemp = 0.0;
        for (int i = 1; i <= 12; i++) {
          totalTemp += double.parse(csvData[i][9].toString());
        }
        double averageTemp = totalTemp / 12;
        String average = averageTemp.toStringAsFixed(2); // Format average to 2 decimal places

        return WeatherData(
          name: name,
          latitude: latitude,
          longitude: longitude,
          stationId: stationId,
          average: average,
        );
      } else {
        print('Failed to fetch weather data: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching weather data: $e');
      return null;
    }
  }
}

class WeatherApp extends StatefulWidget {
  @override
  _WeatherAppState createState() => _WeatherAppState();
}

class _WeatherAppState extends State<WeatherApp> {
  TextEditingController _controller = TextEditingController();
  WeatherData? _weatherData;

  void _fetchWeatherData(String stationId) async {
    if (stationId.isEmpty) {
      // Show error message for empty input
      _showErrorMessage('Please enter a weather station ID.');
      return;
    }

    WeatherData? weatherData =
        await WeatherDataService.fetchWeatherData(stationId);

    if (weatherData != null) {
      // Data fetched successfully, update UI
      setState(() {
        _weatherData = weatherData;
      });
    } else {
      // Failed to fetch data, show error message
      _showErrorMessage('Failed to fetch weather data for station ID: $stationId');
    }
  }

  void _showErrorMessage(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Error'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // Clear weather data and reset UI
  void _clearWeatherData() {
    setState(() {
      _weatherData = null;
      _controller.clear(); // Clear text field
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Weather App'),
      ),
      body: Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Enter Weather Station ID',
              ),
            ),
            SizedBox(height: 20.0),
            ElevatedButton(
              onPressed: () {
                String stationId = _controller.text;
                _fetchWeatherData(stationId);
              },
              child: Text('Fetch Weather Data'),
            ),
            SizedBox(height: 20.0),
            if (_weatherData != null) ...[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Station Name: ${_weatherData!.name}'),
                    Text('Latitude: ${_weatherData!.latitude}'),
                    Text('Longitude: ${_weatherData!.longitude}'),
                    Text('Station ID: ${_weatherData!.stationId}'),
                    Text('Average Temperature: ${_weatherData!.average}F°'),
                    
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
