# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Structure

This is a **location-based scavenger hunt app** called **UrbanQuest** exploring Albanian cities. The project contains:

- **`urbanquest_app/`** - Main Flutter application following Clean Architecture
- **`dashboard/`** - Web-based admin dashboard (HTML/JS) for managing quests and cities
- **`SampleDesing.tsx`** - Sample React component (likely for UI reference)

## Common Development Commands

### Flutter App (`urbanquest_app/`)
```bash
# Navigate to Flutter app directory
cd urbanquest_app

# Install dependencies
flutter pub get

# Generate code (for JSON serialization)
flutter pub run build_runner build

# Run the app
flutter run

# Build for release
flutter build apk
flutter build ios

# Run tests
flutter test

# Analyze code
flutter analyze
```

### Code Generation
When working with model files (`.g.dart` files), regenerate them after changes:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## Architecture Overview

### Clean Architecture with Atomic Design
The Flutter app follows **Clean Architecture** principles with clear separation of concerns:

#### **Core Layer** (`/lib/src/core/`)
- **Services**: Infrastructure services (Supabase, Location, Notifications, Permissions, etc.)
- **Constants**: App-wide constants like colors and themes

#### **Data Layer** (`/lib/src/data/`)
- **Models**: Data entities with JSON serialization (all extend `Equatable`)
- **Repositories**: Data access abstraction using Repository pattern
- **Services**: Business logic services (Quest completion, App data)

#### **Logic Layer** (`/lib/src/logic/`)
- **BLoC Pattern**: State management using `flutter_bloc`
- **Events & States**: All extend `Equatable` for value comparison

#### **Presentation Layer** (`/lib/src/presentation/`)
**Atomic Design structure:**
- **Atoms**: Basic UI components (`custom_button`, `custom_text_field`)
- **Molecules**: Composite components (`quest_card`, `language_selector`)
- **Organisms**: Complex UI sections (`bottom_navigation_bar`, `login_organism`)
- **Templates**: Page layouts (`app_template`)
- **Views**: Complete screens organized by feature

### Key Services
- **SupabaseService**: Database, auth, and real-time functionality
- **LocationService**: GPS tracking and location verification
- **QuestCompletionService**: Quest logic and achievement unlocking
- **NotificationService**: Push notifications for quest updates
- **PhotoUploadService**: Image capture and upload for quest challenges

## Technology Stack

### Flutter App
- **Backend**: Supabase (PostgreSQL, Auth, Real-time, Storage)
- **State Management**: BLoC pattern (`flutter_bloc`)
- **Location**: `geolocator` for GPS functionality
- **UI Framework**: Material Design 3 with Google Fonts
- **Animations**: `flutter_animate`
- **Data Persistence**: `shared_preferences`
- **Image Handling**: `image_picker` + `cached_network_image`

### Admin Dashboard
- **Frontend**: Vanilla HTML/JS with Tailwind CSS
- **Database**: Supabase client for admin operations

## Development Patterns

### State Management
- Use **BLoC pattern** for global state (authentication, quest data)
- Use **StatefulWidget** for component-specific state
- All BLoC events and states must extend `Equatable`

### Data Models
- All models extend `Equatable` for value comparison
- Use `json_annotation` for JSON serialization
- Run `build_runner` after model changes

### Navigation
- Custom enum-based navigation system via `AppTemplate`
- Navigation handled centrally through `_navigateToView()` method
- Bottom navigation maps to main app views

### Service Pattern
- Services are typically singletons accessed via static instances
- Repository pattern abstracts data access from business logic
- Dependency injection used for services in repositories and BLoCs

## Key Files to Understand

- **`lib/main.dart`** - App entry point with Supabase initialization
- **`lib/src/presentation/templates/app_template.dart`** - Central navigation and app shell
- **`lib/src/core/services/supabase_service.dart`** - Database service singleton
- **`lib/src/logic/auth_bloc/auth_bloc.dart`** - Authentication state management
- **`pubspec.yaml`** - Dependencies and project configuration

## Location-Based Features

This app heavily relies on location services for:
- GPS tracking during quests
- Location verification at quest stops
- Real-time position updates
- Step counting with pedometer integration

When working with location features, ensure proper permissions are handled via `PermissionService`.

## Database Schema

The app uses Supabase with these main entities:
- **Users**: User profiles and authentication
- **Quests**: Quest definitions with stops and challenges
- **Cities**: Available cities for exploration
- **Achievements**: Unlockable achievements and rewards
- **Quest Progress**: User progress tracking
- **Leaderboards**: User rankings and scores

## Admin Dashboard

The web dashboard (`dashboard/index.html`) provides:
- Quest management (create, edit, delete)
- City management
- User monitoring
- Achievement system administration
- Real-time activity monitoring

Access requires admin authentication through Supabase.

# Using Gemini CLI for Large Codebase Analysis

When analyzing large codebases or multiple files that might exceed context limits, use the Gemini CLI with its massive
context window. Use `gemini -p` to leverage Google Gemini's large context capacity.

## File and Directory Inclusion Syntax

Use the `@` syntax to include files and directories in your Gemini prompts. The paths should be relative to WHERE you run the
  gemini command:

### Examples:

**Single file analysis:**
gemini -p "@src/main.py Explain this file's purpose and structure"

Multiple files:
gemini -p "@package.json @src/index.js Analyze the dependencies used in the code"

Entire directory:
gemini -p "@src/ Summarize the architecture of this codebase"

Multiple directories:
gemini -p "@src/ @tests/ Analyze test coverage for the source code"

Current directory and subdirectories:
gemini -p "@./ Give me an overview of this entire project"

# Or use --all_files flag:
gemini --all_files -p "Analyze the project structure and dependencies"

Implementation Verification Examples

Check if a feature is implemented:
gemini -p "@src/ @lib/ Has dark mode been implemented in this codebase? Show me the relevant files and functions"

Verify authentication implementation:
gemini -p "@src/ @middleware/ Is JWT authentication implemented? List all auth-related endpoints and middleware"

Check for specific patterns:
gemini -p "@src/ Are there any React hooks that handle WebSocket connections? List them with file paths"

Verify error handling:
gemini -p "@src/ @api/ Is proper error handling implemented for all API endpoints? Show examples of try-catch blocks"

Check for rate limiting:
gemini -p "@backend/ @middleware/ Is rate limiting implemented for the API? Show the implementation details"

Verify caching strategy:
gemini -p "@src/ @lib/ @services/ Is Redis caching implemented? List all cache-related functions and their usage"

Check for specific security measures:
gemini -p "@src/ @api/ Are SQL injection protections implemented? Show how user inputs are sanitized"

Verify test coverage for features:
gemini -p "@src/payment/ @tests/ Is the payment processing module fully tested? List all test cases"

When to Use Gemini CLI

Use gemini -p when:
- Analyzing entire codebases or large directories
- Comparing multiple large files
- Need to understand project-wide patterns or architecture
- Current context window is insufficient for the task
- Working with files totaling more than 100KB
- Verifying if specific features, patterns, or security measures are implemented
- Checking for the presence of certain coding patterns across the entire codebase

Important Notes

- Paths in @ syntax are relative to your current working directory when invoking gemini
- The CLI will include file contents directly in the context
- No need for --yolo flag for read-only analysis
- Gemini's context window can handle entire codebases that would overflow Claude's context
- When checking implementations, be specific about what you're looking for to get accurate results