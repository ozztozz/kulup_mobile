import "package:flutter/material.dart";

class TeamLogoAvatar extends StatelessWidget {
  const TeamLogoAvatar({
    super.key,
    required this.team,
    required this.size,
    this.borderRadius = 16,
    this.fallbackIcon = Icons.groups_outlined,
  });

  final Map<String, dynamic> team;
  final double size;
  final double borderRadius;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    final logoUrl = team["logo_url"]?.toString() ?? "";
    final theme = Theme.of(context);

    if (logoUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Image.network(
          logoUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) {
            return _FallbackAvatar(
              size: size,
              borderRadius: borderRadius,
              icon: fallbackIcon,
              backgroundColor: theme.colorScheme.primary,
            );
          },
        ),
      );
    }

    return _FallbackAvatar(
      size: size,
      borderRadius: borderRadius,
      icon: fallbackIcon,
      backgroundColor: theme.colorScheme.primary,
    );
  }
}

class _FallbackAvatar extends StatelessWidget {
  const _FallbackAvatar({
    required this.size,
    required this.borderRadius,
    required this.icon,
    required this.backgroundColor,
  });

  final double size;
  final double borderRadius;
  final IconData icon;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Icon(icon, color: Colors.white, size: size * 0.5),
    );
  }
}