class NewsModel {
  final String id;
  final String title;
  final String author;
  final DateTime createdAt;
  final int points;
  final int commentsCount;
  final String url;

  NewsModel({
    required this.id,
    required this.title,
    required this.author,
    required this.createdAt,
    required this.points,
    required this.commentsCount,
    required this.url,
  });

  factory NewsModel.fromJson(Map<String, dynamic> json) {
  // Debug the incoming JSON for title issues
  print("Parsing news item ID: ${json['objectID']}");
  if (json['title'] == null) {
    print("Title is null, checking alternative fields: story_title: ${json['story_title']}");
  }

  // Try multiple possible title fields
  String title = json['title'] ?? json['story_title'] ?? '';
  
  // If still no title, extract from other fields or set default
  if (title.isEmpty && json['url'] != null) {
    // Try to extract a title from the URL
    Uri uri = Uri.parse(json['url']);
    title = uri.host;
  }
  
  if (title.isEmpty) {
    title = 'No title available';
  }
  
  return NewsModel(
    id: json['objectID'] ?? '',
    title: title,
    url: json['url'] ?? json['story_url'] ?? '',
    author: json['author'] ?? '',
    points: json['points'] != null ? int.tryParse(json['points'].toString()) ?? 0 : 0,
    commentsCount: json['num_comments'] != null ? int.tryParse(json['num_comments'].toString()) ?? 0 : 0,
    createdAt: json['created_at'] != null 
      ? DateTime.parse(json['created_at']) 
      : (json['created_at_i'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['created_at_i'] * 1000) 
          : DateTime.now()),
  );
}

  Map<String, dynamic> toJson() {
    return {
      'objectID': id,
      'title': title,
      'author': author,
      'created_at_i': createdAt.millisecondsSinceEpoch ~/ 1000,
      'points': points,
      'num_comments': commentsCount,
      'url': url,
    };
  }
}