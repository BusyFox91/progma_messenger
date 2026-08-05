//database_userss_helper.dart
import 'package:sqlite3/sqlite3.dart';

class Users {
  final Database _db;

  Users(this._db) {
    _initTable();
  }

  void _initTable() {
    _db.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        password_salt TEXT NOT NULL,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      );
    ''');
  }

  bool createUser(String username, String passwordHash, String salt) {
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

  bool deleteUser(int userId) {
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

  Row? getUserById(int userId) {
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

  Row? getUserByUsername(String username) {
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

  String? getUserSalt(int userId) {
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
    final String? oldUsername = getUserById(userId)?['username'];
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

  bool changeUserPassword(int userId, String newPasswordHash) {
    final stmt = _db.prepare(
      'UPDATE users SET password_hash = ? WHERE id = ?',
    );
    try {
      stmt.execute([newPasswordHash, userId],);
      
      if(_db.updatedRows == 1) {
        return true;
      } else {
        print('Warning. No such user_id: $userId');
        return false;
      }
    } catch(e) {
      print('Error. Changing user\'s password error:\n$e');
      return false;
    } finally {
      stmt.close();
    }
  }
}