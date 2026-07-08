/// Data model representing a single Flashcard.
/// Holds information such as id, question, answer, category, and favorite status.
class Flashcard {
  final String id;
  final String question;
  final String answer;
  final String category;
  final bool isFavorite;

  const Flashcard({
    required this.id,
    required this.question,
    required this.answer,
    this.category = 'General',
    this.isFavorite = false,
  });

  /// Creates a copy of this Flashcard with the given fields replaced by the new values.
  Flashcard copyWith({
    String? id,
    String? question,
    String? answer,
    String? category,
    bool? isFavorite,
  }) {
    return Flashcard(
      id: id ?? this.id,
      question: question ?? this.question,
      answer: answer ?? this.answer,
      category: category ?? this.category,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}
