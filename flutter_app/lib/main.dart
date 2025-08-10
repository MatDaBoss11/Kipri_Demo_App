import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'product.dart';

void main() {
  runApp(const GrocerySearchApp());
}

class GrocerySearchApp extends StatelessWidget {
  const GrocerySearchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Grocery Search',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.green),
      home: const SearchHomePage(),
    );
  }
}

class SearchHomePage extends StatefulWidget {
  const SearchHomePage({super.key});

  @override
  State<SearchHomePage> createState() => _SearchHomePageState();
}

class _SearchHomePageState extends State<SearchHomePage> {
  final TextEditingController _controller = TextEditingController();
  bool _loading = false;
  String? _error;
  List<Product> _results = [];

  // Update this to your backend URL
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000', // Android emulator localhost
  );

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
      _results = [];
    });

    try {
      final uri = Uri.parse('$apiBaseUrl/search');
      final resp = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'query': query, 'limit': 10}),
          )
          .timeout(const Duration(seconds: 10));

      if (resp.statusCode != 200) {
        setState(() {
          _error = 'Server error: ${resp.statusCode}';
        });
        return;
      }

      final List<dynamic> data = jsonDecode(resp.body) as List<dynamic>;
      final products = data.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
      setState(() {
        _results = products;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to search. Please try again.';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Grocery Search')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: 'Search products (any language)...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                textInputAction: TextInputAction.search,
                onSubmitted: _search,
              ),
            ),
            if (_loading) const LinearProgressIndicator(),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            Expanded(
              child: ListView.separated(
                itemCount: _results.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final p = _results[index];
                  return ListTile(
                    title: Text(p.name),
                    subtitle: Text('${p.storeName} • ${p.category ?? 'uncategorized'}'),
                    trailing: Text('\$${p.price.toStringAsFixed(2)}'),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: FilledButton.icon(
                onPressed: () => _search(_controller.text),
                icon: const Icon(Icons.search),
                label: const Text('Search'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}