import 'package:flutter/material.dart';
import 'package:foodapp/models/order_model.dart';
import 'package:foodapp/models/user_model.dart';
import 'package:foodapp/services/admin_orders_service.dart';
import 'package:intl/intl.dart';

class AdminOrderDetailScreen extends StatefulWidget {
  final String orderId;

  const AdminOrderDetailScreen({super.key, required this.orderId});

  @override
  _AdminOrderDetailScreenState createState() => _AdminOrderDetailScreenState();
}

class _AdminOrderDetailScreenState extends State<AdminOrderDetailScreen> {
  final AdminOrderService _adminOrderService = AdminOrderService();
  
  OrderModel? _order;
  UserModel? _customer;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadOrderDetails();
  }

  Future<void> _loadOrderDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Fetch order details
      OrderModel? order = await _adminOrderService.getOrderById(widget.orderId);
      
      if (order == null) {
        setState(() {
          _errorMessage = 'Order not found';
          _isLoading = false;
        });
        return;
      }

      // Fetch customer details
      UserModel? customer = await _adminOrderService.getUserById(order.userId);

      setState(() {
        _order = order;
        _customer = customer;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load order details: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _updateOrderStatus(String newStatus) async {
    try {
      bool success = await _adminOrderService.updateOrderStatus(widget.orderId, newStatus);
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Order status updated to $newStatus')),
        );
        _loadOrderDetails(); // Reload order details
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update order status')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Order Details'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadOrderDetails,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : _order == null
                  ? Center(child: Text('Order not found'))
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildOrderStatusHeader(context),
                          _buildCustomerInfo(),
                          _buildOrderItems(),
                          _buildOrderSummary(),
                          _buildStatusUpdateSection(),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildOrderStatusHeader(BuildContext context) {
  return Container(
    width: double.infinity,
    color: _getStatusColor(_order!.status).withOpacity(0.2),
    padding: EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(  // Ensure text fits within available space
              child: Text(
                'Order #${_order!.id}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
                overflow: TextOverflow.ellipsis, // Prevents text from overflowing
              ),
            ),
            SizedBox(width: 8), // Space between elements
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(_order!.status),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                _order!.status.toUpperCase(),
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Text(
          'Placed on: ${DateFormat('MMM dd, yyyy • hh:mm a').format(_order!.orderDate)}',
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 14,
          ),
        ),
      ],
    ),
  );
}


  Widget _buildCustomerInfo() {
  return Padding(
    padding: EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Customer Information',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        Card(
          elevation: 2,
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.person, size: 18, color: Colors.grey),
                    SizedBox(width: 8),
                    Text(
                      _customer?.name ?? 'Unknown Customer',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.email, size: 18, color: Colors.grey),
                    SizedBox(width: 8),
                    Text(_customer?.email ?? 'No email provided'),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.phone, size: 18, color: Colors.grey),
                    SizedBox(width: 8),
                    Text(_customer?.contactNumber.isNotEmpty == true 
                      ? _customer!.contactNumber 
                      : 'No phone number'),
                  ],
                ),
                if (_order!.deliveryAddress != null && _order!.deliveryAddress!.isNotEmpty) ...[
                  SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.location_on, size: 18, color: Colors.grey),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(_order!.deliveryAddress!),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    ),
  );
}


  Widget _buildOrderItems() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Items',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Card(
            elevation: 2,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  for (int i = 0; i < _order!.items.length; i++) ...[
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              '${_order!.items[i].quantity}x',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _order!.items[i].food.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '\$${_order!.items[i].food.price.toStringAsFixed(2)} each',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '\$${(_order!.items[i].food.price * _order!.items[i].quantity).toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    if (i < _order!.items.length - 1)
                      Divider(height: 24),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary() {
    double subtotal = 0;
    for (var item in _order!.items) {
      subtotal += item.food.price * item.quantity;
    }
    
    // Estimate delivery fee and tax
    double deliveryFee = 2.99;
    double tax = subtotal * 0.08; // 8% tax rate
    
    return Padding(
      padding: EdgeInsets.all(16),
      child: Card(
        elevation: 2,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Order Summary',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Subtotal'),
                  Text('\$${subtotal.toStringAsFixed(2)}'),
                ],
              ),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Delivery Fee'),
                  Text('\$${deliveryFee.toStringAsFixed(2)}'),
                ],
              ),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Tax'),
                  Text('\$${tax.toStringAsFixed(2)}'),
                ],
              ),
              Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    '\$${_order!.totalAmount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusUpdateSection() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Update Order Status',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatusButton('pending'),
              _buildStatusButton('processing'),
              _buildStatusButton('delivered'),
            ],
          ),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStatusButton('cancelled', isDestructive: true),
            ],
          ),
          SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildStatusButton(String status, {bool isDestructive = false}) {
    bool isCurrentStatus = _order!.status == status;
    
    return ElevatedButton(
      onPressed: isCurrentStatus ? null : () => _updateOrderStatus(status),
      style: ElevatedButton.styleFrom(
        backgroundColor: isDestructive 
            ? (isCurrentStatus ? Colors.red : Colors.red.shade100)
            : (isCurrentStatus ? _getStatusColor(status) : Colors.grey.shade200),
        foregroundColor: isCurrentStatus 
            ? Colors.white 
            : (isDestructive ? Colors.red : Colors.black),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      child: Text(
        status.capitalize(),
        style: TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'processing':
        return Colors.blue;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

// Extension for string capitalization
extension StringExtension on String {
  String capitalize() {
    return isNotEmpty 
        ? '${this[0].toUpperCase()}${substring(1)}'
        : '';
  }
}