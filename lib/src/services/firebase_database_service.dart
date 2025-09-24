import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Modelo para Product - Simplificado y unificado
class Product {
  final String? id;
  final String name;
  final double price;
  final int stock;
  final String? description;
  final DateTime? createdAt;
  final String? barcode; // Código de barras/QR del producto
  final String? code; // Código escaneado
  final String? type; // Tipo de código (QR, EAN13, etc.)
  final String? content; // Contenido adicional del código
  final DateTime? scannedAt; // Fecha de escaneo
  final String? userId; // Usuario que lo escaneó/creó
  final String? username; // Nombre del usuario
  final String? userEmail; // Email del usuario
  final bool isActive; // Estado activo/inactivo

  Product({
    this.id,
    required this.name,
    required this.price,
    required this.stock,
    this.description,
    this.createdAt,
    this.barcode,
    this.code,
    this.type,
    this.content,
    this.scannedAt,
    this.userId,
    this.username,
    this.userEmail,
    this.isActive = true,
  });

  factory Product.fromMap(String id, Map<String, dynamic> map) {
    return Product(
      id: id,
      name: map['name'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      stock: (map['stock'] ?? 0),
      description: map['description'],
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'])
          : null,
      barcode: map['barcode'],
      code: map['code'],
      type: map['type'],
      content: map['content'],
      scannedAt: map['scannedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['scannedAt'])
          : null,
      userId: map['userId'],
      username: map['username'],
      userEmail: map['userEmail'],
      isActive: map['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'stock': stock,
      'description': description,
      'createdAt': createdAt?.millisecondsSinceEpoch ?? ServerValue.timestamp,
      'barcode': barcode,
      'code': code,
      'type': type,
      'content': content,
      'scannedAt': scannedAt?.millisecondsSinceEpoch ?? ServerValue.timestamp,
      'userId': userId,
      'username': username,
      'userEmail': userEmail,
      'isActive': isActive,
    };
  }
}

/// Modelo para Sale
class Sale {
  final String? id;
  final String userId;
  final String productId;
  final int quantity;
  final double total;
  final DateTime date;

  Sale({
    this.id,
    required this.userId,
    required this.productId,
    required this.quantity,
    required this.total,
    required this.date,
  });

  factory Sale.fromMap(String id, Map<String, dynamic> map) {
    return Sale(
      id: id,
      userId: map['userId'] ?? '',
      productId: map['productId'] ?? '',
      quantity: (map['quantity'] ?? 0),
      total: (map['total'] ?? 0.0).toDouble(),
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] ?? 0),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'productId': productId,
      'quantity': quantity,
      'total': total,
      'date': date.millisecondsSinceEpoch,
    };
  }
}

/// Servicio para manejar operaciones con Firebase Realtime Database
class FirebaseDatabaseService {
  static final DatabaseReference _database = FirebaseDatabase.instance.ref();
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Crear perfil de usuario
  static Future<void> createUserProfile({
    required String uid,
    required String email,
    required String username,
    String role = 'user',
  }) async {
    try {
      final userData = {
        'uid': uid,
        'email': email,
        'username': username,
        'roles': role,
        'createdAt': ServerValue.timestamp,
        'lastLogin': ServerValue.timestamp,
        'isActive': true,
      };

      await _database.child('users').child(uid).set(userData);
    } catch (e) {
      throw 'Error al crear perfil de usuario: $e';
    }
  }

  /// Obtener perfil de usuario
  static Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    try {
      final snapshot = await _database.child('users').child(uid).get();
      if (snapshot.exists) {
        return Map<String, dynamic>.from(snapshot.value as Map);
      }
      return null;
    } catch (e) {
      throw 'Error al obtener perfil de usuario: $e';
    }
  }

