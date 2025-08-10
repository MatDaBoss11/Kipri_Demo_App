# Grocery Search Flutter App

## Run
- Update API base URL in `lib/main.dart` if not using Android emulator.
- Install deps and run:
  ```bash
  flutter pub get
  flutter run -d emulator-5554
  ```

The app shows a search bar; submitting sends a POST to `/search` and lists results.