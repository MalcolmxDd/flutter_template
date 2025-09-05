import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;

  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    String path = join(await getDatabasesPath(), 'app_database.db');
    return await openDatabase(
      path,
      version:
          3, // Incrementar versión para la nueva tabla de códigos escaneados
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // Método para asegurar que el usuario admin exista
  Future<void> _ensureAdminUserExists(Database db) async {
    try {
      // Verificar si el admin ya existe
      var adminExists = await db.query(
        'users',
        where: 'username = ?',
        whereArgs: ['admin'],
      );

      if (adminExists.isEmpty) {
        // Insertar usuario admin si no existe
        await db.insert('users', {
          'username': 'admin',
          'password': 'admin123',
          'role': 'admin',
          'email': 'admin@example.com',
          'fullName': 'Administrador',
          'createdAt': DateTime.now().toIso8601String(),
          'isActive': 1,
        });
        print('Usuario admin creado exitosamente');
      } else {
        print('Usuario admin ya existe');
      }
    } catch (e) {
      print('Error al crear usuario admin: $e');
    }
  }

  void _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        role TEXT NOT NULL DEFAULT 'user',
        email TEXT,
        fullName TEXT,
        createdAt TEXT NOT NULL,
        isActive INTEGER NOT NULL DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE scanned_codes(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        code TEXT NOT NULL,
        type TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        deviceId TEXT NOT NULL,
        isSynced INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Insertar usuario admin por defecto usando el método común
    await _ensureAdminUserExists(db);
  }

  void _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Agregar nuevas columnas si no existen
      try {
        await db.execute('ALTER TABLE users ADD COLUMN email TEXT');
        await db.execute('ALTER TABLE users ADD COLUMN fullName TEXT');
        await db.execute(
          'ALTER TABLE users ADD COLUMN createdAt TEXT NOT NULL DEFAULT "${DateTime.now().toIso8601String()}"',
        );
        await db.execute(
          'ALTER TABLE users ADD COLUMN isActive INTEGER NOT NULL DEFAULT 1',
        );

        // Actualizar usuarios existentes
        await db.execute(
          'UPDATE users SET createdAt = "${DateTime.now().toIso8601String()}" WHERE createdAt IS NULL',
        );
        await db.execute(
          'UPDATE users SET isActive = 1 WHERE isActive IS NULL',
        );
      } catch (e) {
        // Las columnas ya existen, continuar
      }
    }

    if (oldVersion < 3) {
      // Crear tabla de códigos escaneados si no existe
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS scanned_codes(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            code TEXT NOT NULL,
            type TEXT NOT NULL,
            timestamp TEXT NOT NULL,
            deviceId TEXT NOT NULL,
            isSynced INTEGER NOT NULL DEFAULT 0
          )
        ''');
      } catch (e) {
        // La tabla ya existe, continuar
      }
    }

    // Asegurar que el usuario admin exista después de cualquier migración
    await _ensureAdminUserExists(db);
  }

  // Método público para crear el admin manualmente si es necesario
  Future<void> createAdminUserIfNotExists() async {
    var dbClient = await database;
    await _ensureAdminUserExists(dbClient);
  }

  Future<int> saveUser(Map<String, dynamic> user) async {
    var dbClient = await database;

    // Crear una copia del mapa para no modificar el original
    Map<String, dynamic> userData = Map<String, dynamic>.from(user);

    // Asegurar campos por defecto con tipos correctos
    if (!userData.containsKey('role')) {
      userData['role'] = 'user';
    }
    if (!userData.containsKey('createdAt')) {
      userData['createdAt'] = DateTime.now().toIso8601String();
    }
    if (!userData.containsKey('isActive')) {
      userData['isActive'] = 1;
    }

    // Asegurar que isActive sea int
    if (userData['isActive'] is String) {
      userData['isActive'] = int.parse(userData['isActive']);
    }

    // Asegurar que createdAt sea String
    if (userData['createdAt'] is DateTime) {
      userData['createdAt'] = userData['createdAt'].toIso8601String();
    }

    return await dbClient.insert('users', userData);
  }

  Future<Map<String, dynamic>?> getUser(
    String username,
    String password,
  ) async {
    var dbClient = await database;
    var result = await dbClient.query(
      'users',
      columns: [
        'id',
        'username',
        'password',
        'role',
        'email',
        'fullName',
        'createdAt',
        'isActive',
      ],
      where: 'username = ? AND password = ? AND isActive = 1',
      whereArgs: [username, password],
    );

    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }

  // Nuevos métodos para administración de usuarios
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    var dbClient = await database;
    var result = await dbClient.query(
      'users',
      columns: [
        'id',
        'username',
        'role',
        'email',
        'fullName',
        'createdAt',
        'isActive',
      ],
      orderBy: 'createdAt DESC',
    );
    return result;
  }

  Future<int> updateUser(Map<String, dynamic> user) async {
    var dbClient = await database;

    // Crear una copia del mapa para no modificar el original
    Map<String, dynamic> userData = Map<String, dynamic>.from(user);

    // Asegurar que isActive sea int si está presente
    if (userData.containsKey('isActive') && userData['isActive'] is String) {
      userData['isActive'] = int.parse(userData['isActive']);
    }

    // Asegurar que createdAt sea String si está presente
    if (userData.containsKey('createdAt') &&
        userData['createdAt'] is DateTime) {
      userData['createdAt'] = userData['createdAt'].toIso8601String();
    }

    return await dbClient.update(
      'users',
      userData,
      where: 'id = ?',
      whereArgs: [userData['id']],
    );
  }

  Future<int> deleteUser(int userId) async {
    var dbClient = await database;
    return await dbClient.delete('users', where: 'id = ?', whereArgs: [userId]);
  }

  Future<int> deactivateUser(int userId) async {
    var dbClient = await database;
    return await dbClient.update(
      'users',
      {'isActive': 0},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  Future<Map<String, dynamic>?> getUserById(int userId) async {
    var dbClient = await database;
    var result = await dbClient.query(
      'users',
      columns: [
        'id',
        'username',
        'role',
        'email',
        'fullName',
        'createdAt',
        'isActive',
      ],
      where: 'id = ?',
      whereArgs: [userId],
    );

    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }

  Future<int> getUsersCount() async {
    var dbClient = await database;
    var result = await dbClient.rawQuery(
      'SELECT COUNT(*) as count FROM users WHERE isActive = 1',
    );
    return result.first['count'] as int;
  }

  Future<int> getUsersCountByRole(String role) async {
    var dbClient = await database;
    var result = await dbClient.rawQuery(
      'SELECT COUNT(*) as count FROM users WHERE role = ? AND isActive = 1',
      [role],
    );
    return result.first['count'] as int;
  }

  // Métodos para manejar códigos escaneados
  Future<int> saveScannedCode(Map<String, dynamic> scannedCode) async {
    var dbClient = await database;

    // Verificar si el código ya existe en los últimos 5 segundos
    final now = DateTime.now();
    final fiveSecondsAgo = now.subtract(const Duration(seconds: 5));

    final existingCodes = await dbClient.query(
      'scanned_codes',
      where: 'code = ? AND timestamp > ?',
      whereArgs: [scannedCode['code'], fiveSecondsAgo.toIso8601String()],
    );

    // Si ya existe un código similar recientemente, no guardar duplicado
    if (existingCodes.isNotEmpty) {
      return existingCodes.first['id'] as int;
    }

    return await dbClient.insert('scanned_codes', scannedCode);
  }

  Future<List<Map<String, dynamic>>> getAllScannedCodes() async {
    var dbClient = await database;
    var result = await dbClient.query(
      'scanned_codes',
      orderBy: 'timestamp DESC',
    );
    return result;
  }

  Future<List<Map<String, dynamic>>> getUnsyncedCodes() async {
    var dbClient = await database;
    var result = await dbClient.query(
      'scanned_codes',
      where: 'isSynced = ?',
      whereArgs: [0],
      orderBy: 'timestamp ASC',
    );
    return result;
  }

  Future<int> markCodeAsSynced(int codeId) async {
    var dbClient = await database;
    return await dbClient.update(
      'scanned_codes',
      {'isSynced': 1},
      where: 'id = ?',
      whereArgs: [codeId],
    );
  }

  Future<int> deleteScannedCode(int codeId) async {
    var dbClient = await database;
    return await dbClient.delete(
      'scanned_codes',
      where: 'id = ?',
      whereArgs: [codeId],
    );
  }

  Future<int> getScannedCodesCount() async {
    var dbClient = await database;
    var result = await dbClient.rawQuery(
      'SELECT COUNT(*) as count FROM scanned_codes',
    );
    return result.first['count'] as int;
  }
}
