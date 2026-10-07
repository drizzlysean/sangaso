import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Returns true when running in a wide browser window (web desktop)
bool isWideScreen(BuildContext context) =>
    kIsWeb && MediaQuery.of(context).size.width > 860;

/// Max content width for web — keeps content readable on large screens
const double kWebMaxWidth = 960.0;

/// Wraps content in a centered column on web, passes through on mobile
class WebConstrained extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  const WebConstrained({super.key, required this.child, this.maxWidth = kWebMaxWidth});

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) return child;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
