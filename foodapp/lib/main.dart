import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:foodapp/screens/admin/admin_home_screen.dart';
import 'package:foodapp/screens/admin/admin_order_dashboard_screen.dart';
import 'package:foodapp/screens/admin/admin_order_screen.dart';
import 'package:foodapp/screens/admin/all_food_screen.dart';
import 'package:foodapp/screens/admin/food_adding_screen.dart';
import 'package:foodapp/screens/admin/users_details.dart';
import 'package:foodapp/screens/all_food_screen.dart';
import 'package:foodapp/screens/auth/froget_password_screen.dart';
import 'package:foodapp/screens/auth/loading_screen.dart';
import 'package:foodapp/screens/auth/sign_in_screen.dart';
import 'package:foodapp/screens/auth/sign_up_screen.dart';
import 'package:foodapp/screens/auth/unauthorized_screen.dart';
import 'package:foodapp/screens/user/home_screen.dart';
import 'package:foodapp/screens/user/order_screen.dart';
import 'package:foodapp/screens/user/profile_screen.dart';
import 'package:foodapp/services/auth_service.dart';
import 'package:foodapp/widgets/admin_auth_check.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure Flutter binding is initialized
  await Firebase.initializeApp(); // Initialize Firebase

  // Create admin user if it doesn't exist
  final AuthService authService = AuthService();
  await authService.ensureAdminExists();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Food Order App',
      debugShowCheckedModeBanner: false,
      initialRoute: '/loading_page', // Set initial route
      routes: {
        '/loading_page': (context) => LoadingScreen(),
        '/sign_in_page': (context) => SignInScreen(),
        '/sign_up_page': (context) => SignUpScreen(),
        '/': (context) => HomeScreen(),
        '/froget_password': (context) => ForgotPasswordScreen(),
        '/all_food_item_screen': (context) => AllFoodsScreen(),
        '/profile_screen': (context) => ProfileScreen(),
        '/all_order_screen': (context) => OrderScreen(),
        




        // Protected admin routes
        '/admin_all_food_screen':
            (context) => AdminAuthCheck(
              adminWidget: AdminAllFoodsScreen(),
              userWidget: UnauthorizedScreen(),
            ),

        '/admin_food_adding_screen':
            (context) => AdminAuthCheck(
              adminWidget: AddFoodScreen(),
              userWidget: UnauthorizedScreen(),
            ),

        '/admin_home':
            (context) => AdminAuthCheck(
              adminWidget: AdminHomeScreen(),
              userWidget: UnauthorizedScreen(),
            ),
        '/user_detail':
            (context) => AdminAuthCheck(
              adminWidget: UsersListScreen(),
              userWidget: UnauthorizedScreen()
            ),
        '/admin_order':
            (context) => AdminAuthCheck(
              adminWidget: AdminOrderScreen(),
              userWidget: UnauthorizedScreen()
            ),
        '/admin_dashboard':
            (context) => AdminAuthCheck(
              adminWidget: AdminOrderDashboard(),
              userWidget: UnauthorizedScreen()
            ),
        
        

        
        
      },
    );
  }
}

