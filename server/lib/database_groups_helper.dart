//database_groupss_helper.dart
import 'package:sqlite3/sqlite3.dart';

class Groups {
  final Database _db;

  Groups(this._db) {
    _initTable();
  }

  void _initTable() {
    _db.execute('''
      CREATE TABLE IF NOT EXISTS groups (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        creator_id TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
        FOREIGN KEY (creator_id) REFERENCES users (id) ON DELETE SET NULL
      );
    ''');
  }

  bool create(String groupName, int creatorId) {
    final stmt = _db.prepare(
      'INSERT INTO groups (name, creator_id) VALUES (?, ?, ?)'
    );
    try {
      stmt.execute([groupName, creatorId]);
      return true;
    } catch(e) {
      print('Error. Group creation error:\n$e');
      return false;
    } finally {
      stmt.close();
    }
  }

  bool deleteGroup(int groupId) {
    final stmt = _db.prepare(
      'DELETE FROM groups WHERE id = ?'
    );
    try {
      stmt.execute([groupId]);
      
      if(_db.updatedRows == 1) {
        return true;
      } else {
        print('Warning. No such group_id: $groupId');
        return false;
      }
    } catch(e) {
      print('Error. Group deletion error:\n$e');
      return false;
    } finally {
      stmt.close();
    }
  }

  Row? getById(int groupId) {
    final stmt = _db.prepare(
      'SELECT * FROM groups WHERE id = ? LIMIT 1'
    );
    try {
      final ResultSet result = stmt.select([groupId]);
      if(result.isEmpty) { return null; }
      else { return result.first; }
    } catch(e) {
      print('Error. Cannot find group_id $groupId:\n$e');
      return null;
    } finally {
      stmt.close();
    }
  }


  bool changeName(int groupId, String newGroupname) {
    final Row? groupRow = getById(groupId);
    if (groupRow == null) { 
      print('Error. Group\'s name wasn\'t changed. groupId $groupId wasn\'t found');
      return false; 
    }
    final String? oldName = groupRow['name'];
    if (oldName == newGroupname) {
      print('Warning. Group\'s name wasn\'t changed. Old group\'s name matches new');
      return false;
    }
    final stmt = _db.prepare(
      'UPDATE groups SET name = ? WHERE id = ?',
    );
    try {
      stmt.execute([newGroupname, groupId],);

      return true;
    } catch(e) {
      print('Error. Changing group\'s name error:\n$e');
      return false;
    } finally {
      stmt.close();
    }
  }

  bool changeCreatorId(int groupId, int newCreatorId) {
    final Row? groupRow = getById(groupId);
    if (groupRow == null) { 
      print('Error. Group creator_id wasn\'t changed. groupId $groupId wasn\'t found');
      return false; 
    }
    final oldCreatorId = groupRow['creator_id'];
    if (oldCreatorId == newCreatorId) {
      print('Warning. Group creator_id wasn\'t changed. Old creator_id matches new');
      return false;
    }

    final stmt = _db.prepare(
      'UPDATE groups SET creator_id = ? WHERE id = ?',
    );
    try {
      stmt.execute([newCreatorId, groupId],);
      return true;
    } catch(e) {
      print('Error. Changing group creator_id error:\n$e');
      return false;
    } finally {
      stmt.close();
    }
  }

  
}