import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dung_chung/dang_nhap/giao_dien/man_dang_nhap.dart';
import 'nen_tang/giao_dien/bang_mau.dart';
import 'nen_tang/mang/cong_api.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CafePosApp());
}

class CafePosApp extends StatelessWidget {
  final PosAuthApiClient? apiClient;
  final bool autoRestoreSession;
  final String? initialRoutePath;

  const CafePosApp({
    super.key,
    this.apiClient,
    this.autoRestoreSession = true,
    this.initialRoutePath,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quản Lý Quán Cà Phê · POS & Quản trị',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.daylightBackground,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.mossMid,
          surface: AppColors.daylightSurface,
        ),
        textTheme: GoogleFonts.beVietnamProTextTheme(),
      ),
      onGenerateRoute: (settings) {
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => LoginScreen(
            apiClient: apiClient,
            autoRestoreSession: autoRestoreSession,
            initialRoutePath: initialRoutePath,
          ),
        );
      },
    );
  }
}
