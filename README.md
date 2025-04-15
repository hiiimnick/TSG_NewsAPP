# TSG News App

## Overview
TSG News App is a Flutter application for browsing news articles from the Hacker News Algolia API. It features search, filtering, sorting, and lets users save favorite articles locally.

## Features
- **Search:** Find news articles by keywords, with infinite scroll for results.
- **Filtering:** Filter news by minimum points or by a specific date range.
- **Sorting:** Sort articles by date or points, ascending or descending.
- **News Details:** View article details and the first few comments.
- **Show More Comments:** Open the full Hacker News comment section in your browser.
- **Favorites:** Mark articles as favorites, stored locally using `shared_preferences`.

## Project Structure
```
tsg_newsapp
├── lib
│   ├── API
│   │   └── NewsAPI.dart
│   ├── classes
│   │   └── NewsModel.dart
│   ├── providers
│   │   ├── NewsProvider.dart
│   │   └── FavoritesProvider.dart
│   ├── screens
│   │   ├── HomeScreen.dart
│   │   └── NewsDetailScreen.dart
│   ├── widgets
│   │   ├── NewsCard.dart
│   │   └── Filter.dart
│   └── main.dart
├── pubspec.yaml
└── README.md
```

## Setup Instructions
1. **Clone the repository:**
    ```bash
    git clone https://github.com/hiiimnick/TSG_NewsAPP.git
    ```
2. **Navigate to the project directory:**
    ```bash
    cd tsg_newsapp
    ```
3. **Install dependencies:**
    ```bash
    flutter pub get
    ```
4. **Build the application:**
    ```bash
    flutter build apk --release
    ```
5. **(OPTIONAL) Install the application to an Android VM:**
   ```bash
   flutter install --release
   ```

## Release Version and Instructions
1. Go to the releases tab [here](https://github.com/hiiimnick/TSG_NewsAPP/releases/tag/DEMO).
2. Download the DEMO build on your Android Device.
3. Install the DEMO build on your Android Device.

## Key Dependencies
- `flutter`
- `provider`
- `http`
- `shared_preferences`
- `url_launcher`
- `intl`
- `html_unescape`
- `table_calendar` (if CalendarScreen is used)

## Contributing
Contributions are welcome! Please submit a pull request or open an issue for suggestions or improvements.

## License
This project is licensed under the MIT License - see the LICENSE file for details.
