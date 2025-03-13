import 'package:flutter/material.dart';
import 'package:foodapp/models/cart_item_model.dart';
import 'package:foodapp/screens/user/checkout_screen.dart';
import 'package:foodapp/services/cart_service.dart';
import 'dart:convert';

class CartScreen extends StatefulWidget {
  final String userId;
  
  const CartScreen({
    super.key, 
    required this.userId,
  });

  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final CartService _cartService = CartService();
  List<CartItemModel> _cartItems = [];
  double _cartTotal = 0.0;
  bool _isLoading = true;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    _loadCartItems();
  }

  Future<void> _loadCartItems() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      List<CartItemModel> items = await _cartService.getCartItems(widget.userId);
      double total = await _cartService.getCartTotal(widget.userId);
      
      setState(() {
        _cartItems = items;
        _cartTotal = total;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load cart: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'My Cart',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(color: Colors.black),
        actions: [
          if (_cartItems.isNotEmpty)
            IconButton(
              icon: Icon(Icons.delete_outline, color: Colors.black),
              onPressed: _confirmClearCart,
            ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: Color(0xFFFF6B01)))
            : _errorMessage != null
                ? _buildErrorView()
                : _cartItems.isEmpty
                    ? _buildEmptyCartView()
                    : _buildCartItemsList(),
      ),
      bottomNavigationBar: _cartItems.isEmpty 
          ? null 
          : _buildCheckoutBar(),
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
              onPressed: _loadCartItems,
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

  Widget _buildEmptyCartView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              color: Colors.grey,
              size: 60,
            ),
            SizedBox(height: 16),
            Text(
              'Your Cart is Empty',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Add some delicious food items to your cart',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Go back to food list
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFFF6B01),
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'BROWSE MENU',
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

  Widget _buildCartItemsList() {
    return RefreshIndicator(
      onRefresh: _loadCartItems,
      color: Color(0xFFFF6B01),
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: _cartItems.length,
        itemBuilder: (context, index) {
          return _buildCartItemCard(_cartItems[index]);
        },
      ),
    );
  }

  Widget _buildCartItemCard(CartItemModel item) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
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
      child: Row(
        children: [
          // Food Image
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
              image: item.food.foodPicture.isNotEmpty
                  ? DecorationImage(
                      image: MemoryImage(base64Decode(item.food.foodPicture)),
                      fit: BoxFit.cover,
                    )
                  : null,
              color: Colors.grey.shade200,
            ),
            child: item.food.foodPicture.isEmpty
                ? Center(
                    child: Icon(
                      Icons.fastfood,
                      color: Colors.grey,
                      size: 40,
                    ),
                  )
                : null,
          ),
          // Food Details
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.food.name,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    item.food.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "\$${item.food.price.toStringAsFixed(2)}",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFF6B01),
                        ),
                      ),
                      _buildQuantityControls(item),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityControls(CartItemModel item) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Color(0xFFF0F0F0),
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconButton(
            padding: EdgeInsets.zero,
            icon: Icon(
              Icons.remove,
              size: 16,
              color: Colors.black,
            ),
            onPressed: () => _updateQuantity(item, item.quantity - 1),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Text(
            '${item.quantity}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Color(0xFFFF6B01),
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconButton(
            padding: EdgeInsets.zero,
            icon: Icon(
              Icons.add,
              size: 16,
              color: Colors.white,
            ),
            onPressed: () => _updateQuantity(item, item.quantity + 1),
          ),
        ),
      ],
    );
  }

  Widget _buildCheckoutBar() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 10,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    '\$${_cartTotal.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: _proceedToCheckout,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFFF6B01),
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'CHECKOUT',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateQuantity(CartItemModel item, int newQuantity) async {
    if (newQuantity <= 0) {
      _confirmRemoveItem(item);
      return;
    }

    bool success = await _cartService.updateCartItemQuantity(
      widget.userId, 
      item.id, 
      newQuantity
    );

    if (success) {
      _loadCartItems(); // Reload cart to reflect changes
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update quantity'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _confirmRemoveItem(CartItemModel item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove Item'),
        content: Text('Are you sure you want to remove "${item.food.name}" from your cart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _removeItem(item);
            },
            child: Text(
              'REMOVE',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _removeItem(CartItemModel item) async {
    bool success = await _cartService.removeCartItem(widget.userId, item.id);
    
    if (success) {
      _loadCartItems(); // Reload cart to reflect changes
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to remove item from cart'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _confirmClearCart() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Clear Cart'),
        content: Text('Are you sure you want to clear all items from your cart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _clearCart();
            },
            child: Text(
              'CLEAR',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _clearCart() async {
    bool success = await _cartService.clearCart(widget.userId);
    
    if (success) {
      _loadCartItems(); // Reload cart to reflect changes
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to clear cart'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _proceedToCheckout() {
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Proceeding to checkout...'),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => CheckoutScreen(userId: widget.userId,)),
    );
  }
}