import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../models/app_models.dart';
import '../services/customer_api_service.dart';

class FavoriteButton extends StatefulWidget {
  final FlourMill mill;
  final double size;
  final double iconSize;
  final Function(bool isFav)? onChanged;

  const FavoriteButton({
    super.key,
    required this.mill,
    this.size = 36.0,
    this.iconSize = 18.0,
    this.onChanged,
  });

  @override
  State<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late bool _isFavorite;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _isFavorite = MockData.isFavorite(widget.mill.id);
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(covariant FavoriteButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    final current = MockData.isFavorite(widget.mill.id);
    if (current != _isFavorite) {
      setState(() => _isFavorite = current);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _toggleFavorite() async {
    if (_isProcessing) return;
    _isProcessing = true;

    final wasFavorite = _isFavorite;
    final nextFavorite = !wasFavorite;

    // Smooth local UI update & bounce animation
    _controller.forward(from: 0.0);
    setState(() {
      _isFavorite = nextFavorite;
      MockData.toggleFavorite(widget.mill.id);
    });

    if (widget.onChanged != null) {
      widget.onChanged!(nextFavorite);
    }

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          nextFavorite
              ? '❤️ ${widget.mill.name} saved to favorites'
              : '💔 ${widget.mill.name} removed from favorites',
          style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: nextFavorite ? AppTheme.primaryTerracotta : Colors.grey[800],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );

    try {
      if (wasFavorite) {
        await CustomerApiService.instance.removeFavorite(widget.mill.id);
      } else {
        await CustomerApiService.instance.addFavorite(widget.mill.id);
      }
    } catch (e) {
      debugPrint('Favorite API error: $e');
    } finally {
      _isProcessing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFav = MockData.isFavorite(widget.mill.id);

    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTap: _toggleFavorite,
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Icon(
              isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: isFav ? AppTheme.primaryTerracotta : AppTheme.textSecondary,
              size: widget.iconSize,
            ),
          ),
        ),
      ),
    );
  }
}
