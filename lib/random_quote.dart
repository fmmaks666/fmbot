import 'dart:convert' show jsonDecode;
import 'package:http/http.dart' show Client;
import 'package:bot/userquotes.dart' show Quote;

class NoRandomQuote implements Exception {
  NoRandomQuote(dynamic message);
}

class RandomQuoteResponse {
  final Quote quote;
  const RandomQuoteResponse(this.quote);
  factory RandomQuoteResponse.fromJson(Map<String, dynamic> json) {
    if (json == null) {
      throw NoRandomQuote("[:(][bot/random_quote]: Couldn't find quote and author in response.");
    }
    return RandomQuoteResponse(Quote(json["quote"], json["author"]));
  }
}

class RandomQuoteFetcher {
  // TODO: Use data from Wikiquotes.
  static final Uri url = Uri.parse("https://dummyjson.com/quotes/1");

  final Client client = Client();

  Future<Quote?> requestRandomQuote() async {
    final response = await client.get(url);
    final results = jsonDecode(response.body);
    if (results != null) {
      try {
        return RandomQuoteResponse.fromJson(results).quote;
      } on NoRandomQuote catch (e, s) {
        print("No random quote :(");
        print(e);
        print(s.toString());
        return null;
      }
    }
    return null;
  }

  void shutdown() {
    client.close();
  }
}