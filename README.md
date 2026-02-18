# Kasir App Mobile

Aplikasi mobile client untuk Kasir App (POS), dibangun menggunakan Flutter.

## Fitur
- Integrasi dengan Backend Laravel Kasir App
- Kasir POS (Point of Sales)
- Manajemen Transaksi & Riwayat
- Support Printer Bluetooth & USB (WebUSB via Webview/Custom)
- Scan Barcode
- Manajemen Stok & Produk

## Instalasi

1.  Pastikan Flutter SDK sudah terinstall.
2.  Clone repository ini via `git clone`.
3.  Jalankan `flutter pub get` untuk menginstall dependencies.
4.  Jalankan `flutter run` untuk debugging.

## Build APK

Untuk membuat file APK siap install (Release):

```bash
flutter build apk --release
```

Atau push ke branch `main`/`master` untuk otomatis build via GitHub Actions.
