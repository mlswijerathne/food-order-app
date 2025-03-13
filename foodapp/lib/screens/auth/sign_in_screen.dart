import 'package:flutter/material.dart';
import 'package:foodapp/models/user_model.dart';
import 'package:foodapp/screens/auth/froget_password_screen.dart';
import 'package:foodapp/screens/auth/sign_up_screen.dart';
import 'package:foodapp/services/auth_service.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _rememberMe = false;
  bool _passwordVisible = false;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 60),
                Text(
                  'Sign In',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 10),
                Text(
                  'Please sign in to your existing account',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 40),
                _buildLoginCard(),
                SizedBox(height: 20),
                _buildSignUpRow(),
                SizedBox(height: 30),
                _buildGoogleSignInSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginCard() {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildEmailField(),
            SizedBox(height: 20),
            _buildPasswordField(),
            SizedBox(height: 20),
            _buildRememberAndForgotRow(),
            SizedBox(height: 30),
            _buildLoginButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailField() {
    return TextField(
      controller: _emailController,
      style: TextStyle(color: Colors.black),
      decoration: InputDecoration(
        labelText: 'Email',
        labelStyle: TextStyle(color: Colors.grey),
        filled: true,
        fillColor: Color(0xFFF0F0F0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        hintText: 'example@gmail.com',
        hintStyle: TextStyle(color: Colors.grey),
      ),
    );
  }

  Widget _buildPasswordField() {
    return TextField(
      controller: _passwordController,
      obscureText: !_passwordVisible,
      style: TextStyle(color: Colors.black),
      decoration: InputDecoration(
        labelText: 'Password',
        labelStyle: TextStyle(color: Colors.grey),
        filled: true,
        fillColor: Color(0xFFF0F0F0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _passwordVisible ? Icons.visibility : Icons.visibility_off,
            color: Colors.grey,
          ),
          onPressed: () {
            setState(() {
              _passwordVisible = !_passwordVisible;
            });
          },
        ),
      ),
    );
  }

  Widget _buildRememberAndForgotRow() {
    return Row(
      children: [
        Checkbox(
          activeColor: Color(0xFFFF6B01),
          checkColor: Colors.white,
          value: _rememberMe,
          onChanged: (value) {
            setState(() {
              _rememberMe = value!;
            });
          },
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        Text('Remember me', style: TextStyle(color: Colors.black)),
        Spacer(),
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ForgotPasswordScreen()),
            );
          },
          child: Text(
            'Forgot Password?',
            style: TextStyle(color: Color(0xFFFF6B01)),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _signIn, // Disable button while loading
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xFFFF6B01),
        padding: EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child:
          _isLoading
              ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 2.0,
                ),
              )
              : Text(
                'LOG IN',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
    );
  }

  Widget _buildSignUpRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Don\'t have an account?', style: TextStyle(color: Colors.grey)),
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SignUpScreen()),
            );
          },
          child: Text(
            'SIGN UP',
            style: TextStyle(
              color: Color(0xFFFF6B01),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
    
  }

  Widget _buildGoogleSignInSection() {
    return Column(
      children: [
        SizedBox(height: 1),
        Text('Or', style: TextStyle(color: Colors.grey)),
        SizedBox(height: 20),
        ElevatedButton(
          onPressed:
              _isLoading
                  ? null
                  : _signInWithGoogle, // Disable button while loading
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            side: BorderSide(color: Colors.grey.shade300),
            
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: EdgeInsets.symmetric(vertical: 16),
            
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!_isLoading) ...[
                Image.asset('assets/image/google_logo.png', height: 24),
                SizedBox(width: 10),
              ],
              _isLoading
                  ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                      strokeWidth: 2.0,
                    ),
                  )
                  : Text(
                    'Sign in with Google',
                    style: TextStyle(color: Colors.black, fontSize: 16),
                  ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _signIn() async {
    try {
      String email = _emailController.text.trim();
      String password = _passwordController.text.trim();

      if (email.isEmpty || password.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Please fill in all fields')));
        return;
      }

      // Show loading indicator
      setState(() {
        _isLoading = true;
      });

      UserModel? user = await _authService.signInWithEmailAndPassword(
        email,
        password,
      );

      if (user != null) {
        // Check if user is admin and navigate accordingly
        if (user.isAdmin) {
          // Navigate to Admin Screen
          Navigator.pushReplacementNamed(context, '/admin_home');
        } else {
          // Navigate to User Home Screen
          Navigator.pushNamed(context, '/');
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign in failed. Please check your credentials.'),
          ),
        );
      }
    } catch (e) {
      // Display error message
      String errorMessage =
          e.toString().contains('Exception:')
              ? e.toString().split('Exception:')[1].trim()
              : 'Sign in failed. Please try again.';

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage)));
    } finally {
      // Hide loading indicator
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      // Show loading indicator
      setState(() {
        _isLoading = true;
      });

      UserModel? user = await _authService.signInWithGoogle();

      if (user != null) {
        // Check if user is admin and navigate accordingly
        if (user.isAdmin) {
          // Navigate to Admin Screen
          Navigator.pushReplacementNamed(context, '/admin_home');
        } else {
          // Navigate to User Home Screen
           Navigator.pushNamed(context, '/');
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Google Sign-In was cancelled or failed')),
        );
      }
    } catch (e) {
      // Display error message
      String errorMessage =
          e.toString().contains('Exception:')
              ? e.toString().split('Exception:')[1].trim()
              : 'Google Sign-In failed. Please try again.';

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage)));
    } finally {
      // Hide loading indicator
      setState(() {
        _isLoading = false;
      });
    }
  }
}
