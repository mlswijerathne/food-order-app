import 'package:flutter/material.dart';
import 'package:foodapp/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminAuthCheck extends StatefulWidget {
  final Widget adminWidget;
  final Widget userWidget;

  const AdminAuthCheck({
    super.key,
    required this.adminWidget,
    required this.userWidget,
  });

  @override
  _AdminAuthCheckState createState() => _AdminAuthCheckState();
}

class _AdminAuthCheckState extends State<AdminAuthCheck> {
  final AuthService _authService = AuthService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = true;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    User? currentUser = _auth.currentUser;
    
    if (currentUser != null) {
      bool isAdmin = await _authService.isUserAdmin(currentUser.uid);
      setState(() {
        _isAdmin = isAdmin;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isAdmin = false;
        _isLoading = false;
      });
      // If no user is logged in, navigate to login screen
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/sign_in_page');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    if (_isAdmin) {
      return widget.adminWidget;
    } else {
      // If not admin, show unauthorized view
      return widget.userWidget;
    }
  }
}