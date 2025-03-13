import 'package:flutter/material.dart';
import 'package:foodapp/models/food_model.dart';
import 'package:foodapp/services/food_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';

class UpdateFoodScreen extends StatefulWidget {
  final String foodId;
  
  const UpdateFoodScreen({super.key, required this.foodId});

  @override
  _UpdateFoodScreenState createState() => _UpdateFoodScreenState();
}

class _UpdateFoodScreenState extends State<UpdateFoodScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final FoodService _foodService = FoodService();

  bool _isLoading = true;
  bool _isUpdating = false;
  bool _isDeleting = false;
  String? _errorMessage;
  FoodModel? _foodItem;
  
  File? _foodImage;
  String? _foodImageBase64;

  @override
  void initState() {
    super.initState();
    _loadFoodItem();
  }

  Future<void> _loadFoodItem() async {
    try {
      final foodItem = await _foodService.getFoodById(widget.foodId);
      if (foodItem != null) {
        setState(() {
          _foodItem = foodItem;
          _nameController.text = foodItem.name;
          _descriptionController.text = foodItem.description;
          _priceController.text = foodItem.price.toString();
          _foodImageBase64 = foodItem.foodPicture;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Food item not found';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading food item: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

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
        title: Text('Update Food Item'),
        backgroundColor: Color(0xFFFF6B01),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading 
        ? Center(child: CircularProgressIndicator()) 
        : SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: 20),
                    Text(
                      'Update Food Item',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Modify food details',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 20),
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
                    _buildUpdateCard(),
                    SizedBox(height: 20),
                    _buildDeleteButton(),
                    SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  Widget _buildUpdateCard() {
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
            _buildUpdateButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildFoodImageUpload() {
    Widget imageWidget;
    
    if (_foodImage != null) {
      imageWidget = Image.file(_foodImage!, fit: BoxFit.cover);
    } else if (_foodImageBase64 != null && _foodImageBase64!.isNotEmpty) {
      try {
        imageWidget = Image.memory(
          base64Decode(_foodImageBase64!),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Icon(
              Icons.image_not_supported,
              size: 40,
              color: Colors.grey,
            );
          },
        );
      } catch (e) {
        imageWidget = Icon(
          Icons.image_not_supported,
          size: 40,
          color: Colors.grey,
        );
      }
    } else {
      imageWidget = Icon(
        Icons.camera_alt,
        size: 40,
        color: Colors.grey,
      );
    }

    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: Color(0xFFF0F0F0),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(child: imageWidget),
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
        hintText: 'Delicious chicken burger with cheese and veggies',
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
        hintText: '9.99',
        prefixText: '\$ ',
        prefixStyle: TextStyle(color: Colors.black),
        hintStyle: TextStyle(color: Colors.grey),
      ),
    );
  }

  Widget _buildUpdateButton() {
    return _isUpdating
        ? Center(child: CircularProgressIndicator())
        : ElevatedButton(
            onPressed: _updateFood,
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFFF6B01),
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'UPDATE FOOD ITEM',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
  }

  Widget _buildDeleteButton() {
    return _isDeleting
        ? Center(child: CircularProgressIndicator())
        : ElevatedButton(
            onPressed: _showDeleteConfirmation,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'DELETE FOOD ITEM',
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

  Future<void> _updateFood() async {
    // Clear any previous error messages
    setState(() {
      _errorMessage = null;
    });

    // Validate input fields
    if (!_validateInputs()) return;

    setState(() {
      _isUpdating = true;
    });

    try {
      double price = double.parse(_priceController.text.trim());
      
      // Create updated food model
      FoodModel updatedFood = FoodModel(
        id: widget.foodId,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        price: price,
        foodPicture: _foodImageBase64 ?? '',
      );

      // Update the food item
      bool success = await _foodService.updateFood(updatedFood);

      if (success) {
        _showSuccessSnackBar('Food item updated successfully');
        // Go back to previous screen
        Navigator.pop(context, true);
      } else {
        setState(() {
          _errorMessage = 'Failed to update food item. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isUpdating = false;
      });
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Food Item'),
        content: Text('Are you sure you want to delete this food item? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteFood();
            },
            child: Text(
              'DELETE',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteFood() async {
    setState(() {
      _isDeleting = true;
      _errorMessage = null;
    });

    try {
      // Delete the food item
      bool success = await _foodService.deleteFood(widget.foodId);

      if (success) {
        _showSuccessSnackBar('Food item deleted successfully');
        // Go back to previous screen
        Navigator.pop(context, true);
      } else {
        setState(() {
          _errorMessage = 'Failed to delete food item. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isDeleting = false;
      });
    }
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

    // Validate price
    try {
      double priceValue = double.parse(price);
      if (priceValue <= 0) {
        setState(() {
          _errorMessage = 'Price must be greater than zero';
        });
        return false;
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Please enter a valid price';
      });
      return false;
    }

    return true;
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