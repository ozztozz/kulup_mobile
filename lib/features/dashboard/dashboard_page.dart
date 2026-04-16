import "package:flutter/material.dart";

import "../../core/app_nav_drawer.dart";
import "../../core/app_top_bar.dart";
import "../auth/auth_service.dart";
import "../questionnaire/questionnaire_list_page.dart";
import "club_service.dart";
import "../payments/payment_list_page.dart";
import "team_list_page.dart";
import "training_weekly_page.dart";

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key, required this.onLogout});

  final VoidCallback onLogout;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final AuthService _authService = AuthService();
  final ClubService _clubService = ClubService();

  bool _isLoading = true;
  String? _error;

  Map<String, dynamic>? _me;
  List<Map<String, dynamic>> _teams = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _trainings = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _questionnaires = <Map<String, dynamic>>[];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final meFuture = _authService.me();
      final teamsFuture = _clubService.fetchTeams();
      final trainingsFuture = _clubService.fetchTrainings();
      final questionnairesFuture = _clubService.fetchActiveQuestionnaires();

      final results = await Future.wait<dynamic>([
        meFuture,
        teamsFuture,
        trainingsFuture,
        questionnairesFuture,
      ]);

      if (!mounted) {
        return;
      }

      setState(() {
        _me = results[0] as Map<String, dynamic>;
        _teams = results[1] as List<Map<String, dynamic>>;
        _trainings = results[2] as List<Map<String, dynamic>>;
        _questionnaires = results[3] as List<Map<String, dynamic>>;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = "Data load failed: $e";
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    await _authService.logout();
    widget.onLogout();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fullName = "${_me?["adi"] ?? ""} ${_me?["soyadi"] ?? ""}".trim();

    return Scaffold(
      drawer: AppNavDrawer(
        fullName: fullName.isEmpty ? "Alpha" : fullName,
        currentSection: AppNavSection.home,
        onHome: () {
          Navigator.of(context).pop();
        },
        onTeams: () {
          Navigator.of(context).pop();
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => TeamListPage(onLogout: widget.onLogout),
            ),
          );
        },
        onPayments: () {
          Navigator.of(context).pop();
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PaymentListPage(onLogout: widget.onLogout),
            ),
          );
        },
        onTrainings: () {
          Navigator.of(context).pop();
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => TrainingWeeklyPage(onLogout: widget.onLogout),
            ),
          );
        },
        onQuestionnaires: () {
          Navigator.of(context).pop();
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => QuestionnaireListPage(onLogout: widget.onLogout),
            ),
          );
        },
        onLogout: () async {
          Navigator.of(context).pop();
          await _logout();
        },
      ),
      appBar: AppTopBar(
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                "assets/images/logo.png",
                width: 28,
                height: 28,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 10),
            const Text("Alpha"),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: theme.colorScheme.outlineVariant),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Ozet",
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _StatPill(label: "Takim", value: _teams.length.toString()),
                                _StatPill(
                                  label: "Antrenman",
                                  value: _trainings.length.toString(),
                                ),
                                _StatPill(
                                  label: "Anket",
                                  value: _questionnaires.length.toString(),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: theme.colorScheme.outlineVariant),
                      ),
                      child: Column(
                        children: [
                          _ActionListTile(
                            title: "Takımlar",
                            icon: Icons.groups_outlined,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => TeamListPage(onLogout: widget.onLogout),
                                ),
                              );
                            },
                          ),
                          const Divider(height: 1),
                          _ActionListTile(
                            title: "Anketler",
                            icon: Icons.assignment_outlined,
                            onTap: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => QuestionnaireListPage(onLogout: widget.onLogout),
                                ),
                              );
                              if (mounted) {
                                await _loadData();
                              }
                            },
                          ),
                          const Divider(height: 1),
                          const _ActionListTile(
                            title: "Ayarlar",
                            icon: Icons.settings_outlined,
                            enabled: false,
                          ),
                          const Divider(height: 1),
                          _ActionListTile(
                            title: "Haftalik Antrenman",
                            icon: Icons.calendar_view_week_outlined,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => TrainingWeeklyPage(onLogout: widget.onLogout),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        "$label: $value",
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ActionListTile extends StatelessWidget {
  const _ActionListTile({
    required this.title,
    required this.icon,
    this.onTap,
    this.enabled = true,
  });

  final String title;
  final IconData icon;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      enabled: enabled,
      onTap: enabled ? onTap : null,
      leading: Icon(
        icon,
        color: enabled ? theme.colorScheme.primary : theme.colorScheme.outline,
      ),
      title: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: enabled ? null : theme.colorScheme.onSurface.withValues(alpha: 0.55),
        ),
      ),
      trailing: enabled ? const Icon(Icons.chevron_right) : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}
