import "package:flutter/material.dart";

import "../../core/app_nav_drawer.dart";
import "../../core/app_top_bar.dart";
import "../dashboard/club_service.dart";
import "../dashboard/team_list_page.dart";
import "../payments/payment_list_page.dart";
import "../dashboard/training_weekly_page.dart";
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
    final hasResponded = row["has_responded"] == true;
    if (hasResponded) {
      return;
    }

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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                const Icon(Icons.assignment_outlined),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    "Toplam ${_rows.length} satir, yanit bekleyen $unansweredCount satir",
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
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
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              onTap: () => _openAnswerPage(row),
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
                                  : Text(
                                      "Yanitla",
                                      style: theme.textTheme.labelMedium?.copyWith(
                                        color: theme.colorScheme.secondary,
                                        fontWeight: FontWeight.w700,
                                      ),
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
