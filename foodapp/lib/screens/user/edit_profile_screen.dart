import 'package:flutter/material.dart';
import 'package:foodapp/models/user_model.dart';
import 'package:foodapp/services/auth_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';

class EditProfileScreen extends StatefulWidget {
  final UserModel user;

  const EditProfileScreen({super.key, required this.user});

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _contactNumberController = TextEditingController();
  final AuthService _authService = AuthService();

  File? _profileImage;
  String? _profileImageBase64;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.user.name;
    _contactNumberController.text = widget.user.contactNumber;
    _profileImageBase64 = widget.user.profilePicture;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Color(0xFFFF6B01),
        title: Text(
          'Edit Profile',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
                _buildEditProfileCard(),
                SizedBox(height: 30),
                _buildUpdateButton(),
                SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEditProfileCard() {
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
            SizedBox(height: 30),
            Text(
              'Personal Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Email',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFFF0F0F0),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                widget.user.email,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                ),
              ),
            ),
            SizedBox(height: 20),
            _buildNameField(),
            SizedBox(height: 20),
            _buildContactNumberField(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfilePictureUpload() {
  return Center(
    child: Stack(
      children: [
        CircleAvatar(
          radius: 60,
          backgroundColor: Color(0xFFF0F0F0),
          backgroundImage: _profileImage != null
              ? FileImage(_profileImage!)
              : (_profileImageBase64 != null && _profileImageBase64!.isNotEmpty
                  ? MemoryImage(base64Decode(_profileImageBase64!)) as ImageProvider
                  : null),
          child: (_profileImage == null && (_profileImageBase64 == null || _profileImageBase64!.isEmpty))
              ? Icon(
                  Icons.person,
                  size: 60,
                  color: Colors.grey,
                )
              : null,
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Color(0xFFFF6B01),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.camera_alt,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
      ],
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
        hintText: 'Enter your name',
        hintStyle: TextStyle(color: Colors.grey),
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

  Widget _buildUpdateButton() {
    return _isLoading
        ? Center(child: CircularProgressIndicator(color: Color(0xFFFF6B01)))
        : ElevatedButton(
            onPressed: _updateProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFFF6B01),
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'UPDATE PROFILE',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
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

  Future<void> _updateProfile() async {
    // Clear any previous error messages
    setState(() {
      _errorMessage = null;
    });

    String name = _nameController.text.trim();
    String contactNumber = _contactNumberController.text.trim();

    // Validate inputs
    if (name.isEmpty) {
      setState(() {
        _errorMessage = 'Name cannot be empty';
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      bool success = await _authService.updateUserDetails(
        widget.user.uid,
        name,
        contactNumber,
        _profileImageBase64 ?? '',
      );

      if (success) {
        // Create updated user model
        UserModel updatedUser = UserModel(
          uid: widget.user.uid,
          email: widget.user.email,
          name: name,
          contactNumber: contactNumber,
          profilePicture: _profileImageBase64 ?? '',
        );

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
          ),
        );

        // Return to profile screen with updated user data
        Navigator.pop(context, updatedUser);
      } else {
        setState(() {
          _errorMessage = 'Failed to update profile. Please try again.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }
}