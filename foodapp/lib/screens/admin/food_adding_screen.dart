import 'package:flutter/material.dart';
import 'package:foodapp/services/food_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';

class AddFoodScreen extends StatefulWidget {
  const AddFoodScreen({super.key});

  @override
  _AddFoodScreenState createState() => _AddFoodScreenState();
}

class _AddFoodScreenState extends State<AddFoodScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final FoodService _foodService = FoodService();

  File? _foodImage;
  String? _foodImageBase64;
  bool _isUploading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Add New Food',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 20),
                Text(
                  'Add New Food Item',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 10),
                Text(
                  'Fill in the details for the new food item',
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
                _buildAddFoodCard(),
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddFoodCard() {
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
            _buildFoodImageUpload(),
            SizedBox(height: 20),
            _buildNameField(),
            SizedBox(height: 20),
            _buildDescriptionField(),
            SizedBox(height: 20),
            _buildPriceField(),
            SizedBox(height: 30),
            _buildAddFoodButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildFoodImageUpload() {
    return Center(
      child: GestureDetector(
        onTap: _pickImage,
        child: Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            color: Color(0xFFF0F0F0),
            borderRadius: BorderRadius.circular(16),
            image: _foodImage != null
                ? DecorationImage(
                    image: FileImage(_foodImage!),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: _foodImage == null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_a_photo,
                      size: 40,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Add Food Image',
                      style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
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
        labelText: 'FOOD NAME',
        labelStyle: TextStyle(color: Colors.grey),
        filled: true,
        fillColor: Color(0xFFF0F0F0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        hintText: 'Chicken Burger',
        hintStyle: TextStyle(color: Colors.grey),
      ),
    );
  }

  Widget _buildDescriptionField() {
    return TextField(
      controller: _descriptionController,
      style: TextStyle(color: Colors.black),
      maxLines: 3,
      decoration: InputDecoration(
        labelText: 'DESCRIPTION',
        labelStyle: TextStyle(color: Colors.grey),
        filled: true,
        fillColor: Color(0xFFF0F0F0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        hintText: 'Delicious burger with crispy chicken, fresh lettuce and special sauce',
        hintStyle: TextStyle(color: Colors.grey),
      ),
    );
  }

  Widget _buildPriceField() {
    return TextField(
      controller: _priceController,
      keyboardType: TextInputType.numberWithOptions(decimal: true),
      style: TextStyle(color: Colors.black),
      decoration: InputDecoration(
        labelText: 'PRICE',
        labelStyle: TextStyle(color: Colors.grey),
        filled: true,
        fillColor: Color(0xFFF0F0F0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        prefixIcon: Icon(Icons.attach_money, color: Colors.grey),
        hintText: '9.99',
        hintStyle: TextStyle(color: Colors.grey),
      ),
    );
  }

  Widget _buildAddFoodButton() {
    return _isUploading
        ? Center(child: CircularProgressIndicator())
        : ElevatedButton(
            onPressed: _addFood,
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFFF6B01),
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'ADD FOOD',
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
        _foodImage = File(pickedFile.path);
      });

      final bytes = await _foodImage!.readAsBytes();
      _foodImageBase64 = base64Encode(bytes);
    }
  }

  Future<void> _addFood() async {
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
    // Create a map for the food item
    final foodMap = {
      'name': _nameController.text.trim(),
      'description': _descriptionController.text.trim(),
      'price': double.parse(_priceController.text.trim()),
      'foodPicture': _foodImageBase64 ?? '', // Ensure this is not null
    };

    // Debug: Print the foodMap to verify its contents
    debugPrint("Food Map: $foodMap");

    // Add the food item and get the generated ID
    final foodId = await _foodService.addFood(foodMap);

    if (foodId != null) {
      _showSuccessSnackBar('Food item added successfully');
      _resetForm();
    } else {
      setState(() {
        _errorMessage = 'Failed to add food item. Please try again.';
      });
    }
  } catch (e) {
    setState(() {
      _errorMessage = 'Error: ${e.toString()}';
    });
    debugPrint("Detailed error: ${e.toString()}");
  } finally {
    setState(() {
      _isUploading = false;
    });
  }
}

  void _resetForm() {
    _nameController.clear();
    _descriptionController.clear();
    _priceController.clear();
    setState(() {
      _foodImage = null;
      _foodImageBase64 = null;
    });
  }

  bool _validateInputs() {
    String name = _nameController.text.trim();
    String description = _descriptionController.text.trim();
    String price = _priceController.text.trim();

    // Check if any field is empty
    if (name.isEmpty || description.isEmpty || price.isEmpty) {
      setState(() {
        _errorMessage = 'Please fill in all fields';
      });
      return false;
    }

    // Validate price format
    if (!_isValidPrice(price)) {
      setState(() {
        _errorMessage = 'Please enter a valid price';
      });
      return false;
    }

    // Check if image is added
    if (_foodImageBase64 == null) {
      setState(() {
        _errorMessage = 'Please add a food image';
      });
      return false;
    }

    return true;
  }

  bool _isValidPrice(String price) {
    try {
      double parsedPrice = double.parse(price);
      return parsedPrice > 0;
    } catch (e) {
      return false;
    }
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