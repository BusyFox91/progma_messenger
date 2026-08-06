// database_helper.dart
import 'dart:io';
import 'package:sqlite3/sqlite3.dart';
import 'package:path/path.dart' as path;

import 'package:server/database_users_helper.dart' as lib_users;
import 'package:server/database_sessions_helper.dart' as lib_sessions;
import 'package:server/database_groups_helper.dart' as lib_groups;
import 'package:server/database_group_members_helper.dart' as lib_group_members;

class DatabaseHelper {
  final Database _db;
  late final lib_users.Users users;
  late final lib_sessions.Sessions sessions;
  late final lib_groups.Groups groups;
  late final lib_group_members.GroupMembers groupMembers;
  DatabaseHelper(this._db) {
    _configureDatabase();
    _initTables();

    users = lib_users.Users(_db);
    sessions = lib_sessions.Sessions(_db);
    groupMembers = lib_group_members.GroupMembers(_db);
    groups = lib_groups.Groups(_db, groupMembers);
  }

  void _configureDatabase() { _db.execute('PRAGMA foreign_keys = ON;'); }
  
  // init tables that not initialised 
  void _initTables() {
    lib_users.Users.initTable(_db);
    lib_sessions.Sessions.initTable(_db);
    lib_groups.Groups.initTable(_db);
    lib_group_members.GroupMembers.initTable(_db);
  }

  void close() { _db.close(); }
}

DatabaseHelper createDatabase(String fpath, String fname) {
  final dbPath = path.join(Directory.current.path, fpath, fname);
  final dbDir = Directory(path.join(Directory.current.path, fpath));
  if (!dbDir.existsSync()) {dbDir.createSync(recursive: true);}
  final db = sqlite3.open(dbPath); 
  return DatabaseHelper(db);
}

  // ###   Check the correctness of the db_helper.   ###
void main(List<String> args) {
  print('Strart working...');
  DatabaseHelper dbHelper = createDatabase('data', 'messenger.db');

  print('Create Busy_Fox: ${dbHelper.users.create('Busy_Fox', 'BF_Hash256', 'BF_salt')}');
  print(dbHelper.users.getByUsername('Busy_Fox'));
  int userId = dbHelper.users.getByUsername('Busy_Fox')?['id'] ?? 1;
  print('Busy_Fox\'s salt: ${dbHelper.users.getSalt(userId)}');

  print('Change username: ${dbHelper.users.changeUsername(userId, 'Busy_Fox_13')}');
  print('Change password_hash: ${dbHelper.users.changePassword(userId, 'BF_hash256_2')}');
  print(dbHelper.users.getByUsername('Busy_Fox_13'));

  print('Create Busy_Fox: ${dbHelper.users.create('Busy_Fox', 'BF_Hash256', 'BF_salt')}');
  dbHelper.users.changeUsername(2, 'Busy_Fox_13');

  dbHelper.close();
  print('End working...');
}