// lib/main.dart
import 'package:flutter/material.dart';
import 'config/app_theme.dart';
import 'screens/welcome_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/records_screen.dart';
import 'screens/add_record_screen.dart';
import 'screens/special_care_screen.dart';
import 'screens/top_side_view_screen.dart';
import 'screens/bcs_evaluation_screen.dart';
import 'screens/pet_detail_screen.dart';
import 'screens/review_add_screen.dart';
import 'services/auth_service.dart';

import 'models/pet_record_model.dart';
import 'screens/profile_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize auth service
  final authService = AuthService();
  await dotenv.load(fileName: ".env");
  await authService.initialize();

  runApp(const BCSLensApp());
}

class BCSLensApp extends StatelessWidget {
  const BCSLensApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BCSLens',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: FutureBuilder(
        future: AuthService().initialize(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // Check if user is authenticated
          final authService = AuthService();
          if (authService.isAuthenticated) {
            return const RecordsScreen();
          } else {
            return const WelcomeScreen();
          }
        },
      ),
      routes: _defineRoutes(),
    );
  }

  Map<String, WidgetBuilder> _defineRoutes() {
    return {
      '/welcome': (context) => const WelcomeScreen(),
      '/login': (context) => const LoginScreen(),
      '/signup': (context) => const SignUpScreen(),
      '/records': (context) => const RecordsScreen(),
      '/add-record': (context) => const AddRecordScreen(),
      '/special-care': (context) => const SpecialCareScreen(),
      '/profile': (context) => const ProfileScreen(),
      '/top-side-view': (context) {
        // Extract the PetRecord from route settings
        final petRecord =
            ModalRoute.of(context)!.settings.arguments as PetRecord;
        return TopSideViewScreen(petRecord: petRecord);
      },
      '/bcs-evaluation': (context) {
        final petRecord =
            ModalRoute.of(context)!.settings.arguments as PetRecord;
        return BcsEvaluationScreen(petRecord: petRecord);
      },
      '/pet-details': (context) {
        final petRecord =
            ModalRoute.of(context)!.settings.arguments as PetRecord;
        return PetDetailsScreen(petRecord: petRecord);
      },
      '/review-details': (context) {
        final petRecord =
            ModalRoute.of(context)!.settings.arguments as PetRecord;
        return BcsReviewScreen(petRecord: petRecord);
      },
    };
  }
}
