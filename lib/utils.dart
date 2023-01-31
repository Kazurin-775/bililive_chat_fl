import 'package:flutter/widgets.dart';

/// A widget that fades in and out, as well as being dynamically added to /
/// removed from the tree, when its visibility changes.
class FadingWidget extends StatefulWidget {
  final Widget child;
  final bool visible;
  final Duration duration;

  const FadingWidget({
    super.key,
    required this.child,
    required this.visible,
    required this.duration,
  });

  @override
  State<StatefulWidget> createState() => _FadingWidgetState();
}

class _FadingWidgetState extends State<FadingWidget> {
  bool _inTree = false;

  @override
  void didUpdateWidget(covariant FadingWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Always put the child in tree when visible = true
    if (widget.visible) _inTree = true;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: widget.visible ? 1 : 0,
      duration: const Duration(milliseconds: 200),
      // If _inTree = false, remove the child from the widget tree
      child: _inTree ? widget.child : const SizedBox.shrink(),
      onEnd: () {
        if (!widget.visible) {
          setState(() {
            _inTree = false;
          });
        }
      },
    );
  }
}
