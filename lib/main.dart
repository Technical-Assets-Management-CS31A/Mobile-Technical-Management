import 'package:flutter/material.dart';
import 'screens/auth/login_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Technical Assets Management',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        visualDensity: VisualDensity.compact,
      ),
      builder: (context, child) {
        final media = MediaQuery.of(context);
        final isSmallMobile = media.size.width < 430;
        final adjusted = media.copyWith(
          textScaler: TextScaler.linear(
            isSmallMobile ? 0.90 : media.textScaler.scale(1.0),
          ),
          padding: media.padding.copyWith(
            top: media.padding.top,
            bottom: media.padding.bottom,
          ),
        );
        return MediaQuery(data: adjusted, child: child!);
      },
      home: const LoginScreen(),
    );
  }
}
