import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class KeyboardStabilizer extends StatefulWidget {
  final Widget child;
  const KeyboardStabilizer({super.key, required this.child});

  @override
  State<KeyboardStabilizer> createState() => _KeyboardStabilizerState();
}

class _KeyboardStabilizerState extends State<KeyboardStabilizer>
    with WidgetsBindingObserver {
  final FocusNode _focusNode = FocusNode(debugLabel: 'KeyboardStabilizer');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        RawKeyboard.instance.clearKeysPressed();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      RawKeyboard.instance.clearKeysPressed();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      child: widget.child,
    );
  }
}
