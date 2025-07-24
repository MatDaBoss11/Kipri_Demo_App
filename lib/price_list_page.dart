// ignore_for_file: use_key_in_widget_constructors, library_private_types_in_public_api, use_build_context_synchronously, use_super_parameters, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PriceListPage extends StatefulWidget {
  @override
  _PriceListPageState createState() => _PriceListPageState();
}

class _PriceListPageState extends State<PriceListPage> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> priceItems = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchPriceData();
  }

  Future<void> fetchPriceData() async {
    try {
      final response = await supabase
          // Query the correct table and ensure we get a strongly-typed response
          .from('products')
          .select('*')
          .order('created_at', ascending: false);
      
      setState(() {
        priceItems = List<Map<String, dynamic>>.from(response);
        isLoading = false;
      });
    } catch (error) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching data: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Price Tracker'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue[50]!, Colors.white],
          ),
        ),
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : priceItems.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_cart_outlined, 
                             size: 64, color: Colors.grey[400]),
                        SizedBox(height: 16),
                        Text(
                          'No price data found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: fetchPriceData,
                    child: ListView.builder(
                      padding: EdgeInsets.all(16),
                      itemCount: priceItems.length,
                      itemBuilder: (context, index) {
                        final item = priceItems[index];
                        return PriceItemCard(item: item);
                      },
                    ),
                  ),
      ),
    );
  }
}

class PriceItemCard extends StatelessWidget {
  final Map<String, dynamic> item;

  const PriceItemCard({Key? key, required this.item}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    item['product'] ?? 'Unknown Product',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '\$${_formatPrice(item['price'])}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[800],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.inventory_2_outlined, 
                     size: 20, color: Colors.grey[600]),
                SizedBox(width: 8),
                Text(
                  'Size: ${item['size'] ?? 'N/A'}',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.storefront_outlined,
                     size: 20, color: Colors.grey[600]),
                SizedBox(width: 8),
                Text(
                  'Store: ${item['store'] ?? 'N/A'}',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today_outlined, 
                     size: 20, color: Colors.grey[600]),
                SizedBox(width: 8),
                Text(
                  'Added: ${_formatDate(item['created_at'])}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(dynamic dateString) {
    if (dateString == null) return 'Unknown';
    try {
      final date = DateTime.parse(dateString.toString());
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Unknown';
    }
  }

  String _formatPrice(dynamic price) {
    if (price == null) return '0.00';
    try {
      final num parsed = price is num ? price : num.parse(price.toString());
      return parsed.toStringAsFixed(2);
    } catch (_) {
      return price.toString();
    }
  }
}