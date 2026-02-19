import 'package:mobile_app/features/dashboard/data/datasources/dashboard_remote_data_source.dart';

class DashboardModel {
  final Map<String, dynamic> stats;
  final List<dynamic> salesChart;
  final List<dynamic> topProducts;
  final List<dynamic> lowStockItems;

  DashboardModel({
    required this.stats,
    required this.salesChart,
    required this.topProducts,
    this.lowStockItems = const [],
  });

  factory DashboardModel.fromJson(Map<String, dynamic> json) {
    return DashboardModel(
      stats: json['stats'] ?? {},
      salesChart: json['sales_chart'] ?? [],
      topProducts: json['top_products'] ?? [],
      lowStockItems: json['low_stock_items'] ?? [],
    );
  }
}
