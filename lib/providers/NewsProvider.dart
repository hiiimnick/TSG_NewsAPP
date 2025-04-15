import 'dart:async';
import 'package:flutter/foundation.dart';
import '../API/NewsAPI.dart';
import '../classes/NewsModel.dart';

enum SortOption { points, date }
enum SortOrder { ascending, descending }

// Define a constant for page size
const int _kPageSize = 20;

class NewsProvider with ChangeNotifier {
  final NewsAPI _newsApi = NewsAPI();
  List<NewsModel> _news = []; // Holds the raw accumulated data (top news or search)
  List<NewsModel> _filteredNews = []; // Holds the final list after ALL filters
  bool _isLoading = false; // Flag for initial loading (first page)
  bool _isLoadingMore = false; // Flag for loading subsequent pages
  String _searchQuery = '';
  int _minPoints = 0;
  DateTime? _startDate;
  DateTime? _endDate;
  SortOption _sortOption = SortOption.date;
  SortOrder _sortOrder = SortOrder.descending;
  String? _currentError;
  int _currentPage = 0; // Page number for pagination (0-based)
  bool _hasMore = true; // Flag to indicate if more pages can be loaded
  bool _isFetchingDateRange = false; // Flag to know if the current _news is from a date range fetch

  List<NewsModel> get news => _filteredNews;
  bool get isLoading => _isLoading; // Represents initial loading
  bool get isLoadingMore => _isLoadingMore; // Represents loading more items
  String get searchQuery => _searchQuery;
  int get minPoints => _minPoints;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;
  SortOption get sortOption => _sortOption;
  SortOrder get sortOrder => _sortOrder;
  String? get currentError => _currentError;
  bool get hasMore => _hasMore; // Expose hasMore flag

  // Fetch the first page of top news
  Future<void> fetchTopNews({bool forceRefresh = false}) async {
    // Avoid refetch if already showing first page of top news unless forced
    if (!forceRefresh && _searchQuery.isEmpty && !_isFetchingDateRange && _currentPage == 0 && _news.isNotEmpty && !_isLoading) {
      print("Using cached top news (first page).");
      // Re-apply filters in case sort/points changed, but don't refetch
      _applyFilters();
      return;
    }

    print("Fetching top news (Page 0)...");
    _isLoading = true;
    _currentError = null;
    _searchQuery = '';
    _startDate = null;
    _endDate = null;
    _currentPage = 0; // Reset to first page
    _hasMore = true; // Assume more pages exist initially
    _isFetchingDateRange = false; // Not fetching date range
    _news = []; // Clear existing news before fetching the first page
    notifyListeners(); // Update UI for loading state and cleared filters

    try {
      // Use the paginated API method
      final fetchedNews = await _newsApi.getTopNewsPaginated(page: _currentPage, pageSize: _kPageSize);
      _news = fetchedNews;
      _hasMore = fetchedNews.length == _kPageSize; // Check if a full page was returned
      print("Fetched ${_news.length} top news items for page $_currentPage. HasMore: $_hasMore");
    } catch (e) {
      print('Error fetching top news: $e');
      _currentError = 'Failed to load top news: $e';
      _news = []; // Clear news on error
      _hasMore = false; // Cannot load more if initial fetch failed
    } finally {
      _isLoading = false;
      _applyFilters(); // Apply filters to the first page results
    }
  }

  // Fetch the first page of search results
  Future<void> searchNews(String query) async {
    // If the query is the same as the current one, don't re-search
    if (query == _searchQuery && !_isLoading && _news.isNotEmpty && !_isFetchingDateRange) {
        print("Search query '$query' hasn't changed. Not re-searching.");
        return;
    }

    _searchQuery = query;
    _isLoading = true;
    _currentError = null;
    _startDate = null; // Clear date range when searching
    _endDate = null;
    _currentPage = 0; // Reset to first page
    _hasMore = true; // Assume more pages exist initially
    _isFetchingDateRange = false; // Not fetching date range
    _news = []; // Clear existing news before fetching the first page of search
    notifyListeners();

    try {
      if (query.isNotEmpty) {
        print("Searching news (Page 0) for query: '$query'");
        // Use the paginated search method
        final fetchedNews = await _newsApi.searchNewsPaginated(query: query, page: _currentPage, pageSize: _kPageSize);
        _news = fetchedNews;
        _hasMore = fetchedNews.length == _kPageSize;
        print("Search returned ${_news.length} items for page $_currentPage. HasMore: $_hasMore");
      } else {
        // If search is cleared, revert to fetching top news (first page)
        print("Search query cleared. Fetching top news.");
        // Call fetchTopNews directly, it handles state updates
        await fetchTopNews(forceRefresh: true); // Use forceRefresh to ensure it runs
        return; // fetchTopNews handles loading state and applyFilters
      }
    } catch (e) {
      print('Error searching news: $e');
      _currentError = 'Failed to perform search: $e';
      _news = [];
      _hasMore = false;
    } finally {
      // Only set isLoading false if not handled by fetchTopNews
      if (query.isNotEmpty) {
        _isLoading = false;
        _applyFilters();
      }
    }
  }

