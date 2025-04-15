import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/NewsProvider.dart';
import '../widgets/NewsCard.dart';
import '../widgets/Filter.dart'; // Assuming Filter widget exists

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController(); // Add ScrollController
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    final newsProvider = Provider.of<NewsProvider>(context, listen: false);

    // Fetch initial news
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Check if news is already loaded (e.g., returning from another tab)
      if (newsProvider.news.isEmpty) {
         newsProvider.fetchTopNews();
      }
    });

    // Add listener for infinite scrolling
    _scrollController.addListener(_onScroll);
  }

  // Listener for scroll events
  void _onScroll() {
    final newsProvider = Provider.of<NewsProvider>(context, listen: false);
    // Check if near the bottom and more data is available and not already loading
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 && // Trigger slightly before the end
        newsProvider.hasMore &&
        !newsProvider.isLoading &&
        !newsProvider.isLoadingMore) {
      newsProvider.fetchMoreNews();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true, // Focus the field when search icon is tapped
                decoration: InputDecoration(
                  hintText: 'Search news...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Theme.of(context).hintColor),
                ),
                style: TextStyle(color: Theme.of(context).appBarTheme.titleTextStyle?.color ?? Colors.black, fontSize: 18), // Match AppBar style
                onSubmitted: (value) {
                  // Trigger search only if value is not empty
                  if (value.trim().isNotEmpty) {
                     Provider.of<NewsProvider>(context, listen: false)
                      .searchNews(value.trim());
                  } else {
                     // If submitted empty, clear search and show top news
                     _searchController.clear();
                     Provider.of<NewsProvider>(context, listen: false).searchNews('');
                  }
                },
              )
            : const Text('TSG News'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                final wasSearching = _isSearching;
                _isSearching = !_isSearching;
                if (wasSearching && !_isSearching) {
                  // If closing search, clear controller and fetch top news
                  _searchController.clear();
                  Provider.of<NewsProvider>(context, listen: false).searchNews('');
                } else if (_isSearching) {
                   // Optionally clear previous search text when opening search
                   // _searchController.clear();
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              showDialog(
                context: context,
                // Pass the current provider state to the Filter dialog if needed
                builder: (context) => const Filter(),
              );
            },
          ),
          // Keep PopupMenuButton and SortOrder IconButton as they are
          PopupMenuButton<SortOption>(
            icon: const Icon(Icons.sort), // Use a generic sort icon
            tooltip: "Sort By",
            onSelected: (SortOption option) {
              Provider.of<NewsProvider>(context, listen: false).setSortOption(option);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: SortOption.date, // Default sort
                child: Text('Sort by Date'),
              ),
              const PopupMenuItem(
                value: SortOption.points,
                child: Text('Sort by Points'),
              ),
            ],
          ),
          Consumer<NewsProvider>(
            builder: (context, newsProvider, child) {
              return IconButton(
                icon: Icon(
                  newsProvider.sortOrder == SortOrder.ascending
                      ? Icons.arrow_upward
                      : Icons.arrow_downward,
                ),
                tooltip: "Toggle Sort Order",
                onPressed: () {
                  newsProvider.toggleSortOrder();
                },
              );
            },
          ),
        ],
      ),
      body: Consumer<NewsProvider>(
        builder: (context, newsProvider, child) {
          // Show loading indicator only on initial load
          if (newsProvider.isLoading && newsProvider.news.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          // Show error message if initial load failed
          if (newsProvider.currentError != null && newsProvider.news.isEmpty) {
             return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Error: ${newsProvider.currentError}\nPull down to refresh.',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
          }

          // Show "No news found" only after a load attempt (isLoading is false)
          if (!newsProvider.isLoading && newsProvider.news.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  newsProvider.searchQuery.isNotEmpty
                      ? 'No news found for "${newsProvider.searchQuery}".'
                      : newsProvider.startDate != null || newsProvider.endDate != null
                          ? 'No news found for the selected date range.'
                          : 'No news found. Pull down to refresh.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final newsList = newsProvider.news;
          // Calculate item count for ListView: add 1 for loading indicator if needed
          final itemCount = newsList.length + (newsProvider.isLoadingMore ? 1 : 0);

          return RefreshIndicator(
            // Use the reset method for pull-to-refresh
            onRefresh: () => newsProvider.resetFiltersAndFetchTopNews(),
            child: ListView.builder(
              controller: _scrollController, // Attach the controller
              itemCount: itemCount,
              itemBuilder: (context, index) {
                // If it's the last item and we are loading more, show indicator
                if (index == newsList.length && newsProvider.isLoadingMore) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                // Otherwise, show the NewsCard
                // Check index bounds just in case
                if (index < newsList.length) {
                   return NewsCard(news: newsList[index]);
                }
                return const SizedBox.shrink(); // Should not happen with correct itemCount
              },
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.removeListener(_onScroll); // Remove listener
    _scrollController.dispose(); // Dispose controller
    super.dispose();
  }
}