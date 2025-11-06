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
import 'screens/history_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/group_details_screen.dart';

import 'models/pet_record_model.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/services.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize auth service
  final authService = AuthService();
  await dotenv.load(fileName: ".env");
  await authService.initialize();

  // Lock app orientation to portrait only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

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
      onGenerateRoute: (RouteSettings settings) {
        switch (settings.name) {
          case '/welcome':
            return MaterialPageRoute(
              builder: (context) => const WelcomeScreen(),
            );
          case '/login':
            return MaterialPageRoute(builder: (context) => const LoginScreen());
          case '/signup':
            return MaterialPageRoute(
              builder: (context) => const SignUpScreen(),
            );
          case '/records':
            return MaterialPageRoute(
              builder: (context) => const RecordsScreen(),
            );
          case '/add-record':
            // รับ PetRecord arguments
            final PetRecord? petRecord = settings.arguments as PetRecord?;
            return MaterialPageRoute(
              builder:
                  (context) => AddRecordScreen(existingPetRecord: petRecord),
            );
          case '/special-care':
            return MaterialPageRoute(
              builder: (context) => const SpecialCareScreen(),
            );
          case '/top-side-view':
            final petRecord = settings.arguments as PetRecord;
            return MaterialPageRoute(
              builder: (context) => TopSideViewScreen(petRecord: petRecord),
            );
          case '/bcs-evaluation':
            final petRecord = settings.arguments as PetRecord;
            return MaterialPageRoute(
              builder: (context) => BcsEvaluationScreen(petRecord: petRecord),
            );
          case '/pet-details':
            final petRecord = settings.arguments as PetRecord;
            return MaterialPageRoute(
              builder: (context) => PetDetailsScreen(petRecord: petRecord),
            );
          case '/review-details':
            final petRecord = settings.arguments as PetRecord;
            return MaterialPageRoute(
              builder: (context) => BcsReviewScreen(petRecord: petRecord),
            );
          case '/history':
            final arguments = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (context) => HistoryScreen(
                pet: arguments['pet'],
                groupName: arguments['groupName'],
              ),
            );
          case '/profile':
            return MaterialPageRoute(
              builder: (context) => const ProfileScreen(),
            );
          case '/group-details':
            final arguments = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (context) => GroupDetailsScreen(
                group: arguments['group'],
                pets: arguments['pets'],
              ),
            );
          default:
            return null;
        }
      },
    );
  }
}
