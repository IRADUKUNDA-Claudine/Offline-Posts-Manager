class Post {
  final int? id;
  final String title;
  final String content;
  final DateTime createdAt;

  Post({
    this.id,
    required this.title,
    required this.content,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Post copyWith({
    int? id,
    String? title,
    String? content,
    DateTime? createdAt,
  }) {
    return Post(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory Post.fromMap(Map<String, dynamic> map) {
    try {
      return Post(
        id: map['id'] as int?,
        title: map['title'] as String? ?? 'Untitled',
        content: map['content'] as String? ?? 'No content',
        createdAt:
            DateTime.tryParse(map['createdAt'] as String? ?? '') ??
            DateTime.now(),
      );
    } catch (e) {
      throw Exception('Invalid post data: $e');
    }
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Validation method
  bool isValid() {
    return title.trim().isNotEmpty && content.trim().isNotEmpty;
  }
}
