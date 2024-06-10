import 'package:html/parser.dart' show HtmlParser;
import 'package:http/http.dart' show Client;
import 'package:intl/intl.dart' show DateFormat;

class OutageData {
  String from;
  String to;
  OutageData(this.from, this.to);
}

class Outage {
  late bool enabled;
  DateTime from;
  DateTime to;
  Outage(this.from, this.to) {
    enabled = false;
  }

  @override
  String toString() {
    return "$from -- $to";
  }
}

class EnergyParser {
  final Client client;

  EnergyParser() : client = Client();

  Future<List<Outage>> getTimes(String page) async {
    List<Outage> outages = [];
    var rawTimes = parsePage(page);
    for (var t in rawTimes) {
      DateFormat format = DateFormat.Hm();
      var from = format.parse(t.from);
      var to = format.parse(t.to);
      outages.add(Outage(from, to));
    }

    return outages;
  }

  Future<String> getPage(Uri url) async {
    var response = await client.get(url);
    var source = response.body;
    return source;
  }

  List<OutageData> parsePage(String page) {
    List<OutageData> parsedTimes = [];
    final parser = HtmlParser(page);
    final document = parser.parse();
    /* This parser MAY FAIL */
    var entries = document.getElementsByClassName(".grafik_string_list_item");
    for (var entry in entries) {
      var times = entry.querySelectorAll("b");
      assert(times.length == 3);
      var from = times[0].innerHtml;
      var to = times[1].innerHtml;
      parsedTimes.add(OutageData(from, to));
    }
    return parsedTimes;
  }

  void shutdown() {
    client.close();
  }
}
