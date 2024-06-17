import 'package:bot/bot.dart';
import 'package:test/test.dart';

void main() {
  test('parseUserName parses correctly', () {
    expect(parseUserName("@user:example.org"), "user");
  });
  test('parseUserName returns Null on invalid input', () {
    expect(parseUserName("user"), null);
  });
  // TODO: Tests for lights.dart
}
