import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:html_unescape/html_unescape.dart'; // Import for HTML unescaping
import '../providers/NewsProvider.dart';
import '../providers/FavoritesProvider.dart';
import '../classes/NewsModel.dart';

class NewsDetailScreen extends StatefulWidget {
  final String newsId;

  const NewsDetailScreen({
    super.key,
    required this.newsId,
  });

  @override
  State<NewsDetailScreen> createState() => _NewsDetailScreenState();
}

class _NewsDetailScreenState extends State<NewsDetailScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _newsDetails = {};
  final dateFormat = DateFormat('MMM dd, yyyy HH:mm');
  int _currentPage = 1; // State for current page
  final int _itemsPerPage = 10; // Items per page
  final _htmlUnescape = HtmlUnescape(); // Instance for HTML unescaping

  @override
  void initState() {
    super.initState();
    _fetchNewsDetails();
  }

  Future<void> _fetchNewsDetails() async {
    // Ensure the widget is still mounted before calling setState
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final details = await Provider.of<NewsProvider>(context, listen: false)
          .getNewsDetails(widget.newsId);
      // Ensure the widget is still mounted before calling setState
      if (mounted) {
        setState(() {
          _newsDetails = details;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading details: $e')),
        );
      }
    } finally {
      // Ensure the widget is still mounted before calling setState
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final favoritesProvider = Provider.of<FavoritesProvider>(context);
    final bool isFavorite = favoritesProvider.isFavorite(widget.newsId);

    // Calculate pagination details
    final List<dynamic> allComments = _newsDetails['children'] ?? [];
    final int totalComments = allComments.length;
    final int totalPages = (totalComments / _itemsPerPage).ceil();

    // Calculate the start and end index for the current page
    final int startIndex = (_currentPage - 1) * _itemsPerPage;
    // Ensure endIndex doesn't exceed the list length
    final int endIndex = (startIndex + _itemsPerPage > totalComments)
        ? totalComments
        : startIndex + _itemsPerPage;

    // Get the comments for the current page, handle potential range errors
    final List<dynamic> currentPageComments = (startIndex < totalComments && startIndex >= 0)
        ? allComments.sublist(startIndex, endIndex)
        : [];


    return Scaffold(
      appBar: AppBar(
        title: Text(_newsDetails['title'] ?? 'Details'), // Show title in AppBar
        actions: [
          // Show favorite button only when details are loaded
          if (!_isLoading && _newsDetails.isNotEmpty)
            IconButton(
              icon: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: isFavorite ? Colors.red : null, // Make filled heart red
              ),
              tooltip: isFavorite ? 'Remove from Favorites' : 'Add to Favorites',
              onPressed: () {
                // Create a NewsModel to pass to the provider
                 final newsItem = NewsModel(
                  id: widget.newsId,
                  title: _newsDetails['title'] ?? '',
                  author: _newsDetails['author'] ?? '',
                  // Handle potential null or incorrect type for created_at_i
                  createdAt: DateTime.fromMillisecondsSinceEpoch(
                      ((_newsDetails['created_at_i'] as num?)?.toInt() ?? 0) * 1000),
                  points: (_newsDetails['points'] as num?)?.toInt() ?? 0,
                  commentsCount: (_newsDetails['children'] as List?)?.length ?? 0,
                  url: _newsDetails['url'] ?? '',
                );
                // Toggle favorite status using the provider
                favoritesProvider.toggleFavorite(newsItem);
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _newsDetails.isEmpty
              ? const Center(child: Text('News details not found'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Display Title (optional, as it's in AppBar)
                      // Text(
                      //   _newsDetails['title'] ?? 'No Title',
                      //   style: Theme.of(context).textTheme.headlineSmall,
                      // ),
                      // const SizedBox(height: 8),

                      // Display Author, Points, Date
                      Row(
                        children: [
                          const Icon(Icons.person_outline, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(_newsDetails['author'] ?? 'Unknown Author'),
                          const SizedBox(width: 16),
                          const Icon(Icons.star_outline, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text('${(_newsDetails['points'] as num?)?.toInt() ?? 0} points'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_newsDetails['created_at_i'] != null)
                         Row(
                           children: [
                             const Icon(Icons.calendar_today_outlined, size: 16, color: Colors.grey),
                             const SizedBox(width: 4),
                             Text(
                               dateFormat.format(DateTime.fromMillisecondsSinceEpoch(
                                   ((_newsDetails['created_at_i'] as num?)?.toInt() ?? 0) * 1000)),
                               style: Theme.of(context).textTheme.bodySmall,
                             ),
                           ],
                         ),
                      const SizedBox(height: 16),

                      // URL Button
                      if (_newsDetails['url'] != null &&
                          _newsDetails['url'].isNotEmpty)
                        ElevatedButton.icon(
                          icon: const Icon(Icons.language),
                          label: const Text('Open Source URL'),
                          onPressed: () async {
                            final Uri url = Uri.parse(_newsDetails['url']);
                            if (await canLaunchUrl(url)) {
                              // Use external application for web links
                              await launchUrl(url, mode: LaunchMode.externalApplication);
                            } else {
                              if (mounted) { // Check if widget is still mounted
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Could not open URL'),
                                  ),
                                );
                              }
                            }
                          },
                        ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),

                      // Comments Section Header
                      Text(
                        'Comments ($totalComments)', // Show total comments
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Build comments for the current page only
                      if (totalComments > 0)
                         ..._buildComments(currentPageComments)
                      else
                         const Text("No comments yet."), // Message if no comments at all

                      const SizedBox(height: 16),

                      // --- Pagination Controls ---
                      if (totalPages > 1)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chevron_left),
                              tooltip: 'Previous Page',
                              // Disable if on the first page
                              onPressed: _currentPage > 1
                                  ? () {
                                      setState(() {
                                        _currentPage--;
                                      });
                                    }
                                  : null,
                            ),
                            Text('Page $_currentPage of $totalPages'),
                            IconButton(
                              icon: const Icon(Icons.chevron_right),
                              tooltip: 'Next Page',
                              // Disable if on the last page
                              onPressed: _currentPage < totalPages
                                  ? () {
                                      setState(() {
                                        _currentPage++;
                                      });
                                    }
                                  : null,
                            ),
                          ],
                        ),
                      // --- End Pagination Controls ---
                    ],
                  ),
                ),
    );
  }

  // Builds the list of comment widgets for the current page
  List<Widget> _buildComments(List<dynamic> comments) {
    // This function receives only the comments for the current page
    if (comments.isEmpty && _currentPage > 1) {
      // This case shouldn't normally happen with correct calculation, but good fallback
      return [const Text('No comments on this page')];
    }
     if (comments.isEmpty && _currentPage == 1) {
       // Handled by the check in the build method
       return [];
     }

    return comments.map((comment) {
      // Safely access comment data, provide defaults
      final textHtml = comment?['text'] as String? ?? '';
      // Unescape HTML entities like &quot;, &lt;, etc.
      final text = _htmlUnescape.convert(textHtml);
      final author = comment?['author'] as String? ?? 'Unknown';
      final createdAtTimestamp = (comment?['created_at_i'] as num?)?.toInt();
      final createdAt = createdAtTimestamp != null
          ? dateFormat.format(DateTime.fromMillisecondsSinceEpoch(createdAtTimestamp * 1000))
          : 'Unknown date';
      final children = (comment?['children'] as List?)?.cast<dynamic>() ?? []; // Ensure correct type

      // Basic check to filter out potentially deleted/empty comments
      if (text.trim().isEmpty && author == 'Unknown') {
         return const SizedBox.shrink(); // Don't display empty/deleted comments
      }

      return Card(
        elevation: 1, // Subtle elevation
        margin: const EdgeInsets.only(bottom: 12.0, left: 4.0, right: 4.0), // Consistent margin
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.person_outline, size: 16, color: Colors.grey[700]),
                  const SizedBox(width: 4),
                  Text(
                    author,
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[800]),
                  ),
                  const Spacer(), // Pushes date to the right
                  Text(
                    createdAt,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Simple rendering of text, removing HTML tags
              // For proper HTML rendering, consider flutter_html package
              Text(
                text.replaceAll(RegExp(r'<[^>]*>'), ''), // Basic HTML tag removal
                style: const TextStyle(height: 1.4), // Improve readability
              ),
              // Recursively build nested comments
              if (children.isNotEmpty) ...[
                const SizedBox(height: 12),
                Padding(
                  // Indent nested comments
                  padding: const EdgeInsets.only(left: 16.0),
                  child: Container(
                     decoration: BoxDecoration(
                       border: Border(
                         left: BorderSide(color: Colors.grey.shade300, width: 2),
                       ),
                     ),
                     child: Padding(
                       padding: const EdgeInsets.only(left: 12.0), // Padding inside the border
                       child: Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: _buildComments(children), // Recursive call
                       ),
                     ),
                  ),
                ),
              ]
            ],
          ),
        ),
      );
    }).toList();
  }
}