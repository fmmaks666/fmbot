import 'package:matrix/matrix.dart' show User;
import 'package:bot/client.dart' show BotClient;
import 'package:bot/lights.dart' show Outage, EnergyParser;
import 'package:bot/weather.dart' show getWeatherInfo, formatWeather;

import 'dart:io' show ProcessSignal, exit;

final eParser = EnergyParser();

String getNews() {
  const news = """
  6 Червня, 2024
  | fmBot починає працювати!
  | Додано почачткову версію !light
  7 Червня, 2024
  | Проведено (не вдалі) тестування
  | Додано !choice
  | Додано WIP версію !weather
  10 Червня, 2024
  | Додано !about
  | Технічні покращення
  """;
  return news;
}

const String aboutMessage = """
fmBot v0.3
Created by fmmaks, thefoxcry
""";

Future<BotClient> getClient() async {
  var client =
      await BotClient.fromConfig("./config.json", (var client, var name) async {
    await client.sendNotice("Вибачте, я не знаю команду: $name");
  });

  const String helpMessage = """
  === HELP ===
  !help -- Отримати цей список
  !echo (Текст) -- Я віправлю зазначений текст
  !news -- Я відправлю новини кімнати, якщо є
  !choice (Варіанти, ...) -- Я виберу випадковий варіант
  !rps (Камінь | Ножиці | Папір) -- Я пограю в Камінь, Ножиці, Папір із тобою
  !light -- Я знайду і відправлю інформацію про відключення світла (WIP)
  !weather -- Я знайду погоду на сьогодні і завтра (WIP)
  !about -- Я відправлю інформацію про моїх авторів
  """;
  client.addCommand(
      name: "help",
      implementation: (List<String> args) async {
        await client.sendNotice(helpMessage);
      });
  client.addCommand(
      name: "echo",
      implementation: (List<String> args) async {
        await client.sendNotice(args.join(' '));
      });
  client.addCommand(
      name: "news",
      implementation: (List<String> args) async {
        await client.sendNotice(getNews());
      });
  client.addCommand(
      name: "light",
      implementation: (List<String> args) async {
        StringBuffer buffer = StringBuffer();
        if (client.customData["lightUrls"] is! Map) {
          print("DOOMED");
          return;
        }
        buffer.writeln("=== Відключення Світла (В розробці) ===");
        for (var i in client.customData["lightUrls"].entries) {
          var page = await eParser.getPage(Uri.parse(i.value));
          var data = await eParser.getTimes(page);
          buffer.write("${i.key}: ");
          for (var j in data) {
            buffer.write("${j.toString()}, ");
          }
          if (data.isEmpty) {
            buffer.write("Не заплановано");
          }
          buffer.writeln();
        }
        client.sendNotice(buffer.toString());
      });
  client.addCommand(
      name: "choice",
      implementation: (List<String> args) async {
        if (args.isEmpty) {
          await client.sendNotice("Вкажи якісь варіанти");
          return;
        }
        args.shuffle();
        var selected = args[0];
        await client.sendNotice("Я вибрала: $selected");
      });
  client.addCommand(
      name: "rps",
      implementation: (List<String> args) async {
        if (args.isEmpty) {
          await client.sendNotice("Вибери щось");
          return;
        }
        var choices = ["Ножиці", "Камінь", "Папір"];
        choices.shuffle();
        var me = choices[0];
        var you = args[0];
        switch ([me, you]) {
          case [var mine, var yours] when mine == yours:
            await client.sendNotice("Ніхто не виграв");
          default:
            await client.sendNotice("Ти вибрав щось не те");
        }
      });
  client.addCommand(
      name: "weather",
      implementation: (List<String> args) async {
        StringBuffer buffer = StringBuffer();
        buffer.writeln("=== Прогноз Погоди (В розробці) ===");
        var forecast = await getWeatherInfo();
        buffer.writeln(formatWeather(forecast));
        client.sendNotice(buffer.toString());
      });
  client.addCommand(
      name: "about",
      implementation: (List<String> args) async {
        await client.sendNotice(aboutMessage);
      });

  return client;
}

Future<void> run() async {
  final client = await getClient();
  await client.encryption?.keyManager.loadAllKeys();
  await client.sendNotice("Я працюю!");
  client.onEvent.stream.listen((var data) async {
    // Better command hanlding (Probably in BotClient)
    String? sender = data.content["sender"];
    String? content = data.content["content"]["body"];
    //print(data.content);
    if (sender != null &&
        sender != "@fmbot:matrix.org" &&
        content != null &&
        content.startsWith("!")) {
      content = content.replaceFirst("!", "");
      var args = client.parseArguments(content);
      var command = args.first;
      args.removeAt(0);
      var room = client.getRoomById(data.roomID);
      if (room != null) {
        User user = User(sender, room: room);
        client.invokeCommand(command, args, user);
      }
    }
  });
  print("The bot is running...");
  ProcessSignal.sigint.watch().listen((var signal) async {
    await client.sendNotice("Sayonara~~");
    await client.dispose();
    eParser.shutdown();
    print("Exiting...");
    await Future.delayed(Duration(seconds: 1));
    exit(0);
  });
}
