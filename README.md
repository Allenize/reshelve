# 📱 ReStore POS – Flutter Edition

A fully converted Flutter mobile app from your original `index.html`.  
Dark theme, smooth animations, camera, barcode scanning, PDF receipts.

---

## 🗂 Project Structure

```
lib/
├── main.dart                  ← App entry + bottom nav shell
├── theme.dart                 ← Colors, ThemeData, constants
│
├── models/
│   ├── product.dart
│   ├── sale.dart
│   ├── debt.dart
│   └── cart_item.dart
│
├── services/
│   ├── app_store.dart         ← ChangeNotifier state (cart, products, sales, debts)
│   └── database_service.dart  ← SharedPreferences persistence
│
├── screens/
│   ├── home_screen.dart       ← Dashboard, stats, quick actions
│   ├── inventory_screen.dart  ← Product list with search + category filter
│   ├── sales_screen.dart      ← POS cart + checkout
│   ├── scan_screen.dart       ← Barcode camera + manual entry
│   ├── more_screen.dart       ← Analytics, debts, settings
│   └── receipt_screen.dart    ← Receipt view + PDF print
│
└── widgets/
    ├── shared_widgets.dart         ← StatCard, GradientButton, CategoryChip, etc.
    ├── product_card.dart           ← Product list tile
    ├── app_sheet.dart              ← Bottom sheet wrapper
    ├── toast.dart                  ← Snackbar helper
    ├── add_edit_product_sheet.dart ← Add / Edit product form
    ├── add_debt_sheet.dart         ← Record utang form
    └── product_detail_sheet.dart   ← Product detail with stats
```

---

## 🚀 Setup

### 1. Install Flutter
```bash
flutter --version  # needs 3.0+
```
Install from: https://docs.flutter.dev/get-started/install

### 2. Get dependencies
```bash
cd restore_flutter
flutter pub get
```

### 3. Run on Android
```bash
flutter run
```

### 4. Run on iOS (Mac only)
```bash
cd ios && pod install && cd ..
flutter run
```

---

## 📦 Dependencies

| Package | Use |
|---|---|
| `provider` | State management |
| `shared_preferences` | Local data storage |
| `pdf` + `printing` | Receipt PDF generation |
| `image_picker` | Camera product photos |
| `mobile_scanner` | Barcode scanning |
| `uuid` | Unique IDs |
| `share_plus` | Export JSON backup |
| `path_provider` | File system paths |

---

## ✨ Features

### Core
- ✅ Sales / POS system with cart
- ✅ Inventory management
- ✅ Utang (debt) system

### Advanced
- 📷 Camera for product photos
- 📊 Barcode scanning (camera + manual)
- ✏️ Edit / delete products
- 🧾 PDF receipt generation & printing

### Premium UI
- 🌑 Dark theme matching original design
- 🎨 Gradient accent colors (`#00C896`)
- ⚡ Smooth animations
- 📱 Mobile-first, portrait-only

---

## 🔑 Permissions Required

**Android** (`AndroidManifest.xml`)
- `CAMERA` — for barcode scan + product photos

**iOS** (`Info.plist`)
- `NSCameraUsageDescription`
- `NSPhotoLibraryUsageDescription`

---

## 📲 Build for Release

### Android APK
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### Android App Bundle (Play Store)
```bash
flutter build appbundle --release
```

### iOS (requires Mac + Xcode)
```bash
flutter build ios --release
```

---

## 🔥 Firebase (Optional Upgrade)

To enable cloud sync and multi-device support, you can replace `SharedPreferences`  
with **Firebase Firestore** by modifying `database_service.dart`:

```
products/{id}   → name, price, stock, emoji, capital, lowAt, cat, sold
sales/{id}      → items[], total, isUtang, customerName, date
debts/{id}      → customerName, amount, items, paid, date
```

Install: `firebase_core`, `cloud_firestore` in `pubspec.yaml`.

---

## 💡 Tips

- Tap any product in Inventory to see full detail (price, capital, profit)
- In the Sales screen, tap the **+** button on a product to instantly add to cart
- Long-press or tap product to open detail → "Add to Cart"
- Utang checkout prompts for customer name and auto-creates a debt record
- Export from **More → Export Data** to share a JSON backup
