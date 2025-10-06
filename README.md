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

### 🔐 Authentication System
- [x] Phone number authentication with OTP verification
- [x] Google Sign-In integration
- [x] User profile creation with custom user IDs
- [x] Auth state management and session handling
- [x] Beautiful onboarding UI with Material 3 design

### 👤 User Profile & Social Features  
- [x] Complete profile setup flow with nickname and bio
- [x] Modern edit profile functionality with real-time validation
- [x] Comprehensive settings screen with account information
- [x] Password change functionality for email users
- [x] Follow/unfollow system with live follower counts
- [x] Clickable user profiles with public profile viewing
- [x] User discovery through posts and interactions

### 📝 Post Creation & Feed System
- [x] Full post creation with database persistence
- [x] Zip code-based community posting and targeting
- [x] Category-based posting (news, events, fun facts, random)
- [x] Real-time post count tracking in user profiles
- [x] Home feed with zip code search and filtering
- [x] Live feed updates when posts are created
- [x] Modal post creation with success feedback and validation
- [x] Event posts with detailed event information fields

### 🏗️ App Structure & Navigation
- [x] Bottom navigation (Home/Post/Profile) with modern design
- [x] Seamless screen routing and navigation flow
- [x] Splash screen with proper Firebase/Supabase initialization
- [x] Responsive design across different screen sizes

## 🎉 MAJOR MILESTONE ACHIEVED

**✅ Core Social Media Functionality Complete!**

Zip Social now has a fully functional social media platform with:
- **Complete user authentication and profile management**
- **Real-time post creation and database integration** 
- **Zip code-based community discovery and targeting**
- **Live user interaction system with follow functionality**
- **Modern, intuitive mobile-first design**

The app successfully demonstrates the core concept: **hyper-local social networking** where users can post content targeted to their zip code community and discover local posts from neighbors.

## 🎯 Current Status & Next Phase

### Phase 2: User Profile & Settings ✅ COMPLETED
- ✅ Complete user profile setup flow
- ✅ Nickname and bio configuration
- ✅ Modern edit profile functionality
- ✅ Comprehensive settings screen with authentication details
- ✅ Password change functionality for email users
- ✅ Follow/unfollow system with real-time counts
- ✅ Clickable user profiles throughout the app

### Phase 3: Feed & Posts ✅ COMPLETED 
- ✅ Complete post creation with database integration
- ✅ Zip code-based posting and community targeting
- ✅ Real-time post count tracking in user profiles
- ✅ Home feed with zip code search and filtering
- ✅ Category-based post filtering (news, events, fun facts, random)
- ✅ Live feed updates when posts are created
- ✅ Modal post creation with success feedback
- ✅ Event posts with detailed event information fields

### Recent Progress & Fixes
- **Preferred Zip Code Feature:**
    - Added a `preferred_zipcode` field to user profiles, allowing users to set a default zip code.
    - Home feed now automatically filters posts by the user's preferred zip code upon login or refresh.
    - The preferred zip code is displayed by default in the home screen's zip code search field.
- **Post Interaction Functionality:**
    - Implemented like, dislike, and save functionality for posts.
    - Ensured correct parsing and display of user's interaction status (vote, saved) from Supabase.
    - Updated Supabase schema and functions (manual steps for user) to support `upvotes` and `downvotes` counts directly in the `posts` table.
- **Improved UI Responsiveness:**
    - Eliminated automatic full feed refresh after each post interaction, improving user experience.
    - Implemented local optimistic UI updates for post interactions.
- **Keypad Auto-Focus Prevention:**
    - Resolved issue where the numeric keypad would automatically appear on the feed tab after navigating back from other screens (e.g., "Create Post").
    - Implemented explicit focus management using `FocusNode` and `didChangeDependencies` in `HomeScreen` (also used for preferred zip code feature).

### Phase 4: Enhanced Post Features (Current Priority)
- [x] Post interactions (like, dislike, save functionality)
- [ ] Comment system with threaded discussions
- [ ] Real-time notifications for interactions
- [ ] Post sharing and mention functionality
- [ ] Image upload and display in posts
- [ ] Enhanced event posting with RSVP functionality

### Phase 5: Local Discovery & Advanced Features (Medium Priority)
- [ ] Advanced zip code-based content filtering
- [ ] Local event discovery and enhanced event features
- [ ] Nearby users discovery with location services
- [ ] Push notifications for local activity
- [ ] Direct messaging system
- [ ] Community groups and local business integration

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
- ✅ Post interactions not persisting/displaying correctly → Fixed by standardizing Supabase client, correcting `Post.fromJson` parsing, and updating Supabase schema/functions for vote counts.
- ✅ Automatic keypad appearance on feed tab → Fixed by implementing explicit focus management in `HomeScreen`.

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