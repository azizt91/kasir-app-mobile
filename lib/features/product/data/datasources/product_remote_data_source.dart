import 'package:dio/dio.dart';
import '../models/product_model.dart';
import '../models/category_model.dart';
import 'package:mobile_app/features/auth/data/datasources/auth_remote_data_source.dart';

abstract class ProductRemoteDataSource {
  Future<Map<String, dynamic>> syncProducts(String? lastSyncTime);
}

class ProductRemoteDataSourceImpl implements ProductRemoteDataSource {
  final Dio dio;

  ProductRemoteDataSourceImpl({required this.dio});

  @override
  Future<Map<String, dynamic>> syncProducts(String? lastSyncTime) async {
    try {
      final response = await dio.get(
        '/products/sync',
        queryParameters: lastSyncTime != null ? {'last_sync': lastSyncTime} : null,
        options: Options(
          headers: {'Accept': 'application/json'}, // Add Bearer token via Interceptor ideally
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        
        // Fix Image URLs
        if (data['products'] != null) {
           final userBaseUrl = dio.options.baseUrl.replaceAll('/api', ''); // e.g. http://localhost:8000
           final List<dynamic> products = data['products'];
           
           for (var product in products) {
              String? image = product['image'];
              String? imageUrl = product['image_url'];
              
              // Backend might send 'image' as filename "products/foo.jpg"
              // We need "http://host/storage/products/foo.jpg"
              
              if (imageUrl != null && imageUrl.startsWith('http')) {
                 // Good
              } else if (image != null && !image.startsWith('http')) {
                 // Construct full URL
                 // Assuming image stored in 'storage/' public disk
                 // If path already has 'storage/', don't add it.
                 // Ideally backend sends full URL.
                 
                 String path = image;
                 if (!path.startsWith('/')) path = '/$path';
                 
                 // If path doesn't start with /storage, add it?
                 // Laravel default: storage/app/public -> symlinked to public/storage
                 // DB stores: "products/foo.jpg"
                 // URL: "http://host/storage/products/foo.jpg"
                 
                 if (!path.contains('/storage')) {
                    path = '/storage$path';
                 }
                 
                 product['image_url'] = '$userBaseUrl$path';
                 print('DEBUG REMOTE: Fixed URL for ${product['name']} -> ${product['image_url']}');
              } else {
                 print('DEBUG REMOTE: keeping URL for ${product['name']} -> $imageUrl');
              }
           }
        }
        
        return data;
      } else {
        throw Exception('Failed to sync products');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}
