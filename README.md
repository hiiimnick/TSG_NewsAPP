# tsg_newsapp

## Overview
tsg_newsapp is a Flutter application designed to provide users with a seamless experience for browsing and managing news articles. The app fetches news from an API, allows users to mark articles as favorites, and provides various functionalities such as searching, filtering, and sorting news items.

## Features
- **News Feed**: Displays a list of news articles fetched from an external API.
- **Favorites**: Users can mark news articles as favorites, which are stored using the `shared_preferences` package.
- **Favorites Page**: A dedicated page to view all favorite news articles.
- **News Details**: Users can view detailed information about each news article.
- **Search Functionality**: Users can search for news articles by keywords.
- **Filter and Sort**: Options to filter news by categories and sort them based on various criteria.
- **Calendar Page**: A calendar interface that allows users to select dates and view news published on those days.

## Project Structure
```
tsg_newsapp
├── lib
│   ├── api
│   │   ├── news_api.dart
│   │   └── api_constants.dart
│   ├── models
│   │   ├── news_model.dart
│   │   └── category_model.dart
│   ├── providers
│   │   ├── news_provider.dart
│   │   └── favorites_provider.dart
│   ├── screens
│   │   ├── home_screen.dart
│   │   ├── news_detail_screen.dart
│   │   ├── favorites_screen.dart
│   │   ├── search_screen.dart
│   │   └── calendar_screen.dart
│   ├── widgets
│   │   ├── news_card.dart
│   │   ├── category_chips.dart
│   │   ├── search_bar.dart
│   │   ├── filter_dialog.dart
│   │   └── sort_dropdown.dart
│   ├── utils
│   │   ├── date_formatter.dart
│   │   └── shared_prefs_helper.dart
│   ├── constants
│   │   ├── theme.dart
│   │   └── strings.dart
│   └── main.dart
├── pubspec.yaml
└── README.md
```

## Setup Instructions
1. Clone the repository:
   ```
   git clone <repository-url>
   ```
2. Navigate to the project directory:
   ```
   cd tsg_newsapp
   ```
3. Install the dependencies:
   ```
   flutter pub get
   ```
4. Run the application:
   ```
   flutter run
   ```

## Dependencies
- `flutter`: The Flutter SDK.
- `shared_preferences`: For storing user preferences and favorite news articles.

## Contributing
Contributions are welcome! Please feel free to submit a pull request or open an issue for any suggestions or improvements.

## License
This project is licensed under the MIT License - see the LICENSE file for details.