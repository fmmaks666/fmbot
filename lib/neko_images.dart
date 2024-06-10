import 'dart:convert' show jsonDecode;
import 'dart:typed_data' show Uint8List;
import 'package:http/http.dart' show Client;

class NekosNoImage implements Exception {
  NekosNoImage(dynamic message);
}

class NekoResponse {
  final Uri url;
  const NekoResponse(this.url);
  factory NekoResponse.fromJson(Map<String, dynamic> json) {
    if (json["url"] == null) {
      throw NekosNoImage("Couldn't find image URL in response");
    }
    return NekoResponse(Uri.parse(json["url"]));
  }
}

class NekoFetcher {
  static final Uri url = Uri.parse("https://nekos.best/api/v2/neko");

  final Client client = Client();

  Future<Uint8List?> requestImageBytes() async {
    final response = await client.get(url);
    final results = jsonDecode(response.body);
    if (results["results"] != null) {
      try {
        var image = NekoResponse.fromJson(results["results"][0]);
        var bytes = (await client.get(image.url)).bodyBytes;
        return bytes;
      } on NekosNoImage catch (e, s) {
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
