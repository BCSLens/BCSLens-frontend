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

import 'models/pet_record_model.dart';

void main() {
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
      initialRoute: '/',
      routes: _defineRoutes(),
    );
  }

  Map<String, WidgetBuilder> _defineRoutes() {
    return {
      '/': (context) => const WelcomeScreen(),
      '/login': (context) => const LoginScreen(),
      '/signup': (context) => const SignUpScreen(),
      '/records': (context) => const RecordsScreen(),
      '/add-record': (context) => const AddRecordScreen(),
      '/special-care': (context) => const SpecialCareScreen(),
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
    };
  }
}
