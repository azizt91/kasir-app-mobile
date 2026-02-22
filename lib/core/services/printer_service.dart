import 'dart:async';
import 'dart:io';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrinterService with WidgetsBindingObserver {
  // Instance from blue_thermal_printer
  final BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;

  static const String _prefPrinterMac = 'pref_printer_mac';
  static const String _prefPrinterName = 'pref_printer_name';

  // Flag to prevent race conditions when connecting
  bool _isConnecting = false;

  PrinterService() {
    WidgetsBinding.instance.addObserver(this);
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      if (!kIsWeb && !Platform.isWindows) {
        // Trigger auto-reconnect when app comes to foreground
        ensureConnected();
      }
    }
  }

  Future<List<BluetoothDevice>> getBondedDevices() async {
    if (kIsWeb || Platform.isWindows) return [];
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

    if (_isConnecting) return false; // Prevent multiple simultaneous connection attempts

    try {
      _isConnecting = true;

      bool? isTurnedOn = await bluetooth.isOn;
      if (isTurnedOn != true) return false;

      // Connect with 7s timeout to prevent hanging
      bool success = false;
      try {
         success = await bluetooth.connect(device).timeout(const Duration(seconds: 7)) ?? false;
      } on TimeoutException {
         success = false;
      }

      if (success && device.address != null) {
        await _savePrinter(device.address!, device.name ?? 'Unknown');
      }

      return success;
    } on PlatformException catch (e) {
      debugPrint("Bluetooth connect platform error: $e");
      return false;
    } catch (e) {
      debugPrint("Bluetooth generic connect error: $e");
      return false;
    } finally {
      _isConnecting = false;
    }
  }

  Future<bool> disconnect() async {
    if (kIsWeb || Platform.isWindows) return true;
    try {
      bool? success = await bluetooth.disconnect();
      if (success == true) {
        await _clearSavedPrinter();
      }
      return success ?? false;
    } on PlatformException {
      return false;
    } catch (e) {
      debugPrint("Disconnect error $e");
      return false;
    }
  }

  Future<bool> get isConnected async {
     if (kIsWeb || Platform.isWindows) return false;
     try {
       return await bluetooth.isConnected ?? false;
     } catch (_) {
       return false;
     }
  }

  Future<bool> autoReconnect() async {
    if (kIsWeb || Platform.isWindows) return false;
    if (_isConnecting) return false; // Prevent race conditions

    try {
      _isConnecting = true;

      // 1. Check if Bluetooth is ON
      bool? isTurnedOn = await bluetooth.isOn;
      if (isTurnedOn != true) return false;

      // 2. Check if already connected
      bool? alreadyConnected = await bluetooth.isConnected;
      if (alreadyConnected == true) return true;

      // 3. Get saved MAC address
      final prefs = await SharedPreferences.getInstance();
      final mac = prefs.getString(_prefPrinterMac);
      final name = prefs.getString(_prefPrinterName);

      if (mac == null || mac.isEmpty) return false; // No saved printer

      BluetoothDevice device = BluetoothDevice(name, mac);

      // 4. Try connecting with Timeout
      bool success = false;
      try {
         success = await bluetooth.connect(device).timeout(const Duration(seconds: 7)) ?? false;
      } on TimeoutException {
         debugPrint("Auto-reconnect timeout");
         success = false;
      }

      return success;
    } catch (e) {
      debugPrint("Auto-reconnect error: $e");
      return false;
    } finally {
      _isConnecting = false;
    }
  }

  Future<bool> ensureConnected() async {
    if (kIsWeb || Platform.isWindows) return true; // Mock for unsupported platforms

    // Check current state
    bool connected = await isConnected;
    if (connected) return true;

    // Attempt auto-reconnect if not connected
    return await autoReconnect();
  }

  Future<void> printReceipt(List<int> bytes) async {
     if (kIsWeb || Platform.isWindows) {
       debugPrint("MOCK PRINT: ${bytes.length} bytes.");
       return;
     }

     if (await ensureConnected()) {
        await bluetooth.writeBytes(Uint8List.fromList(bytes));
     } else {
        throw Exception("Printer belum terhubung. Pastikan bluetooth aktif dan printer menyala.");
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

    return true;
  }

  Future<void> _savePrinter(String macAddress, String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefPrinterMac, macAddress);
    await prefs.setString(_prefPrinterName, name);
  }

  Future<void> _clearSavedPrinter() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefPrinterMac);
    await prefs.remove(_prefPrinterName);
  }

  Future<Map<String, String>?> getSavedPrinter() async {
    final prefs = await SharedPreferences.getInstance();
    final mac = prefs.getString(_prefPrinterMac);
    final name = prefs.getString(_prefPrinterName);
    if (mac != null && mac.isNotEmpty) {
      return {'mac': mac, 'name': name ?? 'Unknown'};
    }
    return null;
  }
}
