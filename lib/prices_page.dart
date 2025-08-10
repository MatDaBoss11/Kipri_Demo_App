import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:js' as js;

class PricesPage extends StatefulWidget {
  const PricesPage({super.key});

  @override
  State<PricesPage> createState() => _PricesPageState();
}

class _PricesPageState extends State<PricesPage> {
  late final SupabaseClient supabase;
  List<Map<String, dynamic>> priceItems = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    
    String? supabaseUrl;
    String? supabaseAnonKey;
    
    if (kIsWeb) {
      final context = js.context;
      if (context.hasProperty('env')) {
        final env = context['env'];
        supabaseUrl = env['SUPABASE_URL'] as String?;
        supabaseAnonKey = env['SUPABASE_ANON_KEY'] as String?;
      }
    } else {
      supabaseUrl = dotenv.env['SUPABASE_URL'];
      supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];
    }
    
    if (supabaseUrl == null || supabaseAnonKey == null) {
      print('Error: Missing Supabase credentials');
      setState(() {
        isLoading = false;
      });
      return;
    }
    
    supabase = SupabaseClient(supabaseUrl, supabaseAnonKey);
    fetchPriceData();
  }

  Future<void> fetchPriceData() async {
    try {
      if (!mounted) return;
      final response = await supabase
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching data: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prices'),
        backgroundColor: const Color(0xFF3B4CCA),
        foregroundColor: Colors.white,
        elevation: 0,
        titleTextStyle: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF3B4CCA), Color(0xFF5A67D8)],
          ),
        ),
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : priceItems.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_cart_outlined, 
                             size: 64, color: Colors.white.withOpacity(0.7)),
                        const SizedBox(height: 16),
                        Text(
                          'No price data found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: fetchPriceData,
                    child: GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.75,
                      ),
                      itemCount: priceItems.length,
                      itemBuilder: (context, index) {
                        final item = priceItems[index];
                        return PokemonPriceCard(item: item);
                      },
                    ),
                  ),
      ),
    );
  }
}

class PokemonPriceCard extends StatelessWidget {
  final Map<String, dynamic> item;

  const PokemonPriceCard({Key? key, required this.item}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF9C4), Color(0xFFFFE082)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFFFD54F),
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.5),
            blurRadius: 4,
            offset: const Offset(-2, -2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF3B4CCA),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                item['product'] ?? 'Unknown Product',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            
            const SizedBox(height: 12),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: const Color(0xFF388E3C), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    'Rs ${_formatPrice(item['price'])}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            
            const Spacer(),
            
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE0E0E0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.storefront, 
                           size: 16, color: Colors.grey[700]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          item['store'] ?? 'N/A',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.straighten, 
                           size: 16, color: Colors.grey[700]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          item['size'] ?? 'N/A',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                          overflow: TextOverflow.ellipsis,
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