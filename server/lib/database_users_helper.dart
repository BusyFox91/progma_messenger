//database_userss_helper.dart
import 'package:sqlite3/sqlite3.dart';

class Users {
  final Database _db;

  Users(this._db);

  static void initTable(Database db) {
    db.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        password_salt TEXT NOT NULL,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        deleted_since DATETIME NULL
      );
    ''');
  }

  bool create(String username, String passwordHash, String salt) {
    final stmt = _db.prepare(
      'INSERT INTO users (username, password_hash, password_salt) VALUES (?, ?, ?)'
    );
    try {
      stmt.execute([username, passwordHash, salt]);
      return true;
    } catch(e) {
      print('Error. User creation error:\n$e');
      return false;
    } finally {
      stmt.close();
    }
  }

  bool markDeleted(int userId) {
    final Row? userRow = getById(userId);
    if (userRow == null) { 
      print('Error. User wasn\'t marked as deleted. userId $userId wasn\'t found');
      return false; 
    }

    final stmt = _db.prepare(
      'UPDATE users SET deleted_since = CURRENT_TIMESTAMP WHERE id = ?'
    );
    try {
      stmt.execute([userId]);
      return true;
    } catch(e) {
      print('Error. Marking deleted error:\n$e');
      return false;
    } finally {
      stmt.close();
    }
  }

  bool delete(int userId) {
    final stmt = _db.prepare(
      'DELETE FROM users WHERE id = ?'
    );
    try {
      stmt.execute([userId]);
      
      if(_db.updatedRows == 1) {
        return true;
      } else {
        print('Warning. No such user_id: $userId');
        return false;
      }
    } catch(e) {
      print('Error. User deletion error:\n$e');
      return false;
    } finally {
      stmt.close();
    }
  }

  int deleteExpired() {
    try {
      _db.execute(
        'DELETE FROM users WHERE deleted_since IS NOT NULL AND deleted_since < datetime(\'now\', \'-30 days\')',
      );
      return _db.updatedRows;
    } catch(e) {
      print('Error. Cleaning deleted accounts error:\n$e');
      return -1;
    }
  }

  Row? getById(int userId) {
    final stmt = _db.prepare(
      'SELECT * FROM users WHERE id = ? LIMIT 1'
    );
    try {
      final ResultSet result = stmt.select([userId]);
      if(result.isEmpty) { return null; }
      else { return result.first; }
    } catch(e) {
      print('Error. Cannot find user_id $userId:\n$e');
      return null;
    } finally {
      stmt.close();
    }
  }

  Row? getByUsername(String username) {
    final stmt = _db.prepare(
      'SELECT * FROM users WHERE username = ? LIMIT 1'
    );
    try {
      final ResultSet result = stmt.select([username]);
      if(result.isEmpty) { return null; }
      else { return result.first; }
    } catch(e) {
      print('Error. Cannot find username $username:\n$e');
      return null;
    } finally {
      stmt.close();
    }
  }

  String? getSalt(int userId) {
    final ResultSet result = _db.select(
      'SELECT password_salt FROM users WHERE id = ?',
      [userId],
    );
    if (result.isEmpty) {
      print('Error. Get user salt error: no user with id = $userId');
      return null;
    }

    return result.first['password_salt'];
  }

  bool changeUsername(int userId, String newUsername) {
    final String? oldUsername = getById(userId)?['username'] as String?;
    if (oldUsername == null) { 
      print('Error. Username wasn\'t changed. userId $userId wasn\'t found');
      return false; 
    }
    if (oldUsername == newUsername) {
      print('Warning. Username wasn\'t changed. Old username matches new');
      return false;
    }

    final stmt = _db.prepare(
      'UPDATE users SET username = ? WHERE id = ?',
    );
    try {
      stmt.execute([newUsername, userId],);
      return true;
    } catch(e) {
      print('Error. Changing username error:\n$e');
      return false;
    } finally {
      stmt.close();
    }
  }

  bool changePassword(int userId, String newPasswordHash) {
    final String? oldPasswordHash = getById(userId)?['password_hash'] as String?;
    if (oldPasswordHash == null) { 
      print('Error. Password wasn\'t changed. userId $userId wasn\'t found');
      return false; 
    }
    if (oldPasswordHash == newPasswordHash) {
      print('Warning. Password wasn\'t changed. Old password matches new');
      return false;
    }
    
    final stmt = _db.prepare(
      'UPDATE users SET password_hash = ? WHERE id = ?',
    );
    try {
      stmt.execute([newPasswordHash, userId],);
      return true;
    } catch(e) {
      print('Error. Changing user\'s password error:\n$e');
      return false;
    } finally {
      stmt.close();
    }
  }
}