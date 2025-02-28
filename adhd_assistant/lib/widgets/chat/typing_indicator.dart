import 'package:flutter/material.dart';

class TypingIndicator extends StatefulWidget {
  const TypingIndicator({Key? key}) : super(key: key);

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 16.0,
        right: 64.0,
        bottom: 8.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 12.0, bottom: 4.0),
            child: Text(
              'AI Assistant',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (index) {
                return AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    final double bounce = 
                        _calculateBounceAnimation(index, _animationController.value);
                    
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      height: 8,
                      width: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      transform: Matrix4.translationValues(0, -bounce * 4, 0),
                    );
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  double _calculateBounceAnimation(int dotIndex, double animationValue) {
    // Stagger the animations by offsetting them based on index
    final double offset = dotIndex * 0.2;
    final double adjustedValue = (animationValue + offset) % 1.0;
    
    // Create a bounce effect 
    if (adjustedValue < 0.4) {
      // Going up (0 to peak)
      return adjustedValue * 2.5;
    } else if (adjustedValue < 0.8) {
      // Coming down (peak to 0)
      return (0.8 - adjustedValue) * 2.5;
    } else {
      // Rest period
      return 0;
    }
  }
}