  /// Crear usuario con Firebase Auth y perfil
  static Future<void> createUserWithEmailAndPassword({
    required String email,
    required String password,
    required String username,
    String role = 'user',
  }) async {
    try {
      // Crear usuario con Firebase Auth
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Crear perfil en la base de datos
        await createUserProfile(
          uid: credential.user!.uid,
          email: email,
          username: username,
          role: role,
        );
      }
    } catch (e) {
      throw 'Error al crear usuario: $e';
    }
  }

  /// Actualizar perfil de usuario
  static Future<void> updateUserProfile({
    required String uid,
    String? username,
    String? email,
    String? role,
  }) async {
    try {
      final updates = <String, dynamic>{};

      if (username != null) updates['username'] = username;
      if (email != null) updates['email'] = email;
      if (role != null) updates['roles'] = role;

      updates['updatedAt'] = ServerValue.timestamp;

      await _database.child('users').child(uid).update(updates);
    } catch (e) {
      throw 'Error al actualizar perfil de usuario: $e';
    }
  }

  /// Actualizar último login
  static Future<void> updateUserLastLogin(String uid) async {
    try {
      await _database.child('users').child(uid).update({
        'lastLogin': ServerValue.timestamp,
      });
    } catch (e) {
      throw 'Error al actualizar último login: $e';
    }
  }

  /// Actualizar estado activo del usuario
  static Future<void> updateUserActiveStatus(String uid, bool isActive) async {
    try {
      await _database.child('users').child(uid).update({
        'isActive': isActive,
        'updatedAt': ServerValue.timestamp,
      });
    } catch (e) {
      throw 'Error al actualizar estado del usuario: $e';
    }
  }

  /// Eliminar perfil de usuario (marcar como eliminado)
  static Future<void> deleteUserProfile(String uid) async {
    try {
      await _database.child('users').child(uid).update({
        'isDeleted': true,
        'isActive': false,
        'deletedAt': ServerValue.timestamp,
      });
    } catch (e) {
      throw 'Error al marcar usuario como eliminado: $e';
    }
  }

  /// Desactivar un usuario y marcarlo como eliminado
  static Future<void> deactivateUser(String uid) async {
    try {
      // 1. Marcar como eliminado en la base de datos
      await _markUserAsDeleted(uid);

      // 2. Eliminar datos relacionados (ej. códigos escaneados)
      await _deleteUserScannedCodes(uid);
    } catch (e) {
      throw 'Error al desactivar usuario: $e';
    }
  }

  /// Función auxiliar para marcar un usuario como eliminado en la DB
  static Future<void> _markUserAsDeleted(String uid) async {
    try {
      await _database.child('users').child(uid).update({
        'isDeleted': true,
        'isActive': false,
        'deletedAt': ServerValue.timestamp,
      });
    } catch (e) {
      throw 'Error al marcar usuario como eliminado: $e';
    }
  }

  

  /// Función auxiliar para eliminar códigos escaneados
  static Future<void> _deleteUserScannedCodes(String uid) async {
    try {
      final codesSnapshot = await _database
          .child('scannedCodes')
          .orderByChild('userId')
          .equalTo(uid)
          .get();

      if (codesSnapshot.exists) {
        final Map<dynamic, dynamic> codes =
            codesSnapshot.value as Map<dynamic, dynamic>;
        final updates = <String, dynamic>{};

        for (final entry in codes.entries) {
          updates['scannedCodes/${entry.key}'] = null;
        }

        await _database.update(updates);
      }
    } catch (e) {
      print('Error al eliminar códigos escaneados: $e');
    }
  }

  /// Obtener todos los usuarios (solo para administradores)
  static Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final snapshot = await _database.child('users').get();
      if (snapshot.exists) {
        final Map<dynamic, dynamic> users =
            snapshot.value as Map<dynamic, dynamic>;
        return users.entries
            .map((entry) => Map<String, dynamic>.from(entry.value as Map))
            .where((user) => user['isDeleted'] != true)
            .toList();
      }
      return [];
    } catch (e) {
      throw 'Error al obtener usuarios: $e';
    }
  }

  /// Obtener estadísticas de usuarios
  static Future<Map<String, int>> getUserStats() async {
    try {
      final users = await getAllUsers();
      final now = DateTime.now();
      final oneWeekAgo = now.subtract(const Duration(days: 7));
      final oneMonthAgo = now.subtract(const Duration(days: 30));

      int totalUsers = users.length;
      int activeUsers = users.where((user) => user['isActive'] == true).length;
      int adminUsers = users.where((user) => user['roles'] == 'admin').length;
      int newUsersThisWeek = 0;
      int newUsersThisMonth = 0;

      for (final user in users) {
        final createdAt = user['createdAt'];
        if (createdAt != null) {
          final createdDate = DateTime.fromMillisecondsSinceEpoch(createdAt);
          if (createdDate.isAfter(oneWeekAgo)) {
            newUsersThisWeek++;
          }
          if (createdDate.isAfter(oneMonthAgo)) {
            newUsersThisMonth++;
          }
        }
      }

      return {
        'totalUsers': totalUsers,
        'activeUsers': activeUsers,
        'adminUsers': adminUsers,
        'newUsersThisWeek': newUsersThisWeek,
        'newUsersThisMonth': newUsersThisMonth,
      };
    } catch (e) {
      throw 'Error al obtener estadísticas: $e';
    }
  }

  /// Guardar código escaneado
  static Future<void> saveScannedCode({
    required String uid,
    required String code,
    required String type,
    String? content,
    String? productName,
    double? productPrice,
  }) async {
    try {
      final userProfile = await getUserProfile(uid);
      final username = userProfile?['username'] ?? 'Usuario desconocido';
      final email = userProfile?['email'] ?? '';

      final scannedCodeData = {
        'code': code,
        'type': type,
        'content': content ?? '',
        'productName': productName ?? '',
        'productPrice': productPrice ?? 0.0,
        'userId': uid,
        'username': username,
        'userEmail': email,
        'scannedAt': ServerValue.timestamp,
        'isActive': true,
      };

      await _database.child('scannedCodes').push().set(scannedCodeData);
    } catch (e) {
      throw 'Error al guardar código escaneado: $e';
    }
  }

  /// Obtener historial de códigos escaneados por usuario
  static Future<List<Map<String, dynamic>>> getScannedCodesHistory(
    String uid,
  ) async {
    try {
      final snapshot = await _database
          .child('scannedCodes')
          .orderByChild('userId')
          .equalTo(uid)
          .get();

      if (snapshot.exists) {
        final Map<dynamic, dynamic> codes =
            snapshot.value as Map<dynamic, dynamic>;
        return codes.entries
            .map(
              (entry) => {
                'id': entry.key,
                ...Map<String, dynamic>.from(entry.value as Map),
              },
            )
            .toList();
      }
      return [];
    } catch (e) {
      throw 'Error al obtener historial de códigos: $e';
    }
  }

  /// Obtener todos los códigos escaneados (solo para administradores)
  static Future<List<Map<String, dynamic>>> getAllScannedCodes() async {
    try {
      final snapshot = await _database.child('scannedCodes').get();

      if (snapshot.exists) {
        final Map<dynamic, dynamic> codes =
            snapshot.value as Map<dynamic, dynamic>;

        final codesList = <Map<String, dynamic>>[];

        for (final entry in codes.entries) {
          final codeData = Map<String, dynamic>.from(entry.value as Map);
          final userId = codeData['userId'] as String?;

          Map<String, dynamic>? userInfo;
          if (userId != null) {
            try {
              userInfo = await getUserProfile(userId);
            } catch (e) {
              userInfo = null;
            }
          }

          codesList.add({'id': entry.key, ...codeData, 'userInfo': userInfo});
        }

        codesList.sort((a, b) {
          final aTime = a['scannedAt'] ?? 0;
          final bTime = b['scannedAt'] ?? 0;
          return bTime.compareTo(aTime);
        });

        return codesList;
      }
      return [];
    } catch (e) {
      throw 'Error al obtener todos los códigos: $e';
    }
  }

  /// Eliminar código escaneado
  static Future<void> deleteScannedCode(String codeId) async {
    try {
      await _database.child('scannedCodes').child(codeId).remove();
    } catch (e) {
      throw 'Error al eliminar código: $e';
    }
  }

  /// Buscar código existente por su valor
  static Future<Map<String, dynamic>?> findExistingCode(String code) async {
    try {
      final snapshot = await _database
          .child('scannedCodes')
          .orderByChild('code')
          .equalTo(code)
          .limitToFirst(1)
          .get();

      if (snapshot.exists && snapshot.value != null) {
        final Map<dynamic, dynamic> codes = snapshot.value as Map<dynamic, dynamic>;

        // Obtener el primer (y único) resultado
        final entry = codes.entries.first;
        final codeData = Map<String, dynamic>.from(entry.value as Map);
        codeData['id'] = entry.key;

        return codeData;
      }

      return null;
    } catch (e) {
      throw 'Error al buscar código existente: $e';
    }
  }

  /// Obtener configuración de la aplicación
  static Future<Map<String, dynamic>?> getAppSettings() async {
    try {
      final snapshot = await _database.child('settings').get();
      if (snapshot.exists) {
        return Map<String, dynamic>.from(snapshot.value as Map);
      }
      return null;
    } catch (e) {
      throw 'Error al obtener configuración: $e';
    }
  }

  /// Actualizar configuración de la aplicación
  static Future<void> updateAppSettings(Map<String, dynamic> settings) async {
    try {
      await _database.child('settings').update(settings);
    } catch (e) {
      throw 'Error al actualizar configuración: $e';
    }
  }

  /// Escuchar cambios en tiempo real en el perfil del usuario
  static Stream<Map<String, dynamic>?> listenToUserProfile(String uid) {
    return _database.child('users').child(uid).onValue.map((event) {
      if (event.snapshot.exists) {
        return Map<String, dynamic>.from(event.snapshot.value as Map);
      }
      return null;
    });
  }

  /// Escuchar cambios en tiempo real en los códigos escaneados
  static Stream<List<Map<String, dynamic>>> listenToScannedCodes(String uid) {
    return _database
        .child('scannedCodes')
        .orderByChild('userId')
        .equalTo(uid)
        .onValue
        .map((event) {
          if (event.snapshot.exists) {
            final Map<dynamic, dynamic> codes =
                event.snapshot.value as Map<dynamic, dynamic>;
            return codes.entries
                .map(
                  (entry) => {
                    'id': entry.key,
                    ...Map<String, dynamic>.from(entry.value as Map),
                  },
                )
                .toList();
          }
          return [];
        });
  }

  /// Crear producto
  static Future<String> createProduct(Product product) async {
    try {
      final newRef = _database.child('products').push();
      final productData = product.toMap();
      await newRef.set(productData);
      return newRef.key!;
    } catch (e) {
      throw 'Error al crear producto: $e';
    }
  }

  /// Crear producto desde código escaneado (simplificado)
  static Future<Product> createProductFromScannedCode({
    required String code,
    required String type,
    required String uid,
    String? productName,
    double? productPrice,
    String? description,
  }) async {
    try {
      // Verificar si ya existe un producto con este código
      final existingProduct = await findProductByBarcode(code);
      if (existingProduct != null) {
        throw 'Ya existe un producto con este código';
      }

      // Obtener información del usuario
      final userProfile = await getUserProfile(uid);
      final username = userProfile?['username'] ?? 'Usuario desconocido';
      final email = userProfile?['email'] ?? '';

      // Crear el producto con toda la información
      final product = Product(
        name: productName ?? 'Producto sin nombre',
        price: productPrice ?? 0.0,
        stock: 10, // Stock predeterminado
        description: description,
        barcode: code,
        code: code,
        type: type,
        scannedAt: DateTime.now(),
        userId: uid,
        username: username,
        userEmail: email,
        isActive: true,
      );

      final productId = await createProduct(product);

      // También guardar el código escaneado en el historial
      await saveScannedCode(
        uid: uid,
        code: code,
        type: type,
        content: '',
        productName: productName,
        productPrice: productPrice,
      );

      return Product(
        id: productId,
        name: product.name,
        price: product.price,
        stock: product.stock,
        description: product.description,
        barcode: product.barcode,
        code: product.code,
        type: product.type,
        scannedAt: product.scannedAt,
        userId: product.userId,
        username: product.username,
        userEmail: product.userEmail,
        isActive: product.isActive,
      );
    } catch (e) {
      throw 'Error al crear producto desde código escaneado: $e';
    }
  }

  /// Buscar producto por código escaneado
  static Future<Product?> findProductByScannedCode(String scannedCode) async {
    try {
      // Buscar en productos por barcode o code
      final product = await findProductByBarcode(scannedCode);
      if (product != null) {
        return product;
      }

      // Si no se encuentra por barcode, buscar por código
      final snapshot = await _database
          .child('products')
          .orderByChild('code')
          .equalTo(scannedCode)
          .limitToFirst(1)
          .get();

      if (snapshot.exists && snapshot.value != null) {
        final Map<dynamic, dynamic> products = snapshot.value as Map<dynamic, dynamic>;
        final entry = products.entries.first;
        return Product.fromMap(entry.key, Map<String, dynamic>.from(entry.value as Map));
      }

      return null;
    } catch (e) {
      throw 'Error al buscar producto por código escaneado: $e';
    }
  }

  /// Vincular código escaneado con producto (simplificado)
  static Future<void> _linkScannedCodeToProduct(
    String code,
    String productId,
    String? productName,
    double? productPrice,
  ) async {
    try {
      // Buscar el código escaneado
      final scannedCodeData = await findExistingCode(code);
      if (scannedCodeData != null) {
        final codeId = scannedCodeData['id'];

        // Actualizar el código escaneado con información del producto
        final updates = <String, dynamic>{};
        updates['scannedCodes/$codeId/productName'] = productName ?? '';
        updates['scannedCodes/$codeId/productPrice'] = productPrice ?? 0.0;
        updates['scannedCodes/$codeId/isActive'] = true;

        // Actualizar el producto con el código
        updates['products/$productId/code'] = code;

        await _database.update(updates);
      }
    } catch (e) {
      print('Error al vincular código escaneado con producto: $e');
    }
  }

  /// Actualizar producto
  static Future<void> updateProduct(String id, Product product) async {
    try {
      await _database.child('products').child(id).update(product.toMap());
    } catch (e) {
      throw 'Error al actualizar producto: $e';
    }
  }

  /// Eliminar producto
  static Future<void> deleteProduct(String id) async {
    try {
      await _database.child('products').child(id).remove();
    } catch (e) {
      throw 'Error al eliminar producto: $e';
    }
  }

  /// Obtener lista de productos
  static Future<List<Product>> getProducts() async {
    try {
      final snapshot = await _database.child('products').get();
      if (snapshot.exists) {
        final Map<dynamic, dynamic> products =
            snapshot.value as Map<dynamic, dynamic>;
        return products.entries
            .map((entry) => Product.fromMap(
                entry.key, Map<String, dynamic>.from(entry.value as Map)))
            .toList();
      }
      return [];
    } catch (e) {
      throw 'Error al obtener productos: $e';
    }
  }

  /// Buscar producto por barcode
  static Future<Product?> findProductByBarcode(String barcode) async {
    try {
      // Buscar por el campo barcode
      final snapshot = await _database
          .child('products')
          .orderByChild('barcode')
          .equalTo(barcode)
          .limitToFirst(1)
          .get();

      if (snapshot.exists && snapshot.value != null) {
        final Map<dynamic, dynamic> products = snapshot.value as Map<dynamic, dynamic>;
        final entry = products.entries.first;
        return Product.fromMap(entry.key, Map<String, dynamic>.from(entry.value as Map));
      }

      return null;
    } catch (e) {
      throw 'Error al buscar producto por barcode: $e';
    }
  }

  /// Registrar venta con transacción atómica
  static Future<void> registerSale(Sale sale) async {
    try {
      final productRef = _database.child('products').child(sale.productId);
      final transactionResult = await productRef.runTransaction((mutableData) {
        if (mutableData != null) {
          final productMap = Map<String, dynamic>.from(mutableData as Map);
          final currentStock = productMap['stock'] ?? 0;
          if (currentStock >= sale.quantity) {
            productMap['stock'] = currentStock - sale.quantity;
            return Transaction.success(productMap);
          } else {
            return Transaction.abort();
          }
        }
        return Transaction.abort();
      });

      if (transactionResult.committed) {
        // Crear la venta
        final newRef = _database.child('sales').push();
        final saleData = sale.toMap();
        await newRef.set(saleData);
      } else {
        throw 'Stock insuficiente para el producto';
      }
    } catch (e) {
      throw 'Error al registrar venta: $e';
    }
  }

  /// Obtener ventas por usuario
  static Future<List<Sale>> getSalesByUser(String userId) async {
    try {
      final snapshot = await _database
          .child('sales')
          .orderByChild('userId')
          .equalTo(userId)
          .get();

      if (snapshot.exists) {
        final Map<dynamic, dynamic> sales =
            snapshot.value as Map<dynamic, dynamic>;
        return sales.entries
            .map((entry) => Sale.fromMap(
                entry.key, Map<String, dynamic>.from(entry.value as Map)))
            .toList();
      }
      return [];
    } catch (e) {
      throw 'Error al obtener ventas: $e';
    }
  }

  /// Sincronizar códigos escaneados con productos (simplificado)
  static Future<Map<String, dynamic>> syncScannedCodesWithProducts() async {
    try {
      final stats = {
        'processed': 0,
        'created': 0,
        'updated': 0,
        'errors': 0,
      };

      // Obtener todos los códigos escaneados que tienen información de producto
      final codesSnapshot = await _database
          .child('scannedCodes')
          .orderByChild('productName')
          .get();

      if (!codesSnapshot.exists) {
        return stats;
      }

      final Map<dynamic, dynamic> codes = codesSnapshot.value as Map<dynamic, dynamic>;

      for (final entry in codes.entries) {
        final codeData = Map<String, dynamic>.from(entry.value as Map);
        final codeId = entry.key;
        final code = codeData['code'] as String?;
        final productName = codeData['productName'] as String?;
        final productPrice = codeData['productPrice'] as double?;

        // Solo procesar códigos que tienen información de producto
        if (code != null && productName != null && productName.isNotEmpty) {
          stats['processed'] = (stats['processed'] as int) + 1;

          try {
            // Verificar si ya existe un producto con este código
            final existingProduct = await findProductByBarcode(code);

            if (existingProduct == null) {
              // Crear nuevo producto con toda la información
              final product = Product(
                name: productName,
                price: productPrice ?? 0.0,
                stock: 10, // Stock predeterminado
                barcode: code,
                code: code,
                type: codeData['type'],
                content: codeData['content'],
                scannedAt: codeData['scannedAt'] != null
                    ? DateTime.fromMillisecondsSinceEpoch(codeData['scannedAt'])
                    : null,
                userId: codeData['userId'],
                username: codeData['username'],
                userEmail: codeData['userEmail'],
                isActive: true,
              );

              await createProduct(product);
              stats['created'] = (stats['created'] as int) + 1;
            } else {
              // Actualizar producto existente si no tiene código
              if (existingProduct.code == null) {
                await updateProduct(existingProduct.id!, Product(
                  id: existingProduct.id,
                  name: existingProduct.name,
                  price: existingProduct.price,
                  stock: existingProduct.stock,
                  description: existingProduct.description,
                  code: code,
                  type: codeData['type'],
                  content: codeData['content'],
                  scannedAt: codeData['scannedAt'] != null
                      ? DateTime.fromMillisecondsSinceEpoch(codeData['scannedAt'])
                      : null,
                  userId: codeData['userId'],
                  username: codeData['username'],
                  userEmail: codeData['userEmail'],
                  isActive: true,
                ));
                stats['updated'] = (stats['updated'] as int) + 1;
              }
            }
          } catch (e) {
            print('Error procesando código $code: $e');
            stats['errors'] = (stats['errors'] as int) + 1;
          }
        }
      }

      return stats;
    } catch (e) {
      throw 'Error al sincronizar códigos con productos: $e';
    }
  }

  /// Obtener productos con información de códigos escaneados (simplificado)
  static Future<List<Map<String, dynamic>>> getProductsWithScannedCodes() async {
    try {
      final products = await getProducts();
      final productsWithCodes = <Map<String, dynamic>>[];

      for (final product in products) {
        // Como ahora el producto ya tiene toda la información del código escaneado,
        // solo necesitamos devolver el producto con sus datos
        productsWithCodes.add({
          'product': product,
          'scannedCode': product.code != null ? {
            'id': product.id,
            'code': product.code,
            'type': product.type,
            'content': product.content,
            'scannedAt': product.scannedAt?.millisecondsSinceEpoch,
            'userId': product.userId,
            'username': product.username,
            'userEmail': product.userEmail,
          } : null,
        });
      }

      return productsWithCodes;
    } catch (e) {
      throw 'Error al obtener productos con códigos escaneados: $e';
    }
  }
}
