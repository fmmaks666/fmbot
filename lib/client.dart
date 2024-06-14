import 'package:matrix/matrix.dart'
    show
        Client,
        Filter,
        User,
        EventFilter,
        LoginType,
        AuthenticationUserIdentifier,
        Room;
import 'dart:async' show FutureOr;
import 'dart:io' show File;
import 'dart:convert' show json;

typedef CommandCallback = Future<void> Function(List<String>, ExecutionContext);
typedef UnknownCommand = FutureOr<void> Function(BotClient, String);

enum AccessLevel {
  user, // user has 0, fmBot has 1
  moderator, // moderator has 50
  admin, // admin has 100
}

// CommandCallback + String?
class Command {
  final CommandCallback implementation;
  final String name;
  final AccessLevel requiredAccess;

  Command(
      {required this.name,
      required this.implementation,
      this.requiredAccess = AccessLevel.user});
  Future<void> run(
      args, AccessLevel userAccess, ExecutionContext context) async {
    if (isAccessible(userAccess, requiredAccess)) {
      await implementation(args, context);
    }
  }

  bool isAccessible(AccessLevel level, AccessLevel needed) {
    if (level.index >= needed.index) {
      return true;
    } else {
      return false;
    }
  }
}

class ExecutionContext {
  final String userId;
  final String displayName;
  const ExecutionContext({required this.userId, required this.displayName});
}

class BotClient extends Client {
  final String roomId;
  Room? _room;
  Room? get room {
    if (_room != null) {
      return _room;
    } else {
      _room = getRoomById(roomId);
      return _room;
    }
  }

  //final Map<String, Command> _botCommands = {};
  final Map<String, Command> _botCommands = {};
  // ^ Мож змінити на List<Command>
  final bool encrypt;
  final UnknownCommand? unknownCommandCallback;
  Map<String, dynamic> customData;

  BotClient(this.roomId, this.encrypt,
      {Filter? syncFilter,
      Future<void> Function(Client)? onSoftLogout,
      this.unknownCommandCallback,
      this.customData = const {}}) // TEST: Try to write to customData
      : super(
          "fmBot/Dart",
          shareKeysWithUnverifiedDevices: true,
          syncFilter: syncFilter,
          onSoftLogout: onSoftLogout,
        );

  // Can't make this a constuctor because we call login
  // Maybe I should turn this into a constuctor
  // TODO: Validate using if case
  static Future<BotClient> fromJson(
      Map<String, Object?> json, UnknownCommand? unknownCommandCallback) async {
    // Errors here are bad
    var instance = BotClient(
        json["roomId"]! as String, json["encrypt"]! as bool,
        syncFilter: Filter(
            presence: EventFilter(notTypes: ["m.encrypted", "m.notice"])),
        unknownCommandCallback: unknownCommandCallback,
        customData: json["custom"] as Map<String, dynamic>? ?? {});

    instance.homeserver = Uri.parse(json["homeserver"]! as String);
    await instance.login(LoginType.mLoginPassword,
        password: json["password"]! as String,
        identifier:
            AuthenticationUserIdentifier(user: json["userId"]! as String),
        initialDeviceDisplayName: "fmBot@Dart");
    return instance;
  }

  static Future<BotClient> fromConfig(
      String path, UnknownCommand? unknownCommandCallback) async {
    Map<String, Object?> config = json.decode(await File(path).readAsString());
    return await fromJson(config, unknownCommandCallback);
  }

  Future<void> sendNotice(String content) async {
    final type = encrypt ? "m.room.encrypted" : "m.room.message";
    final payload = {
      "msgtype": "m.notice",
      "body": content,
    };
    final data = encrypt
        ? await encryption?.encryptGroupMessagePayload(roomId, payload)
        : payload;

    await sendMessage(roomId, type, generateUniqueTransactionId(),
        data!); // Is it okay to use ! here?
  }

  void addCommand(
      {required String name,
      required CommandCallback implementation,
      AccessLevel requiredAccess = AccessLevel.user}) {
    _botCommands[name] = Command(
        name: name,
        implementation: implementation,
        requiredAccess: requiredAccess);
  }

  Future<void> invokeCommand(String name, List<String> args, User user) async {
    Command? f = _botCommands[name];

    if (f == null) {
      if (unknownCommandCallback != null) {
        await unknownCommandCallback!(this, name);
      }
      return;
    }
    final access = switch (user.powerLevel) {
      100 => AccessLevel.admin,
      50 => AccessLevel.moderator,
      0 => AccessLevel
          .user, // TODO: Check the actual PL for User => User by default have 0 PL (check package:matrix/lib/src/room.dart at 1777)
      _ => AccessLevel.user,
    };

    // BUG: Some users with powerLevel 100 are considered to have only 0 here
    var context = ExecutionContext(
        userId: user.id, displayName: user.displayName ?? user.id);
    await f.run(args, access,
        context); // Треба також кинути користувача щоб run міг перевірити доступ
  }

  // TODO: better argument parser
  List<String> parseArguments(String raw) {
    return raw.split(' ');
  }
}
