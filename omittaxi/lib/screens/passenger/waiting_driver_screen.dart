import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/ride_model.dart';
import '../../models/user_model.dart';
import '../../providers/ride_provider.dart';
import '../../services/socket_service.dart';
import 'ride_tracking_screen.dart';
import 'dart:async';

class WaitingDriverScreen extends StatefulWidget {
  final RideModel ride;

  const WaitingDriverScreen({super.key, required this.ride});

  @override
  State<WaitingDriverScreen> createState() => _WaitingDriverScreenState();
}

class _WaitingDriverScreenState extends State<WaitingDriverScreen> {
  bool _isCancelling = false;
  Timer? _timeoutTimer;
  int _waitingSeconds = 0;
  Timer? _counterTimer;

  @override
  void initState() {
    super.initState();
    
    // Verificar si el viaje ya tiene conductor asignado
    if (widget.ride.status == 'accepted' || 
        widget.ride.status == 'arrived' || 
        widget.ride.status == 'in_progress') {
      // El viaje ya fue aceptado, navegar directamente a tracking
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => RideTrackingScreen(ride: widget.ride),
            ),
          );
        }
      });
      return;
    }
    
    _ensureSocketConnection();
    _setupSocketListeners();
    _startWaitingCounter();
    
    // Timeout de 5 minutos
    _timeoutTimer = Timer(const Duration(minutes: 5), () {
      if (mounted) {
        _showTimeoutDialog();
      }
    });
  }

  Future<void> _ensureSocketConnection() async {
    // Asegurar que el socket esté conectado
    if (!SocketService.isConnected) {
      print('🔌 Conectando socket...');
      await SocketService.connect();
      // Esperar un momento para que se establezca la conexión
      await Future.delayed(const Duration(milliseconds: 500));
    }
    print('✅ Socket conectado: ${SocketService.isConnected}');
  }

  void _startWaitingCounter() {
    _counterTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _waitingSeconds++;
        });
      }
    });
  }

  void _setupSocketListeners() {
    // Escuchar cuando un conductor acepta el viaje
    SocketService.onRideAccepted((data) {
      print('🎉 Viaje aceptado: $data');
      
      if (!mounted) return;
      
      // Actualizar el ride con información del conductor
      final rideProvider = Provider.of<RideProvider>(context, listen: false);
      
      // Crear modelo de ride actualizado con la información del conductor
      final updatedRide = widget.ride.copyWith(
        status: 'accepted',
        driver: data['driver'] != null ? UserModel(
          id: data['driver']['id'] ?? '',
          name: data['driver']['name'] ?? 'Conductor',
          email: data['driver']['email'] ?? '',
          phone: data['driver']['phone'] ?? '',
          userType: 'driver',
          vehicleInfo: data['driver']['vehicleInfo'],
          economicNumber: data['driver']['economicNumber'],
        ) : null,
      );
      
      rideProvider.setCurrentRide(updatedRide);
      
      // Navegar a la pantalla de rastreo
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => RideTrackingScreen(ride: updatedRide),
        ),
      );
      
      // Mostrar mensaje de éxito con número económico si está disponible
      final driverName = data['driver']?['name'] ?? 'Un conductor';
      final economicNumber = data['driver']?['economicNumber'];
      final message = economicNumber != null 
          ? '🎉 ¡Conductor encontrado! $driverName (Unidad #$economicNumber) va hacia ti'
          : '🎉 ¡Conductor encontrado! $driverName va hacia ti';
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    });

    // Escuchar cuando el conductor llega al punto de recogida
    SocketService.socket?.on('driver:arrived', (data) {
      print('🚗 Conductor ha llegado: $data');
      
      if (!mounted) return;
      
      _showDriverArrivedDialog(data);
    });

    // Escuchar si el viaje es cancelado
    SocketService.socket?.on('ride:cancelled', (data) {
      print('❌ Viaje cancelado: $data');
      
      if (!mounted) return;
      
      final cancelledBy = data['cancelledBy'] ?? 'otro usuario';
      final reason = data['reason'] ?? 'Sin motivo especificado';
      
      // Limpiar el viaje del provider
      final rideProvider = Provider.of<RideProvider>(context, listen: false);
      rideProvider.clearCurrentRide();
      
      // Volver a la pantalla principal
      Navigator.of(context).popUntil((route) => route.isFirst);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            cancelledBy == 'driver' 
              ? 'El conductor canceló el viaje' 
              : 'El viaje fue cancelado',
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
    });

    // Escuchar si el viaje es completado
    SocketService.socket?.on('ride:completed', (data) {
      if (!mounted) return;
      
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Viaje completado exitosamente!'),
          backgroundColor: Colors.green,
        ),
      );
    });
  }

  void _showTimeoutDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('⏱️ Tiempo agotado'),
        content: const Text(
          'No se encontró ningún conductor disponible. ¿Deseas intentar de nuevo?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Cerrar diálogo
              Navigator.of(context).pop(); // Volver a pantalla anterior
            },
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Cerrar diálogo
              Navigator.of(context).pop(); // Volver a pantalla anterior
              // El usuario puede intentar de nuevo
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
            ),
            child: const Text('Intentar de nuevo'),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelRide() async {
    // Verificar si el viaje ya está cancelado
    if (widget.ride.status == 'cancelled') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Este viaje ya fue cancelado'),
          backgroundColor: Colors.orange,
        ),
      );
      // Volver a la pantalla principal
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }

    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar solicitud'),
        content: const Text('¿Estás seguro de que deseas cancelar la solicitud de viaje?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );

    if (shouldCancel != true) return;

    setState(() {
      _isCancelling = true;
    });

    final rideProvider = Provider.of<RideProvider>(context, listen: false);
    
    try {
      final result = await rideProvider.cancelRide(
        reason: 'Cancelado por el pasajero',
      );

      if (!mounted) return;

      if (result['success'] == true) {
        Navigator.of(context).popUntil((route) => route.isFirst);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Solicitud cancelada'),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        setState(() {
          _isCancelling = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Error al cancelar'),
            backgroundColor: Colors.red,
          ),
        );
        
        // Si el mensaje indica que ya está cancelado, volver al inicio
        if (result['message']?.contains('No se puede cancelar') ?? false) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      }
    } catch (e) {
      debugPrint('Error cancelando viaje: $e');
      if (!mounted) return;
      
      setState(() {
        _isCancelling = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cancelar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatWaitingTime() {
    final minutes = _waitingSeconds ~/ 60;
    final seconds = _waitingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    _counterTimer?.cancel();
    SocketService.removeListener('ride:accepted');
    SocketService.removeListener('ride:cancelled');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Prevenir que el usuario salga sin cancelar
        _cancelRide();
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Buscando conductor'),
          automaticallyImplyLeading: false,
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).primaryColor.withOpacity(0.1),
                Colors.white,
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Animación de búsqueda
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 200,
                                height: 200,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFF2E7D32).withOpacity(0.1),
                                ),
                              ),
                              Container(
                                width: 150,
                                height: 150,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFF2E7D32).withOpacity(0.2),
                                ),
                                child: const Icon(
                                  Icons.two_wheeler,
                                  size: 80,
                                  color: Color(0xFF2E7D32),
                                ),
                              ),
                              const SizedBox(
                                width: 180,
                                height: 180,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xFF2E7D32),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 40),
                          
                          // Título
                          const Text(
                            '🔍 Buscando conductor',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Mensaje
                          const Text(
                            'Estamos buscando un conductor cerca de ti.\nPor favor espera un momento...',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          
                          const SizedBox(height: 32),
                          
                          // Tiempo de espera
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.timer_outlined,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Tiempo de espera: ${_formatWaitingTime()}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 32),
                          
                          // Información del punto de recogida
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
                                  const Row(
                                    children: [
                                      Icon(
                                        Icons.location_on,
                                        color: Colors.green,
                                        size: 20,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Punto de recogida',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    widget.ride.pickupAddress,
                                    style: const TextStyle(
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Botón cancelar
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isCancelling ? null : _cancelRide,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: _isCancelling
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text(
                                'Cancelar solicitud',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDriverArrivedDialog(dynamic data) {
    final driverName = data['driver']?['name'] ?? 'El conductor';
    final driverPhone = data['driver']?['phone'] ?? '';
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Color(0xFF2E7D32), size: 30),
            SizedBox(width: 8),
            Text('¡Conductor ha llegado!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$driverName ha llegado a tu punto de recogida.',
              style: const TextStyle(fontSize: 16),
            ),
            if (driverPhone.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Teléfono: $driverPhone',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
            const SizedBox(height: 16),
            const Text(
              '¿Confirmas que el conductor está en tu ubicación?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              // Cancelar el viaje
              Navigator.pop(context); // Cerrar diálogo
              await _cancelRide();
            },
            child: const Text(
              'Cancelar viaje',
              style: TextStyle(color: Colors.red),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Cerrar diálogo
              await _confirmArrival();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirmar llegada'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmArrival() async {
    final rideProvider = Provider.of<RideProvider>(context, listen: false);
    
    try {
      // Actualizar el ride localmente con el estado 'arrived'
      final updatedRide = widget.ride.copyWith(status: 'arrived');
      rideProvider.setCurrentRide(updatedRide);
      
      if (!mounted) return;
      
      // Cerrar el diálogo de confirmación
      Navigator.of(context).pop();
      
      // Navegar a la pantalla de tracking del viaje
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => RideTrackingScreen(ride: updatedRide),
        ),
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Listo! Confirma con el conductor para iniciar el viaje'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      debugPrint('Error al confirmar llegada: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
