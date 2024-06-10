import 'package:open_meteo/open_meteo.dart'
    show Weather, TemperatureUnit, Hourly;

Future<Map<String, dynamic>> getWeatherInfo() async {
  var w = Weather(
    latitude: 48.1719,
    longitude: 23.2979,
    temperature_unit: TemperatureUnit.celsius,
    start_date: DateTime.now(),
    end_date: DateTime.now().add(Duration(hours: 8)),
    past_hours: 0,
    past_days: 0,
  );

  List<Hourly> hourly = [
    Hourly.temperature_2m,
    Hourly.precipitation_probability
  ];
  var data = await w.raw_request(hourly: hourly);
  return data;
}

String formatWeather(Map<String, dynamic> data) {
  StringBuffer buffer = StringBuffer();
  for (int i in data["hourly"]["time"]) {
    var time = DateTime.fromMicrosecondsSinceEpoch(i);
    buffer.writeln(time.toString());
  }
  return buffer.toString();
}
