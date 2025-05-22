import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  // Asegurar que se inicialice Flutter
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar Firebase con mejor gestión de errores
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase inicializado correctamente');
    
    // Verificar si Firebase Auth está disponible
    final auth = FirebaseAuth.instance;
    print('Firebase Auth disponible: ${auth != null}');
    
  } catch (e) {
    print('ERROR AL INICIALIZAR FIREBASE: $e');
    if (e is FirebaseException) {
      print('Código de error: ${e.code}');
      print('Mensaje: ${e.message}');
      print('Stack trace: ${e.stackTrace}');
    }
  }
  
  runApp(const KwentaApp());
}

class KwentaApp extends StatelessWidget {
  const KwentaApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kwenta',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
      ),
      home: const LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
