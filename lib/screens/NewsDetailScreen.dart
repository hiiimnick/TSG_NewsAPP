import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:html_unescape/html_unescape.dart';
import '../providers/NewsProvider.dart';
import '../providers/FavoritesProvider.dart';
import '../classes/NewsModel.dart';

class NewsDetailScreen extends StatefulWidget {
  final String newsId; // Pass the ID to fetch details
  final NewsModel? initialNews; // Optional: Pass initial data to display while loading

  const NewsDetailScreen({
    super.key,
    required this.newsId,
    this.initialNews,
  });

  @override
  State<NewsDetailScreen> createState() => _NewsDetailScreenState();
}

class _NewsDetailScreenState extends State<NewsDetailScreen> {
  late Future<Map<String, dynamic>> _detailsFuture;
  final HtmlUnescape _unescape = HtmlUnescape();
  static const int _maxInitialComments = 4; // Max comments to show initially

  @override
  void initState() {
    super.initState();
    // Fetch details when the screen initializes
    _detailsFuture = Provider.of<NewsProvider>(context, listen: false)
        .getNewsDetails(widget.newsId);
  }

  // Helper function to launch URL
  Future<void> _launchUrl(Uri url) async {
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      // Optionally show an error message if launching fails
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch $url')),
        );
      }
      print('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use the initialNews data for title/basic info immediately if available
    final displayTitle = widget.initialNews?.title ?? 'Loading...';
    final displayUrl = widget.initialNews?.url;
    final displayPoints = widget.initialNews?.points;
    final displayAuthor = widget.initialNews?.author;
    final displayTime = widget.initialNews?.createdAt;
    final displayCommentCount = widget.initialNews?.commentsCount;

    // Construct the Hacker News item URL
    final hnItemUrl = Uri.parse('https://news.ycombinator.com/item?id=${widget.newsId}');

    return Scaffold(
      appBar: AppBar(
        actions: [
          // Keep favorite toggle if needed
          if (widget.initialNews != null)
            Consumer<FavoritesProvider>(
              builder: (context, favoritesProvider, child) {
                // Pass the ID string instead of the whole object
                final isFavorite = favoritesProvider.isFavorite(widget.initialNews!.id);
                return IconButton(
                  icon: Icon(isFavorite ? Icons.star : Icons.star_border),
                  tooltip: isFavorite ? 'Remove from Favorites' : 'Add to Favorites',
                  onPressed: () {
                    // toggleFavorite likely also needs the ID or the full object,
                    // ensure it matches what FavoritesProvider expects.
                    // Assuming toggleFavorite expects the full object based on previous context:
                    favoritesProvider.toggleFavorite(widget.initialNews!);
                  },
                );
              },
            ),
          // Action to open original HN link
          IconButton(
            icon: const Icon(Icons.open_in_browser),
            tooltip: 'Open HN Comments',
            onPressed: () => _launchUrl(hnItemUrl),
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _detailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Show basic info from initialNews while loading full details
            return _buildContent(
              context: context,
              title: displayTitle,
              url: displayUrl,
              points: displayPoints,
              author: displayAuthor,
              time: displayTime,
              commentCount: displayCommentCount,
              comments: [], // No comments yet
              isLoading: true,
              hnItemUrl: hnItemUrl,
            );
          } else if (snapshot.hasError) {
            return Center(child: Text('Error loading details: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('No details found.'));
          }

          // Details loaded successfully
          final details = snapshot.data!;
          final List<dynamic> allComments = details['children'] ?? [];

          // Extract necessary details (adjust keys based on API response)
          final loadedTitle = _unescape.convert(details['title'] ?? displayTitle);
          final loadedUrl = details['url'] ?? displayUrl;
          final loadedPoints = details['points'] ?? displayPoints;
          final loadedAuthor = details['author'] ?? displayAuthor;
          final loadedTime = details['created_at_i'] != null
              ? DateTime.fromMillisecondsSinceEpoch(details['created_at_i'] * 1000)
              : displayTime;
          final loadedCommentCount = details['children']?.length ?? displayCommentCount ?? 0; // Use actual children count

          return _buildContent(
            context: context,
            title: loadedTitle,
            url: loadedUrl,
            points: loadedPoints,
            author: loadedAuthor,
            time: loadedTime,
            commentCount: loadedCommentCount,
            comments: allComments, // Pass all comments
            isLoading: false,
            hnItemUrl: hnItemUrl,
          );
        },
      ),
    );
  }

  // Extracted content building logic
  Widget _buildContent({
    required BuildContext context,
    required String title,
    required String? url,
    required int? points,
    required String? author,
    required DateTime? time,
    required int? commentCount,
    required List<dynamic> comments, // Receive all comments
    required bool isLoading,
    required Uri hnItemUrl,
  }) {
    // Determine how many comments to actually display initially
    final commentsToShow = comments.take(_maxInitialComments).toList();
    final bool hasMoreComments = comments.length > _maxInitialComments;

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // --- Story Info ---
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        if (url != null)
          InkWell(
            onTap: () => _launchUrl(Uri.parse(url)),
            child: Text(
              url,
              style: TextStyle(color: Theme.of(context).colorScheme.primary, decoration: TextDecoration.underline),
            ),
          ),
        const SizedBox(height: 8),
        Text(
          '${points ?? '?'} points by ${author ?? 'unknown'} | ${time != null ? DateFormat.yMd().add_jm().format(time.toLocal()) : '?'} | ${commentCount ?? '?'} comments',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const Divider(height: 32),

        // --- Comments Section ---
        Text('Comments', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 16),

        if (isLoading && comments.isEmpty)
          const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator()))
        else if (!isLoading && comments.isEmpty)
          const Center(child: Padding(padding: EdgeInsets.all(16.0), child: Text('No comments yet.')))
        else
          // Build the limited list of comments
          ListView.builder(
            shrinkWrap: true, // Important inside another ListView
            physics: const NeverScrollableScrollPhysics(), // Disable scrolling for this inner list
            itemCount: commentsToShow.length,
            itemBuilder: (context, index) {
              final comment = commentsToShow[index];
              // *** Replace this with your actual Comment Widget ***
              // You'll need to parse the 'comment' map and pass data to your widget
              return _buildCommentPlaceholder(comment);
            },
          ),

        // --- Show More Button ---
        if (hasMoreComments)
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.open_in_browser),
                label: Text('Show All ${comments.length} Comments on HN'),
                onPressed: () => _launchUrl(hnItemUrl),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCommentPlaceholder(Map<String, dynamic> commentData) {
    final String? text = commentData['text'];
    final String? author = commentData['author'];
    final DateTime? time = commentData['created_at_i'] != null
        ? DateTime.fromMillisecondsSinceEpoch(commentData['created_at_i'] * 1000)
        : null;
    final int depth = commentData['depth'] ?? 0; // Assuming API provides depth for indentation

    if (text == null || text.isEmpty) {
      return const SizedBox.shrink(); // Skip empty comments
    }

    return Card(
      margin: EdgeInsets.only(left: depth * 16.0, top: 4, bottom: 4), // Basic indentation
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _unescape.convert(text), // Unescape HTML entities
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'by ${author ?? 'unknown'} | ${time != null ? DateFormat.yMd().add_jm().format(time.toLocal()) : '?'}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}