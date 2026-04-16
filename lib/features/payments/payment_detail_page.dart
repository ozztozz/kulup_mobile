import "package:flutter/material.dart";

import "../../core/app_nav_drawer.dart";
import "../../core/app_top_bar.dart";
import "../../core/team_logo_avatar.dart";
import "../dashboard/team_list_page.dart";
import "../dashboard/training_weekly_page.dart";
import "../questionnaire/questionnaire_list_page.dart";

class PaymentDetailPage extends StatelessWidget {
  const PaymentDetailPage({super.key, required this.payment, required this.onLogout});

  final Map<String, dynamic> payment;
  final VoidCallback onLogout;

  String _monthLabel(dynamic value) {
    final text = value?.toString() ?? "";
    if (text.length >= 7) {
      return text.substring(0, 7);
    }
    return text;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final member = Map<String, dynamic>.from((payment["member"] as Map?) ?? <String, dynamic>{});
    final team = Map<String, dynamic>.from((member["team"] as Map?) ?? <String, dynamic>{});
    final memberName = "${member["name"] ?? ""} ${member["surname"] ?? ""}".trim();
    final isPaid = payment["is_paid"] == true;
    final amount = payment["amount"]?.toString() ?? "0";

    return Scaffold(
      drawer: AppNavDrawer(
        fullName: memberName.isEmpty ? "Alpha" : memberName,
        currentSection: AppNavSection.payments,
        onHome: () {
          Navigator.of(context).pop();
          Navigator.of(context).popUntil((route) => route.isFirst);
        },
        onTeams: () {
          Navigator.of(context).pop();
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => TeamListPage(onLogout: onLogout),
            ),
          );
        },
        onPayments: () {
          Navigator.of(context).pop();
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
        title: const Text("Odeme Detayi"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TeamLogoAvatar(
                      team: team,
                      size: 72,
                      borderRadius: 20,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      memberName.isEmpty ? "Uye" : memberName,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(team["name"]?.toString() ?? "Takim"),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: isPaid
                            ? theme.colorScheme.tertiaryContainer
                            : theme.colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        isPaid ? "Odendi" : "Bekliyor",
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: isPaid
                              ? theme.colorScheme.onTertiaryContainer
                              : theme.colorScheme.onSecondaryContainer,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            _InfoCard(title: "Tutar", value: amount, icon: Icons.payments_outlined),
            _InfoCard(
              title: "Ay",
              value: _monthLabel(payment["month"]),
              icon: Icons.calendar_month_outlined,
            ),
            _InfoCard(
              title: "Odeme Tarihi",
              value: payment["paid_date"]?.toString() ?? "-",
              icon: Icons.event_available_outlined,
            ),
            _InfoCard(
              title: "Olusturulma",
              value: payment["created_at"]?.toString() ?? "-",
              icon: Icons.history_outlined,
              multiline: true,
            ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.value,
    required this.icon,
    this.multiline = false,
  });

  final String title;
  final String value;
  final IconData icon;
  final bool multiline;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: multiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    maxLines: multiline ? null : 1,
                    overflow: multiline ? TextOverflow.visible : TextOverflow.ellipsis,
                    style: theme.textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}