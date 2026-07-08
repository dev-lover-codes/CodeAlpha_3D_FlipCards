import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(
    // ProviderScope stores the state of all providers.
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the active theme mode from the provider.
    final themeMode = ref.watch(themeModeProvider);

    // Setup Outfit text theme as our typography foundation
    final textTheme = GoogleFonts.outfitTextTheme(
      Theme.of(context).textTheme,
    );

    // Elegant Light Theme
    final lightTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.deepPurple,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: Colors.grey.shade50,
      textTheme: textTheme,
      dialogTheme: const DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      chipTheme: const ChipThemeData(
        surfaceTintColor: Colors.transparent,
      ),
    );

    // Sophisticated Dark Theme
    final darkTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.deepPurple,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: const Color(0xFF0F0F12),
      textTheme: textTheme,
      dialogTheme: const DialogThemeData(
        backgroundColor: Color(0xFF1E1E24),
        surfaceTintColor: Colors.transparent,
      ),
      chipTheme: const ChipThemeData(
        surfaceTintColor: Colors.transparent,
      ),
    );

    return MaterialApp(
      title: 'MemoSpark Flashcards',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
