import 'package:http/http.dart' show Client;
import 'package:html/parser.dart' show HtmlParser;
import 'package:html/dom.dart' show Element;

class Weather {
  // TODO: Support weather icon (emoji in this case)
  final String month;
  final int day;
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
    final tabs = document.querySelector(".tabs")?.children;
    if (tabs == null) return <Weather>[];
    for (Element tab in tabs) {
      if (!tab.classes.contains("main")) continue;
      reports.add(_parseCard(tab));
    }
    return reports;
  }

  Weather _parseCard(final Element tab) {
    final month = tab.querySelector(".month")?.text ?? "???";
    final day = int.tryParse(tab.querySelector(".date")?.text ?? "") ?? -1;
    final info = tab.querySelector(".weatherIco")?.attributes["title"] ??
        "???"; // May fail (accessing title attribute)
    final tempMin =
        tab.querySelector(".min")?.querySelector("span")?.text ?? "0";
    final tempMax =
        tab.querySelector(".max")?.querySelector("span")?.text ?? "0";
    return Weather(month, day, info, tempMin, tempMax);
  }

  void shutdown() {
    client.close();
  }
}
