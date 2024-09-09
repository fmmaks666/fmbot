// https://cataas.com/cat
import 'dart:typed_data' show Uint8List;
import 'package:http/http.dart' show Client;

// No cat?
class NoCatImage implements Exception {
  NoCatImage(dynamic message);
}

class CatFetcher {
    static final Uri url = Uri.parse("https://cataas.com/cat"); // :3

    final Client client = Client();

    Future<Uint8List?> requestImageBytes() async {
        final response = await client.get(url);
        if (response != null) {
            try {
                return response.bodyBytes;
            } on NoCatImage catch (e, s) {
                print("No cat :(");
                print(e);
                print(s.toString());
                return null;
            }
        }
        return null;

        void shutdown() {
            client.close();
        }
    }
}