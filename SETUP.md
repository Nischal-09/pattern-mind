# Setup Guide 🛠️

This guide will help you get **PatternMind** running on your local machine.

## Prerequisites
- **Flutter SDK**: [Install Flutter](https://docs.flutter.dev/get-started/install)
- **Dart SDK**: Included with Flutter
- **Supabase Account**: [Sign up for Supabase](https://supabase.com)
- **An IDE**: VS Code or Android Studio with Flutter extensions

## 1. Clone the Project
```bash
git clone https://github.com/YOUR_USERNAME/pattern_mind.git
cd pattern_mind
```

## 2. Install Dependencies
```bash
flutter pub get
```

## 3. Configure Environment Variables
1. Create a file named `.env` in the root directory.
2. Copy the contents from `.env.example` into `.env`.
3. Fill in your Supabase project details:
```env
SUPABASE_URL=https://your-project-url.supabase.co
SUPABASE_ANON_KEY=your-anon-key
```

## 4. Supabase Database Setup
Ensure your Supabase project has a `stats` table with the following schema:
- `id`: uuid (primary key)
- `user_id`: uuid (references auth.users)
- `patterns_correct`: int4
- `errors`: int4
- `accuracy`: float8
- `difficulty`: text
- `created_at`: timestamptz (default: now())

Enable **RLS (Row Level Security)** on the `stats` table and add policies to allow users to `select` and `insert` their own data.

## 5. Run the App
```bash
# To run on a connected device or emulator
flutter run
```

## Troubleshooting
- **Missing .env**: Ensure the `.env` file is in the root directory, not in `lib/`.
- **Supabase Connectivity**: Verify your internet connection and that your Supabase project is active.
- **Font Issues**: If fonts don't load, run `flutter clean` then `flutter pub get`.
