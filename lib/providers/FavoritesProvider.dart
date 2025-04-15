import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../classes/NewsModel.dart';

class FavoritesProvider with ChangeNotifier {
  final SharedPreferences _preferences;
  List<NewsModel> _favorites = [];
  
  FavoritesProvider(this._preferences) {
    _loadFavorites();
  }
  
  List<NewsModel> get favorites => _favorites;
  
  bool isFavorite(String id) {
    return _favorites.any((news) => news.id == id);
  }
  
  void _loadFavorites() {
    final favoritesJson = _preferences.getStringList('favorites') ?? [];
    _favorites = favoritesJson
        .map((item) => NewsModel.fromJson(json.decode(item)))
        .toList();
    notifyListeners();
  }
  
  Future<void> _saveFavorites() async {
    final favoritesJson = _favorites
        .map((news) => json.encode(news.toJson()))
        .toList();
    await _preferences.setStringList('favorites', favoritesJson);
  }
  
  Future<void> toggleFavorite(NewsModel news) async {
    final isAlreadyFavorite = isFavorite(news.id);
    
    if (isAlreadyFavorite) {
      _favorites.removeWhere((item) => item.id == news.id);
    } else {
      _favorites.add(news);
    }
    
    notifyListeners();
    await _saveFavorites();
  }
  
  Future<void> removeFavorite(String id) async {
    _favorites.removeWhere((news) => news.id == id);
    notifyListeners();
    await _saveFavorites();
  }
}