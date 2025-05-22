import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';

class DistribuidorService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Obtener lista de distribuidoras
  Future<List<Map<String, dynamic>>> getDistribuidoras() async {
    try {
      final snapshot = await _firestore
          .collection('distribuidoras')
          .orderBy('nombre')
          .get();

      return snapshot.docs
          .map((doc) => {
                ...doc.data(),
                'id': doc.id,
              })
          .toList();
    } catch (e) {
      // En caso de error, devolver lista predefinida
      return [
        {'id': '1', 'nombre': 'Enel Distribución', 'region': 'Metropolitana'},
        {'id': '2', 'nombre': 'CGE Distribución', 'region': 'Múltiples'},
        {'id': '3', 'nombre': 'Chilquinta', 'region': 'Valparaíso'},
        {'id': '4', 'nombre': 'Saesa', 'region': 'Sur'},
        {'id': '5', 'nombre': 'Frontel', 'region': 'Sur'},
        {'id': '6', 'nombre': 'Otras', 'region': 'Otra'},
      ];
    }
  }

  // Buscar información de una distribuidora por nombre
  Future<Map<String, dynamic>?> getDistribuidoraPorNombre(String nombre) async {
    try {
      final snapshot = await _firestore
          .collection('distribuidoras')
          .where('nombre', isEqualTo: nombre)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      return {
        ...snapshot.docs.first.data(),
        'id': snapshot.docs.first.id,
      };
    } catch (e) {
      rethrow;
    }
  }

  // Obtener tarifas de una distribuidora
  Future<Map<String, dynamic>> getTarifas(String distribuidoraId) async {
    try {
      final doc = await _firestore
          .collection('distribuidoras')
          .doc(distribuidoraId)
          .collection('tarifas')
          .doc('actual') // Documento con tarifas actuales
          .get();

      if (!doc.exists) {
        throw Exception('No se encontraron tarifas para esta distribuidora');
      }

      return doc.data()!;
    } catch (e) {
      // Devolver tarifas predeterminadas
      return {
        'cargoFijo': 1200.0,
        'kwhBase': 130.0,
        'fechaActualizacion': Timestamp.now(),
      };
    }
  }

  // Simular extracción de datos de una boleta mediante OCR
  Future<Map<String, dynamic>> extraerDatosBoleta(File imagen) async {
    // Aquí iría la lógica real de OCR, pero por ahora simulamos
    
    // Simular tiempo de procesamiento
    await Future.delayed(const Duration(seconds: 2));
    
    // Simular datos extraídos
    return {
      'distribuidora': 'Enel Distribución',
      'numeroCliente': '10054321',
      'fecha': DateTime.now(),
      'monto': 32500.0,
      'kwh': 250.0,
      'exito': true,
    };
  }

  // Obtener información de consumo desde la web de la distribuidora (simulado)
  Future<List<Map<String, dynamic>>> obtenerConsumoDesdeDistribuidora({
    required String distribuidora,
    required String numeroCliente,
    int meses = 6,
  }) async {
    // Aquí iría la implementación real por web scraping o API
    
    // Simular tiempo de procesamiento
    await Future.delayed(const Duration(seconds: 3));
    
    // Generar datos simulados para los últimos meses
    final ahora = DateTime.now();
    final consumos = <Map<String, dynamic>>[];
    
    for (var i = 0; i < meses; i++) {
      final fecha = DateTime(ahora.year, ahora.month - i, 15);
      final kwh = 200.0 + (50.0 * (i % 3)); // Variación para simular
      final monto = kwh * 130.0; // Precio simulado por kWh
      
      consumos.add({
        'fecha': fecha,
        'mes': _obtenerNombreMes(fecha.month),
        'ano': fecha.year,
        'kwh': kwh,
        'monto': monto,
      });
    }
    
    return consumos;
  }
  
  // Método de ayuda para obtener nombre del mes
  String _obtenerNombreMes(int mes) {
    const meses = [
      'Enero', 'Febrero', 'Marzo', 'Abril',
      'Mayo', 'Junio', 'Julio', 'Agosto',
      'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return meses[mes - 1];
  }
} 