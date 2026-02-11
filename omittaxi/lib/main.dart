import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/splash_screen.dart';
import 'providers/user_provider.dart';
import 'providers/ride_provider.dart';

void main() {
  runApp(const MotoTaxiApp());
}

class MotoTaxiApp extends StatelessWidget {
  const MotoTaxiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => RideProvider()),
      ],
      child: MaterialApp(
        title: 'Angeles - Mototaxi Express',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primaryColor: const Color(0xFF0047AB), // Azul Rey
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF0047AB), // Azul Rey
            primary: const Color(0xFF0047AB), // Azul Rey
            secondary: const Color(0xFF87CEEB), // Azul Cielo
          ),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF0047AB), // Azul Rey
            foregroundColor: Colors.white,
            elevation: 0,
          ),
        ),
        home: const SplashScreen(),
      ),
    );
  }
}
