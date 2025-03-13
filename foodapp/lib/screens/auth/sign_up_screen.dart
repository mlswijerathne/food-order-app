import 'package:flutter/material.dart';
import 'package:foodapp/models/user_model.dart';
import 'package:foodapp/services/auth_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _contactNumberController = TextEditingController();
  final AuthService _authService = AuthService();

  File? _profileImage;
  String? _profileImageBase64;
  bool _isUploading = false;
  bool _passwordVisible = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _contactNumberController.dispose();
    super.dispose();
  }

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
                SizedBox(height: 40),
                Text(
                  'Sign Up',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 10),
                Text(
                  'Create a new account',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 30),
                // Display error message if exists
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: Colors.red.shade800,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                _buildSignUpCard(),
                SizedBox(height: 20),
                _buildLoginRow(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSignUpCard() {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildProfilePictureUpload(),
            SizedBox(height: 20),
            _buildNameField(),
            SizedBox(height: 20),
            _buildEmailField(),
            SizedBox(height: 20),
            _buildPasswordField(),
            SizedBox(height: 20),
            _buildContactNumberField(),
            SizedBox(height: 30),
            _buildSignUpButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfilePictureUpload() {
    return Center(
      child: GestureDetector(
        onTap: _pickImage,
        child: CircleAvatar(
          radius: 50,
          backgroundColor: Color(0xFFF0F0F0),
          backgroundImage: _profileImage != null ? FileImage(_profileImage!) : null,
          child: _profileImage == null
              ? Icon(
                  Icons.camera_alt,
                  size: 40,
                  color: Colors.grey,
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildNameField() {
    return TextField(
      controller: _nameController,
      style: TextStyle(color: Colors.black),
      decoration: InputDecoration(
        labelText: 'NAME',
        labelStyle: TextStyle(color: Colors.grey),
        filled: true,
        fillColor: Color(0xFFF0F0F0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        hintText: 'John Doe',
        hintStyle: TextStyle(color: Colors.grey),
      ),
    );
  }

  Widget _buildEmailField() {
    return TextField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      style: TextStyle(color: Colors.black),
      decoration: InputDecoration(
        labelText: 'EMAIL',
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
        labelText: 'PASSWORD',
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

  Widget _buildContactNumberField() {
    return TextField(
      controller: _contactNumberController,
      keyboardType: TextInputType.phone,
      style: TextStyle(color: Colors.black),
      decoration: InputDecoration(
        labelText: 'CONTACT NUMBER',
        labelStyle: TextStyle(color: Colors.grey),
        filled: true,
        fillColor: Color(0xFFF0F0F0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        hintText: '+1234567890',
        hintStyle: TextStyle(color: Colors.grey),
      ),
    );
  }

  Widget _buildSignUpButton() {
    return _isUploading
        ? Center(child: CircularProgressIndicator())
        : ElevatedButton(
            onPressed: _signUp,
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFFF6B01),
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'SIGN UP',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
  }

  Widget _buildLoginRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Already have an account?',
          style: TextStyle(color: Colors.grey),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text(
            'LOG IN',
            style: TextStyle(
              color: Color(0xFFFF6B01),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });

      final bytes = await _profileImage!.readAsBytes();
      _profileImageBase64 = base64Encode(bytes);
    }
  }

  Future<void> _signUp() async {
    // Clear any previous error messages
    setState(() {
      _errorMessage = null;
    });

    // Validate input fields
    if (!_validateInputs()) return;

    setState(() {
      _isUploading = true;
    });

    try {
      UserModel? user = await _authService.registerWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        _nameController.text.trim(),
        _contactNumberController.text.trim(),
        _profileImageBase64 ?? '',
      );

      if (user != null) {
        _showSuccessSnackBar('Signed up successfully');
        // TODO: Navigate to next screen or home page
        // Example: Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomeScreen()));
      } else {
        setState(() {
          _errorMessage = 'Registration failed. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  bool _validateInputs() {
    String name = _nameController.text.trim();
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();
    String contactNumber = _contactNumberController.text.trim();

    // Check if any field is empty
    if (name.isEmpty || email.isEmpty || password.isEmpty || contactNumber.isEmpty) {
      setState(() {
        _errorMessage = 'Please fill in all fields';
      });
      return false;
    }

    // Email validation
    if (!_isValidEmail(email)) {
      setState(() {
        _errorMessage = 'Please enter a valid email address';
      });
      return false;
    }

    // Password strength validation
    if (password.length < 6) {
      setState(() {
        _errorMessage = 'Password must be at least 6 characters long';
      });
      return false;
    }

    // Contact number validation (basic)
    if (contactNumber.length < 10) {
      setState(() {
        _errorMessage = 'Please enter a valid contact number';
      });
      return false;
    }

    return true;
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }
}