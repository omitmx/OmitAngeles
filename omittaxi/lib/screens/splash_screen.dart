import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'welcome_screen.dart';
import '../providers/user_provider.dart';
import '../providers/ride_provider.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import 'passenger/passenger_home_screen.dart';
import 'driver/driver_home_screen.dart';
import 'driver/driver_navigation_screen.dart';
import 'passenger/waiting_driver_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _controller.forward();

    // Verificar sesión y redirigir
    Timer(const Duration(seconds: 3), () {
      _checkSessionAndNavigate();
    });
  }

  Future<void> _checkSessionAndNavigate() async {
    final authService = AuthService();
    final token = await authService.getToken();

    if (token != null) {
      // Hay sesión guardada, obtener perfil del usuario
      final profileResult = await authService.getProfile();
      
      if (profileResult['success'] == true && mounted) {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        final rideProvider = Provider.of<RideProvider>(context, listen: false);
        
        // Crear usuario con token
        final userData = profileResult['user'];
        final user = UserModel(
          id: userData.id,
          name: userData.name,
          email: userData.email,
          phone: userData.phone,
          userType: userData.userType,
          photoUrl: userData.photoUrl,
          rating: userData.rating,
          totalRides: userData.totalRides,
          vehicleInfo: userData.vehicleInfo,
          economicNumber: userData.economicNumber,
          licenseNumber: userData.licenseNumber,
          token: token,
        );
        userProvider.login(user);
        
        // Verificar si hay un viaje activo
        final activeRideResult = await rideProvider.checkActiveRide();
        
        if (!mounted) return;
        
        if (activeRideResult['hasActiveRide'] == true) {
          // Hay un viaje activo, redirigir según el tipo de usuario y estado del viaje
          final ride = activeRideResult['ride'];
          final userType = profileResult['user'].userType;
          
          if (userType == 'driver') {
            // Conductor con viaje activo
            if (ride.status == 'accepted') {
              // Navegando hacia el pasajero
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => DriverNavigationScreen(ride: ride),
                ),
              );
            } else {
              // Otro estado (arrived, in_progress)
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const DriverHomeScreen()),
              );
            }
          } else {
            // Pasajero con viaje activo
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => WaitingDriverScreen(ride: ride),
              ),
            );
          }
        } else {
          // No hay viaje activo, ir a home según tipo de usuario
          if (profileResult['user'].userType == 'driver') {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const DriverHomeScreen()),
            );
          } else {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const PassengerHomeScreen()),
            );
          }
        }
      } else {
        // Error al obtener perfil, borrar sesión e ir a welcome
        await authService.clearToken();
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
        );
      }
    } else {
      // No hay sesión, ir a welcome
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0047AB),
              Color(0xFF003380),
            ], // Azul Rey degradado
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.two_wheeler,
                      size: 100,
                      color: Color(0xFF0047AB), // Azul Rey
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'Angeles',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Tu Mototaxi Express',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.white70,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  const SizedBox(height: 50),
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
