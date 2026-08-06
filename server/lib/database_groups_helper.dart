//database_groups_helper.dart
import 'package:sqlite3/sqlite3.dart';

import 'package:server/database_group_members_helper.dart' as lib_group_members;

class Groups {
  final Database _db;
  final lib_group_members.GroupMembers _groupMembers;

  Groups(this._db, this._groupMembers);

  static void initTable(Database db) {
    db.execute('''
      CREATE TABLE IF NOT EXISTS groups (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL DEFAULT 'group' CHECK(type IN ('direct', 'group')),
        name TEXT NULL,              -- NULL if type == 'direct'
        creator_id INTEGER NULL,     -- NULL if type == 'direct'
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        empty_since DATETIME NULL,
        FOREIGN KEY (creator_id) REFERENCES users (id) ON DELETE SET NULL
      );
    ''');
  }


  bool create(String? groupName, int? creatorId, String type) {
    if (groupName == '') {
      print('Error. Can\'t create group with empty name');
      return false;
    }
    if (type == 'group') {
      if (groupName == null) {
        print('Error. Can\'t create group without name');
        return false;
      }
      if (creatorId == null) {
        print('Error. Can\'t create group without creator');
        return false;
      }
    }
    final stmt = _db.prepare(
      'INSERT INTO groups (name, creator_id, type) VALUES (?, ?, ?)'
    );
    try {
      _db.execute('BEGIN TRANSACTION;');

      stmt.execute([groupName, creatorId, type]);
      
      if (creatorId != null) {
        final int newGroupId = _db.lastInsertRowId;
        final bool memberCreationResult = _groupMembers.create(newGroupId, creatorId, 'creator');
        if (!memberCreationResult) {throw Exception('Fail to create member \'creator\' to the group $newGroupId');}
      }
      _db.execute('COMMIT;');
      return true;
    } catch(e) {
      _db.execute('ROLLBACK;');

      print('Error. Group creation error:\n$e');
      return false;
    } finally {
      stmt.close();
    }
  }

  bool delete(int groupId) {
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

  int deleteEmpty() {
    try {
      _db.execute(
        'DELETE FROM groups WHERE empty_since IS NOT NULL AND empty_since < datetime(\'now\', \'-30 days\')',
      );
      return _db.updatedRows;
    } catch(e) {
      print('Error. Deletion empty groups error:\n$e');
      return -1;
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