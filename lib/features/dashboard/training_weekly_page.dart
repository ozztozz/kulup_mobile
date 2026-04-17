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
  final ScrollController _dayScrollController = ScrollController();

  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _trainings = <Map<String, dynamic>>[];
  int _selectedDay = DateTime.now().weekday;

  static const Map<int, String> _weekdayNames = <int, String>{
    1: "Pzt",
    2: "Sal",
    3: "Car",
    4: "Per",
    5: "Cum",
    6: "Cmt",
    7: "Paz",
  };

  static const Map<int, String> _weekdayLongNames = <int, String>{
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
    _dayScrollController.dispose();
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

  int _dayValue(Map<String, dynamic> row) {
    final raw = row["day_of_week"];
    if (raw is num) {
      final value = raw.toInt();
      if (value >= 1 && value <= 7) {
        return value;
      }
      if (value >= 0 && value <= 6) {
        return value + 1;
      }
      return 0;
    }
    if (raw is String) {
      final parsed = int.tryParse(raw);
      if (parsed != null) {
        if (parsed >= 1 && parsed <= 7) {
          return parsed;
        }
        if (parsed >= 0 && parsed <= 6) {
          return parsed + 1;
        }
      }

      final normalized = raw.trim().toLowerCase();
      const dayNames = <String, int>{
        "pzt": 1,
        "pazartesi": 1,
        "sal": 2,
        "salı": 2,
        "sali": 2,
        "çarşamba": 3,
        "carsamba": 3,
        "car": 3,
        "per": 4,
        "perşembe": 4,
        "persembe": 4,
        "cum": 5,
        "cuma": 5,
        "cmt": 6,
        "cumartesi": 6,
        "paz": 7,
        "pazar": 7,
      };
      return dayNames[normalized] ?? 0;
    }
    return 0;
  }

  String _dayLabel(int day) {
    return _weekdayNames[day] ?? "Day";
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

  List<int> _weekDays() => const <int>[1, 2, 3, 4, 5, 6, 7];

  List<Map<String, dynamic>> _rowsForDay(int day) {
    final grouped = _groupedTrainings();
    return grouped[day] ?? <Map<String, dynamic>>[];
  }

  int _startMinutes(Map<String, dynamic> row, {String key = "time"}) {
    final value = _timeOnly(row, key: key);
    final parts = value.split(":");
    if (parts.length < 2) {
      return 24 * 60;
    }
    return (int.tryParse(parts[0]) ?? 0) * 60 + (int.tryParse(parts[1]) ?? 0);
  }

  int _endMinutes(Map<String, dynamic> row) {
    final end = _startMinutes(row, key: "end_time");
    if (end == 24 * 60) {
      return _startMinutes(row) + 60;
    }
    return end <= _startMinutes(row) ? _startMinutes(row) + 60 : end;
  }

  DateTime _dateForWeekday(int weekday) {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    return DateTime(monday.year, monday.month, monday.day + (weekday - 1));
  }

  String _monthName(int month) {
    const names = <String>[
      "Ocak",
      "Subat",
      "Mart",
      "Nisan",
      "Mayis",
      "Haziran",
      "Temmuz",
      "Agustos",
      "Eylul",
      "Ekim",
      "Kasim",
      "Aralik",
    ];
    return names[month - 1];
  }

  String _selectedDateLabel(DateTime date) {
    final longDay = _weekdayLongNames[date.weekday] ?? _dayLabel(date.weekday);
    return "${_monthName(date.month)} ${date.day}, $longDay";
  }

  String _timeRangeLabel(Map<String, dynamic> row) {
    final start = _timeOnly(row, key: "time");
    final end = _timeOnly(row, key: "end_time");
    if (end.isEmpty) {
      return start;
    }
    return "$start - $end";
  }

  ({Color bg, Color fg}) _teamColorStyle(String teamName) {
    final normalized = teamName.trim().toUpperCase();
    if (normalized.contains("KIRMIZI")) {
      return (bg: const Color(0xFFF8D7DA), fg: const Color(0xFF7A1C24));
    }
    if (normalized.contains("TURUNCU")) {
      return (bg: const Color(0xFFFFE4CC), fg: const Color(0xFF8A4A0F));
    }
    if (normalized.contains("MAVI") || normalized.contains("BLUE")) {
      return (bg: const Color(0xFFD8E7FF), fg: const Color(0xFF1D3F73));
    }
    if (normalized.contains("YESIL") || normalized.contains("GREEN")) {
      return (bg: const Color(0xFFDCEFD8), fg: const Color(0xFF2D5B2E));
    }
    return (bg: const Color(0xFFE8EBF1), fg: const Color(0xFF3F4653));
  }

  void _scrollToSelectedDay() {
    if (!_dayScrollController.hasClients) {
      return;
    }

    const chipWidth = 56.0;
    const chipGap = 10.0;
    final offset = (_selectedDay - 1) * (chipWidth + chipGap);
    final maxOffset = _dayScrollController.position.maxScrollExtent;
    final targetOffset = offset.clamp(0.0, maxOffset);

    _dayScrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedRows = _rowsForDay(_selectedDay);
    final selectedDate = _dateForWeekday(_selectedDay);
    final now = DateTime.now();
    final isToday =
        now.year == selectedDate.year &&
        now.month == selectedDate.month &&
        now.day == selectedDate.day;
    final todayMinutes = now.hour * 60 + now.minute;

    final listItems = selectedRows.map((training) {
      final team = Map<String, dynamic>.from(
        (training["team"] as Map?) ?? <String, dynamic>{},
      );
      final title =
          team["name"]?.toString() ??
          training["team_name"]?.toString() ??
          training["title"]?.toString() ??
          "Antrenman";
      final location = (training["location"]?.toString() ?? "").trim();
      final trainerName = (training["trainer_name"]?.toString() ?? "").trim();
      final timeLabel = _timeRangeLabel(training);
      final start = _startMinutes(training);
      final end = _endMinutes(training);
      final isCurrent = isToday && todayMinutes >= start && todayMinutes <= end;

      final details = <String>[
        timeLabel,
        if (location.isNotEmpty) location,
        if (trainerName.isNotEmpty) trainerName,
      ].join(" • ");
      final teamStyle = _teamColorStyle(title);

      return <String, dynamic>{
        "title": title,
        "details": details,
        "isCurrent": isCurrent,
        "start": start,
        "teamBg": teamStyle.bg,
        "teamFg": teamStyle.fg,
      };
    }).toList();
    final morningItems = listItems
        .where((item) => (item["start"] as int? ?? 0) < 12 * 60)
        .toList();
    final eveningItems = listItems
        .where((item) => (item["start"] as int? ?? 0) >= 12 * 60)
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFEFF0F3),
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
        title: const Text("Training Weekly"),
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
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreateTraining,
        backgroundColor: const Color(0xFF2CC36B),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : RefreshIndicator(
              onRefresh: _loadTrainings,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 96),
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F7F8),
                      borderRadius: BorderRadius.circular(26),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            SizedBox(
                              width: 40,
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () {
                                  setState(() {
                                    _selectedDay = _selectedDay == 1
                                        ? 7
                                        : _selectedDay - 1;
                                  });
                                },
                                icon: const Icon(Icons.chevron_left_rounded),
                              ),
                            ),
                            const Expanded(
                              child: Text(
                                "Timeline",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 28,
                                  color: Color(0xFF2B2D33),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 40,
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: _openCreateTraining,
                                icon: const Icon(
                                  Icons.add_circle_outline_rounded,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFEFF1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                          child: Row(
                            children: _weekDays().map((day) {
                              final date = _dateForWeekday(day);
                              final isSelected = day == _selectedDay;
                              return Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedDay = day;
                                    });
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 2,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: isSelected
                                          ? [
                                              BoxShadow(
                                                color: Colors.black.withValues(
                                                  alpha: 0.06,
                                                ),
                                                blurRadius: 8,
                                                offset: const Offset(0, 3),
                                              ),
                                            ]
                                          : null,
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          _dayLabel(day),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isSelected
                                                ? const Color(0xFF5E6370)
                                                : const Color(0xFF8C909A),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "${date.day}",
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w800,
                                            color: isSelected
                                                ? const Color(0xFF2E3138)
                                                : const Color(0xFF606470),
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
                        const SizedBox(height: 18),
                        Text(
                          _selectedDateLabel(selectedDate),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2F3239),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          selectedRows.isEmpty
                              ? "Bu gunde antrenman yok"
                              : "${selectedRows.length} antrenman",
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF7C8390),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 14),
                        if (listItems.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF4F6F8),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFD9DEE6),
                              ),
                            ),
                            child: const Text(
                              "Bu gun icin antrenman yok",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFF5F6775),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          )
                        else
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Sabah",
                                style: TextStyle(
                                  color: Color(0xFF5E6370),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (morningItems.isEmpty)
                                Container(
                                  width: double.infinity,
                                  margin: const EdgeInsets.only(bottom: 14),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF3D6),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: const Color(0xFFF0C97A),
                                    ),
                                  ),
                                  child: const Text(
                                    "Antrenman yok",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Color(0xFF8A6412),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                )
                              else
                                ...List.generate(morningItems.length, (index) {
                                  final item = morningItems[index];
                                  final isCurrent = item["isCurrent"] == true;
                                  final teamBg =
                                      item["teamBg"] as Color? ??
                                      const Color(0xFFE8EBF1);
                                  final teamFg =
                                      item["teamFg"] as Color? ??
                                      const Color(0xFF3F4653);
                                  return Container(
                                    margin: EdgeInsets.only(
                                      bottom: index == morningItems.length - 1
                                          ? 14
                                          : 10,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isCurrent
                                          ? const Color(0xFF232A38)
                                          : const Color(0xFFD5EBD4),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: teamBg,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Text(
                                            item["title"]?.toString() ??
                                                "Antrenman",
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: teamFg,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          item["details"]?.toString() ?? "",
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: isCurrent
                                                ? Colors.white70
                                                : const Color(0xFF5E6B62),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              const Text(
                                "Aksam",
                                style: TextStyle(
                                  color: Color(0xFF5E6370),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (eveningItems.isEmpty)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF3D6),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: const Color(0xFFF0C97A),
                                    ),
                                  ),
                                  child: const Text(
                                    "Antrenman yok",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Color(0xFF8A6412),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                )
                              else
                                ...List.generate(eveningItems.length, (index) {
                                  final item = eveningItems[index];
                                  final isCurrent = item["isCurrent"] == true;
                                  final teamBg =
                                      item["teamBg"] as Color? ??
                                      const Color(0xFFE8EBF1);
                                  final teamFg =
                                      item["teamFg"] as Color? ??
                                      const Color(0xFF3F4653);
                                  return Container(
                                    margin: EdgeInsets.only(
                                      bottom: index == eveningItems.length - 1
                                          ? 0
                                          : 10,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isCurrent
                                          ? const Color(0xFF232A38)
                                          : const Color(0xFFD5EBD4),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: teamBg,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Text(
                                            item["title"]?.toString() ??
                                                "Antrenman",
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: teamFg,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          item["details"]?.toString() ?? "",
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: isCurrent
                                                ? Colors.white70
                                                : const Color(0xFF5E6B62),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                            ],
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
