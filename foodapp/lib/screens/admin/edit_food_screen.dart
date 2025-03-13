import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:foodapp/models/food_model.dart';
import 'package:foodapp/services/food_service.dart';
import 'package:image_picker/image_picker.dart';

class AdminEditFoodScreen extends StatefulWidget {
  final String foodId;

  const AdminEditFoodScreen({super.key, required this.foodId});

  @override
  _AdminEditFoodScreenState createState() => _AdminEditFoodScreenState();
}

class _AdminEditFoodScreenState extends State<AdminEditFoodScreen> {
  final FoodService _foodService = FoodService();
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  FoodModel? _food;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isDeleting = false;
  String? _errorMessage;
  String? _selectedImage;
  String _originalImage = '';

  @override
  void initState() {
    super.initState();
    _loadFoodDetails();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _loadFoodDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      FoodModel? food = await _foodService.getFoodById(widget.foodId);
      if (food != null) {
        setState(() {
          _food = food;
          _nameController.text = food.name;
          _descriptionController.text = food.description;
          _priceController.text = food.price.toString();
          _originalImage = food.foodPicture;
          _selectedImage = food.foodPicture;
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
        _errorMessage = 'Failed to load food details: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 90,
      );
      
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedImage = base64Encode(bytes);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick image: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Create updated food model
      final updatedFood = FoodModel(
        id: _food!.id,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        price: double.parse(_priceController.text.trim()),
        foodPicture: _selectedImage ?? '',
      );

      // Update in Firestore
      final success = await _foodService.updateFood(updatedFood);

      if (success) {
        // Navigate back to details page
        if (mounted) {
          Navigator.pop(context, true); // Return true to indicate successful update
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Food item updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          setState(() {
            _isSaving = false;
            _errorMessage = 'Failed to update food item';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _errorMessage = 'Error: ${e.toString()}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(
          'Edit Food Item',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.delete, color: Colors.red),
            onPressed: _confirmDelete,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Color(0xFFFF6B01)))
          : _errorMessage != null
              ? _buildErrorView()
              : _buildEditForm(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 60,
            ),
            SizedBox(height: 16),
            Text(
              'Error',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade800,
              ),
            ),
            SizedBox(height: 8),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade700,
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadFoodDetails,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFFF6B01),
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'TRY AGAIN',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditForm() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildImageSection(),
              SizedBox(height: 12),
              _buildFormFields(),
              SizedBox(height: 32),
              _buildSaveButton(),
              SizedBox(height: 16),
              
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Food Image',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 16),
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: _selectedImage != null && _selectedImage!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(
                            base64Decode(_selectedImage!),
                            fit: BoxFit.cover,
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate,
                              size: 50,
                              color: Colors.grey.shade500,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Tap to select an image',
                              style: TextStyle(
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
            SizedBox(height: 16),
            Center(
              child: TextButton.icon(
                onPressed: _pickImage,
                icon: Icon(Icons.photo_library, color: Color(0xFFFF6B01)),
                label: Text(
                  'Change Image',
                  style: TextStyle(
                    color: Color(0xFFFF6B01),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormFields() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Food Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Food Name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                floatingLabelBehavior: FloatingLabelBehavior.auto,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a food name';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                floatingLabelBehavior: FloatingLabelBehavior.auto,
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a description';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _priceController,
              decoration: InputDecoration(
                labelText: 'Price',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixText: '\$ ',
                floatingLabelBehavior: FloatingLabelBehavior.auto,
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a price';
                }
                try {
                  double price = double.parse(value);
                  if (price <= 0) {
                    return 'Price must be greater than 0';
                  }
                } catch (e) {
                  return 'Please enter a valid price';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: _isSaving ? null : _saveChanges,
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xFFFF6B01),
        padding: EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        disabledBackgroundColor: Colors.grey,
      ),
      child: _isSaving
          ? SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            )
          : Text(
              'SAVE CHANGES',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }

  // Widget _buildDeleteButton() {
  //   return ElevatedButton(
  //     onPressed: _isDeleting ? null : _confirmDelete,
  //     style: ElevatedButton.styleFrom(
  //       backgroundColor: Colors.white,
  //       foregroundColor: Colors.red,
  //       padding: EdgeInsets.symmetric(vertical: 16),
  //       shape: RoundedRectangleBorder(
  //         borderRadius: BorderRadius.circular(12),
  //         side: BorderSide(color: Colors.red, width: 1.5),
  //       ),
  //       elevation: 0,
  //     ),
  //     child: _isDeleting
  //         ? SizedBox(
  //             height: 20,
  //             width: 20,
  //             child: CircularProgressIndicator(
  //               color: Colors.red,
  //               strokeWidth: 3,
  //             ),
  //           )
  //         : Row(
  //             mainAxisAlignment: MainAxisAlignment.center,
  //             children: [
  //               Icon(Icons.delete_outline, color: Colors.red),
  //               SizedBox(width: 8),
  //               Text(
  //                 'DELETE FOOD ITEM',
  //                 style: TextStyle(
  //                   color: Colors.red,
  //                   fontSize: 16,
  //                   fontWeight: FontWeight.bold,
  //                 ),
  //               ),
  //             ],
  //           ),
  //   );
  // }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Food Item'),
        content: Text('Are you sure you want to delete "${_food!.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('CANCEL'),
          ),
          TextButton(
            onPressed: _deleteFood,
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
    Navigator.pop(context); // Close dialog
    setState(() {
      _isDeleting = true;
    });

    try {
      final success = await _foodService.deleteFood(_food!.id);
      if (success) {
        if (mounted) {
          Navigator.pop(context, 'deleted'); // Return 'deleted' to indicate deletion
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Food item deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          setState(() {
            _isDeleting = false;
            _errorMessage = 'Failed to delete food item';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDeleting = false;
          _errorMessage = 'Error: ${e.toString()}';
        });
      }
    }
  }
}