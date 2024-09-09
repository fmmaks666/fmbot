import 'package:bot/database.dart' show DatabaseManager;
import 'package:sqlite_async/sqlite_async.dart';

/// Got rename'd 'cause it's user quotes, not user qoutes :D

class Quote {
  final String quote;
  final String author;

  const Quote(this.quote, this.author);
  @override
  String toString() {
    return "$quote\n\n\t-- $author";
  }
}

// Would be smart to make this an Interface :D
class UserQuotes {
  final DatabaseManager _db;

  UserQuotes(this._db);

  Future<void> setup() async {
    _db.execute((SqliteWriteContext ctx) async {
      ctx.execute(
          "CREATE TABLE IF NOT EXISTS quotes(quote TEXT PRIMARY KEY, author TEXT)");
    });
  }

  Future<void> addQuote(Quote quote) async {
    _db.execute((SqliteWriteContext ctx) async {
      await ctx.execute("INSERT INTO quotes(quote, author) VALUES (?, ?)",
          [quote.quote, quote.author]);
    });
  }

  Future<Quote> getRandomQuote() async {
    final data = await _db.db
        .get("SELECT quote, author FROM quotes ORDER BY random() LIMIT 1");
    return Quote(data["quote"], data["author"]);
  }
}
