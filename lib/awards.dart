import 'package:bot/database.dart' show DatabaseManager;
import 'package:sqlite_async/sqlite3.dart' show Row;

class InvalidAward implements Exception {
  InvalidAward(dynamic message);
}

class Award {
  final String name;
  final String description;
  final int? credit;
  final int? id;
  const Award(this.name, this.description, [this.credit, this.id]);
  factory Award.fromJson(Map<String, Object> json) {
    if (json
        case {
          "name": String name,
          "description": String description,
        }) {
      return Award(
        name,
        description,
        json["credit"] as int?,
        json["id"] as int?,
      );
    }
    throw InvalidAward("Provided Map doesn't contain all required values");
  }
  @override
  String toString() {
    return "$name ($description) $credit $id";
  }

  String toBasicString() {
    return "$name ($description)";
  }

  String toExtendedString() {
    String awardStatus = (credit ?? 0) >= 0 ? "⭐️" : "👹️";

    return "$awardStatus $name ($description)";
  }
}

class Awards {
  final DatabaseManager db;

  Awards(this.db);

  Future<void> setup() async {
    await db.createTables(
      (var tx) async {
        await tx.execute(
            "CREATE TABLE IF NOT EXISTS awards(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, description TEXT, credit INTEGER)");
        await tx.execute(
            "CREATE TABLE IF NOT EXISTS userAwards(userId TEXT, awardId INTEGER, FOREIGN KEY (awardId) REFERENCES awards(id))");
      },
    );
  }

  Future<List<Award>> getUserAwards(final String userId) async {
    // TODO: Handle errors
    const String query = """
    SELECT name, description, credit
    FROM awards
    JOIN userAwards ON awards.id = userAwards.awardId
    WHERE userAwards.userId = (?);
    """;
    final results = await db.db.getAll(query, [userId]);
    // IMPORTANT: Handle [InvalidAward] here
    List<Award> awards = [];
    void addAwardvar(Row element) => awards.add(Award.fromJson(element.cast()));
    results.forEach(
      addAwardvar,
    );
    return awards;
  }

  Future<void> grantAward(final String userId, final int awardId) async {
    // TODO: Handle error when awardId is not in awards
    const String query = """
    INSERT INTO userAwards(userId, awardId) VALUES(?, ?);
    """;
    try {
      await db.db.execute(query, [userId, awardId]);
    } catch (e, s) {
      print(e);
      print(s);
    }
  }

  Future<Award?> getAward(final int awardId) async {
    const String query = "SELECT name, description FROM awards WHERE id = (?)";
    // BUG: No element Exception is thrown here
    var result = await db.db.get(query, [awardId]);
    try {
      var award = Award.fromJson(result.cast());
      return award;
    } on InvalidAward {
      return null;
    }
  }

  Future<List<Award>> listAwards() async {
    // TODO
    return <Award>[];
  }
}
