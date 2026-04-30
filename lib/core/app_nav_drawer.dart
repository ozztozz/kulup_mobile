import "package:flutter/material.dart";

enum AppNavSection {
  home,
  teams,
  startlist,
  payments,
  trainings,
  questionnaires,
}

class AppNavDrawer extends StatelessWidget {
  const AppNavDrawer({
    super.key,
    required this.fullName,
    required this.currentSection,
    required this.onHome,
    required this.onTeams,
    this.onStartList,
    required this.onPayments,
    required this.onTrainings,
    required this.onQuestionnaires,
    this.onLogout,
  });

  final String fullName;
  final AppNavSection currentSection;
  final VoidCallback onHome;
  final VoidCallback onTeams;
  final VoidCallback? onStartList;
  final VoidCallback onPayments;
  final VoidCallback onTrainings;
  final VoidCallback onQuestionnaires;
  final VoidCallback? onLogout;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            "assets/images/logo.png",
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fullName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Alpha",
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Divider(color: theme.colorScheme.outlineVariant),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                children: [
                  _MenuItemTile(
                    icon: Icons.home_outlined,
                    label: "Anasayfa",
                    selected: currentSection == AppNavSection.home,
                    onTap: onHome,
                  ),
                  _MenuItemTile(
                    icon: Icons.groups_outlined,
                    label: "Takimlar",
                    selected: currentSection == AppNavSection.teams,
                    onTap: onTeams,
                  ),
                  if (onStartList != null)
                    _MenuItemTile(
                      icon: Icons.view_list_outlined,
                      label: "Start List",
                      selected: currentSection == AppNavSection.startlist,
                      onTap: onStartList!,
                    ),
                  _MenuItemTile(
                    icon: Icons.payments_outlined,
                    label: "Odemeler",
                    selected: currentSection == AppNavSection.payments,
                    onTap: onPayments,
                  ),
                  _MenuItemTile(
                    icon: Icons.fitness_center_outlined,
                    label: "Antrenmanlar",
                    selected: currentSection == AppNavSection.trainings,
                    onTap: onTrainings,
                  ),
                  _MenuItemTile(
                    icon: Icons.assignment_outlined,
                    label: "Anketler",
                    selected: currentSection == AppNavSection.questionnaires,
                    onTap: onQuestionnaires,
                  ),
                  if (onLogout != null) ...[
                    const SizedBox(height: 8),
                    _MenuItemTile(
                      icon: Icons.logout,
                      label: "Cikis",
                      selected: false,
                      onTap: onLogout!,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuItemTile extends StatelessWidget {
  const _MenuItemTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        selected: selected,
        selectedTileColor: theme.colorScheme.surfaceContainerHighest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        leading: Icon(icon, size: 20),
        title: Text(
          label,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}
