import "package:flutter/material.dart";

import "../../core/app_nav_drawer.dart";
import "../../core/app_top_bar.dart";
import "club_service.dart";
import "team_list_page.dart";
import "../manage/training_create_page.dart";
import "../payments/payment_list_page.dart";
import "../questionnaire/questionnaire_list_page.dart";

class TrainingWeeklyPage extends StatefulWidget {
  const TrainingWeeklyPage({super.key, required this.onLogout});

  final VoidCallback onLogout;

  @override
  State<TrainingWeeklyPage> createState() => _TrainingWeeklyPageState();
}

class _TrainingWeeklyPageState extends State<TrainingWeeklyPage> {
  final ClubService _clubService = ClubService();
  final ScrollController _calendarScrollController = ScrollController();

  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _trainings = <Map<String, dynamic>>[];

  static const Map<int, String> _weekdayNames = <int, String>{
    1: "Pazartesi",
    2: "Sali",
    3: "Carsamba",
    4: "Persembe",
    5: "Cuma",
    6: "Cumartesi",
    7: "Pazar",
  };

  @override
  void initState() {
    super.initState();
    _loadTrainings();
  }

  @override
  void dispose() {
    _calendarScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadTrainings() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final trainings = await _clubService.fetchTrainings();
      if (!mounted) {
        return;
      }
      setState(() {
        _trainings = trainings;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusCurrentDay();
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = "Antrenmanlar yuklenemedi: $e";
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  int _dayValue(Map<String, dynamic> row) {
    final raw = row["day_of_week"];
    if (raw is num) {
      return raw.toInt();
    }
    if (raw is String) {
      return int.tryParse(raw) ?? 0;
    }
    return 0;
  }

  String _dayLabel(int day, List<Map<String, dynamic>> rows) {
    final fromApi = rows
        .map((row) => row["day_name"]?.toString() ?? "")
        .firstWhere((name) => name.trim().isNotEmpty, orElse: () => "");
    if (fromApi.isNotEmpty) {
      return fromApi;
    }
    return _weekdayNames[day] ?? "Belirsiz";
  }

  Map<int, List<Map<String, dynamic>>> _groupedTrainings() {
    final grouped = <int, List<Map<String, dynamic>>>{};
    for (final training in _trainings) {
      final day = _dayValue(training);
      grouped.putIfAbsent(day, () => <Map<String, dynamic>>[]).add(training);
    }

    for (final rows in grouped.values) {
      rows.sort((a, b) => _startMinutes(a).compareTo(_startMinutes(b)));
    }

    return grouped;
  }

  int _startMinutes(Map<String, dynamic> row, {String key = "time"}) {
    final value = _timeOnly(row, key: key);
    final parts = value.split(":");
    if (parts.length < 2) {
      return 24 * 60;
    }
    return (int.tryParse(parts[0]) ?? 0) * 60 + (int.tryParse(parts[1]) ?? 0);
  }

  void _focusCurrentDay() {
    if (!_calendarScrollController.hasClients) {
      return;
    }

    const columnWidth = 164.0;
    const columnGap = 8.0;
    final todayIndex = DateTime.now().weekday - 1;
    final rawOffset = todayIndex * (columnWidth + columnGap);
    final maxOffset = _calendarScrollController.position.maxScrollExtent;
    final targetOffset = rawOffset.clamp(0.0, maxOffset);

    _calendarScrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  String _timeOnly(Map<String, dynamic> row, {String key = "time"}) {
    final value = row[key]?.toString() ?? "";
    if (value.contains(":")) {
      final parts = value.split(":");
      if (parts.length >= 2) {
        return "${parts[0].padLeft(2, "0")}:${parts[1].padLeft(2, "0")}";
      }
    }
    return value;
  }

  List<int> _calendarWeekdays() => const <int>[1, 2, 3, 4, 5, 6, 7];

  Color _dayColor(int day) {
    const colors = <Color>[
      Color(0xFF3A3D55),
      Color(0xFF7E8CAA),
      Color(0xFFA5BBBE),
      Color(0xFF3A3D55),
      Color(0xFF7E8CAA),
      Color(0xFFA5BBBE),
      Color(0xFF3A3D55),
    ];

    if (day < 1 || day > 7) {
      return colors.first;
    }

    return colors[day - 1];
  }

  Future<void> _openCreateTraining() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => TrainingCreatePage(onLogout: widget.onLogout),
      ),
    );
    if (created == true && mounted) {
      await _loadTrainings();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final grouped = _groupedTrainings();

    return Scaffold(
      drawer: AppNavDrawer(
        fullName: "Alpha",
        currentSection: AppNavSection.trainings,
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
        },
        onQuestionnaires: () {
          Navigator.of(context).pop();
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => QuestionnaireListPage(onLogout: widget.onLogout),
            ),
          );
        },
        onLogout: widget.onLogout,
      ),
      appBar: AppTopBar(
        title: const Text("Haftalik Antrenman Programi"),
        actions: [
          IconButton(
            onPressed: _openCreateTraining,
            icon: const Icon(Icons.add),
            tooltip: "Yeni antrenman",
          ),
          IconButton(
            onPressed: _loadTrainings,
            icon: const Icon(Icons.refresh),
            tooltip: "Yenile",
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: _loadTrainings,
                  child: _trainings.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 200),
                            Center(child: Text("Antrenman bulunamadi.")),
                          ],
                        )
                      : ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            Text(
                              "Haftalik Takvim",
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "Gunleri yatay takvimde goruntuleyin.",
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 460,
                              child: SingleChildScrollView(
                                controller: _calendarScrollController,
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: _calendarWeekdays().map((day) {
                                    final dayRows = grouped[day] ?? <Map<String, dynamic>>[];
                                    final dayTitle = _dayLabel(day, dayRows);
                                    final isToday = DateTime.now().weekday == day;
                                    final sabahRows = dayRows
                                        .where((row) => _startMinutes(row, key: "time") < 12 * 60)
                                        .toList();
                                    final aksamRows = dayRows
                                        .where((row) => _startMinutes(row, key: "time") >= 12 * 60)
                                        .toList();

                                    return Container(
                                      width: 164,
                                      margin: const EdgeInsets.only(right: 8),
                                      child: Card(
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(14),
                                          side: BorderSide(
                                            color: isToday
                                                ? _dayColor(day)
                                                : theme.colorScheme.outlineVariant,
                                            width: isToday ? 1.4 : 1,
                                          ),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(8),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Container(
                                                    width: 8,
                                                    height: 8,
                                                    decoration: BoxDecoration(
                                                      color: _dayColor(day),
                                                      shape: BoxShape.circle,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Expanded(
                                                    child: Text(
                                                      dayTitle,
                                                      style: theme.textTheme.labelLarge?.copyWith(
                                                        fontWeight: FontWeight.w800,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                isToday ? "Bugun" : "${dayRows.length} ders",
                                                style: theme.textTheme.labelSmall?.copyWith(
                                                  color: theme.colorScheme.onSurfaceVariant,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Expanded(
                                                child: Column(
                                                  children: [
                                                    Expanded(
                                                      child: _PeriodSection(
                                                        label: "Sabah",
                                                        rows: sabahRows,
                                                        dayColor: _dayColor(day),
                                                        sectionTint: theme.colorScheme.primary.withValues(
                                                          alpha: 0.1,
                                                        ),
                                                        timeOnly: _timeOnly,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 6),
                                                    Expanded(
                                                      child: _PeriodSection(
                                                        label: "Aksam",
                                                        rows: aksamRows,
                                                        dayColor: _dayColor(day),
                                                        sectionTint: theme.colorScheme.tertiary.withValues(
                                                          alpha: 0.12,
                                                        ),
                                                        timeOnly: _timeOnly,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                              ],
                            ),
                    ),
    );
  }
}

class _PeriodHeader extends StatelessWidget {
  const _PeriodHeader({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            "($count)",
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _PeriodSection extends StatelessWidget {
  const _PeriodSection({
    required this.label,
    required this.rows,
    required this.dayColor,
    required this.sectionTint,
    required this.timeOnly,
  });

  final String label;
  final List<Map<String, dynamic>> rows;
  final Color dayColor;
  final Color sectionTint;
  final String Function(Map<String, dynamic>, {String key}) timeOnly;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: sectionTint,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outline, width: 1.1),
      ),
      child: Column(
        children: [
          _PeriodHeader(label: label, count: rows.length),
          const SizedBox(height: 2),
          Expanded(
            child: rows.isEmpty
                ? Center(
                    child: Text(
                      "Bos",
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: rows.length,
                    padding: EdgeInsets.zero,
                    physics: const ClampingScrollPhysics(),
                    itemBuilder: (context, index) {
                      return _TrainingCompactCard(
                        training: rows[index],
                        dayColor: dayColor,
                        timeOnly: timeOnly,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _TrainingCompactCard extends StatelessWidget {
  const _TrainingCompactCard({
    required this.training,
    required this.dayColor,
    required this.timeOnly,
  });

  final Map<String, dynamic> training;
  final Color dayColor;
  final String Function(Map<String, dynamic>, {String key}) timeOnly;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final team = Map<String, dynamic>.from((training["team"] as Map?) ?? <String, dynamic>{});
    final teamName = (team["name"]?.toString() ?? "TAKIM").toUpperCase();
    final startTime = timeOnly(training, key: "time");
    final endTime = timeOnly(training, key: "end_time");
    final location = (training["location"]?.toString() ?? "").toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 5),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: dayColor.withValues(alpha: 0.35), width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$startTime-$endTime",
            style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            teamName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurface,
            ),
          ),
          if (location.isNotEmpty)
            Text(
              location,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }
}
