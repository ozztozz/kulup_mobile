import "package:flutter/material.dart";

import "../../core/app_footer_menu.dart";
import "../../core/app_nav_drawer.dart";
import "../../core/app_top_bar.dart";
import "../dashboard/club_service.dart";
import "../dashboard/team_list_page.dart";
import "../dashboard/training_weekly_page.dart";
import "../payments/payment_list_page.dart";
import "questionnaire_list_page.dart";
import "questionnaire_response_page.dart";

class QuestionnaireDetailPage extends StatefulWidget {
  const QuestionnaireDetailPage({
    super.key,
    required this.row,
    required this.allRows,
    required this.onLogout,
  });

  final Map<String, dynamic> row;
  final List<Map<String, dynamic>> allRows;
  final VoidCallback onLogout;

  @override
  State<QuestionnaireDetailPage> createState() => _QuestionnaireDetailPageState();
}

class _QuestionnaireDetailPageState extends State<QuestionnaireDetailPage> {
  final ClubService _clubService = ClubService();

  late final Map<String, dynamic> _member;
  late final Map<String, dynamic> _questionnaire;
  late final int _questionnaireId;
  late final int? _memberId;
  late bool _hasResponded;
  bool _isLoadingDetail = true;
  String? _detailError;
  Map<String, dynamic>? _detailData;

