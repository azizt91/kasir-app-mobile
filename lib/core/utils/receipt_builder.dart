import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

class ReceiptBuilder {
  final BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;

  // Since we are using blue_thermal_printer, it has its own methods for text, but writing raw bytes gives more control.
  // However, the library is simpler with its methods. Let's use its methods mixed with bytes if needed.
  // Actually, constructing a list of bytes manually is often better for consistency across libraries, 
  // but blue_thermal_printer takes methods like printCustom.
  
  // Let's use the high level methods provided by the library for simplicity and speed.
  // Method expected by HistoryDetailPage
  Future<List<int>> buildReceipt(
      Map<String, dynamic> transaction, 
      Map<String, dynamic> settings,
      List<dynamic> items
  ) async {
    // This method was expected to return bytes for another printer package, 
    // but we are using BlueThermalPrinter which prints directly.
    // For now, we reuse printReceipt logic or just print directly.
    // To satisfy the compilation, we return empty bytes, but we should call printReceipt inside.
    
    await printReceipt(transaction, settings, items);
    return [];
  }

  Future<void> printReceipt(
      Map<String, dynamic> transaction, 
      Map<String, dynamic> settings,
      List<dynamic> items
  ) async {
    // Check connection first
    bool? isConnected = await bluetooth.isConnected;
    if (isConnected != true) {
      throw Exception("Printer belum terhubung. Silakan hubungkan printer di menu Pengaturan > Printer.");
    }

    try {
      // Styling
      // 0: Left, 1: Center, 2: Right
      // 0: Normal, 1: Bold, 2: Medium, 3: Large
      
      // Header
      await bluetooth.printCustom(settings['store_name'] ?? 'Minimarket POS', 3, 1);
      await bluetooth.printCustom(settings['store_address'] ?? '-', 0, 1);
      await bluetooth.printCustom(settings['store_phone'] ?? '-', 0, 1);
      await bluetooth.printNewLine();

      // Info
      final dateFormat = DateFormat('dd-MM-yyyy HH:mm');
      final String date = transaction['created_at'] != null 
          ? dateFormat.format(DateTime.parse(transaction['created_at']).toLocal()) 
          : dateFormat.format(DateTime.now());
          
      await bluetooth.printLeftRight("Tgl: $date", "", 0);
      await bluetooth.printLeftRight("No: ${transaction['transaction_code'] ?? '-'}", "", 0);
      await bluetooth.printLeftRight("Kasir: ${transaction['user_name'] ?? 'Admin'}", "", 0); // Need to pass user name
      await bluetooth.printLeftRight("Pelanggan: ${transaction['customer_name'] ?? 'Umum'}", "", 0);
      await bluetooth.printCustom("--------------------------------", 1, 1);

      // Body
      final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

      for (var item in items) {
         final name = item['product_name'] ?? (item['product']?['name'] ?? 'Unknown Product');
         await bluetooth.printCustom(name, 1, 0); // Item Name Left
         // Qty x Price ... Subtotal
         final qty = item['quantity'];
         final price = currencyFormatter.format(item['price']);
         final subtotal = currencyFormatter.format(item['subtotal'] ?? (item['price'] * qty));
         
         await bluetooth.printLeftRight("$qty x $price", subtotal, 0);
      }
      
      await bluetooth.printCustom("--------------------------------", 1, 1);

      // Summary
      await bluetooth.printLeftRight("Total :", currencyFormatter.format(transaction['total_amount']), 1);
      
      // Payment
      String paymentMethod = transaction['payment_method'] ?? 'cash';
      await bluetooth.printLeftRight("Bayar ($paymentMethod):", currencyFormatter.format(transaction['amount_paid']), 0);
      
      if (paymentMethod == 'utang') {
         await bluetooth.printCustom("** BELUM LUNAS - PIUTANG **", 3, 1);
      } else {
         await bluetooth.printLeftRight("Kembali :", currencyFormatter.format(transaction['change_amount'] ?? 0), 0);
      }

      await bluetooth.printNewLine();
      await bluetooth.printCustom("Terima Kasih", 1, 1);
      await bluetooth.printCustom("Barang yang sudah dibeli", 0, 1);
      await bluetooth.printCustom("tidak dapat ditukar/dikembalikan", 0, 1);
      await bluetooth.printNewLine();
      await bluetooth.printNewLine();
    } catch (e) {
      if (e is PlatformException && e.code == 'write_error') {
         throw Exception("Gagal mengirim data ke printer. Pastikan printer menyala dan terhubung.");
      }
      rethrow;
    }
  }
}
