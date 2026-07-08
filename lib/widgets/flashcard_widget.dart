import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/flashcard.dart';
import '../providers/flashcard_provider.dart';

/// A reusable, highly interactive 3D Flip Flashcard Widget.
/// Uses Transform matrix to simulate a 3D flip animation when tapped.
class FlashcardWidget extends ConsumerStatefulWidget {
  final Flashcard flashcard;

  const FlashcardWidget({
    super.key,
    required this.flashcard,
  });

  @override
  ConsumerState<FlashcardWidget> createState() => _FlashcardWidgetState();
}

class _FlashcardWidgetState extends ConsumerState<FlashcardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isFront = true;

  @override
  void initState() {
    super.initState();
    // Animation controller for the 3D flip effect
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    // Map the animation from 0 (front) to pi (back)
    _animation = Tween<double>(begin: 0.0, end: pi).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOutBack,
      ),
    );
  }

  @override
  void didUpdateWidget(covariant FlashcardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the card changes, automatically flip it back to the front
    if (oldWidget.flashcard.id != widget.flashcard.id) {
      _controller.reverse();
      _isFront = true;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Toggles the card flip state
  void _flipCard() {
    if (_isFront) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
    setState(() {
      _isFront = !_isFront;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: GestureDetector(
        onTap: _flipCard,
        behavior: HitTestBehavior.opaque,
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            final double value = _animation.value;
            final bool isFrontSide = value < pi / 2;

            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0012) // 3D Perspective
                ..rotateY(value),
              child: isFrontSide
                  ? _buildCardSide(
                      isFront: true,
                      content: widget.flashcard.question,
                      label: 'QUESTION',
                      category: widget.flashcard.category,
                      gradientColors: isDark
                          ? [const Color(0xFF2E1A47), const Color(0xFF1A1F3B)]
                          : [Colors.deepPurple.shade50, Colors.indigo.shade50],
                      textColor: isDark ? Colors.white : Colors.indigo.shade900,
                      isFavorite: widget.flashcard.isFavorite,
                    )
                  : Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()..rotateY(pi), // Avoid mirroring
                      child: _buildCardSide(
                        isFront: false,
                        content: widget.flashcard.answer,
                        label: 'ANSWER',
                        category: widget.flashcard.category,
                        gradientColors: isDark
                            ? [const Color(0xFF0F2C2A), const Color(0xFF1E1E2F)]
                            : [Colors.teal.shade50, Colors.blue.shade50],
                        textColor: isDark ? Colors.white : Colors.teal.shade900,
                        isFavorite: widget.flashcard.isFavorite,
                      ),
                    ),
            );
          },
        ),
      ),
    );
  }

  /// Builds a card side (either Front or Back) with a shared aesthetic.
  Widget _buildCardSide({
    required bool isFront,
    required String content,
    required String label,
    required String category,
    required List<Color> gradientColors,
    required Color textColor,
    required bool isFavorite,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      height: 380,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.indigo.withValues(alpha: 0.08),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.4)
                : Colors.indigo.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: isDark
                ? Colors.black26
                : Colors.deepPurple.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            // Background design elements (subtle soft circular gradient)
            Positioned(
              right: -30,
              top: -30,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (isFront ? Colors.deepPurple : Colors.teal)
                      .withValues(alpha: 0.06),
                ),
              ),
            ),
            Positioned(
              left: -40,
              bottom: -40,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (isFront ? Colors.indigo : Colors.blue)
                      .withValues(alpha: 0.06),
                ),
              ),
            ),

            // Main Content Layout
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Row: Category Pill & Favorite Toggle Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: isDark
                                ? Colors.white12
                                : Colors.indigo.withValues(alpha: 0.1),
                          ),
                          boxShadow: [
                            if (!isDark)
                              BoxShadow(
                                color: Colors.indigo.withValues(alpha: 0.02),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              )
                          ],
                        ),
                        child: Text(
                          category.toUpperCase(),
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                            color: isFront
                                ? (isDark ? Colors.deepPurple.shade300 : Colors.deepPurple.shade700)
                                : (isDark ? Colors.teal.shade300 : Colors.teal.shade700),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          // Stop propagation of gesture detection
                          ref.read(flashcardsProvider.notifier).toggleFavorite(widget.flashcard.id);
                        },
                        icon: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border_rounded,
                          color: isFavorite
                              ? Colors.red.shade400
                              : (isDark ? Colors.white38 : Colors.black38),
                        ),
                        splashRadius: 24,
                      ),
                    ],
                  ),

                  const Spacer(),

                  // Center Content (Question / Answer)
                  Center(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Small Label (QUESTION / ANSWER)
                          Text(
                            label,
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2.0,
                              color: isDark ? Colors.white38 : Colors.black38,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Primary Text Content
                          Text(
                            content,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              fontSize: isFront ? 22 : 18,
                              fontWeight: isFront ? FontWeight.w700 : FontWeight.w500,
                              height: 1.4,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Bottom Prompt
                  Align(
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.flip_camera_android_rounded,
                          size: 14,
                          color: isDark ? Colors.white30 : Colors.black38,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isFront ? 'TAP TO SHOW ANSWER' : 'TAP TO SHOW QUESTION',
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                            color: isDark ? Colors.white30 : Colors.black38,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
