import 'package:flutter/material.dart';

class BotonAnadir extends StatelessWidget {
  final VoidCallback onPressed;
  final String tooltip;

  const BotonAnadir({
    super.key,
    required this.onPressed,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onPressed,
      tooltip: tooltip,
      backgroundColor: const Color(0xFF1B263B),
      foregroundColor: Colors.white,
      child: const Icon(Icons.add),
    );
  }
}
