# Shelf Tracker

A Flutter application to track expiration dates of household items - food, groceries, medicine, and cosmetics.

## Features

- **Track Items**: Add and manage items with expiration dates
- **Categories**: Organize items by Food, Grocery, Medicine, and Cosmetics
- **Expiry Alerts**: Get notified before items expire
- **Analytics**: View usage patterns and waste reduction insights
- **Deals & Offers**: Discover relevant deals based on your inventory
- **Dark/Light Mode**: Professional themes for comfortable viewing
- **Phone & Tablet**: Responsive design for all screen sizes

## Getting Started

### Prerequisites

- Flutter SDK 3.0.0 or higher
- Dart SDK 3.0.0 or higher
- Android Studio / Xcode for native builds

### Installation

1. Clone the repository
2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the app:
   ```bash
   flutter run
   ```

### Building for Production

#### Android
```bash
flutter build apk --release
# or for app bundle
flutter build appbundle --release
```

#### iOS
```bash
flutter build ios --release
```

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── core/
│   ├── theme/               # App theming (colors, typography)
│   ├── constants/           # App constants
│   └── utils/               # Utility functions
├── features/
│   ├── splash/              # Splash screen
│   ├── home/                # Home/Dashboard
│   ├── profile/             # User profile & settings
│   ├── analytics/           # Analytics & insights
│   ├── deals/               # Deals & offers
│   └── add_item/            # Add new item
└── shared/
    ├── models/              # Data models
    ├── widgets/             # Reusable widgets
    └── services/            # App services
```

## Design System

### Typography
- **Primary Font**: IBM Plex Sans (body, UI)
- **Display Font**: Montserrat (headings, brand)

### Color Palette
- **Primary**: Sky Blue (#03A9F4)
- **Categories**:
  - Food: Green (#4CAF50)
  - Grocery: Orange (#FF9800)
  - Medicine: Red (#F44336)
  - Cosmetics: Purple (#9C27B0)

## Device Support

### Phones
- iOS: iPhone 6s and newer (iOS 12+)
- Android: API 21+ (Android 5.0 Lollipop)

### Tablets
- iPad: All models with iPadOS 12+
- Android Tablets: 7" and larger

## License

This project is proprietary software. All rights reserved.
