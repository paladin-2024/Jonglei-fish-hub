import 'package:flutter/material.dart';

class InteractiveRating extends StatefulWidget {
  final void Function(int stars) onRated;
  const InteractiveRating({super.key, required this.onRated});
  @override State<InteractiveRating> createState() => _InteractiveRatingState();
}

class _InteractiveRatingState extends State<InteractiveRating> {
  int _selected = 0;
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) => GestureDetector(
        onTap: () { setState(() => _selected = i + 1); widget.onRated(i + 1); },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Icon(
            i < _selected ? Icons.star_rounded : Icons.star_outline_rounded,
            size: 32,
            color: const Color(0xFFF59E0B),
          ),
        ),
      )),
    );
  }
}
