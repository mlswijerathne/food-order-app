import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:foodapp/models/user_model.dart';
import 'package:foodapp/screens/user/edit_profile_screen.dart';
import 'package:foodapp/services/auth_service.dart';
import 'package:foodapp/screens/auth/sign_in_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _fetchUserDetails();
  }

  Future<void> _fetchUserDetails() async {
    setState(() {
      _isLoading = true;
    });

    UserModel? user = await _authService.getCurrentUser();
    
    if (user != null) {
      setState(() {
        _currentUser = user;
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  // Handle back button press
  Future<bool> _onWillPop() async {
    // Navigate to the root route
    Navigator.of(context).pushReplacementNamed('/');
    // Return false to prevent default back navigation
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Color(0xFFFF6B01),
          title: Text(
            'Profile',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              Navigator.of(context).pushReplacementNamed('/');
            },
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.edit, color: Colors.white,),
              onPressed: () => _navigateToEditProfile(),
            ),
          ],
        ),
        body: _isLoading
            ? Center(child: CircularProgressIndicator(color: Color(0xFFFF6B01)))
            : _currentUser == null
                ? Center(child: Text("Failed to load user data"))
                : SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(height: 20),
                          _buildProfileImage(),
                          SizedBox(height: 24),
                          _buildProfileName(),
                          SizedBox(height: 40),
                          _buildInfoSection(),
                          SizedBox(height: 40),
                          _buildLogoutButton(),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }

  Widget _buildProfileImage() {
    return Center(
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey.shade200,
          image: _currentUser!.profilePicture.isNotEmpty
              ? DecorationImage(
                  image: MemoryImage(base64Decode(_currentUser!.profilePicture)),
                  fit: BoxFit.cover,
                )
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: _currentUser!.profilePicture.isEmpty
            ? Icon(
                Icons.person,
                size: 60,
                color: Colors.grey,
              )
            : null,
      ),
    );
  }

  Widget _buildProfileName() {
    return Column(
      children: [
        Text(
          _currentUser!.name,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 4),
      ],
    );
  }

  Widget _buildInfoSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          children: [
            _buildInfoItem(Icons.email, 'Email', _currentUser!.email.isEmpty ? 'Not provided' : _currentUser!.email),
            Divider(),
            _buildInfoItem(Icons.phone, 'Contact Number', _currentUser!.contactNumber.isEmpty ? 'Not provided' : _currentUser!.contactNumber),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String title, String value) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Color(0xFFFF6B01).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: Color(0xFFFF6B01),
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLogoutButton() {
    return ElevatedButton(
      onPressed: _logout,
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xFFFF6B01).withOpacity(1),
        padding: EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        minimumSize: Size(double.infinity, 50),
      ),
      child: Text(
        'LOG OUT',
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Future<void> _navigateToEditProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(user: _currentUser!),
      ),
    );
    if (result != null && result is UserModel) {
      setState(() {
        _currentUser = result;
      });
    }
  }

  Future<void> _logout() async {
    await _authService.signOut();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => SignInScreen()),
    );
  }
}