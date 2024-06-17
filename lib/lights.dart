import 'package:html/parser.dart' show HtmlParser;
import 'package:http/http.dart' show Client;
import 'package:intl/intl.dart' show DateFormat;

class OutageData {
  String from;
  String to;
  bool tomorrow;
  OutageData(this.from, this.to, this.tomorrow);
}

class Outage {
  DateTime from;
  DateTime to;
  bool tomorrow;
  Outage(this.from, this.to, this.tomorrow);

  @override
  String toString() {
    var fromHour = from.hour.toString().padLeft(2, "0");
    var fromMinute = from.minute.toString().padLeft(2, "0");
    var toHour = to.hour.toString().padLeft(2, "0");
    var toMinute = to.minute.toString().padLeft(2, "0");

    return "${tomorrow ? '*' : ''}$fromHour:$fromMinute -- $toHour:$toMinute";
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
      var tomorrow = t.tomorrow;
      outages.add(Outage(from, to, tomorrow));
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
    // The site also has section for Tomorrow; Would be nice to clarify if there a data for Tomorrow
    var entries = document.querySelectorAll(".grafik_string_list_item");
    var todayList = document.querySelector(".grafik_string_list");
    var today = todayList?.children.length ?? 0;
    var plannedToday = today > 0;
    for (var entry in entries) {
      var times = entry.querySelectorAll("b");
      assert(times.length == 3);
      var from = times[0].innerHtml;
      var to = times[1].innerHtml;
      parsedTimes.add(OutageData(from, to, today > 0 ? false : true));
      if (plannedToday) today--;
    }
    return parsedTimes;
  }

  void shutdown() {
    client.close();
  }
}
