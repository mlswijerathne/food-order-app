import 'package:flutter/material.dart';
import 'package:foodapp/services/admin_orders_service.dart';
import 'package:foodapp/screens/admin/admin_order_screen.dart';
import 'package:foodapp/screens/admin/admin_order_details_screen.dart';
import 'package:foodapp/models/order_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminOrderDashboard extends StatefulWidget {
  const AdminOrderDashboard({super.key});

  @override
  _AdminOrderDashboardState createState() => _AdminOrderDashboardState();
}

class _AdminOrderDashboardState extends State<AdminOrderDashboard> {
  final AdminOrderService _adminOrderService = AdminOrderService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  Map<String, dynamic> _statistics = {
    'totalOrders': 0,
    'totalRevenue': 0.0,
    'statusCounts': {
      'pending': 0,
      'processing': 0,
      'delivered': 0,
      'cancelled': 0,
    },
  };
  
  List<OrderModel> _recentOrders = [];
  bool _isLoading = true;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    _setupRealTimeDashboard();
  }

  void _setupRealTimeDashboard() {
    // Load initial data
    _loadDashboardData();
    
    // Setup real-time listener for orders collection
    _firestore
        .collection('orders')
        .snapshots()
        .listen((snapshot) {
      _loadDashboardData();
    });
  }
  
  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // Fetch statistics
      Map<String, dynamic> stats = await _adminOrderService.getOrderStatistics();
      
      // Fetch recent orders (latest 5)
      List<OrderModel> allOrders = await _adminOrderService.getAllOrders();
      List<OrderModel> recentOrders = allOrders.take(5).toList();
      
      setState(() {
        _statistics = stats;
        _recentOrders = recentOrders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load dashboard data: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadDashboardData,
            tooltip: 'Refresh Dashboard',
          ),
        ],
        
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : RefreshIndicator(
                  onRefresh: _loadDashboardData,
                  child: SingleChildScrollView(
                    physics: AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildStatisticsCards(),
                          SizedBox(height: 24),
                          _buildStatusBreakdown(),
                          SizedBox(height: 24),
                          _buildRecentOrdersSection(),
                          SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: Icon(Icons.list_alt),
                              label: Text('View All Orders'),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AdminOrderScreen(),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }

  Widget _buildStatisticsCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Orders',
            _statistics['totalOrders'].toString(),
            Icons.receipt_long,
            Colors.blue,
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Total Revenue',
            '\$${_statistics['totalRevenue'].toStringAsFixed(2)}',
            Icons.attach_money,
            Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatusBreakdown() {
    Map<String, int> statusCounts = _statistics['statusCounts'];
    int totalOrders = _statistics['totalOrders'];
    
    // Define status colors to match those in the order detail screen
    Map<String, Color> statusColors = {
      'pending': Colors.orange,
      'processing': Colors.blue,
      'delivered': Colors.green,
      'cancelled': Colors.red,
    };
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Order Status Breakdown',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16),
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: statusCounts.entries.map((entry) {
                String status = entry.key;
                int count = entry.value;
                double percentage = totalOrders > 0 
                    ? (count / totalOrders) * 100 
                    : 0;
                
                return Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _capitalizeStatus(status),
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '$count (${percentage.toStringAsFixed(1)}%)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: percentage / 100,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          statusColors[status] ?? Colors.grey,
                        ),
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildRecentOrdersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Orders',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16),
        _recentOrders.isEmpty
            ? Card(
                elevation: 2,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: Text(
                      'No recent orders',
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ),
              )
            : Column(
                children: _recentOrders.map((order) => _buildOrderCard(order)).toList(),
              ),
      ],
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          // Correctly pass the order ID to the AdminOrderDetailScreen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AdminOrderDetailScreen(orderId: order.id),
            ),
          ).then((_) => _loadDashboardData()); // Refresh after returning
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Order #${order.id.substring(0, 8)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(order.status),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      order.status.toUpperCase(),
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                      SizedBox(width: 4),
                      Text(
                        DateFormat('MMM dd, yyyy • hh:mm a').format(order.orderDate),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '\$${order.totalAmount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.shopping_bag, size: 16, color: Colors.grey[600]),
                  SizedBox(width: 4),
                  Text(
                    '${order.items.length} ${order.items.length == 1 ? 'item' : 'items'}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  Spacer(),
                  TextButton(
                    onPressed: () {
                      // Correctly pass the order ID to the AdminOrderDetailScreen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AdminOrderDetailScreen(orderId: order.id),
                        ),
                      ).then((_) => _loadDashboardData());
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    ),
                    child: Text('View Details'),
                  ),
                ],
              ),
            ],
          ),
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
  
  String _capitalizeStatus(String status) {
    if (status.isEmpty) return '';
    return status[0].toUpperCase() + status.substring(1);
  }
}