// import 'package:flutter/material.dart';
// import 'package:flutter/foundation.dart' show kIsWeb;
// import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';
// import 'dart:js' as js;

// class PriceListPage extends StatefulWidget {
//   const PriceListPage({super.key});

//   @override
//   State<PriceListPage> createState() => _PriceListPageState();
// }

// class _PriceListPageState extends State<PriceListPage> {
//   late final SupabaseClient supabase;
//   List<Map<String, dynamic>> priceItems = [];
//   bool isLoading = true;

//   @override
//   void initState() {
//     super.initState();
    
//     String? supabaseUrl;
//     String? supabaseAnonKey;
    
//     // Check if running on web platform
//     if (kIsWeb) {
//       // Access environment variables from window.env
//       final context = js.context;
//       if (context.hasProperty('env')) {
//         final env = context['env'];
//         supabaseUrl = env['SUPABASE_URL'] as String?;
//         supabaseAnonKey = env['SUPABASE_ANON_KEY'] as String?;
//       }
//     } else {
//       // Use dotenv for mobile platforms
//       supabaseUrl = dotenv.env['SUPABASE_URL'];
//       supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];
//     }
    
//     if (supabaseUrl == null || supabaseAnonKey == null) {
//       print('Error: Missing Supabase credentials');
//       setState(() {
//         isLoading = false;
//       });
//       return;
//     }
    
//     supabase = SupabaseClient(supabaseUrl, supabaseAnonKey);
//     fetchPriceData();
//   }

//   Future<void> fetchPriceData() async {
//     try {
//       if (!mounted) return;
//       final response = await supabase
//           .from('products')
//           .select('*')
//           .order('created_at', ascending: false);
      
//       setState(() {
//         priceItems = List<Map<String, dynamic>>.from(response);
//         isLoading = false;
//       });
//     } catch (error) {
//       setState(() {
//         isLoading = false;
//       });
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error fetching data: $error')),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Price Tracker'),
//         backgroundColor: Colors.blue[50],
//         foregroundColor: const Color.fromARGB(255, 0, 0, 0),
//         titleTextStyle: TextStyle(
//           fontSize: 25,
//           fontWeight: FontWeight.w500,
//           color: Colors.black,
//           fontFamily: 'Poppins',
//         ),
//         elevation: 0,
//       ),
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [Colors.blue[50]!, Colors.white],
//           ),
//         ),
//         child: isLoading
//             ? const Center(child: CircularProgressIndicator())
//             : priceItems.isEmpty
//                 ? Center(
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Icon(Icons.shopping_cart_outlined, 
//                              size: 64, color: Colors.grey[400]),
//                         const SizedBox(height: 16),
//                         Text(
//                           'No price data found',
//                           style: TextStyle(
//                             fontSize: 18,
//                             color: Colors.grey[600],
//                           ),
//                         ),
//                       ],
//                     ),
//                   )
//                 : RefreshIndicator(
//                     onRefresh: fetchPriceData,
//                     child: ListView.builder(
//                       padding: const EdgeInsets.all(16),
//                       itemCount: priceItems.length,
//                       itemBuilder: (context, index) {
//                         final item = priceItems[index];
//                         return PriceItemCard(item: item);
//                       },
//                     ),
//                   ),
//       ),
//     );
//   }
// }

// class PriceItemCard extends StatelessWidget {
//   final Map<String, dynamic> item;

//   const PriceItemCard({Key? key, required this.item}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.1),
//             blurRadius: 8,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               // Move the price box a little more to the left by reducing spacing
//               mainAxisAlignment: MainAxisAlignment.start,
//               children: [
//                 Expanded(
//                   child: Text(
//                     item['product'] ?? 'Unknown Product',
//                     style: TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.blue[800],
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 Container(
//                   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                   decoration: BoxDecoration(
//                     color: Colors.green[100],
//                     borderRadius: BorderRadius.circular(20),
//                   ),
//                   child: Text(
//                     'Rs ${_formatPrice(item['price'])}',
//                     style: TextStyle(
//                       fontSize: 16,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.green[800],
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 12),
//             Row(
//               children: [
//                 Icon(Icons.inventory_2_outlined, 
//                      size: 20, color: Colors.grey[600]),
//                 const SizedBox(width: 8),
//                 Text(
//                   'Size: ${item['size'] ?? 'N/A'}',
//                   style: TextStyle(
//                     fontSize: 16,
//                     color: Colors.grey[700],
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 8),
//             Row(
//               children: [
//                 Icon(Icons.storefront_outlined,
//                      size: 20, color: Colors.grey[600]),
//                 const SizedBox(width: 8),
//                 Text(
//                   'Store: ${item['store'] ?? 'N/A'}',
//                   style: TextStyle(
//                     fontSize: 16,
//                     color: Colors.grey[700],
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 8),
//             Row(
//               children: [
//                 Icon(Icons.calendar_today_outlined, 
//                      size: 20, color: Colors.grey[600]),
//                 const SizedBox(width: 8),
//                 Text(
//                   'Added: ${_formatDate(item['created_at'])}',
//                   style: TextStyle(
//                     fontSize: 14,
//                     color: Colors.grey[600],
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   String _formatDate(dynamic dateString) {
//     if (dateString == null) return 'Unknown';
//     try {
//       final date = DateTime.parse(dateString.toString());
//       return '${date.day}/${date.month}/${date.year}';
//     } catch (e) {
//       return 'Unknown';
//     }
//   }

//   String _formatPrice(dynamic price) {
//     if (price == null) return '0.00';
//     try {
//       final num parsed = price is num ? price : num.parse(price.toString());
//       return parsed.toStringAsFixed(2);
//     } catch (_) {
//       return price.toString();
//     }
//   }
// }