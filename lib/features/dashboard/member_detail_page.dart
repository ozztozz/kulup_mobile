import "package:flutter/material.dart";

import "../../core/app_nav_drawer.dart";
import "../../core/app_top_bar.dart";
import "../../core/team_logo_avatar.dart";
import "team_list_page.dart";
import "../payments/payment_list_page.dart";
import "training_weekly_page.dart";
import "../questionnaire/questionnaire_list_page.dart";

class MemberDetailPage extends StatelessWidget {
  const MemberDetailPage({super.key, required this.member, required this.onLogout});

  final Map<String, dynamic> member;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final team = Map<String, dynamic>.from(
      (member["team"] as Map?) ?? <String, dynamic>{},
    );

    final fullName = "${member["name"] ?? ""} ${member["surname"] ?? ""}".trim();
    final school = member["school"]?.toString() ?? "";
    final birthdate = member["birthdate"]?.toString() ?? "";
    final joinedDate = member["joined_date"]?.toString() ?? "";
    final notes = member["notes"]?.toString() ?? "";
    final isActive = member["is_active"] == true;
    final teamName = team["name"]?.toString() ?? "";
    final photoUrl = member["photo_url"]?.toString() ?? "";
    final email = member["email"]?.toString() ?? "";

    return Scaffold(
      drawer: AppNavDrawer(
        fullName: fullName.isEmpty ? "Alpha" : fullName,
        currentSection: AppNavSection.teams,
        onHome: () {
          Navigator.of(context).pop();
          Navigator.of(context).popUntil((route) => route.isFirst);
        },
        onTeams: () {
          Navigator.of(context).pop();
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => TeamListPage(onLogout: onLogout),
            ),
          );
        },
        onPayments: () {
          Navigator.of(context).pop();
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PaymentListPage(onLogout: onLogout),
            ),
          );
        },
        onTrainings: () {
          Navigator.of(context).pop();
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => TrainingWeeklyPage(onLogout: onLogout),
            ),
          );
        },
        onQuestionnaires: () {
          Navigator.of(context).pop();
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => QuestionnaireListPage(onLogout: onLogout),
            ),
          );
        },
        onLogout: onLogout,
      ),
      appBar: AppTopBar(
        title: const Text("Uye Detayi"),
      ),
      body: Stack(
        children: [
          Container(
            height: 220,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.primary.withValues(alpha: 0.88),
                ],
              ),
            ),
          ),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              children: [
                Row(
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => Navigator.of(context).maybePop(),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.arrow_back_ios_new,
                          size: 18,
                          color: theme.colorScheme.onPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            "PROFILE",
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onPrimary,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                          Text(
                            teamName.isEmpty ? "TAKIM" : teamName.toUpperCase(),
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: theme.colorScheme.onPrimary.withValues(alpha: 0.82),
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Menü yakında eklenecek.")),
                        );
                      },
                      icon: Icon(Icons.more_vert, color: theme.colorScheme.onPrimary),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.topCenter,
                  children: [
                    Card(
                      margin: const EdgeInsets.only(top: 56),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 72, 20, 22),
                        child: Column(
                          children: [
                            Text(
                              fullName.isEmpty ? "Uye" : fullName,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              teamName.isEmpty ? "Takim bilgisi yok" : teamName,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: isActive
                                    ? theme.colorScheme.tertiaryContainer
                                    : theme.colorScheme.errorContainer,
                              ),
                              child: Text(
                                isActive ? "Aktif" : "Pasif",
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: isActive
                                      ? theme.colorScheme.onTertiaryContainer
                                      : theme.colorScheme.onErrorContainer,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: FilledButton.icon(
                                    onPressed: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text("Duzenleme yakinda eklenecek.")),
                                      );
                                    },
                                    icon: const Icon(Icons.edit_outlined),
                                    label: const Text("Duzenle"),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: FilledButton.icon(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: theme.colorScheme.secondary,
                                      foregroundColor: theme.colorScheme.onSecondary,
                                    ),
                                    onPressed: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text("Silme islemi yakinda eklenecek.")),
                                      );
                                    },
                                    icon: const Icon(Icons.delete_outline),
                                    label: const Text("Sil"),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                TeamLogoAvatar(
                                  team: team,
                                  size: 34,
                                  borderRadius: 10,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    teamName.isEmpty ? "Takim" : teamName,
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      child: _MemberAvatar(
                        photoUrl: photoUrl,
                        initials: _initials(member),
                        radius: 56,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _InfoCard(
                  title: "Iletisim",
                  value: email.isEmpty ? "E-posta bilgisi yok" : email,
                  icon: Icons.email_outlined,
                ),
                _InfoCard(
                  title: "Kisisel Bilgiler",
                  value:
                      "Dogum Tarihi: ${birthdate.isEmpty ? "-" : birthdate}\nOkul: ${school.isEmpty ? "-" : school}\nKatilim Tarihi: ${joinedDate.isEmpty ? "-" : joinedDate}\nTakim: ${teamName.isEmpty ? "-" : teamName}",
                  multiline: true,
                  icon: Icons.badge_outlined,
                ),
                _InfoCard(
                  title: "Notlar",
                  value: notes.isEmpty ? "-" : notes,
                  multiline: true,
                  icon: Icons.sticky_note_2_outlined,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _initials(Map<String, dynamic> row) {
    final first = row["name"]?.toString().trim() ?? "";
    final last = row["surname"]?.toString().trim() ?? "";
    final f = first.isEmpty ? "" : first[0].toUpperCase();
    final l = last.isEmpty ? "" : last[0].toUpperCase();
    final value = "$f$l";
    return value.isEmpty ? "U" : value;
  }
}

class _MemberAvatar extends StatelessWidget {
  const _MemberAvatar({required this.photoUrl, required this.initials, this.radius = 44});

  final String photoUrl;
  final String initials;
  final double radius;

  @override
  Widget build(BuildContext context) {
    if (photoUrl.isEmpty) {
      return CircleAvatar(
        radius: radius,
        child: Text(
          initials,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: ClipOval(
        child: Image.network(
          photoUrl,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) {
            return Center(
              child: Text(
                initials,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.value,
    this.multiline = false,
    this.icon,
  });

  final String title;
  final String value;
  final bool multiline;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                ],
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              value,
              maxLines: multiline ? null : 1,
              overflow: multiline ? TextOverflow.visible : TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}
