import 'package:flutter/material.dart';

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;

  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null || isLoading;
    const radius = 24.0;

    return Opacity(
      opacity: disabled ? 0.6 : 1,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(radius),
        clipBehavior: Clip.antiAlias, // 🔒 keeps highlight inside pill
        child: InkWell(
          onTap: disabled ? null : onPressed,
          borderRadius: BorderRadius.circular(radius),
          splashColor: Colors.white.withOpacity(0.08),
          highlightColor: Colors.white.withOpacity(0.04),
          child: Ink(
            height: 58,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              gradient: const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Color(0xFF2F6F8D), // soft blue
                  Color(0xFF4DA3C7), // soft cyan
                ],
              ),
              boxShadow: [
                // 🌑 Main depth shadow (kept tight)
                BoxShadow(
                  color: Colors.black.withOpacity(0.22),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                  spreadRadius: -6, // 🔑 prevents overflow feel
                ),
                // ✨ Soft cyan glow
                BoxShadow(
                  color: const Color(0xFF4DA3C7).withOpacity(0.12),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                  spreadRadius: -8, // 🔑 keeps glow inside card
                ),
              ],
            ),
            child: Stack(
              children: [
                // 🔹 Top glass highlight
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(radius),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.center,
                        colors: [
                          Colors.white.withOpacity(0.12),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                // 🔹 Inner bottom shadow (depth line)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    height: 2,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(radius),
                      ),
                      color: Colors.black.withOpacity(0.18),
                    ),
                  ),
                ),

                // 🔹 Content
                Center(
                  child: isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFFD6F3FF),
                          ),
                        )
                      : Text(
                          text,
                          style: const TextStyle(
                            color: Color(0xFFD6F3FF),
                            fontSize: 19,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
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
