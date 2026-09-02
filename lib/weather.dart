import 'package:http/http.dart' show Client;
import 'package:html/parser.dart' show HtmlParser;
import 'package:html/dom.dart' show Element;

class Weather {
  // TODO: Support weather icon (emoji in this case)
  final String month;
  final String day;
  final String info;
  final String temperatureMin; // Would be nice to store it as int
  final String temperatureMax; // ^
  const Weather(this.month, this.day, this.info, this.temperatureMin,
      this.temperatureMax);

  @override
  String toString() {
    return "[$day $month] $info | $temperatureMin - $temperatureMax";
  }
}

class SinoptikParser {
  final Client client;
	static const tabsClass = ".DMP0kolW";
	static const monthClass = ".yQxWb1P4";
	static const dayClass = ".RSWdP9mW";
	static const weekDayClass = ".xM6dxfW4";
	static const weatherIcoClass = ".bSOXy2ra"; // Not sure whether this is the correct class
	static const minClass = ".+Ovk0iEc";
	static const maxClass = ".+Ovk0iEc";
	static const temperatureLabelClass = "._4skXjqhc";
	static const temperaturesQuery = ".\\+Ncy59Ya p:not(.\\+Ovk0iEc)";

	// Add Custom UserAgent
  SinoptikParser() : client = Client();

  Future<List<Weather>> parseWeather(Uri url) async {
    final page = await getPage(url);
    final results = parsePage(page);
    return results;
  }

  Future<String> getPage(Uri url) async {
    var response = await client.get(url);
    var source = response.body;
    return source;
  }

  // Return null to indicate parse failure
  List<Weather> parsePage(String page) {
    List<Weather> reports = [];
    final HtmlParser parser = HtmlParser(page);
    final document = parser.parse();
    final tabs = document.querySelector(tabsClass)?.children;

    if (tabs == null) return <Weather>[];
    for (Element tab in tabs) {
      //if (!tab.classes.contains("main")) continue;
      reports.add(_parseCard(tab));
    }
    return reports;
  }

  Weather _parseCard(final Element tab) {
    final month = tab.querySelector(monthClass)?.text ?? "???";
    final day = int.tryParse(tab.querySelector(dayClass)?.text ?? "") ?? -1;
		final weekday = tab.querySelector(weekDayClass)?.innerHtml;
    final info = tab.querySelector(weatherIcoClass)?.attributes["aria-label"] ??
        "???"; // May fail (accessing title attribute)
		final temps = tab.querySelectorAll(temperaturesQuery);
    final tempMin = temps[0].innerHtml;
    final tempMax = temps[1].innerHtml;
		final fullDay = "$weekday, $day";
   	return Weather(month, fullDay, info, tempMin, tempMax);
  }

  void shutdown() {
    client.close();
  }
}
