import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'widgets/auth_wrapper.dart';
import 'providers/theme_provider.dart';
import 'providers/auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => AuthProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Technical Assets Management',
          theme: themeProvider.lightTheme.copyWith(
            textTheme: themeProvider.lightTheme.textTheme.apply(
              fontFamily: GoogleFonts.poppins().fontFamily,
            ),
          ),
          darkTheme: themeProvider.darkTheme.copyWith(
            textTheme: themeProvider.darkTheme.textTheme.apply(
              fontFamily: GoogleFonts.poppins().fontFamily,
            ),
          ),
          themeMode: themeProvider.isDarkMode
              ? ThemeMode.dark
              : ThemeMode.light,
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
          home: const AuthWrapper(),
        );
      },
    );
  }
}
