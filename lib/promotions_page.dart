import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class PromotionsPage extends StatefulWidget {
  const PromotionsPage({super.key});

  @override
  State<PromotionsPage> createState() => _PromotionsPageState();
}

class _PromotionsPageState extends State<PromotionsPage> {
  late final SupabaseClient supabase;
  List<Map<String, dynamic>> promotionItems = [];
  bool isLoading = true;
  String selectedCategory = 'All';
  List<String> categories = ['All'];

  @override
  void initState() {
    super.initState();
    
    final supabaseUrl = dotenv.env['SUPABASE_URL'];
    final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];
    
    if (supabaseUrl == null || supabaseAnonKey == null) {
      print('Error: Missing SUPABASE_URL or SUPABASE_ANON_KEY in .env file');
      setState(() {
        isLoading = false;
      });
      return;
    }
    
    supabase = SupabaseClient(supabaseUrl, supabaseAnonKey);
    fetchPromotionData();
  }

  Future<void> fetchPromotionData() async {
    try {
      if (!mounted) return;
      final response = await supabase
          .from('winners_promotions')
          .select('*')
          .order('timestamp', ascending: false);
      
      setState(() {
        promotionItems = List<Map<String, dynamic>>.from(response);
        isLoading = false;
        
        // Extract unique categories
        Set<String> categorySet = {'All'};
        for (var item in promotionItems) {
          if (item['category'] != null) {
            categorySet.add(item['category'].toString());
          }
        }
        categories = categorySet.toList();
      });
    } catch (error) {
      print('Error fetching promotions: $error');  // Debug log
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching promotions. Please check your connection and try again.'),
          duration: Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Retry',
            onPressed: () {
              fetchPromotionData();
            },
          ),
        ),
      );
    }
  }

  List<Map<String, dynamic>> get filteredPromotions {
    if (selectedCategory == 'All') {
      return promotionItems;
    }
    return promotionItems.where((item) => 
        item['category']?.toString() == selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Promotions'),
        backgroundColor: Colors.blue[50],
        foregroundColor: const Color.fromARGB(255, 0, 0, 0),
        titleTextStyle: TextStyle(
          fontSize: 25,
          fontWeight: FontWeight.w500,
          color: Colors.black,
          fontFamily: 'Poppins',
        ),
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
        child: Column(
          children: [
            // Category filter
            Container(
              height: 60,
              padding: EdgeInsets.symmetric(vertical: 8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 16),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final isSelected = selectedCategory == category;
                  return Container(
                    margin: EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(category),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          selectedCategory = category;
                        });
                      },
                      backgroundColor: Colors.white,
                      selectedColor: Colors.blue[100],
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.blue[800] : Colors.grey[700],
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  );
                },
              ),
            ),
            
            // Promotions list
            Expanded(
              child: isLoading
                  ? Center(child: CircularProgressIndicator())
                  : filteredPromotions.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.local_offer_outlined, 
                                   size: 64, color: Colors.grey[400]),
                              SizedBox(height: 16),
                              Text(
                                'No promotions found',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: fetchPromotionData,
                          child: ListView.builder(
                            padding: EdgeInsets.all(16),
                            itemCount: filteredPromotions.length,
                            itemBuilder: (context, index) {
                              final item = filteredPromotions[index];
                              return PromotionItemCard(item: item);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class PromotionItemCard extends StatelessWidget {
  final Map<String, dynamic> item;

  const PromotionItemCard({Key? key, required this.item}) : super(key: key);

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
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    item['product_name'] ?? 'Unknown Product',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'PROMO',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.red[800],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Price section
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Rs ${_formatPrice(item['new_price'])}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[800],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                if (item['previous_price'] != null)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Rs ${_formatPrice(item['previous_price'])}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.inventory_2_outlined, 
                     size: 20, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  'Size: ${item['size'] ?? 'N/A'}',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.storefront_outlined,
                     size: 20, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  'Store: ${item['store'] ?? 'N/A'}',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
            if (item['category'] != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.category_outlined,
                       size: 20, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    'Category: ${item['category']}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
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