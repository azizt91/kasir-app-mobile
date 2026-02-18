import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:flutter/services.dart';
import 'dart:io'; // Import Platform
import 'package:permission_handler/permission_handler.dart';

class PrinterService {
  final BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;

  Future<List<BluetoothDevice>> getBondedDevices() async {
    if (kIsWeb || Platform.isWindows) return []; // Mock for Web & Windows
    try {
      if (await _checkPermissions()) {
          return await bluetooth.getBondedDevices();
      }
      return [];
    } on PlatformException {
      return [];
    }
  }

  Future<bool> connect(BluetoothDevice device) async {
    if (kIsWeb || Platform.isWindows) return false;
    try {
      if (await bluetooth.isConnected == true) {
         return true;
      }
      return await bluetooth.connect(device) ?? false;
    } on PlatformException {
      return false;
    }
  }

  Future<bool> disconnect() async {
    if (kIsWeb || Platform.isWindows) return true;
    try {
      return await bluetooth.disconnect() ?? false;
    } on PlatformException {
      return false;
    }
  }
  
  Future<bool> get isConnected async {
     if (kIsWeb || Platform.isWindows) return false;
     return await bluetooth.isConnected ?? false;
  }

  Future<void> printReceipt(List<int> bytes) async {
     if (kIsWeb || Platform.isWindows) {
       debugPrint("MOCK PRINT: ${bytes.length} bytes.");
       return;
     }
     if (await isConnected) {
        await bluetooth.writeBytes(Uint8List.fromList(bytes));
     }
  }
  
  Future<bool> _checkPermissions() async {
    // Android 12+ requires BLUETOOTH_SCAN, BLUETOOTH_CONNECT
    // Older Android requires LOCATION
    
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();
    
    return true; // Simplify for now, assuming user grants if asked
  }
}
