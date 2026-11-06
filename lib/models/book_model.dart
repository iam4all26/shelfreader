class Book {
  const Book({
    required this.id,
    required this.title,
    required this.pdfPath,
    required this.addedAt,
    this.author = 'Unknown author',
    this.category = 'Other',
    this.shelf = 'My Books',
    this.coverPath,
    this.description = '',
    this.lastPage = 1,
    this.totalPages = 0,
    this.isFavorite = false,
    this.pagesRead = 0,
    this.bookmarks = const <int>[],
  });

  final String id;
  final String title;
  final String pdfPath;
  final DateTime addedAt;
  final String author;
  final String category;
  final String shelf;
  final String? coverPath;
  final String description;
  final int lastPage;
  final int totalPages;
  final bool isFavorite;
  final int pagesRead;
  final List<int> bookmarks;

  double get progress => totalPages <= 0 ? 0 : (lastPage / totalPages).clamp(0, 1);

  Book copyWith({
    String? title, String? author, String? category, String? shelf,
    String? coverPath, bool clearCover = false, String? description,
    int? lastPage, int? totalPages, bool? isFavorite, int? pagesRead,
    List<int>? bookmarks,
  }) => Book(
    id: id, title: title ?? this.title, pdfPath: pdfPath, addedAt: addedAt,
    author: author ?? this.author, category: category ?? this.category,
    shelf: shelf ?? this.shelf,
    coverPath: clearCover ? null : (coverPath ?? this.coverPath),
    description: description ?? this.description,
    lastPage: lastPage ?? this.lastPage, totalPages: totalPages ?? this.totalPages,
    isFavorite: isFavorite ?? this.isFavorite, pagesRead: pagesRead ?? this.pagesRead,
    bookmarks: bookmarks ?? this.bookmarks,
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id, 'title': title, 'pdfPath': pdfPath, 'addedAt': addedAt.toIso8601String(),
    'author': author, 'category': category, 'shelf': shelf, 'coverPath': coverPath,
    'description': description, 'lastPage': lastPage, 'totalPages': totalPages,
    'isFavorite': isFavorite, 'pagesRead': pagesRead, 'bookmarks': bookmarks,
  };

  factory Book.fromJson(Map<String, dynamic> json) => Book(
    id: json['id'] as String,
    title: json['title'] as String? ?? 'Untitled',
    pdfPath: json['pdfPath'] as String,
    addedAt: DateTime.tryParse(json['addedAt'] as String? ?? '') ?? DateTime.now(),
    author: json['author'] as String? ?? 'Unknown author',
    category: json['category'] as String? ?? 'Other',
    shelf: json['shelf'] as String? ?? 'My Books',
    coverPath: json['coverPath'] as String?,
    description: json['description'] as String? ?? '',
    lastPage: json['lastPage'] as int? ?? 1,
    totalPages: json['totalPages'] as int? ?? 0,
    isFavorite: json['isFavorite'] as bool? ?? false,
    pagesRead: json['pagesRead'] as int? ?? 0,
    bookmarks: (json['bookmarks'] as List<dynamic>? ?? <dynamic>[]).whereType<int>().toList(),
  );
}
