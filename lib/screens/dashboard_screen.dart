import 'package:flutter/material.dart';
import '../services/services.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'login_screen.dart';

class DashboardScreen extends StatefulWidget {
  final bool isEmailLogin;
  final String identifier;
  
  const DashboardScreen({
    super.key, 
    this.isEmailLogin = false, 
    this.identifier = "Usuario"
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedIndex = 0;
  bool _isLoading = false;
  
  // Datos de consumo simulados para los últimos 6 meses
  late List<Map<String, dynamic>> _consumosMensuales = [
    {'mes': 'Enero', 'kwh': 220, 'monto': 28500},
    {'mes': 'Febrero', 'kwh': 240, 'monto': 31200},
    {'mes': 'Marzo', 'kwh': 280, 'monto': 36400},
    {'mes': 'Abril', 'kwh': 195, 'monto': 25350},
    {'mes': 'Mayo', 'kwh': 210, 'monto': 27300},
    {'mes': 'Junio', 'kwh': 250, 'monto': 32500},
  ];
  
  // Datos de consumo comparativo
  late Map<String, dynamic> _comparativoAnual = {
    'consumoActual': 1395, // kWh totales en los últimos 6 meses
    'consumoAnterior': 1520, // kWh totales mismo periodo año anterior
    'ahorro': 125, // kWh ahorrados
    'porcentaje': 8.2, // % de ahorro
  };
  
  // Alertas del usuario
  late List<Map<String, dynamic>> _alertas = [
    {
      'titulo': 'Consumo superior al promedio',
      'descripcion': 'Tu consumo de junio fue un 19% mayor al promedio mensual',
      'tipo': 'warning', // tipos: info, warning, success
      'fecha': '01/07/2023',
    },
    {
      'titulo': 'Recordatorio de pago',
      'descripcion': 'Tu próxima factura vence en 5 días',
      'tipo': 'info',
      'fecha': '10/07/2023',
    },
  ];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Obtener datos desde Firebase
    _cargarDatos();
  }
  
  void _cargarDatos() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final consumoService = ConsumoService();
      final notificacionService = NotificacionService();
      
      // Obtener datos de consumo
      final consumos = await consumoService.getHistorialConsumo();
      if (consumos.isNotEmpty) {
        setState(() {
          // Convertir a formato de la aplicación
          _consumosMensuales = consumos.map((consumo) => {
            'mes': consumo['mes'] as String,
            'kwh': (consumo['kwh'] as num).toDouble(),
            'monto': (consumo['monto'] as num).toDouble(),
          }).toList();
        });
      }
      
      // Obtener comparativa anual
      final comparativa = await consumoService.getComparativaAnual();
      setState(() {
        _comparativoAnual = comparativa;
      });
      
      // Obtener alertas
      final alertas = await notificacionService.getAlertas();
      if (alertas.isNotEmpty) {
        setState(() {
          _alertas = alertas.map((alerta) => {
            'id': alerta['id'] as String,
            'titulo': alerta['titulo'] as String,
            'descripcion': alerta['descripcion'] as String,
            'tipo': alerta['tipo'] as String,
            'fecha': alerta['fecha'].toString(),
            'leida': alerta['leida'] as bool,
          }).toList();
        });
      }
    } catch (e) {
      // En caso de error, usar datos simulados
      print('Error al cargar datos: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kwenta'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              _mostrarNotificaciones(context);
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarDatos,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Dashboard'),
            Tab(text: 'Histórico'),
            Tab(text: 'Boletas'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildDashboardTab(),
                _buildHistoricoTab(),
                _buildBoletasTab(),
              ],
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
          
          // Navegación según BottomNavigationBar
          if (index == 2) { // Si es el perfil
            _mostrarPerfil(context);
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Alertas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _cargarBoleta(context);
        },
        child: const Icon(Icons.add),
        tooltip: 'Cargar boleta',
      ),
    );
  }
  
  Widget _buildDashboardTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildClienteInfo(),
          const SizedBox(height: 20),
          _buildResumenConsumo(_consumosMensuales.last),
          const SizedBox(height: 24),
          _buildTitleWithAction(
            'Historial de Consumo', 
            'Ver Completo', 
            () {
              _tabController.animateTo(1); // Ir a pestaña Histórico
            }
          ),
          const SizedBox(height: 8),
          _buildHistorialConsumo(_consumosMensuales),
          const SizedBox(height: 24),
          _buildComparativoAnual(),
          const SizedBox(height: 24),
          _buildTitleWithAction(
            'Recomendaciones', 
            'Ver Todas', 
            () {
              // Aquí iría la navegación a recomendaciones
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Mostrando todas las recomendaciones...')),
              );
            }
          ),
          const SizedBox(height: 8),
          _buildRecomendaciones(),
        ],
      ),
    );
  }
  
  Widget _buildHistoricoTab() {
    // Ampliamos los datos para tener un histórico más largo
    final historicoCompleto = [
      ..._consumosMensuales,
      {'mes': 'Julio', 'kwh': 240, 'monto': 31200},
      {'mes': 'Agosto', 'kwh': 230, 'monto': 29900},
      {'mes': 'Septiembre', 'kwh': 210, 'monto': 27300},
      {'mes': 'Octubre', 'kwh': 200, 'monto': 26000},
      {'mes': 'Noviembre', 'kwh': 240, 'monto': 31200},
      {'mes': 'Diciembre', 'kwh': 260, 'monto': 33800},
    ];
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Consumo Histórico',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 220,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: historicoCompleto.map((consumo) {
                        // Calculamos altura relativa basada en el consumo
                        final double alturaRelativa = (consumo['kwh'] / 300) * 150;
                        
                        return Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text('${consumo['kwh']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              const SizedBox(height: 4),
                              Container(
                                height: alturaRelativa,
                                width: 12,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.blue.shade300, Colors.blue.shade600],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                consumo['mes'].substring(0, 3), 
                                style: const TextStyle(fontSize: 10),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildEstadisticaItem('Promedio', '225 kWh', Colors.blue),
                      _buildEstadisticaItem('Máximo', '280 kWh', Colors.red),
                      _buildEstadisticaItem('Mínimo', '195 kWh', Colors.green),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Detalle Mensual',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: historicoCompleto.length,
            itemBuilder: (context, index) {
              final consumo = historicoCompleto[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(consumo['mes']),
                  subtitle: Text('Monto: \$${consumo['monto']}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${consumo['kwh']} kWh',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                        color: Colors.grey.shade600,
                      ),
                    ],
                  ),
                  onTap: () {
                    _mostrarDetalleMes(context, consumo);
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBoletasTab() {
    final boletas = [
      {
        'fecha': '15/06/2023',
        'monto': 32500,
        'estado': 'Pagada',
        'archivo': 'boleta_junio.pdf',
      },
      {
        'fecha': '15/05/2023',
        'monto': 27300,
        'estado': 'Pagada',
        'archivo': 'boleta_mayo.pdf',
      },
      {
        'fecha': '15/04/2023',
        'monto': 25350,
        'estado': 'Pagada',
        'archivo': 'boleta_abril.pdf',
      },
    ];
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mis Boletas',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: boletas.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        const Text(
                          'No tienes boletas cargadas',
                          style: TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: () => _cargarBoleta(context),
                          icon: const Icon(Icons.add),
                          label: const Text('Cargar boleta'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: boletas.length,
                    itemBuilder: (context, index) {
                      final boleta = boletas[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.indigo.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.picture_as_pdf, color: Colors.indigo),
                          ),
                          title: Text('Boleta ${boleta['fecha']}'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Monto: \$${boleta['monto']}'),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: boleta['estado'] == 'Pagada' ? Colors.green.shade100 : Colors.orange.shade100,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      boleta['estado'] as String,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: boleta['estado'] == 'Pagada' ? Colors.green.shade800 : Colors.orange.shade800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.download),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Descargando ${boleta['archivo']}...')),
                              );
                            },
                          ),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Abriendo boleta de ${boleta['fecha']}')),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildClienteInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.indigo.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cliente: Juan Pérez',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            'Empresa: Enel Distribución',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 4),
          Text(
            'N° Cliente: 10054321',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 4),
          Text(
            widget.isEmailLogin 
              ? 'Identificación: ${widget.identifier} (Correo)' 
              : 'Identificación: ${widget.identifier} (RUT)',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }

  Widget _buildResumenConsumo(Map<String, dynamic> ultimoMes) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo.shade300, Colors.indigo.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resumen del Último Mes',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildConsumoDato('Consumo', '${ultimoMes['kwh']} kWh', Icons.bolt),
              _buildConsumoDato('Monto', '\$${ultimoMes['monto']}', Icons.attach_money),
              _buildConsumoDato('Mes', ultimoMes['mes'], Icons.calendar_today),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () {
                  _mostrarDetalleMes(context, ultimoMes);
                },
                icon: const Icon(Icons.visibility, color: Colors.white70),
                label: const Text(
                  'Ver detalle',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConsumoDato(String titulo, String valor, IconData icono) {
    return Column(
      children: [
        Icon(icono, color: Colors.white, size: 28),
        const SizedBox(height: 8),
        Text(
          titulo,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        const SizedBox(height: 4),
        Text(
          valor,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildTitleWithAction(String title, String actionText, VoidCallback onAction) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        TextButton(
          onPressed: onAction,
          child: Text(actionText),
        ),
      ],
    );
  }

  Widget _buildHistorialConsumo(List<Map<String, dynamic>> consumos) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: consumos.map((consumo) {
          // Calculamos altura relativa basada en el consumo
          final double alturaRelativa = (consumo['kwh'] / 300) * 150;
          
          return Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('${consumo['kwh']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Container(
                  height: alturaRelativa,
                  width: 20,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade300, Colors.blue.shade600],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Text(consumo['mes'].substring(0, 3), style: const TextStyle(fontSize: 12)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRecomendaciones() {
    final recomendaciones = [
      {
        'titulo': 'Uso eficiente de la calefacción',
        'descripcion': 'Programa tu calefacción para que funcione solo cuando es necesario.'
      },
      {
        'titulo': 'Cambia a iluminación LED',
        'descripcion': 'Ahorra hasta un 80% de energía utilizando luces LED.'
      },
    ];

    return Column(
      children: recomendaciones.map((recomendacion) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade200,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.lightbulb_outline, color: Colors.amber, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recomendacion['titulo']!,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      recomendacion['descripcion']!,
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildComparativoAnual() {
    final comparativo = _comparativoAnual;
    final esPositivo = comparativo['ahorro'] > 0;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: esPositivo ? Colors.green.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: esPositivo ? Colors.green.shade200 : Colors.orange.shade200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                esPositivo ? Icons.trending_down : Icons.trending_up, 
                color: esPositivo ? Colors.green : Colors.orange,
              ),
              const SizedBox(width: 8),
              Text(
                'Comparativa Anual',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: esPositivo ? Colors.green.shade800 : Colors.orange.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildComparativoItem(
                'Este Año', 
                '${comparativo['consumoActual']} kWh',
                Icons.calendar_today,
              ),
              _buildComparativoItem(
                'Año Anterior', 
                '${comparativo['consumoAnterior']} kWh',
                Icons.history,
              ),
              _buildComparativoItem(
                esPositivo ? 'Ahorro' : 'Incremento', 
                '${comparativo['ahorro'].abs()} kWh (${comparativo['porcentaje']}%)',
                esPositivo ? Icons.savings : Icons.show_chart,
                destacado: true,
                esPositivo: esPositivo,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildComparativoItem(String titulo, String valor, IconData icono, {bool destacado = false, bool esPositivo = true}) {
    return Column(
      children: [
        Icon(
          icono, 
          color: destacado 
            ? (esPositivo ? Colors.green.shade700 : Colors.orange.shade700)
            : Colors.grey.shade700,
          size: 24,
        ),
        const SizedBox(height: 8),
        Text(
          titulo,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          valor,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: destacado 
              ? (esPositivo ? Colors.green.shade700 : Colors.orange.shade700)
              : Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildEstadisticaItem(String titulo, String valor, MaterialColor color) {
    return Column(
      children: [
        Text(
          titulo,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          valor,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: color.shade700,
          ),
        ),
      ],
    );
  }

  void _mostrarNotificaciones(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Notificaciones',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Icon(Icons.notifications_outlined),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            Expanded(
              child: _alertas.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.notifications_off, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          const Text('No tienes notificaciones'),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _alertas.length,
                      itemBuilder: (context, index) {
                        final alerta = _alertas[index];
                        IconData iconoTipo;
                        Color colorTipo;
                        
                        switch (alerta['tipo']) {
                          case 'warning':
                            iconoTipo = Icons.warning_amber;
                            colorTipo = Colors.orange;
                            break;
                          case 'success':
                            iconoTipo = Icons.check_circle;
                            colorTipo = Colors.green;
                            break;
                          case 'info':
                          default:
                            iconoTipo = Icons.info;
                            colorTipo = Colors.blue;
                            break;
                        }
                        
                        return ListTile(
                          leading: Icon(iconoTipo, color: colorTipo),
                          title: Text(alerta['titulo']),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(alerta['descripcion']),
                              Text(
                                alerta['fecha'],
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarPerfil(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            const CircleAvatar(
              radius: 40,
              backgroundColor: Colors.indigo,
              child: Text(
                'JP',
                style: TextStyle(
                  fontSize: 30,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Juan Pérez',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              widget.isEmailLogin ? widget.identifier : 'correo@ejemplo.com',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            const ListTile(
              leading: Icon(Icons.person_outline),
              title: Text('Datos Personales'),
              trailing: Icon(Icons.arrow_forward_ios, size: 16),
            ),
            const Divider(),
            const ListTile(
              leading: Icon(Icons.home_outlined),
              title: Text('Mis Propiedades'),
              trailing: Icon(Icons.arrow_forward_ios, size: 16),
            ),
            const Divider(),
            const ListTile(
              leading: Icon(Icons.settings_outlined),
              title: Text('Configuración'),
              trailing: Icon(Icons.arrow_forward_ios, size: 16),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                'Cerrar Sesión',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () async {
                Navigator.pop(context);
                
                // Cerrar sesión en Firebase
                try {
                  await FirebaseAuth.instance.signOut();
                  
                  // Navegar a la pantalla de login
                  if (mounted) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error al cerrar sesión: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _cargarBoleta(BuildContext context) async {
    final resultado = await showModalBottomSheet<File?>(
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
                    'Cargar Boleta',
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
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Toma una foto de tu boleta o sube un archivo PDF para actualizar tus datos de consumo.',
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
                        onTap: () async {
                          final picker = ImagePicker();
                          final pickedFile = await picker.pickImage(
                            source: ImageSource.camera,
                            maxWidth: 1080,
                            maxHeight: 1920,
                          );
                          
                          if (pickedFile != null) {
                            Navigator.pop(context, File(pickedFile.path));
                          }
                        },
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
                        Expanded(child: Divider()),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text('o'),
                        ),
                        Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final picker = ImagePicker();
                        final pickedFile = await picker.pickImage(
                          source: ImageSource.gallery,
                        );
                        
                        if (pickedFile != null) {
                          Navigator.pop(context, File(pickedFile.path));
                        }
                      },
                      icon: const Icon(Icons.file_upload),
                      label: const Text('Subir archivo desde galería'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
    
    if (resultado != null) {
      _procesarBoleta(resultado);
    }
  }
  
  void _procesarBoleta(File archivo) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Mostrar diálogo de procesamiento
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),
                const CircularProgressIndicator(),
                const SizedBox(height: 24),
                const Text(
                  'Procesando boleta...',
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
      
      // Extraer datos de la boleta con OCR (simulado)
      final distribuidorService = DistribuidorService();
      final datosExtraidos = await distribuidorService.extraerDatosBoleta(archivo);
      
      // Cerrar diálogo de procesamiento
      if (mounted) Navigator.of(context).pop();
      
      if (datosExtraidos['exito'] == true) {
        // Guardar la boleta y sus datos
        final consumoService = ConsumoService();
        await consumoService.cargarBoleta(
          fecha: datosExtraidos['fecha'] as DateTime,
          monto: datosExtraidos['monto'] as double,
          kwh: datosExtraidos['kwh'] as double,
          archivo: archivo,
        );
        
        // Mostrar mensaje de éxito
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Boleta procesada correctamente')),
          );
          
          // Recargar datos
          _cargarDatos();
          
          // Ir a la pestaña de boletas
          _tabController.animateTo(2);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se pudo procesar la boleta. Intenta de nuevo.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al procesar la boleta: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _mostrarDetalleMes(BuildContext context, Map<String, dynamic> datosMes) {
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
                  Text(
                    'Detalle de ${datosMes['mes']}',
                    style: const TextStyle(
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
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _buildDetalleItem('Consumo', '${datosMes['kwh']} kWh', Icons.bolt),
                            const Divider(),
                            _buildDetalleItem('Monto Total', '\$${datosMes['monto']}', Icons.attach_money),
                            const Divider(),
                            _buildDetalleItem('Cargo Fijo', '\$1,200', Icons.money),
                            const Divider(),
                            _buildDetalleItem('Energía', '\$${datosMes['monto'] - 1200}', Icons.electric_meter),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Comparativa',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'vs. Mes Anterior',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    datosMes['kwh'] > 210 ? Icons.arrow_upward : Icons.arrow_downward,
                                    color: datosMes['kwh'] > 210 ? Colors.red : Colors.green,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${((datosMes['kwh'] - 210) / 210 * 100).abs().toStringAsFixed(1)}%',
                                    style: TextStyle(
                                      color: datosMes['kwh'] > 210 ? Colors.red : Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'vs. Mismo Mes (año ant.)',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    datosMes['kwh'] > 240 ? Icons.arrow_upward : Icons.arrow_downward,
                                    color: datosMes['kwh'] > 240 ? Colors.red : Colors.green,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${((datosMes['kwh'] - 240) / 240 * 100).abs().toStringAsFixed(1)}%',
                                    style: TextStyle(
                                      color: datosMes['kwh'] > 240 ? Colors.red : Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _tabController.animateTo(2); // Ir a pestaña de boletas
                      },
                      icon: const Icon(Icons.receipt_long),
                      label: const Text('Ver Boleta'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDetalleItem(String titulo, String valor, IconData icono) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icono, color: Colors.indigo, size: 20),
              const SizedBox(width: 8),
              Text(titulo),
            ],
          ),
          Text(
            valor,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
