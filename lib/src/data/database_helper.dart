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
      version: 6, // Incrementar versión para incluir ocupación en persons
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

    // Tabla de personas autorizadas (para validar RUT)
    await db.execute('''
      CREATE TABLE persons(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        rut TEXT NOT NULL UNIQUE,
        fullName TEXT,
        occupation TEXT,
        isActive INTEGER NOT NULL DEFAULT 1,
        createdAt TEXT NOT NULL
      )
    ''');

    // Tabla de asistencias
    await db.execute('''
      CREATE TABLE attendance(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        rut TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        deviceId TEXT NOT NULL,
        sourceCode TEXT,
        isSynced INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Insertar usuario admin por defecto usando el método común
    await _ensureAdminUserExists(db);

    // Sembrar personas de ejemplo
    await _seedSamplePersons(db);
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

    if (oldVersion < 4) {
      // Crear tabla de asistencias si no existe
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS attendance(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            rut TEXT NOT NULL,
            timestamp TEXT NOT NULL,
            deviceId TEXT NOT NULL,
            sourceCode TEXT,
            isSynced INTEGER NOT NULL DEFAULT 0
          )
        ''');
      } catch (e) {
        // La tabla ya existe, continuar
      }
    }

    if (oldVersion < 5) {
      // Crear tabla persons si no existe y sembrar datos de ejemplo
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS persons(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            rut TEXT NOT NULL UNIQUE,
            fullName TEXT,
            occupation TEXT,
            isActive INTEGER NOT NULL DEFAULT 1,
            createdAt TEXT NOT NULL
          )
        ''');
      } catch (e) {
        // La tabla ya existe
      }

      await _seedSamplePersons(db);
    }

    if (oldVersion < 6) {
      // Agregar columna occupation si falta
      try {
        await db.execute('ALTER TABLE persons ADD COLUMN occupation TEXT');
      } catch (e) {
        // La columna ya existe
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

  // Semilla de RUTs/personas de ejemplo para validación
  Future<void> _seedSamplePersons(Database db) async {
    final existing = await db.query('persons', limit: 1);
    if (existing.isNotEmpty) return;

    final now = DateTime.now().toIso8601String();
    final samplePersons = [
      {
        'rut': '12.345.678-5',
        'fullName': 'Juan Pérez',
        'occupation': 'Guardia',
        'isActive': 1,
        'createdAt': now,
      },
      {
        'rut': '9.876.543-2',
        'fullName': 'María González',
        'occupation': 'Jefa de Turno',
        'isActive': 1,
        'createdAt': now,
      },
      {
        'rut': '7.654.321-K',
        'fullName': 'Pedro López',
        'occupation': 'Supervisor',
        'isActive': 1,
        'createdAt': now,
      },
      {
        'rut': '12345678-5',
        'fullName': 'Formato Simple',
        'occupation': 'Operario',
        'isActive': 1,
        'createdAt': now,
      },
    ];

    for (final p in samplePersons) {
      try {
        await db.insert(
          'persons',
          p,
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      } catch (_) {}
    }
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

  // Métodos para manejar asistencias
  Future<int> saveAttendance(Map<String, dynamic> attendance) async {
    var dbClient = await database;

    // Evitar duplicados inmediatos del mismo RUT en 30 segundos
    final now = DateTime.now();
    final thirtySecondsAgo = now.subtract(const Duration(seconds: 30));
    final existing = await dbClient.query(
      'attendance',
      where: 'rut = ? AND timestamp > ?',
      whereArgs: [attendance['rut'], thirtySecondsAgo.toIso8601String()],
      limit: 1,
    );
    if (existing.isNotEmpty) {
      return existing.first['id'] as int;
    }

    return await dbClient.insert('attendance', attendance);
  }

  Future<List<Map<String, dynamic>>> getAllAttendance() async {
    var dbClient = await database;
    return await dbClient.query('attendance', orderBy: 'timestamp DESC');
  }

  Future<List<Map<String, dynamic>>> getUnsyncedAttendance() async {
    var dbClient = await database;
    return await dbClient.query(
      'attendance',
      where: 'isSynced = 0',
      orderBy: 'timestamp ASC',
    );
  }

  Future<int> markAttendanceAsSynced(int attendanceId) async {
    var dbClient = await database;
    return await dbClient.update(
      'attendance',
      {'isSynced': 1},
      where: 'id = ?',
      whereArgs: [attendanceId],
    );
  }

  // Personas / RUTs
  Future<Map<String, dynamic>?> getPersonByRut(String rut) async {
    final dbClient = await database;
    final result = await dbClient.query(
      'persons',
      where: 'rut = ? AND isActive = 1',
      whereArgs: [rut],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return result.first;
  }

  Future<bool> personExists(String rut) async {
    final person = await getPersonByRut(rut);
    return person != null;
  }

  Future<int> addOrUpdatePerson(Map<String, dynamic> person) async {
    final dbClient = await database;
    final nowIso = DateTime.now().toIso8601String();
    final data = Map<String, dynamic>.from(person);
    data['createdAt'] = data['createdAt'] ?? nowIso;
    data['isActive'] = data['isActive'] ?? 1;

    // Intentar actualizar por RUT; si no existe, insertar
    final updated = await dbClient.update(
      'persons',
      data,
      where: 'rut = ?',
      whereArgs: [data['rut']],
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
    if (updated > 0) return updated;
    return await dbClient.insert(
      'persons',
      data,
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<List<Map<String, dynamic>>> getAllPersons({
    bool? isActive,
    String? searchQuery,
    String orderBy = 'createdAt DESC',
  }) async {
    final dbClient = await database;
    final whereClauses = <String>[];
    final whereArgs = <Object?>[];

    if (isActive != null) {
      whereClauses.add('isActive = ?');
      whereArgs.add(isActive ? 1 : 0);
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = '%${searchQuery.trim()}%';
      whereClauses.add('(rut LIKE ? OR fullName LIKE ? OR occupation LIKE ?)');
      whereArgs.addAll([q, q, q]);
    }

    final whereSql = whereClauses.isEmpty ? null : whereClauses.join(' AND ');
    return await dbClient.query(
      'persons',
      where: whereSql,
      whereArgs: whereArgs,
      orderBy: orderBy,
    );
  }

  Future<int> insertPerson({
    required String rut,
    required String fullName,
    String? occupation,
    bool isActive = true,
  }) async {
    final dbClient = await database;
    return await dbClient.insert('persons', {
      'rut': rut,
      'fullName': fullName,
      'occupation': occupation,
      'isActive': isActive ? 1 : 0,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  Future<int> updatePersonByRut({
    required String rut,
    String? fullName,
    String? occupation,
    bool? isActive,
  }) async {
    final dbClient = await database;
    final data = <String, Object?>{};
    if (fullName != null) data['fullName'] = fullName;
    if (occupation != null) data['occupation'] = occupation;
    if (isActive != null) data['isActive'] = isActive ? 1 : 0;
    if (data.isEmpty) return 0;
    return await dbClient.update(
      'persons',
      data,
      where: 'rut = ?',
      whereArgs: [rut],
    );
  }

  Future<int> deletePersonByRut(String rut) async {
    final dbClient = await database;
    return await dbClient.delete('persons', where: 'rut = ?', whereArgs: [rut]);
  }

  Future<int> deactivatePersonByRut(String rut) async {
    final dbClient = await database;
    return await dbClient.update(
      'persons',
      {'isActive': 0},
      where: 'rut = ?',
      whereArgs: [rut],
    );
  }

  // Consultas combinadas de asistencia + persona
  Future<List<Map<String, dynamic>>> getAttendanceWithPerson({
    DateTime? from,
    DateTime? to,
    String? rut,
    bool onlyActivePersons = true,
  }) async {
    final dbClient = await database;
    final whereClauses = <String>[];
    final whereArgs = <Object?>[];

    if (from != null) {
      whereClauses.add('attendance.timestamp >= ?');
      whereArgs.add(from.toIso8601String());
    }
    if (to != null) {
      whereClauses.add('attendance.timestamp <= ?');
      whereArgs.add(to.toIso8601String());
    }
    if (rut != null && rut.isNotEmpty) {
      whereClauses.add('attendance.rut = ?');
      whereArgs.add(rut);
    }
    if (onlyActivePersons) {
      whereClauses.add('persons.isActive = 1');
    }

    final whereSql = whereClauses.isEmpty
        ? ''
        : 'WHERE ' + whereClauses.join(' AND ');

    final result = await dbClient.rawQuery('''
      SELECT attendance.id as attendanceId,
             attendance.rut as rut,
             attendance.timestamp as timestamp,
             attendance.deviceId as deviceId,
             attendance.sourceCode as sourceCode,
             attendance.isSynced as isSynced,
             persons.fullName as fullName,
             persons.occupation as occupation
      FROM attendance
      LEFT JOIN persons ON persons.rut = attendance.rut
      $whereSql
      ORDER BY attendance.timestamp DESC
    ''', whereArgs);

    return result;
  }

  Future<int> getAttendanceCountForRut(
    String rut, {
    DateTime? from,
    DateTime? to,
  }) async {
    final dbClient = await database;
    final whereClauses = <String>['rut = ?'];
    final whereArgs = <Object?>[rut];
    if (from != null) {
      whereClauses.add('timestamp >= ?');
      whereArgs.add(from.toIso8601String());
    }
    if (to != null) {
      whereClauses.add('timestamp <= ?');
      whereArgs.add(to.toIso8601String());
    }
    final result = await dbClient.rawQuery(
      'SELECT COUNT(*) as count FROM attendance WHERE ' +
          whereClauses.join(' AND '),
      whereArgs,
    );
    return (result.first['count'] as int?) ?? 0;
  }
}
