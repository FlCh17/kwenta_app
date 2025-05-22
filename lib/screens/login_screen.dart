import 'package:flutter/material.dart';
import 'dashboard_screen.dart'; // Importa el dashboard
import '../services/services.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  // Servicios
  final AuthService _authService = AuthService();
  
  // Controladores para la pestaña de login
  final _loginIdentifierController = TextEditingController(); // Para RUT o correo
  final _loginPasswordController = TextEditingController();
  
  // Controladores para la pestaña de registro
  final _registerRutController = TextEditingController();
  final _registerEmailController = TextEditingController();
  final _registerPasswordController = TextEditingController();
  final _registerConfirmPasswordController = TextEditingController();
  final _registerClienteNumController = TextEditingController();
  
  // Controlador para recuperación de contraseña
  final _recoveryEmailController = TextEditingController();
  
  // Variables para control de UI
  late TabController _tabController;
  bool _isLoading = false;
  bool _showRecoveryForm = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  
  // Lista de empresas distribuidoras
  final _distribuidoras = [
    'Enel Distribución',
    'CGE Distribución',
    'Chilquinta',
    'Saesa',
    'Frontel',
    'Otras'
  ];
  
  String _distribuidoraSeleccionada = 'Enel Distribución';
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Verificar si ya hay un usuario autenticado
    _checkCurrentUser();
  }
  
  void _checkCurrentUser() async {
    final currentUser = _authService.currentUser;
    if (currentUser != null) {
      // Si ya hay un usuario autenticado, navegar al dashboard
      _navigateToDashboard(currentUser.email ?? 'Usuario', true);
    }
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _loginIdentifierController.dispose();
    _loginPasswordController.dispose();
    _registerRutController.dispose();
    _registerEmailController.dispose();
    _registerPasswordController.dispose();
    _registerConfirmPasswordController.dispose();
    _registerClienteNumController.dispose();
    _recoveryEmailController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    final identifier = _loginIdentifierController.text.trim();
    final password = _loginPasswordController.text;
    
    if (identifier.isEmpty || password.isEmpty) {
      _showSnackBar('Por favor ingresa tu RUT o correo y contraseña');
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      UserCredential userCredential;
      
      // Detectar si es un email o un RUT
      bool isEmail = identifier.contains('@');
      
      if (isEmail) {
        userCredential = await _authService.signInWithEmail(identifier, password);
      } else {
        userCredential = await _authService.signInWithRut(identifier, password);
      }
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        // Navegar al dashboard
        _navigateToDashboard(
          isEmail ? identifier : userCredential.user?.email ?? 'Usuario', 
          isEmail
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      String mensaje = 'Error al iniciar sesión';
      
      switch (e.code) {
        case 'user-not-found':
          mensaje = 'No existe una cuenta con este correo o RUT';
          break;
        case 'wrong-password':
          mensaje = 'Contraseña incorrecta';
          break;
        case 'invalid-email':
          mensaje = 'Correo electrónico inválido';
          break;
        default:
          mensaje = 'Error: ${e.message}';
      }
      
      _showSnackBar(mensaje);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Error: $e');
    }
  }
  
  void _handleRegister() async {
    final rut = _registerRutController.text.trim();
    final email = _registerEmailController.text.trim();
    final password = _registerPasswordController.text;
    final confirmPassword = _registerConfirmPasswordController.text;
    final clienteNum = _registerClienteNumController.text.trim();
    
    // Validaciones
    if (rut.isEmpty || email.isEmpty || password.isEmpty || 
        confirmPassword.isEmpty || clienteNum.isEmpty) {
      _showSnackBar('Por favor completa todos los campos');
      return;
    }
    
    if (password != confirmPassword) {
      _showSnackBar('Las contraseñas no coinciden');
      return;
    }
    
    if (password.length < 6) {
      _showSnackBar('La contraseña debe tener al menos 6 caracteres');
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Registrar usuario
      await _authService.registerWithEmail(
        email: email,
        password: password,
        rut: rut,
        numeroCliente: clienteNum,
        distribuidora: _distribuidoraSeleccionada,
      );
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        // Mostrar mensaje de éxito y navegar al dashboard
        _showSnackBar('¡Registro exitoso!');
        _navigateToDashboard(email, true);
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      String mensaje = 'Error al registrar usuario';
      
      switch (e.code) {
        case 'email-already-in-use':
          mensaje = 'Ya existe una cuenta con este correo electrónico';
          break;
        case 'invalid-email':
          mensaje = 'Correo electrónico inválido';
          break;
        case 'weak-password':
          mensaje = 'La contraseña es demasiado débil';
          break;
        default:
          mensaje = 'Error: ${e.message}';
      }
      
      _showSnackBar(mensaje);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Error: $e');
    }
  }
  
  void _handlePasswordRecovery() async {
    final email = _recoveryEmailController.text.trim();
    
    if (email.isEmpty) {
      _showSnackBar('Por favor ingresa tu correo electrónico');
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      await _authService.resetPassword(email);
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          _showRecoveryForm = false;
        });
        
        _showSnackBar('Hemos enviado un correo con instrucciones para recuperar tu contraseña');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Error al enviar instrucciones de recuperación: $e');
    }
  }
  
  void _navigateToDashboard(String identifier, bool isEmail) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => DashboardScreen(
          isEmailLogin: isEmail,
          identifier: identifier,
        ),
      ),
    );
  }
  
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kwenta'),
        bottom: _showRecoveryForm ? null : TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Iniciar Sesión'),
            Tab(text: 'Registrarse'),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: _isLoading 
        ? _buildLoadingView() 
        : _showRecoveryForm 
          ? _buildRecoveryForm()
          : TabBarView(
              controller: _tabController,
              children: [
                _buildLoginForm(),
                _buildRegisterForm(),
              ],
            ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          TextField(
            controller: _loginIdentifierController,
            decoration: const InputDecoration(
              labelText: 'RUT o Correo electrónico',
              hintText: 'Ingresa tu RUT o correo',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _loginPasswordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Contraseña',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.lock),
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                setState(() {
                  _showRecoveryForm = true;
                });
              },
              child: const Text('¿Olvidaste tu contraseña?'),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _handleLogin,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Ingresar'),
          ),
          const SizedBox(height: 16),
          // Implementación básica de login con biometría
          OutlinedButton.icon(
            onPressed: () {
              _showSnackBar('Autenticación biométrica no disponible en esta versión');
            },
            icon: const Icon(Icons.fingerprint),
            label: const Text('Ingresar con huella digital'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterForm() {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 10),
          TextField(
            controller: _registerRutController,
            decoration: const InputDecoration(
              labelText: 'RUT',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _registerEmailController,
            decoration: const InputDecoration(
              labelText: 'Correo electrónico',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.email),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _registerPasswordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Contraseña',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.lock),
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _registerConfirmPasswordController,
            obscureText: _obscureConfirmPassword,
            decoration: InputDecoration(
              labelText: 'Confirmar contraseña',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_obscureConfirmPassword ? Icons.visibility : Icons.visibility_off),
                onPressed: () {
                  setState(() {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _registerClienteNumController,
                decoration: const InputDecoration(
                  labelText: 'Número de Cliente',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.pin),
                ),
                keyboardType: TextInputType.number,
              ),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () => _mostrarEjemploBoleta(context),
                    icon: const Icon(Icons.help_outline, size: 16),
                    label: const Text('¿Dónde encuentro mi N° Cliente?'),
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => _escanearBoleta(context),
                    icon: const Icon(Icons.document_scanner, size: 16),
                    label: const Text('Escanear boleta'),
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Empresa Distribuidora',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.business),
            ),
            value: _distribuidoraSeleccionada,
            items: _distribuidoras.map((String distribuidora) {
              return DropdownMenuItem<String>(
                value: distribuidora,
                child: Text(distribuidora),
              );
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() {
                  _distribuidoraSeleccionada = newValue;
                });
              }
            },
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _handleRegister,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Crear cuenta'),
          ),
          const SizedBox(height: 16),
          const Text(
            'Al registrarte, aceptas nuestros Términos y Condiciones y Política de Privacidad',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildRecoveryForm() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(
          Icons.lock_reset,
          size: 80,
          color: Colors.indigo,
        ),
        const SizedBox(height: 24),
        const Text(
          'Recuperar contraseña',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        const Text(
          'Ingresa tu correo electrónico y te enviaremos instrucciones para recuperar tu contraseña.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _recoveryEmailController,
          decoration: const InputDecoration(
            labelText: 'Correo electrónico',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.email),
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _handlePasswordRecovery,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Text('Enviar instrucciones'),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () {
            setState(() {
              _showRecoveryForm = false;
            });
          },
          child: const Text('Volver al inicio de sesión'),
        ),
      ],
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(
            _showRecoveryForm 
            ? 'Enviando instrucciones de recuperación...'
            : _tabController.index == 0 
              ? 'Iniciando sesión...' 
              : 'Registrando cuenta...',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 12),
          const Text(
            'Esto puede tardar unos segundos...',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // Nuevo método para mostrar ejemplo de boleta
  void _mostrarEjemploBoleta(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '¿Dónde encontrar tu N° Cliente?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long, size: 60, color: Colors.indigo),
                      SizedBox(height: 8),
                      Text('Ejemplo de boleta'),
                      SizedBox(height: 16),
                      Text('N° Cliente: 10054321', style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      Text('Busca este número en la parte\nsuperior de tu boleta', textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'El N° Cliente suele estar en la parte superior de la boleta, generalmente junto a tus datos personales.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Entendido'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 40),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Nuevo método para escanear boleta
  void _escanearBoleta(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Escanear boleta',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Toma una foto clara de tu boleta para extraer automáticamente el N° Cliente y la empresa distribuidora.',
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: InkWell(
                          onTap: () => _simularTomaFoto(context),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo, size: 56, color: Colors.indigo),
                              SizedBox(height: 16),
                              Text('Tomar foto de la boleta'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Row(
                        children: [
                          Expanded(
                            child: Divider(),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text('o'),
                          ),
                          Expanded(
                            child: Divider(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: () => _simularSeleccionarFoto(context),
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Seleccionar desde galería'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Métodos para simular la captura y procesamiento de la boleta
  void _simularTomaFoto(BuildContext context) {
    Navigator.pop(context); // Cerrar el modal actual
    _mostrarProcesamientoImagen(context);
  }
  
  void _simularSeleccionarFoto(BuildContext context) {
    Navigator.pop(context); // Cerrar el modal actual
    _mostrarProcesamientoImagen(context);
  }
  
  void _mostrarProcesamientoImagen(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              const CircularProgressIndicator(),
              const SizedBox(height: 24),
              const Text(
                'Procesando imagen...',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Estamos extrayendo la información de tu boleta',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
    
    // Simulamos el tiempo de procesamiento
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pop(context); // Cerrar diálogo de procesamiento
      
      // Actualizar los campos con la información "extraída"
      setState(() {
        _registerClienteNumController.text = '10054321';
        _distribuidoraSeleccionada = 'Enel Distribución';
      });
      
      // Mostrar mensaje de éxito
      _showSnackBar('Información extraída correctamente');
    });
  }
}
