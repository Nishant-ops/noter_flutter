class Note {
  final String id;
  final String rawText;

  Note({required this.id, required this.rawText});

  // Add copyWith method
  Note copyWith({
    String? id,
    String? rawText,
  }) {
    return Note(
      id: id ?? this.id,
      rawText: rawText ?? this.rawText,
    );
  }

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'].toString(),
      rawText: json['rawText'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'rawText': rawText,
    };
  }
} 