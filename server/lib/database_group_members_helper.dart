//database_group_members_helper.dart
import 'package:sqlite3/sqlite3.dart';

class GroupMembers {
  final Database _db;

  GroupMembers(this._db);

  static void initTable(Database db) {
    db.execute('''
      CREATE TABLE IF NOT EXISTS group_members (
        group_id INTEGER NOT NULL,
        user_id INTEGER NOT NULL,
        role TEXT NOT NULL DEFAULT 'member' CHECK(role IN ('creator', 'admin', 'member')),
        invited_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        PRIMARY KEY (group_id, user_id),
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
        FOREIGN KEY (group_id) REFERENCES groups (id) ON DELETE CASCADE
      );
    ''');

    // Set timestamp to empty group
    db.execute('''
      CREATE TRIGGER IF NOT EXISTS set_group_empty_timestamp
      AFTER DELETE ON group_members
      FOR EACH ROW
      WHEN NOT EXISTS (SELECT 1 FROM group_members WHERE group_id = OLD.group_id)
      BEGIN
        UPDATE groups SET empty_since = CURRENT_TIMESTAMP WHERE id = OLD.group_id;
      END;
      '''
    );

    // Set null to non empty groups
    db.execute('''
      CREATE TRIGGER IF NOT EXISTS reset_group_empty_timestamp
      AFTER INSERT ON group_members
      FOR EACH ROW
      BEGIN
        UPDATE groups SET empty_since = NULL WHERE id = NEW.group_id;
      END;
    ''');
  }

  bool create(int groupId, int userId, String role) {
    final stmt = _db.prepare(
      'INSERT INTO group_members (group_id, user_id, role) VALUES (?, ?, ?)'
    );
    try {
      stmt.execute([groupId, userId, role]);
      return true;
    } catch(e) {
      print('Error. Member creation error:\n$e');
      return false;
    } finally {
      stmt.close();
    }
  }

  bool delete(int groupId, int userId) {
    final stmt = _db.prepare(
      'DELETE FROM group_members WHERE group_id = ? AND user_id = ?'
    );
    try {
      stmt.execute([groupId, userId]);
      
      if(_db.updatedRows == 1) {
        return true;
      } else {
        print('Warning. No such member: ($groupId, $userId)');
        return false;
      }
    } catch(e) {
      print('Error. Member deletion error:\n$e');
      return false;
    } finally {
      stmt.close();
    }
  }

  Row? getById(int groupId, int userId) {
    final stmt = _db.prepare(
      'SELECT * FROM group_members WHERE group_id = ? AND user_id = ? LIMIT 1'
    );
    try {
      final ResultSet result = stmt.select([groupId, userId]);
      if(result.isEmpty) { return null; }
      else { return result.first; }
    } catch(e) {
      print('Error. Cannot find member ($groupId, $userId):\n$e');
      return null;
    } finally {
      stmt.close();
    }
  }

  bool changeRole(int groupId, int userId, String newRole) {
    final String? oldRole = getById(groupId, userId)?['role'] as String?;
    if (oldRole == null) { 
      print('Error. Member\'s role wasn\'t changed. member ($groupId, $userId) wasn\'t found');
      return false; 
    }
    if (oldRole == newRole) {
      print('Warning. Member\'s role wasn\'t changed. Old role matches new');
      return false;
    }

    final stmt = _db.prepare(
      'UPDATE group_members SET role = ? WHERE group_id = ? AND user_id = ?',
    );
    try {
      stmt.execute([newRole, groupId, userId]);
      return true;
    } catch (e) {
      print('Error. Changing member\'s role error:\n$e');
      return false;
    } finally {
      stmt.close();
    }
  }

}