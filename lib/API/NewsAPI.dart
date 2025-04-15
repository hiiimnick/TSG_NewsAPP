import 'dart:convert';
import 'package:http/http.dart' as http;
import '../classes/NewsModel.dart';

class NewsAPI {
  static const String _baseUrl = 'https://hn.algolia.com/api/v1';

  // Keep original getTopNews if needed elsewhere, or remove if unused
  Future<List<NewsModel>> getTopNews() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/search?tags=front_page'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> hits = data['hits'];
      return hits.map((item) => NewsModel.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load news');
    }
  }

  // NEW: Paginated version for top news
  Future<List<NewsModel>> getTopNewsPaginated({required int page, required int pageSize}) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/search?tags=front_page&page=$page&hitsPerPage=$pageSize'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> hits = data['hits'] ?? []; // Handle null hits
      return hits.map((item) => NewsModel.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load paginated top news (Page $page)');
    }
  }

  // Keep original searchNews if needed elsewhere, or remove if unused
  Future<List<NewsModel>> searchNews(String query) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/search?query=$query'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> hits = data['hits'];
      return hits.map((item) => NewsModel.fromJson(item)).toList();
    } else {
      throw Exception('Failed to search news');
    }
  }

  // NEW: Paginated version for search
  Future<List<NewsModel>> searchNewsPaginated({required String query, required int page, required int pageSize}) async {
    final encodedQuery = Uri.encodeComponent(query); // Ensure query is URL-safe
    final response = await http.get(
      Uri.parse('$_baseUrl/search?query=$encodedQuery&page=$page&hitsPerPage=$pageSize'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> hits = data['hits'] ?? []; // Handle null hits
      return hits.map((item) => NewsModel.fromJson(item)).toList();
    } else {
      throw Exception('Failed to search paginated news (Query: $query, Page $page)');
    }
  }

  // ...existing getNewsDetails...
  Future<Map<String, dynamic>> getNewsDetails(String id) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/items/$id'),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load news details');
    }
  }

  // ...existing getNewsByDate...
  Future<List<NewsModel>> getNewsByDate(DateTime date) async {
    // Calculate timestamps for the start and end of the day
    final startTimestamp = DateTime(date.year, date.month, date.day).millisecondsSinceEpoch ~/ 1000;
    final endTimestamp = DateTime(date.year, date.month, date.day, 23, 59, 59).millisecondsSinceEpoch ~/ 1000;

    final response = await http.get(
      Uri.parse('$_baseUrl/search_by_date?tags=story&numericFilters=created_at_i>=$startTimestamp,created_at_i<=$endTimestamp'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> hits = data['hits'];
      return hits.map((item) => NewsModel.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load news by date');
    }
  }

  // ...existing getNewsByDateRange (fetches all, no pagination needed here)...
  Future<List<NewsModel>> getNewsByDateRange(DateTime? startDate, DateTime? endDate) async {
    if (startDate == null && endDate == null) {
      print("API: Both dates null in getNewsByDateRange, returning empty list.");
      return [];
    }

    try {
      List<String> numericFilters = [];

      if (startDate != null) {
        final startTimestamp = DateTime.utc(startDate.year, startDate.month, startDate.day).millisecondsSinceEpoch ~/ 1000;
        numericFilters.add('created_at_i>=$startTimestamp');
      }

      if (endDate != null) {
        final endTimestamp = DateTime.utc(endDate.year, endDate.month, endDate.day, 23, 59, 59, 999).millisecondsSinceEpoch ~/ 1000;
        numericFilters.add('created_at_i<=$endTimestamp');
      }

      final filterString = numericFilters.join(',');
      // Fetch a large number of hits for date range, assuming no pagination needed for this feature
      final url = Uri.parse('$_baseUrl/search?tags=story&hitsPerPage=1000&numericFilters=$filterString');

      print("Fetching news for range/date: $url");

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final List<NewsModel> news = (jsonData['hits'] as List? ?? [])
            .map((item) => NewsModel.fromJson(item))
            .toList();
        print("Fetched ${news.length} items for date filter.");
        return news;
      } else {
        print("API Error (Date Filter): ${response.statusCode} - ${response.body}");
        throw Exception('Failed to load news for date filter');
      }
    } catch (e) {
      print("Error in getNewsByDateRange: $e");
      throw Exception('Error loading news for date filter: $e');
    }
  }
}