import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:foodapp/models/user_model.dart';
import 'package:foodapp/services/auth_service.dart';

class UsersListScreen extends StatefulWidget {
  const UsersListScreen({super.key});

  @override
  _UsersListScreenState createState() => _UsersListScreenState();
}

class _UsersListScreenState extends State<UsersListScreen> {
  final AuthService _authService = AuthService();
  List<UserModel> _users = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _isAdmin = false;  // Track admin status

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _checkIfAdmin();
  }

  // Check if current user is admin
  Future<void> _checkIfAdmin() async {
    try {
      UserModel? currentUser = await _authService.getCurrentUser();
      if (currentUser != null) {
        setState(() {
          _isAdmin = currentUser.isAdmin;
        });
      }
    } catch (e) {
      debugPrint("Error checking admin status: ${e.toString()}");
    }
  }

  // Handle logout
  Future<void> _handleLogout() async {
    try {
      await _authService.signOut();
      // Navigate to login screen after logout
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/sign_in_page');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout failed: ${e.toString()}')),
      );
    }
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      List<UserModel> users = await _authService.getAllUsersExcludingAdmin();
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load users: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Handle back button press
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          Navigator.of(context).pushReplacementNamed('/admin_home');
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(
            'Users List',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () {
              Navigator.of(context).pushReplacementNamed('/admin_home');
            },
          ),
          actions: [
            // Add logout button if the user is admin
            if (_isAdmin)
              IconButton(
                icon: Icon(Icons.logout, color: Color(0xFFFF6B01)),
                onPressed: _handleLogout,
                tooltip: 'Logout',
              ),
          ],
        ),
        body: SafeArea(
          child: _isLoading
              ? Center(child: CircularProgressIndicator(color: Color(0xFFFF6B01)))
              : _errorMessage != null
                  ? _buildErrorView()
                  : _users.isEmpty
                      ? _buildEmptyView()
                      : _buildUsersList(),
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Text(_errorMessage!, style: TextStyle(color: Colors.red)),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Text(
        'No Users Found',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildUsersList() {
    return RefreshIndicator(
      onRefresh: _loadUsers,
      color: Color(0xFFFF6B01),
      child: ListView.builder(
        padding: EdgeInsets.all(16.0),
        itemCount: _users.length,
        itemBuilder: (context, index) {
          final user = _users[index];
          return _buildUserRow(user);
        },
      ),
    );
  }

  Widget _buildUserRow(UserModel user) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.grey.shade200,
          backgroundImage: user.profilePicture.isNotEmpty
              ? _getProfileImage(user.profilePicture)
              : null,
          child: user.profilePicture.isEmpty
              ? Icon(Icons.person, color: Colors.grey)
              : null,
        ),
        title: Text(
          user.name,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(user.email),
      ),
    );
  }

  ImageProvider? _getProfileImage(String profilePicture) {
    if (profilePicture.startsWith('http')) {
      return NetworkImage(profilePicture);
    }
    try {
      return MemoryImage(base64Decode(profilePicture));
    } catch (e) {
      return null;
    }
  }
}