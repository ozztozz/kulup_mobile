import "package:flutter/material.dart";

class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({
    super.key,
    required this.title,
    this.actions = const <Widget>[],
    this.centerTitle = false,
    this.backgroundColor,
    this.foregroundColor,
  });

  final Widget title;
  final List<Widget> actions;
  final bool centerTitle;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppBar(
      automaticallyImplyLeading: false,
      centerTitle: centerTitle,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      title: title,
      actions: [
        ...actions,
        Builder(
          builder: (context) => IconButton(
            onPressed: () => Scaffold.of(context).openDrawer(),
            icon: const Icon(Icons.menu),
            tooltip: "Menu",
          ),
        ),
      ],
      titleTextStyle: theme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
      ),
    );
  }
}