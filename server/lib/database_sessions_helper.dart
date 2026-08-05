//database_sessions_helper.dart
import 'package:sqlite3/sqlite3.dart';

class Sessions {
  final Database _db;

  Sessions(this._db) {
    initTable();
  }

  void initTable() {
    _db.execute('''
      CREATE TABLE IF NOT EXISTS sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        token TEXT UNIQUE NOT NULL,
        user_id INTEGER NOT NULL,
        expires_at DATETIME NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      );
    ''');
  }

  bool createSession(int userId, String token, DateTime expiresAt) {
    final stmt = _db.prepare(
      'INSERT INTO sessions (token, user_id, expires_at) VALUES (?, ?, ?)'
    );
    try {
      stmt.execute([token, userId, expiresAt.toIso8601String()]);
      return true;
    } catch(e) {
      print('Session creation error:\n$e');
      return false;
    } finally {
      stmt.close();
    }
  }

  bool deleteSession(int sessionId) {
    final stmt = _db.prepare(
      'DELETE FROM sessions WHERE id = ?'
    );
    try {
      stmt.execute([sessionId]);
      
      if(_db.updatedRows == 1) {
        return true;
      } else {
        print('Warning no such session_id: $sessionId');
        return false;
      }
    } catch(e) {
      print('User deletion error:\n$e');
      return false;
    } finally {
      stmt.close();
    }
  }

  Row? findSessionByToken(String token) {
    final stmt = _db.prepare(
      'SELECT * FROM sessions WHERE token = ? LIMIT 1'
    );
    try {
      final ResultSet result = stmt.select([token]);
      if(result.isEmpty) { return null; }
      else { return result.first; }
    } catch(e) {
      print('Cannot find token $token:\n$e');
      return null;
    } finally {
      stmt.close();
    }
  }
}