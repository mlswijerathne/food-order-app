import 'package:flutter/material.dart';
import 'package:foodapp/models/food_model.dart';
import 'package:foodapp/screens/food_detail_screen.dart';
import 'package:foodapp/screens/user/cart_screen.dart';
import 'package:foodapp/services/food_service.dart';
import 'package:foodapp/services/cart_service.dart';
import 'dart:convert';
import 'package:foodapp/services/auth_service.dart';

class AllFoodsScreen extends StatefulWidget {
  const AllFoodsScreen({super.key});

  @override
  _AllFoodsScreenState createState() => _AllFoodsScreenState();
}

class _AllFoodsScreenState extends State<AllFoodsScreen> {
  final FoodService _foodService = FoodService();
  final CartService _cartService = CartService();
  final AuthService _authService = AuthService();
  List<FoodModel> _foods = [];
  List<FoodModel> _filteredFoods = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadFoods();
    _searchController.addListener(_onSearchChanged);
    _getCurrentUser();
  }

  Future<void> _getCurrentUser() async {
    final currentUser = await _authService.getCurrentUser();
    setState(() {
      _currentUserId = currentUser?.uid;
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _filterFoods(_searchController.text);
  }

  void _filterFoods(String query) {
    List<FoodModel> filteredList = [];
    
    if (query.isEmpty) {
      filteredList = _foods;
    } else {
      filteredList = _foods.where((food) => 
        food.name.toLowerCase().contains(query.toLowerCase()) ||
        food.description.toLowerCase().contains(query.toLowerCase())
      ).toList();
    }

    setState(() {
      _filteredFoods = filteredList;
    });
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        _filteredFoods = _foods;
      }
    });
  }

  Future<void> _loadFoods() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      List<FoodModel> foods = await _foodService.getAllFoods();
      setState(() {
        _foods = foods;
        _filteredFoods = foods;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load foods: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _addToCart(FoodModel food) async {
    if (_currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You need to be logged in to add items to cart'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    
    try {
      bool success = await _cartService.addToCart(_currentUserId!, food);
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${food.name} added to cart'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
            action: SnackBarAction(
              label: 'VIEW CART',
              onPressed: _goToCart,
              textColor: Colors.white,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add to cart'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding to cart: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _goToCart() {
    if (_currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You need to be logged in to view your cart'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CartScreen(userId: _currentUserId!),
      ),
    ).then((_) {
      // Refresh when returning from cart
      _loadFoods();
    });
  }

  Future<bool> _onWillPop() async {
    // Navigate to the root route when back button is pressed
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
          title: _isSearching
              ? TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Search foods...',
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: Colors.grey),
                  ),
                  style: TextStyle(color: Colors.black),
                )
              : Text(
                  'Food Menu',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: _isSearching ? false : true,
          leading: _isSearching
              ? IconButton(
                  icon: Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: _toggleSearch,
                )
              : IconButton(
                  icon: Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () {
                    Navigator.of(context).pushReplacementNamed('/');
                  },
                ),
          actions: [
            IconButton(
              icon: Icon(
                _isSearching ? Icons.clear : Icons.search,
                color: Colors.black,
              ),
              onPressed: _isSearching
                  ? () {
                      _searchController.clear();
                    }
                  : _toggleSearch,
            ),
            IconButton(
              icon: Icon(
                Icons.shopping_cart,
                color: Colors.black,
              ),
              onPressed: _goToCart,
            ),
          ],
        ),
        body: SafeArea(
          child: _isLoading
              ? Center(child: CircularProgressIndicator(color: Color(0xFFFF6B01)))
              : _errorMessage != null
                  ? _buildErrorView()
                  : _filteredFoods.isEmpty
                      ? _buildEmptySearchView()
                      : _buildFoodsGrid(),
        ),
      ),
    );
  }

  // Rest of your widget methods remain the same
  Widget _buildEmptySearchView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              color: Colors.grey,
              size: 60,
            ),
            SizedBox(height: 16),
            Text(
              'No Results Found',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'We couldn\'t find any food items matching your search.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
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
              onPressed: _loadFoods,
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

  Widget _buildEmptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant_menu,
              color: Colors.grey,
              size: 60,
            ),
            SizedBox(height: 16),
            Text(
              'No Food Items',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'There are no food items available at the moment.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFoodsGrid() {
    return RefreshIndicator(
      onRefresh: _loadFoods,
      color: Color(0xFFFF6B01),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.75,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: _filteredFoods.length,
          itemBuilder: (context, index) {
            final food = _filteredFoods[index];
            return _buildFoodCard(food);
          },
        ),
      ),
    );
  }

  Widget _buildFoodCard(FoodModel food) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FoodDetailScreen(foodId: food.id, userId: _currentUserId),
          ),
        ).then((_) {
          // Refresh when returning from food detail
          _loadFoods();
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              spreadRadius: 1,
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  image: food.foodPicture.isNotEmpty
                      ? DecorationImage(
                          image: MemoryImage(base64Decode(food.foodPicture)),
                          fit: BoxFit.cover,
                        )
                      : null,
                  color: Colors.grey.shade200,
                ),
                child: food.foodPicture.isEmpty
                    ? Center(
                        child: Icon(
                          Icons.fastfood,
                          color: Colors.grey,
                          size: 40,
                        ),
                      )
                    : null,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    food.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    food.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "\$${food.price.toStringAsFixed(2)}",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Color(0xFFFF6B01),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 18,
                          ),
                          onPressed: () => _addToCart(food),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}