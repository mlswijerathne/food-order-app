import 'package:flutter/material.dart';
import 'package:foodapp/models/food_model.dart';
import 'package:foodapp/screens/admin/edit_food_screen.dart';
import 'package:foodapp/screens/admin/food_details_screen.dart';
import 'package:foodapp/services/food_service.dart';
import 'dart:convert';

class AdminAllFoodsScreen extends StatefulWidget {
  const AdminAllFoodsScreen({super.key});

  @override
  _AdminAllFoodsScreenState createState() => _AdminAllFoodsScreenState();
}

class _AdminAllFoodsScreenState extends State<AdminAllFoodsScreen> {
  final FoodService _foodService = FoodService();
  List<FoodModel> _foods = [];
  List<FoodModel> _filteredFoods = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  FoodModel? _food;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _loadFoods();
    _searchController.addListener(_filterFoods);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterFoods);
    _searchController.dispose();
    super.dispose();
  }

  void _filterFoods() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredFoods = List.from(_foods);
      } else {
        _filteredFoods = _foods
            .where((food) =>
                food.name.toLowerCase().contains(query) ||
                food.description.toLowerCase().contains(query))
            .toList();
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
        _filteredFoods = List.from(foods);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load foods: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
      } else {
        // Focus on search field when opened
        FocusScope.of(context).requestFocus(FocusNode());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_isSearching) {
          setState(() {
            _isSearching = false;
            _searchController.clear();
          });
          return false;
        }
        Navigator.pushReplacementNamed(context, '/admin_home');
        return false; // Prevent default back behavior
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: _buildAppBar(),
        body: SafeArea(
          child: _isLoading
              ? Center(child: CircularProgressIndicator(color: Color(0xFFFF6B01)))
              : _errorMessage != null
                  ? _buildErrorView()
                  : _filteredFoods.isEmpty
                      ? _buildEmptyView()
                      : _buildFoodsGrid(),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.pushNamed(context, '/admin_food_adding_screen');
          },
          backgroundColor: Color(0xFFFF6B01),
          child: Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    if (_isSearching) {
      return AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Search foods...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.grey),
          ),
          style: TextStyle(color: Colors.black, fontSize: 16),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: _toggleSearch,
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.clear, color: Colors.black),
            onPressed: () {
              _searchController.clear();
            },
          ),
        ],
      );
    } else {
      return AppBar(
        title: Text(
          'Food Menu',
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
            Navigator.pushReplacementNamed(context, '/admin_home');
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: Colors.black),
            onPressed: _toggleSearch,
          ),
        ],
      );
    }
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
              _searchController.text.isNotEmpty
                  ? 'No Results Found'
                  : 'No Food Items',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            SizedBox(height: 8),
            Text(
              _searchController.text.isNotEmpty
                  ? 'No food items match your search criteria.'
                  : 'There are no food items available at the moment.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            if (_searchController.text.isNotEmpty) ...[
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  _searchController.clear();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFFF6B01),
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'CLEAR SEARCH',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
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

  Future<void> _deleteFood() async {
    Navigator.pop(context); // Close dialog
    setState(() {
      _isDeleting = true;
    });

    try {
      final success = await _foodService.deleteFood(_food!.id);
      if (success) {
        setState(() {
          // Remove the deleted food from both lists
          _foods.removeWhere((item) => item.id == _food!.id);
          _filteredFoods.removeWhere((item) => item.id == _food!.id);
        });
        
        if (mounted) {
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

  void _confirmDelete(FoodModel food) {
    // Set the selected food before showing the dialog
    setState(() {
      _food = food;
    });
    
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

  Widget _buildFoodCard(FoodModel food) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AdminFoodDetailScreen(foodId: food.id),
          ),
        );
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
                      Row(
                        children: [
                          // Delete button
                          Container(
                            width: 32,
                            height: 32,
                            margin: EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: Color(0xFFFF6B01),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: Icon(
                                Icons.delete,
                                color: Colors.white,
                                size: 18,
                              ),
                              onPressed: () => _confirmDelete(food),
                            ),
                          ),
                          // Edit button
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
                                Icons.edit,
                                color: Colors.white,
                                size: 18,
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AdminEditFoodScreen(foodId: food.id),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
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