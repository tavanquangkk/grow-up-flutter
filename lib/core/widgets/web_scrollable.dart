import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Web対応のスクロール可能ウィジェット
class WebScrollable extends StatelessWidget {
  final Widget child;
  final ScrollController? controller;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;

  const WebScrollable({
    Key? key,
    required this.child,
    this.controller,
    this.padding,
    this.physics,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return SingleChildScrollView(
        controller: controller,
        physics: physics ?? const AlwaysScrollableScrollPhysics(),
        padding: padding,
        scrollDirection: Axis.vertical,
        child: child,
      );
    } else {
      return Padding(padding: padding ?? EdgeInsets.zero, child: child);
    }
  }
}

/// Web対応のリストビューウィジェット
class WebListView extends StatelessWidget {
  final List<Widget> children;
  final ScrollController? controller;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;
  final bool shrinkWrap;

  const WebListView({
    Key? key,
    required this.children,
    this.controller,
    this.padding,
    this.physics,
    this.shrinkWrap = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: controller,
      physics:
          physics ??
          (kIsWeb
              ? const AlwaysScrollableScrollPhysics()
              : const BouncingScrollPhysics()),
      padding: padding,
      shrinkWrap: shrinkWrap,
      children: children,
    );
  }
}
