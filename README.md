# Zip Social

A hyper-local social media app for connecting with your zip code community.

## 🚀 Project Overview

Zip Social is a lightweight Flutter mobile application that enables users to connect with people in their local zip code area. The app focuses on minimal code and clean architecture while providing essential social media features.

## ✅ Current Progress

### Phase 1: Authentication System ✅ COMPLETED
- **Firebase Authentication Integration**
  - Phone number authentication with OTP verification
  - Google Sign-In integration
  - Custom URL schemes configured for iOS
  - Hybrid Firebase (auth) + Supabase (database) architecture

- **UI/UX Implementation**
  - Beautiful authentication screen matching HTML mockups
  - Green theme (#8CE830) design system
  - Material 3 design components
  - Responsive layout for different screen sizes

- **iOS Configuration**
  - Xcode project setup with proper bundle ID
  - CocoaPods dependencies managed
  - Firebase configuration with GoogleService-Info.plist
  - Google Sign-In URL schemes
  - Firebase phone auth URL schemes
  - iOS deployment target updated to 13.0+

### Phase 1 Technical Achievements
- ✅ Flutter project initialization with minimal dependencies
- ✅ Firebase Core and Auth integration
- ✅ Google Sign-In SDK integration
- ✅ Supabase client setup
- ✅ Custom user ID generation system
- ✅ User profile creation in Supabase database
- ✅ Modern authentication UI with both phone and Google options
- ✅ Error handling and loading states
- ✅ iOS build and deployment to physical device

## 🏗️ Technical Architecture

### Frontend
- **Framework**: Flutter (Dart)
- **UI**: Material 3 design system
- **State Management**: setState (keeping it simple)
- **Navigation**: Basic Navigator

### Backend Services
- **Authentication**: Firebase Auth
  - Phone authentication with SMS verification
  - Google OAuth integration
- **Database**: Supabase
  - User profiles storage
  - Row Level Security (RLS) policies
- **File Storage**: Supabase Storage (planned)

### Key Dependencies
```yaml
dependencies:
  flutter: sdk
  firebase_core: ^3.8.0
  firebase_auth: ^5.3.3
  google_sign_in: ^6.2.1
  supabase_flutter: ^2.8.0
  provider: ^6.1.2
  shared_preferences: ^2.2.3
```

## 📱 Current Features

### Authentication
- [x] Phone number authentication with OTP
- [x] Google Sign-In integration
- [x] User profile creation
- [x] Auth state management
- [x] Beautiful onboarding UI

### App Structure
- [x] Bottom navigation (Home/Post/Profile)
- [x] Basic screen routing
- [x] Splash screen with proper initialization

## 🎯 Next Phase: Core Features

### Phase 2: User Profile & Settings (Immediate Priority)
- [ ] Complete user profile setup flow
- [ ] Zip code location detection/input
- [ ] Profile photo upload
- [ ] User preferences and settings
- [ ] Display name and bio setup

### Phase 3: Feed & Posts (High Priority)
- [ ] Home feed implementation
- [ ] Create post functionality
- [ ] Post types (text, image, location-based)
- [ ] Real-time feed updates
- [ ] Post interactions (like, comment)

### Phase 4: Local Discovery (Medium Priority)
- [ ] Zip code-based content filtering
- [ ] Local events and activities
- [ ] Nearby users discovery
- [ ] Location-based notifications

### Phase 5: Social Features (Future)
- [ ] Direct messaging
- [ ] Groups and communities
- [ ] Event creation and RSVP
- [ ] Local business integration

## 🔧 Development Setup

### Prerequisites
- Flutter SDK (3.8.1+)
- Xcode (for iOS development)
- CocoaPods
- Firebase project setup
- Supabase project setup

### Getting Started
1. Clone the repository
2. Install dependencies: `flutter pub get`
3. iOS setup: `cd ios && pod install`
4. Configure Firebase and Supabase credentials
5. Run: `flutter run`

### Firebase Configuration
- Project ID: `zip-social-443a3`
- Bundle ID: `com.zipsocial.zipSocial`
- Google Sign-In client configured
- Phone auth test numbers available

### Supabase Configuration
- Database with `users` table
- RLS policies configured
- Authentication integration with Firebase

## 📂 Project Structure

```
lib/
├── main.dart                 # App entry point
├── config/
│   ├── firebase_config.dart  # Firebase initialization
│   └── supabase_config.dart  # Supabase client setup
├── services/
│   └── firebase_auth_service.dart  # Authentication logic
├── screens/
│   ├── auth_screen.dart      # Login/signup UI
│   ├── home_screen.dart      # Main feed
│   ├── post_screen.dart      # Create post
│   └── profile_screen.dart   # User profile
├── models/
│   └── user.dart            # User data model
└── widgets/                 # Reusable UI components
```

## 🐛 Known Issues & Fixes Applied

### Resolved Issues
- ✅ Firebase initialization failures → Fixed with explicit FirebaseOptions
- ✅ iOS deployment target too low → Updated to 13.0+
- ✅ Bundle ID mismatches → Corrected across all config files
- ✅ CocoaPods dependency conflicts → Resolved GTMSessionFetcher version
- ✅ Missing URL schemes → Added Firebase and Google auth schemes
- ✅ UI overflow on smaller screens → Responsive design improvements

### Current Known Issues
- ⚠️ Supabase URL needs proper configuration for user profile creation
- ⚠️ Phone number validation needs better UX (format hints)
- ⚠️ Minor UI overflow on very small screens (27px)

## 🚀 Deployment

### iOS
- Development team: D2ZV2Z6V4T
- Minimum iOS version: 13.0
- Successfully tested on iPhone device
- App Store preparation pending

## 📈 Performance & Optimization

### Current Status
- Lightweight codebase with minimal dependencies
- Fast app startup with proper async initialization
- Efficient state management
- Optimized Firebase and Supabase integration

### Future Optimizations
- Image compression and caching
- Lazy loading for feeds
- Background sync for offline support
- Performance monitoring integration

## 🤝 Contributing

This project follows clean code principles and minimal dependency philosophy. When adding features:
1. Keep dependencies minimal
2. Follow existing code patterns
3. Maintain consistent UI/UX design
4. Test on physical devices
5. Update this README with progress

## 📄 License

[License information to be added]

---

**Built with ❤️ using Flutter • Last updated: October 2025**
