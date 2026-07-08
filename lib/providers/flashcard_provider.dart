import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/flashcard.dart';

// Sample list of starter flashcards to display initially
final List<Flashcard> _starterCards = [
  const Flashcard(
    id: '1',
    question: 'What is Flutter?',
    answer: 'Flutter is Google\'s open-source UI SDK used to build high-performance, cross-platform applications for iOS, Android, Web, and Desktop from a single codebase.',
    category: 'Flutter Basics',
  ),
  const Flashcard(
    id: '2',
    question: 'What is the difference between Hot Reload and Hot Restart?',
    answer: 'Hot Reload injects updated code into the running Dart VM, preserving the application state. Hot Restart destroys the current state, resets the Dart VM, and rebuilds the app from scratch.',
    category: 'Flutter Development',
  ),
  const Flashcard(
    id: '3',
    question: 'What is Riverpod?',
    answer: 'Riverpod is a compile-safe, testable, and reactive state management framework for Flutter. It is a complete rewrite of the Provider package that doesn\'t depend on the Flutter widget tree.',
    category: 'State Management',
  ),
  const Flashcard(
    id: '4',
    question: 'What are Keys in Flutter and when should you use them?',
    answer: 'Keys preserve widget state when they move around in the widget tree. They are essential when modifying collections of stateful widgets (like reordering, adding, or deleting items in a list).',
    category: 'Flutter Architecture',
  ),
  const Flashcard(
    id: '5',
    question: 'Why is Dart used in Flutter?',
    answer: 'Dart supports both Just-In-Time (JIT) compilation for fast development (Hot Reload) and Ahead-Of-Time (AOT) compilation for native, high-performance production builds.',
    category: 'Dart Programming',
  ),
];

/// A Notifier that manages the list of flashcards.
class FlashcardNotifier extends Notifier<List<Flashcard>> {
  @override
  List<Flashcard> build() {
    return _starterCards;
  }

  /// Adds a new flashcard to the list.
  void addCard(String question, String answer, String category) {
    final newCard = Flashcard(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      question: question.trim(),
      answer: answer.trim(),
      category: category.trim().isEmpty ? 'General' : category.trim(),
    );
    state = [...state, newCard];
  }

  /// Updates an existing flashcard by ID.
  void updateCard(String id, String question, String answer, String category) {
    state = [
      for (final card in state)
        if (card.id == id)
          card.copyWith(
            question: question.trim(),
            answer: answer.trim(),
            category: category.trim().isEmpty ? 'General' : category.trim(),
          )
        else
          card
    ];
  }

  /// Deletes a flashcard by ID.
  void deleteCard(String id) {
    state = state.where((card) => card.id != id).toList();
  }

  /// Toggles the favorite status of a card by ID.
  void toggleFavorite(String id) {
    state = [
      for (final card in state)
        if (card.id == id) card.copyWith(isFavorite: !card.isFavorite) else card
    ];
  }
}

/// Notifier to track the current active card index.
class CurrentCardIndexNotifier extends Notifier<int> {
  @override
  int build() {
    return 0;
  }

  void setIndex(int newIndex) {
    state = newIndex;
  }
}

/// Notifier for the selected filter category (e.g. 'All', 'Favorites', or specific categories).
class SelectedFilterCategoryNotifier extends Notifier<String> {
  @override
  String build() {
    return 'All';
  }

  void setCategory(String category) {
    state = category;
  }
}

/// Provider for the list of flashcards.
final flashcardsProvider = NotifierProvider<FlashcardNotifier, List<Flashcard>>(() {
  return FlashcardNotifier();
});

/// Provider for tracking the current active card index.
final currentCardIndexProvider = NotifierProvider<CurrentCardIndexNotifier, int>(() {
  return CurrentCardIndexNotifier();
});

/// Provider for the selected filter category.
final selectedFilterCategoryProvider = NotifierProvider<SelectedFilterCategoryNotifier, String>(() {
  return SelectedFilterCategoryNotifier();
});

/// Provider that extracts all unique categories from the flashcards.
final categoriesProvider = Provider<List<String>>((ref) {
  final cards = ref.watch(flashcardsProvider);
  final categories = cards.map((c) => c.category).toSet().toList();
  categories.sort();
  return ['All', 'Favorites', ...categories];
});

/// Provider that returns the filtered list of flashcard IDs based on the selected category filter.
final filteredFlashcardsProvider = Provider<List<String>>((ref) {
  final cards = ref.watch(flashcardsProvider);
  final selectedFilter = ref.watch(selectedFilterCategoryProvider);

  if (selectedFilter == 'All') {
    return cards.map((c) => c.id).toList();
  } else if (selectedFilter == 'Favorites') {
    return cards.where((c) => c.isFavorite).map((c) => c.id).toList();
  } else {
    return cards.where((c) => c.category == selectedFilter).map((c) => c.id).toList();
  }
});
