import "package:flutter/material.dart";

import "../../core/app_footer_menu.dart";
import "../../core/app_nav_drawer.dart";
import "../../core/app_top_bar.dart";
import "../dashboard/club_service.dart";
import "../dashboard/team_list_page.dart";
import "../payments/payment_list_page.dart";
import "../dashboard/training_weekly_page.dart";
import "questionnaire_detail_page.dart";
import "questionnaire_response_page.dart";

class QuestionnaireListPage extends StatefulWidget {
  const QuestionnaireListPage({super.key, required this.onLogout});

  final VoidCallback onLogout;

  @override
  State<QuestionnaireListPage> createState() => _QuestionnaireListPageState();
}

class _QuestionnaireListPageState extends State<QuestionnaireListPage> {
  final ClubService _clubService = ClubService();

  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _rows = <Map<String, dynamic>>[];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final rows = await _clubService.fetchActiveQuestionnaires();
      if (!mounted) {
        return;
      }
      setState(() {
        _rows = rows;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = "Anketler yuklenemedi: $e";
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _openAnswerPage(Map<String, dynamic> row) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => QuestionnaireResponsePage(
          row: row,
          onLogout: widget.onLogout,
        ),
      ),
    );

    if (result == true) {
      await _load();
    }
  }

  Future<void> _openDetailPage(Map<String, dynamic> row) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => QuestionnaireDetailPage(
          row: row,
          allRows: _rows,
          onLogout: widget.onLogout,
        ),
      ),
    );

    if (result == true) {
      await _load();
    }
  }

  void _handleBottomTap(int index) {
    if (index == 2) {
      return;
    }

    if (index == 0) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }

    Widget? targetPage;
    if (index == 1) {
      targetPage = TrainingWeeklyPage(onLogout: widget.onLogout);
    } else if (index == 3) {
      targetPage = PaymentListPage(onLogout: widget.onLogout);
    }

    if (targetPage == null) {
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => targetPage!),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unansweredCount = _rows.where((row) => row["has_responded"] != true).length;

    return Scaffold(
      drawer: AppNavDrawer(
        fullName: "Alpha",
        currentSection: AppNavSection.questionnaires,
        onHome: () {
          Navigator.of(context).pop();
          Navigator.of(context).popUntil((route) => route.isFirst);
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
        },
        onLogout: widget.onLogout,
      ),
      appBar: AppTopBar(
        title: const Text("Anketler"),
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            tooltip: "Refresh",
          ),
        ],
      ),
      bottomNavigationBar: AppFooterMenu(
        selectedIndex: 2,
        onTap: _handleBottomTap,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                    children: [
                      Text(
                        "Plan Details",
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF12233F),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Takip edilen anketler ve cevap durumlari.",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Card(
                        color: const Color(0xFF10213E),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Anket ozeti",
                                      style: theme.textTheme.titleSmall?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      "${_rows.length} anket • $unansweredCount bekliyor",
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: Colors.white70,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.white,
                                        side: const BorderSide(color: Colors.white70),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                      onPressed: _load,
                                      child: const Text("Yenile"),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withValues(alpha: 0.1),
                                ),
                                child: Center(
                                  child: Text(
                                    "$unansweredCount",
                                    style: theme.textTheme.headlineSmall?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _SummaryChip(
                              label: "Toplam",
                              value: _rows.length.toString(),
                              icon: Icons.assignment_outlined,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _SummaryChip(
                              label: "Bekliyor",
                              value: unansweredCount.toString(),
                              icon: Icons.pending_actions_outlined,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Text(
                            "Activity",
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: _load,
                            child: const Text("See all"),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                        ..._rows.map((row) {
                          final member = Map<String, dynamic>.from(
                            (row["member"] as Map?) ?? <String, dynamic>{},
                          );
                          final questionnaire = Map<String, dynamic>.from(
                            (row["questionnaire"] as Map?) ?? <String, dynamic>{},
                          );
                          final hasResponded = row["has_responded"] == true;

                          final memberName =
                              "${member["name"] ?? ""} ${member["surname"] ?? ""}".trim();
                          final team = Map<String, dynamic>.from(
                            (member["team"] as Map?) ?? <String, dynamic>{},
                          );

                          return Card(
                            elevation: 0,
                            margin: const EdgeInsets.only(bottom: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: theme.colorScheme.outlineVariant),
                            ),
                            child: ListTile(
                              onTap: () => _openDetailPage(row),
                              leading: Icon(
                                hasResponded ? Icons.check_circle : Icons.edit_note,
                                color: hasResponded
                                    ? theme.colorScheme.tertiary
                                    : theme.colorScheme.secondary,
                              ),
                              title: Text(questionnaire["title"]?.toString() ?? "Anket"),
                              subtitle: Text(
                                "$memberName - ${team["name"] ?? ""}",
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              trailing: hasResponded
                                  ? Text(
                                      "Yanitlandi",
                                      style: theme.textTheme.labelMedium?.copyWith(
                                        color: theme.colorScheme.tertiary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    )
                                  : TextButton(
                                      onPressed: () => _openAnswerPage(row),
                                      child: const Text("Yanitla"),
                                    ),
                            ),
                          );
                        }),
                    ],
                  ),
                ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF12233F)),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
