# UrbanQuest

A location-based scavenger hunt app for exploring Albanian cities.

## Overview

UrbanQuest is a mobile application that turns city exploration into an exciting adventure. Users complete quests by visiting specific locations, solving challenges, and earning points while discovering the rich history and culture of Albanian cities.

## Features

- 📱 **Mobile App** (Flutter) - Cross-platform iOS/Android application
- 🌐 **Admin Dashboard** - Web-based content management system
- 🗺️ **Location-Based Gameplay** - GPS verification and real-time tracking
- 🏆 **Gamification** - Points, achievements, and leaderboards
- 📸 **Photo Challenges** - Interactive photo capture and sharing
- 🌍 **Multi-language Support** - Albanian and English
- 🔐 **User Authentication** - Secure Supabase authentication

## Project Structure

```
UrbanQuest/
├── urbanquest_app/          # Flutter mobile application
├── dashboard/               # Admin web dashboard
├── docs/                   # Documentation
└── README.md
```

## Technology Stack

### Mobile App
- **Framework**: Flutter
- **Backend**: Supabase (PostgreSQL, Auth, Storage)
- **State Management**: BLoC Pattern
- **Maps**: Google Maps / OpenStreetMap
- **Architecture**: Clean Architecture with Atomic Design

### Admin Dashboard
- **Frontend**: HTML/CSS/JavaScript
- **Styling**: Tailwind CSS
- **Maps**: Leaflet.js + OpenStreetMap
- **Backend**: Supabase integration

## Getting Started

### Prerequisites
- Flutter SDK (3.0+)
- Dart SDK (3.0+)
- Node.js (for dashboard development)
- Supabase account

### Mobile App Setup

1. Navigate to the Flutter app directory:
   ```bash
   cd urbanquest_app
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Generate code files:
   ```bash
   flutter pub run build_runner build
   ```

4. Run the app:
   ```bash
   flutter run
   ```

### Admin Dashboard

The admin dashboard is deployed at: [https://gerandi.github.io/UrbanQuest-Mobile/](https://gerandi.github.io/UrbanQuest-Mobile/)

For local development:
1. Navigate to dashboard directory
2. Open `index.html` in a browser
3. Login with admin credentials

## Database Schema

The app uses Supabase with the following main entities:
- **Users & Profiles** - User authentication and profile data
- **Cities & Quests** - Location-based quest content
- **Quest Stops** - Individual challenge points
- **User Progress** - Tracking quest completion
- **Achievements** - Gamification system
- **Leaderboards** - User rankings

## Configuration

### Supabase Setup
1. Create a new Supabase project
2. Update connection strings in the app
3. Apply database migrations
4. Configure Row Level Security (RLS) policies

### Environment Variables
```bash
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_supabase_anon_key
```

## Development

### Mobile App Development
```bash
# Development
flutter run

# Build for release
flutter build apk --release
flutter build ios --release

# Run tests
flutter test

# Code analysis
flutter analyze
```

### Deployment

#### Mobile App
- **Android**: Build APK/AAB and deploy to Google Play Store
- **iOS**: Build IPA and deploy to Apple App Store

#### Admin Dashboard
- **GitHub Pages**: Automatically deployed from `main` branch
- **Custom Domain**: Configure in repository settings

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support and questions:
- Create an issue in this repository
- Contact: [Your contact information]

## Roadmap

- [ ] Advanced quest creation tools
- [ ] Social features and team quests
- [ ] Augmented Reality integration
- [ ] Additional Albanian cities
- [ ] Tourism partnership integration