  // Fetch the next page of data (either top news or search results)
  Future<void> fetchMoreNews() async {
    // Don't fetch more if already loading, or if no more pages, or if showing date range results
    if (_isLoading || _isLoadingMore || !_hasMore || _isFetchingDateRange) {
      print("Skipping fetchMoreNews: isLoading=$_isLoading, isLoadingMore=$_isLoadingMore, hasMore=$_hasMore, isFetchingDateRange=$_isFetchingDateRange");
      return;
    }

    _isLoadingMore = true;
    _currentError = null; // Clear previous errors related to loading more
    notifyListeners();

    _currentPage++; // Increment page number
    print("Fetching more news (Page $_currentPage)... Query: '$_searchQuery'");

    try {
      List<NewsModel> fetchedNews;
      if (_searchQuery.isNotEmpty) {
        // Fetch next page of search results
        fetchedNews = await _newsApi.searchNewsPaginated(query: _searchQuery, page: _currentPage, pageSize: _kPageSize);
        print("Fetched ${fetchedNews.length} more search items for page $_currentPage.");
      } else {
        // Fetch next page of top news
        fetchedNews = await _newsApi.getTopNewsPaginated(page: _currentPage, pageSize: _kPageSize);
        print("Fetched ${fetchedNews.length} more top news items for page $_currentPage.");
      }

      _news.addAll(fetchedNews); // Append new results
      _hasMore = fetchedNews.length == _kPageSize; // Update hasMore flag
      print("Total items after fetchMore: ${_news.length}. HasMore: $_hasMore");

    } catch (e) {
      print('Error fetching more news: $e');
      _currentError = 'Failed to load more news: $e';
      // Optionally keep _hasMore true to allow retry? Or set to false?
      // Let's set to false to prevent infinite loading loops on error.
      _hasMore = false;
      _currentPage--; // Decrement page number on error so retry fetches the same page? Or keep it? Let's keep it incremented.
    } finally {
      _isLoadingMore = false;
      _applyFilters(); // Re-apply filters to the combined list
    }
  }


  // Method to fetch news based on date range (fetches ALL results, not paginated)
  Future<void> fetchNewsForDateRange(DateTime? start, DateTime? end) async {
    // Avoid refetch if dates haven't changed and we are already showing date range results
    if (_isFetchingDateRange && _startDate == start && _endDate == end && !_isLoading) {
        print("Date range hasn't changed. Not refetching.");
        return;
    }

    if (start == null && end == null) {
      print("fetchNewsForDateRange called with both dates null. Reverting to top news.");
      await fetchTopNews(forceRefresh: true);
      return;
    }
    if (start != null && end != null && end.isBefore(start)) {
       _currentError = "End date cannot be before start date.";
       _isLoading = false;
       _news = [];
       _hasMore = false; // No pagination for date range
       _isFetchingDateRange = true; // Mark as date range fetch
       _applyFilters();
       return;
    }

    print("Fetching ALL news for date filter: start=$start, end=$end");
    _isLoading = true;
    _currentError = null;
    _searchQuery = ''; // Clear search query
    _startDate = start; // Update internal state for dates
    _endDate = end;
    _news = []; // Clear previous results
    _hasMore = false; // Date range results are not paginated
    _isFetchingDateRange = true; // Mark as date range fetch
    notifyListeners();

    try {
      // Call the API method that gets ALL results for the range
      _news = await _newsApi.getNewsByDateRange(start, end);
      print("Fetched ${_news.length} items for the date filter.");
    } catch (e) {
      print('Error fetching news for date filter: $e');
      _currentError = 'Failed to load news for date filter: $e';
      _news = [];
    } finally {
      _isLoading = false;
      _applyFilters(); // Apply other filters (points, sort)
    }
  }

  // setDateRange now calls fetchNewsForDateRange or fetchTopNews
  void setDateRange(DateTime? start, DateTime? end) {
    // Case 1: Both dates are set OR only one date is set
    if (start != null || end != null) {
      fetchNewsForDateRange(start, end); // Fetches all for range, sets _hasMore=false
    }
    // Case 2: Both dates are cleared (set to null)
    else { // start == null && end == null
      // Only fetch top news if we were previously showing date range results or search results
      if (_isFetchingDateRange || _searchQuery.isNotEmpty) {
         fetchTopNews(forceRefresh: true); // Force refresh to get paginated top news
      } else {
         // If dates/search were already null, just update state and re-apply filters
         _startDate = null;
         _endDate = null;
         // If _news is empty or we want to ensure it's the first page of top news:
         if (_news.isEmpty) {
            fetchTopNews(forceRefresh: true);
         } else {
            _applyFilters(); // Just re-apply filters if already showing top news
         }
      }
    }
  }

  // Keep other filter setters as they are, they just call _applyFilters
  void setMinPoints(int points) {
    if (_minPoints == points) return; // Avoid unnecessary updates
    _minPoints = points;
    _applyFilters();
  }

  void setSortOption(SortOption option) {
    if (_sortOption == option) return; // Avoid unnecessary updates
    _sortOption = option;
    _applyFilters();
  }

