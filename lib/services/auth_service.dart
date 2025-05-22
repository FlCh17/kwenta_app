import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Obtener usuario actual
  User? get currentUser => _auth.currentUser;

  // Stream para escuchar cambios en el estado de autenticación
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Iniciar sesión con correo y contraseña
  Future<UserCredential> signInWithEmail(String email, String password) async {
    try {
      print('Intentando iniciar sesión con email: $email');
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      print('Error en signInWithEmail: $e');
      rethrow;
    }
  }

  // Iniciar sesión con RUT (utilizamos el RUT como nombre de usuario)
  Future<UserCredential> signInWithRut(String rut, String password) async {
    try {
      print('Intentando iniciar sesión con RUT: $rut');
      // Buscar el correo asociado al RUT en Firestore
      final userDoc = await _firestore
          .collection('usuarios')
          .where('rut', isEqualTo: rut)
          .limit(1)
          .get();

      if (userDoc.docs.isEmpty) {
        print('No se encontró ningún usuario con el RUT: $rut');
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'No se encontró ningún usuario con este RUT',
        );
      }

      // Obtener el correo del documento y usar para autenticar
      final email = userDoc.docs.first.data()['email'] as String;
      print('RUT encontrado, email asociado: $email');
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      print('Error en signInWithRut: $e');
      rethrow;
    }
  }

  // Registro con correo, contraseña y datos adicionales
  Future<UserCredential> registerWithEmail({
    required String email,
    required String password,
    required String rut,
    required String numeroCliente,
    required String distribuidora,
  }) async {
    try {
      print('Intentando registrar usuario con email: $email, rut: $rut');
      
      // Crear el usuario en Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      print('Usuario creado en Auth, UID: ${userCredential.user?.uid}');

      // Guardar datos adicionales en Firestore
      await _firestore.collection('usuarios').doc(userCredential.user!.uid).set({
        'email': email,
        'rut': rut,
        'numeroCliente': numeroCliente,
        'distribuidora': distribuidora,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      print('Datos guardados en Firestore para usuario: ${userCredential.user?.uid}');

      return userCredential;
    } catch (e) {
      print('ERROR EN registerWithEmail: $e');
      if (e is FirebaseAuthException) {
        print('Código de error: ${e.code}');
        print('Mensaje: ${e.message}');
      }
      rethrow;
    }
  }

  // Obtener datos del usuario actual
  Future<Map<String, dynamic>?> getCurrentUserData() async {
    try {
      if (currentUser == null) return null;

      final doc = await _firestore
          .collection('usuarios')
          .doc(currentUser!.uid)
          .get();

      if (!doc.exists) return null;

      return doc.data();
    } catch (e) {
      print('Error en getCurrentUserData: $e');
      rethrow;
    }
  }

  // Cerrar sesión
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Error en signOut: $e');
      rethrow;
    }
  }

  // Recuperar contraseña
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      print('Error en resetPassword: $e');
      rethrow;
    }
  }
} 