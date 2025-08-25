# Technical Assets Management Mobile App

A Flutter mobile application for managing technical assets, inventory, and borrowing/returning items.

## Features

### 🔐 Authentication
- Login page with username/password
- Registration page for admin accounts
- Secure authentication flow

### 📊 Dashboard
- Overview of total inventory counts
- Category-based inventory summary
- Quick access to item lists by category
- Navigation drawer for easy app navigation

### 📋 Inventory Management
- **Item Table**: Complete item details including:
  - ID (Primary Key)
  - Serial Number
  - Item Name
  - Item Image
  - Item Category
  - Condition
  - Created/Updated timestamps

- **Item List Table**: List view with essential fields:
  - Item Image
  - Serial Number
  - Item Name
  - Category
  - Condition

- **Inventory List Table**: Category-based summaries:
  - Category
  - Total Item Count
  - Total Borrowed Count
  - Available Count (calculated)

### 🎯 Core Screens

1. **Login Screen** - User authentication
2. **Registration Screen** - Admin account creation
3. **Dashboard Screen** - Inventory overview and navigation
4. **Item List Screen** - Category-specific item listings
5. **Item Detail Screen** - Complete item information and actions

### 🎨 UI/UX Features

- Modern Material Design 3
- Consistent color scheme (Primary: #338AFF)
- Responsive card-based layouts
- Interactive elements with proper feedback
- Search and filter capabilities
- Status indicators with color coding

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
│   ├── item.dart            # Complete item model
│   ├── item_list.dart       # List view item model
│   └── inventory_list.dart  # Category summary model
├── screens/                  # App screens
│   ├── dashboard_screen.dart    # Main dashboard
│   ├── item_list_screen.dart    # Category item list
│   └── item_detail_screen.dart  # Item details
└── widgets/                  # Reusable widgets
    └── app_drawer.dart       # Navigation drawer
```

## Data Models

### Item Model
Complete item representation with all database fields:
- Primary key and metadata
- Serial number and naming
- Category and condition tracking
- Timestamp management

### ItemList Model
Optimized for list views with essential display fields:
- Image and identification
- Name and category
- Condition status

### InventoryList Model
Category-level aggregation for dashboard display:
- Total counts per category
- Borrowed vs. available items
- Calculated availability

## Getting Started

1. Ensure Flutter is installed and configured
2. Clone the repository
3. Run `flutter pub get` to install dependencies
4. Connect a device or start an emulator
5. Run `flutter run` to launch the app

## Dependencies

- Flutter SDK
- Material Design components
- Standard Flutter packages

## Future Enhancements

- Database integration (SQLite, Firebase, etc.)
- User role management
- Barcode/QR code scanning
- Image capture and storage
- Push notifications
- Offline support
- Export/import functionality

## Contributing

This is a Flutter project following standard Flutter development practices. Contributions are welcome!

## License

This project is for educational and demonstration purposes.
