import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class GlowingButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final bool compact;
  final bool outlined;
  final IconData? icon;

  const GlowingButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.compact = false,
    this.outlined = false,
    this.icon,
  });

  @override
  State<GlowingButton> createState() => _GlowingButtonState();
}

class _GlowingButtonState extends State<GlowingButton>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) {
          _controller.reverse();
          widget.onPressed();
        },
        onTapCancel: () => _controller.reverse(),
        child: ScaleTransition(
          scale: _scaleAnim,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(
              horizontal: widget.compact ? 16 : 24,
              vertical: widget.compact ? 10 : 14,
            ),
            decoration: BoxDecoration(
              gradient: widget.outlined
                  ? null
                  : (_hovered
                  ? const LinearGradient(
                colors: [Color(0xFF00C8F0), Color(0xFF90E0EF)],
              )
                  : AppColors.primaryGradient),
              border: widget.outlined
                  ? Border.all(
                color: _hovered
                    ? AppColors.primary
                    : AppColors.primary.withOpacity(0.5),
                width: 1.5,
              )
                  : null,
              borderRadius: BorderRadius.circular(50),
              boxShadow: widget.outlined
                  ? null
                  : [
                BoxShadow(
                  color: AppColors.primary
                      .withOpacity(_hovered ? 0.5 : 0.25),
                  blurRadius: _hovered ? 20 : 10,
                  spreadRadius: _hovered ? 2 : 0,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.icon != null) ...[
                  Icon(
                    widget.icon,
                    color: widget.outlined
                        ? AppColors.primary
                        : Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: widget.compact ? 13 : 15,
                      fontWeight: FontWeight.w600,
                      color:
                          widget.outlined ? AppColors.primary : Colors.white,
                      letterSpacing: 0.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}