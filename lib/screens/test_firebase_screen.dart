import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TestFirebaseScreen extends StatefulWidget {
  const TestFirebaseScreen({super.key});

  @override
  State<TestFirebaseScreen> createState() => _TestFirebaseScreenState();
}

class _TestFirebaseScreenState extends State<TestFirebaseScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _rutController = TextEditingController();
  
  String _resultado = "No se ha realizado ninguna operación";
  bool _estaOperando = false;
  
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _rutController.dispose();
    super.dispose();
  }
  
  Future<void> _probarRegistro() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final rut = _rutController.text.trim();
    
    if (email.isEmpty || password.isEmpty || rut.isEmpty) {
      setState(() {
        _resultado = "Por favor, completa todos los campos";
      });
      return;
    }
    
    setState(() {
      _estaOperando = true;
      _resultado = "Intentando crear usuario...";
    });
    
    try {
      // 1. Primero intentamos crear el usuario en Firebase Auth
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      setState(() {
        _resultado = "Usuario creado en Auth. UID: ${credential.user?.uid}\nGuardando datos en Firestore...";
      });
      
      // 2. Luego guardamos datos adicionales en Firestore
      try {
        await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(credential.user?.uid)
            .set({
          'email': email,
          'rut': rut,
          'createdAt': FieldValue.serverTimestamp(),
        });
        
        setState(() {
          _resultado = "¡Usuario creado con éxito!\nAuth UID: ${credential.user?.uid}\nDatos guardados en Firestore.";
        });
      } catch (firestoreError) {
        setState(() {
          _resultado = "Usuario creado en Auth pero error al guardar en Firestore:\n$firestoreError";
        });
      }
      
    } on FirebaseAuthException catch (e) {
      String mensajeError = "Error de Firebase Auth: ${e.code}";
      switch (e.code) {
        case 'email-already-in-use':
          mensajeError = "Este correo ya está registrado.";
          break;
        case 'invalid-email':
          mensajeError = "El formato del correo no es válido.";
          break;
        case 'weak-password':
          mensajeError = "La contraseña es demasiado débil.";
          break;
        case 'operation-not-allowed':
          mensajeError = "El registro con correo y contraseña no está habilitado.";
          break;
      }
      
      setState(() {
        _resultado = mensajeError;
      });
    } catch (e) {
      setState(() {
        _resultado = "Error desconocido: $e";
      });
    } finally {
      setState(() {
        _estaOperando = false;
      });
    }
  }
  
  Future<void> _verificarConexion() async {
    setState(() {
      _estaOperando = true;
      _resultado = "Verificando conexión a Firebase...";
    });
    
    try {
      // Verificar Firebase Auth
      final auth = FirebaseAuth.instance;
      
      // Verificar Firestore
      final firestore = FirebaseFirestore.instance;
      await firestore.collection('test').doc('conexion').set({
        'timestamp': FieldValue.serverTimestamp(),
        'test': 'conexión exitosa'
      });
      
      setState(() {
        _resultado = "Conexión exitosa a Firebase Auth y Firestore.\n"
                   "Auth instance: ${auth != null}\n"
                   "Documento de prueba creado en Firestore.";
      });
    } catch (e) {
      setState(() {
        _resultado = "Error al verificar conexión: $e";
      });
    } finally {
      setState(() {
        _estaOperando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prueba de Firebase'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Esta pantalla permite diagnosticar problemas con Firebase',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              
              // Formulario de prueba
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Correo electrónico',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Contraseña',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _rutController,
                decoration: const InputDecoration(
                  labelText: 'RUT',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              
              // Botones de acción
              ElevatedButton(
                onPressed: _estaOperando ? null : _probarRegistro,
                child: const Text('Probar Registro'),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _estaOperando ? null : _verificarConexion,
                child: const Text('Verificar Conexión a Firebase'),
              ),
              
              const SizedBox(height: 24),
              const Text('Resultado:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              
              // Área de resultado
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _estaOperando
                    ? const Center(child: CircularProgressIndicator())
                    : Text(_resultado),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 