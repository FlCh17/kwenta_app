import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'consumo_service.dart';

class NotificacionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ConsumoService _consumoService = ConsumoService();

  // Obtener alertas del usuario
  Future<List<Map<String, dynamic>>> getAlertas() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('Usuario no autenticado');

      final snapshot = await _firestore
          .collection('usuarios')
          .doc(userId)
          .collection('alertas')
          .orderBy('fecha', descending: true)
          .get();

      // Si no hay alertas, generar algunas basadas en el consumo
      if (snapshot.docs.isEmpty) {
        await _generarAlertasAutomaticas();
        
        // Buscar nuevamente las alertas generadas
        final snapshotNuevo = await _firestore
            .collection('usuarios')
            .doc(userId)
            .collection('alertas')
            .orderBy('fecha', descending: true)
            .get();
            
        return snapshotNuevo.docs
            .map((doc) => {
                  ...doc.data(),
                  'id': doc.id,
                })
            .toList();
      }

      return snapshot.docs
          .map((doc) => {
                ...doc.data(),
                'id': doc.id,
              })
          .toList();
    } catch (e) {
      // En caso de error, devolver alertas predefinidas
      return [
        {
          'id': '1',
          'titulo': 'Consumo superior al promedio',
          'descripcion': 'Tu consumo de junio fue un 19% mayor al promedio mensual',
          'tipo': 'warning',
          'fecha': Timestamp.now(),
          'leida': false,
        },
        {
          'id': '2',
          'titulo': 'Recordatorio de pago',
          'descripcion': 'Tu próxima factura vence en 5 días',
          'tipo': 'info',
          'fecha': Timestamp.now(),
          'leida': false,
        },
      ];
    }
  }

  // Marcar alerta como leída
  Future<void> marcarAlertaLeida(String alertaId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('Usuario no autenticado');

      await _firestore
          .collection('usuarios')
          .doc(userId)
          .collection('alertas')
          .doc(alertaId)
          .update({'leida': true});
    } catch (e) {
      rethrow;
    }
  }

  // Crear nueva alerta
  Future<void> crearAlerta({
    required String titulo,
    required String descripcion,
    required String tipo,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('Usuario no autenticado');

      await _firestore
          .collection('usuarios')
          .doc(userId)
          .collection('alertas')
          .add({
        'titulo': titulo,
        'descripcion': descripcion,
        'tipo': tipo,
        'fecha': Timestamp.now(),
        'leida': false,
      });
    } catch (e) {
      rethrow;
    }
  }

  // Generar alertas automáticas basadas en el consumo
  Future<void> _generarAlertasAutomaticas() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      // Obtener datos de consumo
      final consumos = await _consumoService.getHistorialConsumo();
      if (consumos.isEmpty) return;

      final ultimoConsumo = consumos.first;
      final promedio = await _consumoService.getConsumoPromedio();
      
      // Generar alerta si el último consumo está por encima del promedio
      if (ultimoConsumo['kwh'] > promedio * 1.15) {
        final porcentaje = ((ultimoConsumo['kwh'] - promedio) / promedio * 100).toInt();
        
        await crearAlerta(
          titulo: 'Consumo superior al promedio',
          descripcion: 'Tu consumo de ${ultimoConsumo['mes']} fue un $porcentaje% mayor al promedio mensual',
          tipo: 'warning',
        );
      }
      
      // Alerta de recordatorio de pago (simulada)
      final ahora = DateTime.now();
      if (ahora.day > 10 && ahora.day < 15) {
        await crearAlerta(
          titulo: 'Recordatorio de pago',
          descripcion: 'Tu próxima factura vence en ${25 - ahora.day} días',
          tipo: 'info',
        );
      }
      
    } catch (e) {
      // Ignorar errores en este proceso automático
    }
  }

  // Mostrar notificación en la UI
  void mostrarNotificacion(BuildContext context, String mensaje, {bool esError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: esError ? Colors.red : Colors.indigo,
      ),
    );
  }
} 