import 'package:matrix/matrix.dart' show User;
import 'package:bot/client.dart' show BotClient, AccessLevel;
import 'package:bot/lights.dart' show Outage, EnergyParser;
import 'package:bot/neko_images.dart' show NekoFetcher;
import 'package:bot/weather.dart' show getWeatherInfo, formatWeather;

import 'dart:io' show ProcessSignal, exit;

final eParser = EnergyParser();
final nekoFetcher = NekoFetcher();

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
  | Додано !unban
  | Додано !neko
  | Додано !rules
  | Додано !users
  11 Червня, 2024
  | Майже завершено !light
  """;
  return news;
}

const String aboutMessage = """
fmBot v0.3
Created by fmmaks, thefoxcry
""";

const String rulesMessage = """
Павила! 
Правило №1:
  Не спамити. 
Правило №2:
  Не присилати 18+ контент. 
Правило №3: 
  Не ображати одне одного. 
Правило №4:
  Не приглашати людей без попередження адміна. 
Правило №5:
  За прославлення Корпорацій як Google, Microsoft, Apple - БАН. 
Правило №6:
  Не використовувати своє обличчя на аватарці. 
Правило №7: 
  Не просити зробити вас адміном чи модератором.
Created by 2becool, Edited by fmmaks.
Дякую що прочитали (дотримуйтеся правил!).
Щоб отримувати бонуси від Адміністраторів Вам потрібно приводити нових користувачів у групу. 
* Admins can ban You without leading on ban reason, but if got Banned you 100% broke rule(s) *
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
  !choice (Варіанти ...) -- Я виберу випадковий варіант
  !rps (Камінь | Ножиці | Папір) -- Я пограю в Камінь, Ножиці, Папір із тобою
  !light -- Я знайду і відправлю інформацію про відключення світла (WIP)
  !weather -- Я знайду погоду на сьогодні і завтра (WIP)
  !about -- Я відправлю інформацію про моїх авторів
  !neko -- Я відправлю зображення Neko
  !unban (UserID) -- Я розбаню зазначеного користувача
  !users -- Я відправлю список користувачів нашої кімнати
  !rules -- Я Нагадаю правила кімнати
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
            buffer.write("$j, ");
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
        Future<void> message(String status) async =>
            await client.sendNotice("Я $status");
        var me = choices[0];
        var you = args[0];
        await client.sendNotice("Я вибрала $me");
        switch ([me.toLowerCase(), you.toLowerCase()]) {
          case ["ножиці", "папір"]:
            await message("виграла!");
          case ["папір", "камінь"]:
            await message("виграла!");
          case ["камінь", "ножиці"]:
            await message("виграла!");
          case ["папір", "ножиці"]:
            await message("програла :(");
          case ["камінь", "папір"]:
            await message("програла :(");
          case ["ножиці", "камінь"]:
            await message("програла :(");
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
  client.addCommand(
      name: "neko",
      implementation: (List<String> args) async {
        var image = await nekoFetcher.requestImageBytes();
        if (image == null) {
          return;
        }
        Uri id = await client.uploadContent(image, filename: "image/png");
        // TODO: Send Image method in BotClient
        client.sendMessage(
            client.roomId,
            "m.room.message",
            client.generateUniqueTransactionId(),
            {"msgtype": "m.image", "url": id.toString(), "body": "An image"});
      });
  // Usage: unban (userId)
  client.addCommand(
      name: "unban",
      implementation: (List<String> args) async {
        if (args.isEmpty) {
          await client.sendNotice("Вкажи кого розбанити.");
          return;
        }
        var room = client.getRoomById(client.roomId);
        await room?.unban(args[0]);
      },
      requiredAccess: AccessLevel.admin);
  client.addCommand(
      name: "rules",
      implementation: (List<String> args) async {
        await client.sendNotice(rulesMessage);
      });
  client.addCommand(
      name: "users",
      implementation: (List<String> args) async {
        var room = client.getRoomById(client.roomId);
        if (room == null) return;
        // var users = await room.requestParticipants();
        var users = await room.loadHeroUsers();
        StringBuffer buffer = StringBuffer();
        buffer.writeln("=== Список Користувачів ===");
        for (var user in users) {
          final access = switch (user.powerLevel) {
            100 => AccessLevel.admin,
            50 => AccessLevel.moderator,
            0 => AccessLevel.user,
            _ => AccessLevel.user,
          };
          buffer.writeln("${user.displayName} (${user.id}) - $access");
        }
        await client.sendNotice(buffer.toString());
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
    print("Exiting...");
    await client.sendNotice("Sayonara~~");
    await client.logout();
    await Future.delayed(Duration(seconds: 1));
    await client.dispose();
    eParser.shutdown();
    nekoFetcher.shutdown();
    exit(0);
  });
}