  void toggleSortOrder() {
    _sortOrder = _sortOrder == SortOrder.ascending ?
      SortOrder.descending : SortOrder.ascending;
    _applyFilters();
  }

  // _applyFilters works on the accumulated _news list
  void _applyFilters() {
    print("\n--- APPLYING FILTERS ---");
    print("Current Filters: Points >= $_minPoints, Start: ${_startDate?.toIso8601String()}, End: ${_endDate?.toIso8601String()}, Query: '$_searchQuery'");
    print("Base news list size (accumulated): ${_news.length}");
    List<NewsModel> result = [..._news]; // Work on a copy

    // --- Point Filter ---
    // Apply point filter regardless of fetch type
    if (_minPoints > 0) {
      int beforeCount = result.length;
      result = result.where((news) => news.points >= _minPoints).toList();
      print("Points Filter (>= $_minPoints): ${beforeCount} -> ${result.length} items");
    }

    // --- Date Filters (Verification/Client-side for non-date-range fetches) ---
    // These filters are primarily for verification if _isFetchingDateRange is true,
    // or for client-side filtering if needed (though API should handle it).
    // They should NOT be applied if _isFetchingDateRange is false, as the API handles date range fetches entirely.
    if (_isFetchingDateRange) {
        if (_startDate != null) {
          final startOfDayUtc = DateTime.utc(_startDate!.year, _startDate!.month, _startDate!.day);
          print("Verifying Start Date (>= ${startOfDayUtc.toIso8601String()} UTC):");
          int beforeCount = result.length;
          result = result.where((news) {
            final newsUtc = news.createdAt.toUtc();
            return newsUtc.isAfter(startOfDayUtc) || _isSameUtcDay(newsUtc, startOfDayUtc);
          }).toList();
          if(beforeCount != result.length) print("  WARN: Start date filter removed items fetched by date range API!");
          print("  After verification: ${result.length} items");
        }

        if (_endDate != null) {
          final nextDayStartUtc = DateTime.utc(_endDate!.year, _endDate!.month, _endDate!.day).add(const Duration(days: 1));
          print("Verifying End Date (< ${nextDayStartUtc.toIso8601String()} UTC):");
          int beforeCount = result.length;
          result = result.where((news) {
            final newsUtc = news.createdAt.toUtc();
            return newsUtc.isBefore(nextDayStartUtc);
          }).toList();
          if(beforeCount != result.length) print("  WARN: End date filter removed items fetched by date range API!");
          print("  After verification: ${result.length} items");
        }
    } // End of date filter verification block


    // --- Sorting ---
    // Sorting should always be applied to the currently filtered list
    if (_sortOption == SortOption.points) {
      result.sort((a, b) => _sortOrder == SortOrder.ascending ?
        a.points.compareTo(b.points) : b.points.compareTo(a.points));
    } else { // SortOption.date
      result.sort((a, b) => _sortOrder == SortOrder.ascending ?
        a.createdAt.compareTo(b.createdAt) : b.createdAt.compareTo(a.createdAt));
    }
    print("Sorting Applied: Option=$_sortOption, Order=$_sortOrder");

    // --- Final Result ---
    // Update the filtered list. Handle potential errors.
    // If there's an error AND the list is empty (initial load failed), keep it empty.
    // Otherwise, show the results obtained so far, even if a later 'fetchMore' failed.
    if (_currentError != null && result.isEmpty && _news.isEmpty) {
        print("Error present and list is empty: $_currentError");
        _filteredNews = []; // Keep list empty on initial load error
    } else {
        _filteredNews = result; // Update the final list
    }
    print("Final list size to display: ${_filteredNews.length}");

    print("--- FILTERS APPLIED ---");
    notifyListeners(); // Notify listeners AFTER all filters and sorting are done
  }

  // Helper function to check if two DateTimes fall on the same day in UTC
  bool _isSameUtcDay(DateTime a, DateTime b) {
    final aUtc = a.toUtc();
    final bUtc = b.toUtc();
    return aUtc.year == bUtc.year && aUtc.month == bUtc.month && aUtc.day == bUtc.day;
  }

  // Keep getNewsDetails if used elsewhere
  Future<Map<String, dynamic>> getNewsDetails(String id) async {
    return await _newsApi.getNewsDetails(id);
  }

  // Keep getNewsByDate if used by CalendarScreen (assumes it fetches all for that specific day)
  Future<List<NewsModel>> getNewsByDate(DateTime date) async {
    print("Fetching news specifically for date: $date (used by Calendar?)");
    return await _newsApi.getNewsByDate(date);
  }

  // Helper method to reset filters and fetch first page of top news
  Future<void> resetFiltersAndFetchTopNews() async { // Change return type to Future<void> and add async
    print("Resetting filters and fetching top news...");
    _minPoints = 0;
    _sortOption = SortOption.date;
    _sortOrder = SortOrder.descending;
    // fetchTopNews handles resetting search/date and fetching data
    await fetchTopNews(forceRefresh: true); // Add await here
  }
}