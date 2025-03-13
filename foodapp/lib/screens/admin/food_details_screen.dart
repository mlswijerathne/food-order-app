import 'package:flutter/material.dart';
import 'package:foodapp/models/food_model.dart';
import 'package:foodapp/screens/admin/edit_food_screen.dart';
import 'package:foodapp/services/food_service.dart';
import 'dart:convert';

class AdminFoodDetailScreen extends StatefulWidget {
  final String foodId;

  const AdminFoodDetailScreen({super.key, required this.foodId});

  @override
  _AdminFoodDetailScreenState createState() => _AdminFoodDetailScreenState();
}

class _AdminFoodDetailScreenState extends State<AdminFoodDetailScreen> {
  final FoodService _foodService = FoodService();
  FoodModel? _food;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadFoodDetails();
  }

  Future<void> _loadFoodDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      FoodModel? food = await _foodService.getFoodById(widget.foodId);
      setState(() {
        _food = food;
        _isLoading = false;
        if (food == null) {
          _errorMessage = 'Food item not found';
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load food details: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(
          _food != null ? _food!.name : 'Food Details',
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
      ),
      body: SafeArea(
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: Color(0xFFFF6B01)))
            : _errorMessage != null
                ? _buildErrorView()
                : _buildFoodDetailsView(),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: Colors.red, size: 60),
          SizedBox(height: 16),
          Text(_errorMessage!, style: TextStyle(fontSize: 16, color: Colors.grey.shade700)),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadFoodDetails,
            style: ElevatedButton.styleFrom(backgroundColor: Color(0xFFFF6B01)),
            child: Text('TRY AGAIN'),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodDetailsView() {
    if (_food == null) return Container();
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildFoodImage(),
            SizedBox(height: 24),
            _buildFoodInfoCard(),
            SizedBox(height: 24),
            _buildEditFoodDetails(),
          ],
        ),
      ),
    );
  }

  Widget _buildFoodImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: _food!.foodPicture.isNotEmpty
          ? Image.memory(base64Decode(_food!.foodPicture), height: 250, fit: BoxFit.cover)
          : Container(
              height: 250,
              color: Color(0xFFF0F0F0),
              child: Center(child: Icon(Icons.fastfood, size: 80, color: Colors.grey)),
            ),
    );
  }

  Widget _buildFoodInfoCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_food!.name, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text(_food!.description, style: TextStyle(fontSize: 16, color: Colors.grey.shade700)),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('\$${_food!.price.toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFFF6B01))),
              ],
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildEditFoodDetails() {
    return ElevatedButton(
      onPressed: () async {
        // Add 'await' here to get the result when returning from the edit screen
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AdminEditFoodScreen(foodId: _food!.id),
          ),
        );
        
        // Check if the edit was successful or if the item was deleted
        if (result == true || result == 'deleted') {
          if (result == 'deleted') {
            // If item was deleted, navigate back to the food list
            Navigator.pop(context);
          } else {
            // If item was updated, refresh the details
            _loadFoodDetails();
          }
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xFFFF6B01),
        padding: EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text('Edit Food details', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
    );
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
