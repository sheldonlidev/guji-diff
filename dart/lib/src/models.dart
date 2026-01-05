/// 表示古籍的一个段落
class Paragraph {
  final String id;
  final String content;

  Paragraph({required this.id, required this.content});

  Map<String, dynamic> toJson() => {'id': id, 'content': content};
}

/// 表示古籍的一个章节
class Chapter {
  final String title;
  final List<Paragraph> paragraphs;

  Chapter({required this.title, required this.paragraphs});

  Map<String, dynamic> toJson() => {
    'title': title,
    'paragraphs': paragraphs.map((p) => p.toJson()).toList(),
  };
}

/// 表示完整的古籍文档
class Document {
  final List<Chapter> chapters;

  Document({required this.chapters});

  Map<String, dynamic> toJson() => {
    'chapters': chapters.map((c) => c.toJson()).toList(),
  };
}
