import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ProductsScreen extends StatelessWidget {
  const ProductsScreen({super.key});

  // 6.1 Chrome: localhost | Physical iPhone: LAN IP of the Mac running the API
  // Update the IP if the Mac changes networks (ipconfig getifaddr en0)
  static const String baseUrl = kIsWeb
      ? 'http://localhost:8090'
      : 'http://192.168.1.114:8090';

  // 6.2 Request the products and decode the JSON
  Future<List<dynamic>> fetchProducts() async {
    final response = await http.get(Uri.parse('$baseUrl/products'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    }
    throw Exception('Error al cargar productos de la API');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Productos de Spring Boot')),
      // 6.3 Draw each state of the request
      body: FutureBuilder<List<dynamic>>(
        future: fetchProducts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          // 6.4 Product list
          final products = snapshot.data ?? [];
          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return ListTile(
                title: Text(product['name'].toString()),
                subtitle: Text('Stock: ${product['stock']}'),
                trailing: Text('\$${product['price']}'),
              );
            },
          );
        },
      ),
    );
  }
}