  @override
  void initState() {
    super.initState();
    _member = Map<String, dynamic>.from(
      (widget.row["member"] as Map?) ?? <String, dynamic>{},
    );
    _questionnaire = Map<String, dynamic>.from(
      (widget.row["questionnaire"] as Map?) ?? <String, dynamic>{},
    );
    _questionnaireId = (_questionnaire["id"] as num?)?.toInt() ?? -1;
    _memberId = (_member["id"] as num?)?.toInt();
    _hasResponded = widget.row["has_responded"] == true;
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    if (_questionnaireId <= 0) {
      setState(() {
        _isLoadingDetail = false;
      });
      return;
    }

    setState(() {
      _isLoadingDetail = true;
      _detailError = null;
    });

    try {
      final detail = await _clubService.fetchQuestionnaireDetail(
        questionnaireId: _questionnaireId,
        memberId: _memberId,
      );

      if (!mounted) {
        return;
      }

      final response = detail["response"];
      setState(() {
        _detailData = detail;
        _hasResponded = response is Map;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _detailError = "Detay yuklenemedi: $e";
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingDetail = false;
        });
      }
    }
  }

  void _handleBottomTap(int index) {
    if (index == 2) {
      Navigator.of(context).pop();
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

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => targetPage!),
      (route) => route.isFirst,
    );
  }

  Future<void> _openAnswerPage() async {
    if (_hasResponded || _questionnaire["is_active"] != true) {
      return;
    }

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => QuestionnaireResponsePage(
          row: widget.row,
          onLogout: widget.onLogout,
        ),
      ),
    );

    if (result == true && mounted) {
      setState(() {
        _hasResponded = true;
      });
      Navigator.of(context).pop(true);
    }
  }

  List<Map<String, dynamic>> _rowsForQuestionnaire() {
    return widget.allRows.where((row) {
      final questionnaire = Map<String, dynamic>.from(
        (row["questionnaire"] as Map?) ?? <String, dynamic>{},
      );
      final id = (questionnaire["id"] as num?)?.toInt() ?? -1;
      return id == _questionnaireId;
    }).map((row) => Map<String, dynamic>.from(row)).toList();
  }

  String _memberName(Map<String, dynamic> member) {
    final value = "${member["name"] ?? ""} ${member["surname"] ?? ""}".trim();
    return value.isEmpty ? "Uye" : value;
  }

  String _dateLabel() {
    final begin = _formatDate(_questionnaire["begin_date"]?.toString());
    final end = _formatDate(_questionnaire["end_date"]?.toString());

    if (begin == null && end == null) {
      return "Tarih kisiti yok";
    }
    if (begin != null && end != null) {
      return "$begin - $end";
    }
    if (begin != null) {
      return "Baslangic: $begin";
    }
    return "Bitis: $end";
  }

  String? _formatDate(String? source) {
    if (source == null || source.trim().isEmpty) {
      return null;
    }
    try {
      final date = DateTime.parse(source);
      final day = date.day.toString().padLeft(2, "0");
      final month = date.month.toString().padLeft(2, "0");
      return "$day.$month.${date.year}";
    } catch (_) {
      return source;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final detailQuestionnaire = Map<String, dynamic>.from(
      ((_detailData?["questionnaire"] as Map?) ?? _questionnaire),
    );
    final selectedMember = Map<String, dynamic>.from(
      ((_detailData?["member"] as Map?) ?? _member),
    );
    final memberTeam = Map<String, dynamic>.from(
      (selectedMember["team"] as Map?) ?? <String, dynamic>{},
    );

    final allRows = _rowsForQuestionnaire();
    final respondedRows = allRows.where((row) => row["has_responded"] == true).toList();
    final notRespondedRows = allRows.where((row) => row["has_responded"] != true).toList();

    final respondedRowsData = ((_detailData?["responded_rows"] as List<dynamic>?) ?? respondedRows)
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
    final notRespondedRowsData =
        ((_detailData?["not_responded_rows"] as List<dynamic>?) ?? notRespondedRows)
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();

    final schema = Map<String, dynamic>.from(
      (detailQuestionnaire["schema"] as Map?) ?? <String, dynamic>{},
    );
    final questions = ((schema["questions"] as List<dynamic>?) ?? <dynamic>[])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
    final questionsWithStats = ((_detailData?["questions_with_stats"] as List<dynamic>?) ?? questions)
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
    final requiredCount =
        questionsWithStats.where((question) => question["required"] != false).length;

    final counts = Map<String, dynamic>.from(
      (_detailData?["counts"] as Map?) ?? <String, dynamic>{},
    );
    final respondedCount = (counts["responded"] as num?)?.toInt() ?? respondedRowsData.length;
    final notRespondedCount = (counts["not_responded"] as num?)?.toInt() ?? notRespondedRowsData.length;

    final teams = ((detailQuestionnaire["teams"] as List<dynamic>?) ?? <dynamic>[])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F7),
      drawer: AppNavDrawer(
        fullName: _memberName(_member),
        currentSection: AppNavSection.questionnaires,
        onHome: () {
          Navigator.of(context).pop();
          Navigator.of(context).popUntil((route) => route.isFirst);
        },
        onTeams: () {
          Navigator.of(context).pop();
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => TeamListPage(onLogout: widget.onLogout),
            ),
          );
        },
        onPayments: () {
          Navigator.of(context).pop();
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => PaymentListPage(onLogout: widget.onLogout),
            ),
          );
        },
        onTrainings: () {
          Navigator.of(context).pop();
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => TrainingWeeklyPage(onLogout: widget.onLogout),
            ),
          );
        },
        onQuestionnaires: () {
          Navigator.of(context).pop();
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) => QuestionnaireListPage(onLogout: widget.onLogout),
            ),
            (route) => route.isFirst,
          );
        },
        onLogout: widget.onLogout,
      ),
      appBar: AppTopBar(
        title: const Text("Anket Detayi"),
      ),
      bottomNavigationBar: AppFooterMenu(
        selectedIndex: 2,
        onTap: _handleBottomTap,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 22),
        children: [
          Card(
            color: const Color(0xFF10213E),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          detailQuestionnaire["title"]?.toString() ?? "Anket",
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: detailQuestionnaire["is_active"] == true
                              ? const Color(0xFF2CC36B)
                              : Colors.white24,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          detailQuestionnaire["is_active"] == true ? "Aktif" : "Pasif",
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "${_memberName(selectedMember)} - ${memberTeam["name"] ?? "Takim"}",
                    style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    teams.isEmpty
                        ? "Tum takimlar"
                        : teams.map((team) => team["name"]?.toString() ?? "Takim").join(", "),
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _dateLabel(),
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _hasResponded
                          ? const Color(0xFF2CC36B).withValues(alpha: 0.22)
                          : Colors.white24,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      _hasResponded ? "Bu uye yanitladi" : "Bu uye yanit bekliyor",
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoadingDetail) ...[
            const SizedBox(height: 12),
            const Center(child: CircularProgressIndicator()),
          ],
          if (_detailError != null) ...[
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  _detailError!,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ),
          ],
          if ((detailQuestionnaire["description"]?.toString() ?? "").trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Text(
                  detailQuestionnaire["description"]?.toString() ?? "",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  title: "Soru",
                  value: questionsWithStats.length.toString(),
                  icon: Icons.help_outline_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  title: "Zorunlu",
                  value: requiredCount.toString(),
                  icon: Icons.rule_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  title: "Yanit",
                  value: respondedCount.toString(),
                  icon: Icons.check_circle_outline_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            "Uyelerin Durumu",
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          _MemberStatusCard(
            title: "Cevaplayan Uyeler",
            count: respondedCount,
            backgroundColor: const Color(0xFFE7F8EE),
            borderColor: const Color(0xFFB6E8CC),
            icon: Icons.check_circle,
            iconColor: const Color(0xFF18A355),
            rows: respondedRowsData,
          ),
          const SizedBox(height: 10),
          _MemberStatusCard(
            title: "Cevaplamayan Uyeler",
            count: notRespondedCount,
            backgroundColor: const Color(0xFFFFF3E4),
            borderColor: const Color(0xFFF6D3A5),
            icon: Icons.pending_actions_rounded,
            iconColor: const Color(0xFFB06A12),
            rows: notRespondedRowsData,
          ),
          const SizedBox(height: 16),
          Text(
            "Sorular",
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          if (questionsWithStats.isEmpty)
            Card(
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Text(
                  "Bu ankette soru bulunmuyor.",
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            )
          else
            ...questionsWithStats.map((question) {
              return _buildQuestionCard(question, respondedCount: respondedCount);
            }),
          const SizedBox(height: 10),
          if (detailQuestionnaire["is_active"] == true && !_hasResponded)
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF10213E),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _openAnswerPage,
              icon: const Icon(Icons.edit_note_rounded),
              label: const Text("Anketi Yanitla"),
            )
          else
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: null,
              icon: Icon(
                _hasResponded ? Icons.check_circle_rounded : Icons.lock_clock,
              ),
              label: Text(
                _hasResponded ? "Bu uye daha once yanitladi" : "Anket aktif degil",
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(
    Map<String, dynamic> question, {
    required int respondedCount,
  }) {
    final theme = Theme.of(context);
    final label = question["label"]?.toString() ?? "Soru";
    final type = question["type"]?.toString() ?? "text";
    final help = question["help"]?.toString() ?? "";
    final required = question["required"] != false;
    final choices = ((question["choices"] as List<dynamic>?) ?? <dynamic>[])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10213E).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _typeLabel(type),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: const Color(0xFF10213E),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: required
                        ? const Color(0xFF2CC36B).withValues(alpha: 0.12)
                        : const Color(0xFFE8EBF1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    required ? "Zorunlu" : "Opsiyonel",
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: required ? const Color(0xFF127C40) : const Color(0xFF3F4653),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            if (help.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                help,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (choices.isNotEmpty) ...[
              const SizedBox(height: 8),
              Column(
                children: choices.map((choice) {
                  final choiceLabel = choice["label"]?.toString() ?? "Secenek";
                  final choiceCount = (choice["count"] as num?)?.toInt() ?? 0;
                  final percent = respondedCount == 0
                      ? 0
                      : ((choiceCount * 100) / respondedCount).round();
                  final barValue = respondedCount == 0
                      ? 0.0
                      : (choiceCount / respondedCount).clamp(0.0, 1.0);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F5F7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  choiceLabel,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              Text(
                                "$choiceCount",
                                style: theme.textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF10213E),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "%$percent",
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 7),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              minHeight: 7,
                              value: barValue,
                              backgroundColor: const Color(0xFFDCE3EC),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFF12233F),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _typeLabel(String type) {
    if (type == "single") {
      return "Tekli";
    }
    if (type == "multi") {
      return "Coklu";
    }
    return "Yazi";
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF12233F)),
          const SizedBox(height: 6),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            title,
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

class _MemberStatusCard extends StatelessWidget {
  const _MemberStatusCard({
    required this.title,
    required this.count,
    required this.backgroundColor,
    required this.borderColor,
    required this.icon,
    required this.iconColor,
    required this.rows,
  });

  final String title;
  final int count;
  final Color backgroundColor;
  final Color borderColor;
  final IconData icon;
  final Color iconColor;
  final List<Map<String, dynamic>> rows;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                "$count",
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: iconColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (rows.isEmpty)
            Text(
              "Kayit yok.",
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          else
            ...rows.take(6).map((row) {
              final member = Map<String, dynamic>.from(
                (row["member"] as Map?) ?? <String, dynamic>{},
              );
              final team = Map<String, dynamic>.from(
                (member["team"] as Map?) ?? <String, dynamic>{},
              );
              final name = "${member["name"] ?? ""} ${member["surname"] ?? ""}".trim();

              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  "• ${name.isEmpty ? "Uye" : name} - ${team["name"] ?? "Takim"}",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }),
          if (rows.length > 6)
            Text(
              "+${rows.length - 6} uye daha",
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    );
  }
}