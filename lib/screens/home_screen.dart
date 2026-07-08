import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/flashcard.dart';
import '../providers/flashcard_provider.dart';
import '../widgets/flashcard_widget.dart';

/// Notifier to manage ThemeMode.
class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    return ThemeMode.system;
  }

  void toggleTheme() {
    state = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
  }
}

/// Provider for ThemeMode.
final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(() {
  return ThemeModeNotifier();
});

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Watch providers
    final allCards = ref.watch(flashcardsProvider);
    final filteredCardIds = ref.watch(filteredFlashcardsProvider);
    final activeIndex = ref.watch(currentCardIndexProvider);
    final selectedFilter = ref.watch(selectedFilterCategoryProvider);
    final categories = ref.watch(categoriesProvider);

    final totalFiltered = filteredCardIds.length;

    // Safety checks for indices out of bounds (e.g., if card filter changed or card was deleted)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (totalFiltered > 0 && activeIndex >= totalFiltered) {
        ref.read(currentCardIndexProvider.notifier).setIndex(totalFiltered - 1);
      }
    });

    // Resolve the active card object
    Flashcard? activeCard;
    if (totalFiltered > 0 && activeIndex < totalFiltered) {
      final activeId = filteredCardIds[activeIndex];
      activeCard = allCards.firstWhere((c) => c.id == activeId);
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F12) : Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? Colors.deepPurple.shade900.withValues(alpha: 0.5) : Colors.deepPurple.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.bolt_rounded,
                color: isDark ? Colors.deepPurple.shade300 : Colors.deepPurple,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'MemoSpark',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: isDark ? Colors.white : Colors.grey.shade900,
              ),
            ),
          ],
        ),
        actions: [
          // Theme Toggle
          IconButton(
            onPressed: () {
              ref.read(themeModeProvider.notifier).toggleTheme();
            },
            icon: Icon(
              ref.watch(themeModeProvider) == ThemeMode.dark
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
              color: isDark ? Colors.yellow.shade400 : Colors.grey.shade700,
            ),
            tooltip: 'Toggle Theme',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),

            // Horizontal List of Category Filters
            _buildCategorySelector(context, ref, categories, selectedFilter),

            const SizedBox(height: 16),

            // Main body area (Card & Actions or Empty State)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: totalFiltered == 0
                    ? _buildEmptyState(context, ref, selectedFilter)
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Progress Bar & Info Row
                          _buildProgressBar(context, activeIndex, totalFiltered),
                          const SizedBox(height: 12),

                          // Card actions (Edit, Delete, Card position indicator)
                          if (activeCard != null)
                            _buildCardActionBar(context, ref, activeIndex, totalFiltered, activeCard),

                          const SizedBox(height: 12),

                          // Flashcard Widget
                          if (activeCard != null)
                            Expanded(
                              child: FlashcardWidget(
                                key: ValueKey(activeCard.id), // Forces state reset on flip when navigation occurs
                                flashcard: activeCard,
                              ),
                            ),

                          const SizedBox(height: 24),

                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: totalFiltered == 0
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(left: 24.0, right: 24.0, bottom: 20.0, top: 8.0),
                child: _buildNavigationControls(context, ref, activeIndex, totalFiltered),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditCardDialog(context, ref),
        label: Text(
          'Add Card',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
        icon: const Icon(Icons.add_rounded),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
    );
  }

  /// Builds the horizontal category filter chip bar.
  Widget _buildCategorySelector(
    BuildContext context,
    WidgetRef ref,
    List<String> categories,
    String selectedFilter,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = category == selectedFilter;

          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(
                category,
                style: GoogleFonts.outfit(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 13,
                  color: isSelected
                      ? Colors.white
                      : (isDark ? Colors.grey.shade400 : Colors.grey.shade700),
                ),
              ),
              selected: isSelected,
              selectedColor: Colors.deepPurple,
              backgroundColor: isDark ? Colors.grey.shade900 : Colors.white,
              checkmarkColor: Colors.white,
              elevation: isSelected ? 2 : 0,
              side: BorderSide(
                color: isSelected
                    ? Colors.transparent
                    : (isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                width: 1,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              onSelected: (selected) {
                if (selected) {
                  ref.read(selectedFilterCategoryProvider.notifier).setCategory(category);
                  ref.read(currentCardIndexProvider.notifier).setIndex(0); // Reset index on filter change
                }
              },
            ),
          );
        },
      ),
    );
  }

  /// Builds a progress bar depicting overall completion.
  Widget _buildProgressBar(BuildContext context, int activeIndex, int totalFiltered) {
    final progress = (activeIndex + 1) / totalFiltered;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'PROGRESS',
              style: GoogleFonts.outfit(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white38 : Colors.black38,
                letterSpacing: 1.0,
              ),
            ),
            Text(
              '${(progress * 100).toInt()}% Done',
              style: GoogleFonts.outfit(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: isDark ? Colors.grey.shade900 : Colors.grey.shade200,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.deepPurple),
          ),
        ),
      ],
    );
  }

  /// Action bar shown right above the card containing index info and CRUD controls.
  Widget _buildCardActionBar(
    BuildContext context,
    WidgetRef ref,
    int activeIndex,
    int totalFiltered,
    Flashcard activeCard,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Card ${activeIndex + 1} of $totalFiltered',
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
          ),
        ),
        Row(
          children: [
            // Edit Card Button
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              color: isDark ? Colors.white70 : Colors.black87,
              tooltip: 'Edit Card',
              onPressed: () => _showAddEditCardDialog(context, ref, activeCard),
              splashRadius: 20,
            ),
            // Delete Card Button
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              color: Colors.red.shade400,
              tooltip: 'Delete Card',
              onPressed: () => _confirmDeleteCard(context, ref, activeCard.id),
              splashRadius: 20,
            ),
          ],
        ),
      ],
    );
  }

  /// Navigation buttons (Previous & Next) with boundary logic.
  Widget _buildNavigationControls(
    BuildContext context,
    WidgetRef ref,
    int activeIndex,
    int totalFiltered,
  ) {
    final isFirst = activeIndex == 0;
    final isLast = activeIndex == totalFiltered - 1;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Previous Button
        OutlinedButton.icon(
          onPressed: isFirst
              ? null
              : () {
                  ref.read(currentCardIndexProvider.notifier).setIndex(activeIndex - 1);
                },
          icon: const Icon(Icons.arrow_back_rounded),
          label: Text(
            'Previous',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          ),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            side: BorderSide(
              color: isFirst ? Colors.transparent : Colors.deepPurple.withValues(alpha: 0.3),
            ),
          ),
        ),
        // Next Button
        ElevatedButton.icon(
          onPressed: isLast
              ? null
              : () {
                  ref.read(currentCardIndexProvider.notifier).setIndex(activeIndex + 1);
                },
          icon: const Icon(Icons.arrow_forward_rounded),
          label: Text(
            'Next',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey.withValues(alpha: 0.12),
            disabledForegroundColor: Colors.grey.withValues(alpha: 0.38),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ],
    );
  }

  /// Renders a beautiful empty state if no flashcards match the active filter.
  Widget _buildEmptyState(BuildContext context, WidgetRef ref, String selectedFilter) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    String titleText = 'No Flashcards Found';
    String descriptionText = 'Start studying by adding a new card to your deck!';
    IconData icon = Icons.style_outlined;

    if (selectedFilter == 'Favorites') {
      titleText = 'No Favorites Yet';
      descriptionText = 'Tap the heart icon on any card to add it to your favorite deck.';
      icon = Icons.favorite_border_rounded;
    } else if (selectedFilter != 'All') {
      titleText = 'Empty Category';
      descriptionText = 'There are no flashcards in the "$selectedFilter" category.';
      icon = Icons.folder_open_rounded;
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey.shade900 : Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Icon(
            icon,
            size: 64,
            color: Colors.deepPurple.shade300,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          titleText,
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Text(
            descriptionText,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 24),
        if (selectedFilter != 'All')
          TextButton(
            onPressed: () {
              ref.read(selectedFilterCategoryProvider.notifier).setCategory('All');
              ref.read(currentCardIndexProvider.notifier).setIndex(0);
            },
            child: Text(
              'Show All Cards',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.deepPurple),
            ),
          )
      ],
    );
  }

  /// Triggers dialog popup for adding a new card or editing an existing card.
  void _showAddEditCardDialog(BuildContext context, WidgetRef ref, [Flashcard? cardToEdit]) {
    final formKey = GlobalKey<FormState>();
    final isEdit = cardToEdit != null;

    final questionController = TextEditingController(text: cardToEdit?.question ?? '');
    final answerController = TextEditingController(text: cardToEdit?.answer ?? '');
    final categoryController = TextEditingController(text: cardToEdit?.category ?? '');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            isEdit ? 'Edit Flashcard' : 'Create Flashcard',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Question Field
                  TextFormField(
                    controller: questionController,
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                    style: GoogleFonts.outfit(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Question',
                      labelStyle: GoogleFonts.outfit(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Question is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // Answer Field
                  TextFormField(
                    controller: answerController,
                    maxLines: 4,
                    textCapitalization: TextCapitalization.sentences,
                    style: GoogleFonts.outfit(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Answer',
                      labelStyle: GoogleFonts.outfit(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Answer is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // Category Field
                  TextFormField(
                    controller: categoryController,
                    textCapitalization: TextCapitalization.words,
                    style: GoogleFonts.outfit(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Category (Optional)',
                      labelStyle: GoogleFonts.outfit(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                      hintText: 'e.g. History, Math, Flutter',
                      hintStyle: GoogleFonts.outfit(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final q = questionController.text;
                  final a = answerController.text;
                  final c = categoryController.text.isEmpty ? 'General' : categoryController.text;

                  if (isEdit) {
                    ref.read(flashcardsProvider.notifier).updateCard(cardToEdit.id, q, a, c);
                  } else {
                    ref.read(flashcardsProvider.notifier).addCard(q, a, c);
                  }
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isEdit ? 'Card updated successfully' : 'Card added successfully',
                        style: GoogleFonts.outfit(),
                      ),
                      backgroundColor: Colors.deepPurple,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: Text(
                isEdit ? 'Save Changes' : 'Create Card',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Triggers confirmation alert dialog before deleting a card.
  void _confirmDeleteCard(BuildContext context, WidgetRef ref, String cardId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Delete Card',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          content: Text(
            'Are you sure you want to permanently delete this flashcard?',
            style: GoogleFonts.outfit(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: () {
                final filteredIds = ref.read(filteredFlashcardsProvider);
                final index = ref.read(currentCardIndexProvider);

                ref.read(flashcardsProvider.notifier).deleteCard(cardId);

                // Adjust index safely
                final newLength = filteredIds.length - 1;
                if (newLength <= 0) {
                  ref.read(currentCardIndexProvider.notifier).setIndex(0);
                } else if (index >= newLength) {
                  ref.read(currentCardIndexProvider.notifier).setIndex(newLength - 1);
                }

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Card deleted successfully', style: GoogleFonts.outfit()),
                    backgroundColor: Colors.red.shade400,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              },
              child: Text(
                'Delete',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.red.shade400),
              ),
            ),
          ],
        );
      },
    );
  }
}
