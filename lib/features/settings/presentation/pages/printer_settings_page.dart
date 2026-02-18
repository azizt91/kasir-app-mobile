import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter/material.dart';
import 'package:mobile_app/core/theme/app_colors.dart';
import '../../../../core/services/printer_service.dart';
import '../../../../injection_container.dart';

class PrinterSettingsPage extends StatefulWidget {
  const PrinterSettingsPage({super.key});

  @override
  State<PrinterSettingsPage> createState() => _PrinterSettingsPageState();
}

class _PrinterSettingsPageState extends State<PrinterSettingsPage> {
  final PrinterService _printerService = sl<PrinterService>();
  List<BluetoothDevice> _devices = [];
  BluetoothDevice? _selectedDevice;
  bool _isConnected = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initPrinter();
  }

  Future<void> _initPrinter() async {
    setState(() => _isLoading = true);
    try {
      _devices = await _printerService.getBondedDevices();
      bool? isConnected = await _printerService.isConnected;
      _isConnected = isConnected;
    } catch (e) {
      debugPrint("Error initializing printer: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _connect(BluetoothDevice device) async {
    setState(() => _isLoading = true);
    try {
      bool success = await _printerService.connect(device);
      setState(() {
        _isConnected = success;
        _selectedDevice = success ? device : null;
      });

      if (success) {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Terhubung ke ${device.name}', style: const TextStyle(color: Colors.white)), backgroundColor: AppColors.success),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal menghubungkan printer'), backgroundColor: AppColors.error),
          );
        }
      }
    } catch (e) {
       debugPrint("Connection error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _disconnect() async {
    setState(() => _isLoading = true);
    try {
      await _printerService.disconnect();
      setState(() {
        _isConnected = false;
        _selectedDevice = null;
      });
    } catch (e) {
      debugPrint("Disconnect error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  Future<void> _testPrint() async {
     if (!_isConnected) return;
     
     try {
        final service = sl<PrinterService>();
        final bluetooth = service.bluetooth;
        
        await bluetooth.printCustom("TEST PRINT SUCCESS", 1, 1);
        await bluetooth.printNewLine();
        await bluetooth.printCustom("Terima Kasih", 0, 1);
        await bluetooth.printNewLine();
        await bluetooth.printNewLine();
     } catch (e) {
       debugPrint("Test print error: $e");
       ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal mencetak test print'), backgroundColor: AppColors.error),
       );
     }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Pengaturan Printer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.textDark)),
        backgroundColor: AppColors.surfaceLight,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading && _devices.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Status Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Status Printer',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _isConnected 
                                    ? AppColors.success.withOpacity(0.1) 
                                    : AppColors.error.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: _isConnected ? AppColors.success : AppColors.error,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _isConnected ? 'Terhubung' : 'Belum Terhubung',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: _isConnected ? AppColors.success : AppColors.error,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _isConnected ? Icons.print : Icons.print_disabled,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Search Button
                  ElevatedButton.icon(
                    onPressed: _initPrinter,
                    icon: _isLoading 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                        : const Icon(Icons.bluetooth_searching, size: 24),
                    label: Text(_isLoading ? 'Memindai...' : 'Cari Printer Bluetooth'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                      shadowColor: AppColors.primary.withOpacity(0.4),
                    ),
                  ),

                  if (_isConnected) ...[
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _testPrint,
                      icon: const Icon(Icons.receipt_long),
                      label: const Text('Test Print'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Device List
                  Text(
                    'DAFTAR PRINTER TERSEDIA',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade500,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  if (_devices.isEmpty)
                     Container(
                        padding: const EdgeInsets.all(20),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Text(
                          'Tidak ada perangkat Bluetooth ditemukan.\nPastikan printer menyala dan sudah dipasangkan (paired) di pengaturan Bluetooth HP Anda.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                     )
                  else
                    ..._devices.map((device) => _buildDeviceItem(device)).toList(),

                  const SizedBox(height: 48),
                  
                  // Instructions
                  Opacity(
                    opacity: 0.6,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.settings_bluetooth, size: 40, color: AppColors.primary),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Pastikan printer Bluetooth Anda dalam mode pairing dan sudah terdaftar di pengaturan Bluetooth HP.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildDeviceItem(BluetoothDevice device) {
    bool isDeviceConnected = _isConnected && _selectedDevice?.address == device.address;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.print, color: Colors.grey),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device.name ?? 'Unknown Device',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  device.address ?? '-',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ),
          if (isDeviceConnected)
             Container(
               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
               decoration: BoxDecoration(
                 color: AppColors.success.withOpacity(0.1),
                 borderRadius: BorderRadius.circular(8),
               ),
               child: const Text('Tersambung', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 12)),
             )
          else
            ElevatedButton(
              onPressed: () => _connect(device),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary.withOpacity(0.1),
                foregroundColor: AppColors.primary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              ),
              child: const Text('Hubungkan'),
            ),
        ],
      ),
    );
  }
}
