import "package:flutter/material.dart";

import "../dashboard/club_service.dart";
import "questionnaire_response_page.dart";

class QuestionnaireListPage extends StatefulWidget {
  const QuestionnaireListPage({super.key});

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
        builder: (_) => QuestionnaireResponsePage(row: row),
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
      appBar: AppBar(
        title: const Text("Anketler"),
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            tooltip: "Refresh",
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.primaryContainer.withValues(alpha: 0.2),
              theme.scaffoldBackgroundColor,
            ],
          ),
        ),
        child: _isLoading
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
                                color: hasResponded ? Colors.green : Colors.orange,
                              ),
                              title: Text(questionnaire["title"]?.toString() ?? "Anket"),
                              subtitle: Text(
                                "$memberName - ${team["name"] ?? ""}",
                              ),
                              trailing: hasResponded
                                  ? const Text("Yanitlandi")
                                  : const Text("Yanitla"),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
      ),
    );
  }
}
