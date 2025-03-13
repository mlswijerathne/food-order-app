import 'package:flutter/material.dart';
import 'package:foodapp/models/food_model.dart';
import 'package:foodapp/screens/user/cart_screen.dart';
import 'package:foodapp/services/food_service.dart';
import 'package:foodapp/services/cart_service.dart';
import 'package:foodapp/services/auth_service.dart';
import 'dart:convert';

class FoodDetailScreen extends StatefulWidget {
  final String foodId;
  final String? userId;

  const FoodDetailScreen({super.key, required this.foodId, this.userId});

  @override
  _FoodDetailScreenState createState() => _FoodDetailScreenState();
}

class _FoodDetailScreenState extends State<FoodDetailScreen> {
  final FoodService _foodService = FoodService();
  final CartService _cartService = CartService();
  final AuthService _authService = AuthService();
  FoodModel? _food;
  bool _isLoading = true;
  String? _errorMessage;
  int _quantity = 1; // Default quantity
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadFoodDetails();
    _currentUserId = widget.userId;
    if (_currentUserId == null) {
      _getCurrentUser();
    }
  }

  Future<void> _getCurrentUser() async {
    final currentUser = await _authService.getCurrentUser();
    setState(() {
      _currentUserId = currentUser?.uid;
    });
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

  Future<void> _addToCart() async {
    if (_food == null) return;
    if (_currentUserId == null) {
      _showErrorSnackBar('You need to be logged in to add items to cart');
      return;
    }
    
    try {
      bool success = await _cartService.addToCart(_currentUserId!, _food!, quantity: _quantity);
      
      if (success) {
        _showSuccessSnackBar('${_food!.name} added to cart');
      } else {
        _showErrorSnackBar('Failed to add to cart');
      }
    } catch (e) {
      _showErrorSnackBar('Error adding to cart: ${e.toString()}');
    }
  }

  void _goToCart() {
    if (_currentUserId == null) {
      _showErrorSnackBar('You need to be logged in to view your cart');
      return;
    }
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CartScreen(userId: _currentUserId!),
      ),
    ).then((_) {
      // Refresh when returning from cart screen
      _loadFoodDetails();
      if (widget.userId == null) {
        _getCurrentUser();
      }
    });
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
        actions: [
          IconButton(
            icon: Icon(Icons.shopping_cart, color: Colors.black),
            onPressed: _goToCart,
          ),
        ],
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
            SizedBox(height: 16),
            _buildQuantitySelector(),
            SizedBox(height: 24),
            _buildAddToCartButton(),
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

  Widget _buildQuantitySelector() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Quantity',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Color(0xFFF0F0F0),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: Icon(
                      Icons.remove,
                      size: 18,
                      color: Colors.black,
                    ),
                    onPressed: () {
                      if (_quantity > 1) {
                        setState(() {
                          _quantity--;
                        });
                      }
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    '$_quantity',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Color(0xFFFF6B01),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: Icon(
                      Icons.add,
                      size: 18,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      setState(() {
                        _quantity++;
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddToCartButton() {
    return ElevatedButton(
      onPressed: _addToCart,
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xFFFF6B01),
        padding: EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text('ADD TO CART', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
        action: SnackBarAction(
          label: 'VIEW CART',
          onPressed: _goToCart,
          textColor: Colors.white,
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 2),
      ),
    );
  }
}