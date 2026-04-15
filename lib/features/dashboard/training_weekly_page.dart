import "package:flutter/material.dart";

import "club_service.dart";

class TrainingWeeklyPage extends StatefulWidget {
  const TrainingWeeklyPage({super.key});

  @override
  State<TrainingWeeklyPage> createState() => _TrainingWeeklyPageState();
}

class _TrainingWeeklyPageState extends State<TrainingWeeklyPage> {
  final ClubService _clubService = ClubService();

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

  static const List<Color> _dayHeaderStartColors = <Color>[
    Color(0xFF71B2F2),
    Color(0xFF63B8D8),
    Color(0xFF8AB4F8),
    Color(0xFF72A1FF),
    Color(0xFF79B0E2),
    Color(0xFF61C7D8),
    Color(0xFF8FAEE8),
  ];

  @override
  void initState() {
    super.initState();
    _loadTrainings();
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
      rows.sort((a, b) => _timeOnly(a).compareTo(_timeOnly(b)));
    }

    return grouped;
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

  int _minutesBetween(String start, String end) {
    final s = start.split(":");
    final e = end.split(":");
    if (s.length < 2 || e.length < 2) {
      return 0;
    }
    final sMinutes = (int.tryParse(s[0]) ?? 0) * 60 + (int.tryParse(s[1]) ?? 0);
    final eMinutes = (int.tryParse(e[0]) ?? 0) * 60 + (int.tryParse(e[1]) ?? 0);
    final diff = eMinutes - sMinutes;
    return diff > 0 ? diff : 0;
  }

  List<Map<String, dynamic>> _upcomingTrainings(Map<int, List<Map<String, dynamic>>> grouped) {
    final rows = <Map<String, dynamic>>[];
    for (final key in grouped.keys.toList()..sort()) {
      rows.addAll(grouped[key] ?? <Map<String, dynamic>>[]);
    }
    return rows.take(3).toList();
  }

  Map<String, dynamic> _teamSummary() {
    final byTeam = <String, int>{};
    var totalMinutes = 0;

    for (final row in _trainings) {
      final team = Map<String, dynamic>.from((row["team"] as Map?) ?? <String, dynamic>{});
      final teamName = team["name"]?.toString().trim();
      if (teamName != null && teamName.isNotEmpty) {
        byTeam[teamName] = (byTeam[teamName] ?? 0) + 1;
      }

      totalMinutes += _minutesBetween(
        _timeOnly(row, key: "time"),
        _timeOnly(row, key: "end_time"),
      );
    }

    return <String, dynamic>{
      "counts": byTeam,
      "minutes": totalMinutes,
    };
  }

  List<String> _locations() {
    final set = <String>{};
    for (final row in _trainings) {
      final location = row["location"]?.toString().trim() ?? "";
      if (location.isNotEmpty) {
        set.add(location.toUpperCase());
      }
    }
    return set.toList()..sort();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final grouped = _groupedTrainings();
    final dayKeys = grouped.keys.toList()..sort();
    final upcoming = _upcomingTrainings(grouped);
    final teamSummary = _teamSummary();
    final teamCounts = (teamSummary["counts"] as Map<String, int>? ?? <String, int>{}).entries.toList();
    final totalMinutes = teamSummary["minutes"] as int? ?? 0;
    final locations = _locations();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Haftalik Antrenman Programi"),
        actions: [
          IconButton(
            onPressed: _loadTrainings,
            icon: const Icon(Icons.refresh),
            tooltip: "Yenile",
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
                    onRefresh: _loadTrainings,
                    child: dayKeys.isEmpty
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
                                "Haftalik Antrenman\nProgrami",
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _SummarySurfaceCard(
                                borderColor: const Color(0xFF00A8FF),
                                title: "Siradaki 3 Antrenman",
                                child: Column(
                                  children: upcoming.map((training) {
                                    final team = Map<String, dynamic>.from(
                                      (training["team"] as Map?) ?? <String, dynamic>{},
                                    );
                                    final teamName = team["name"]?.toString() ?? "TAKIM";
                                    final location =
                                        (training["location"]?.toString() ?? "").toUpperCase();
                                    final startTime = _timeOnly(training, key: "time");
                                    final endTime = _timeOnly(training, key: "end_time");
                                    final day = _dayValue(training);

                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 10),
                                      child: Row(
                                        children: [
                                          _MiniDayBadge(
                                            label: _dayLabel(day, <Map<String, dynamic>>[training]),
                                          ),
                                          const SizedBox(width: 8),
                                          SizedBox(
                                            width: 84,
                                            child: Text(
                                              "$startTime -\n$endTime",
                                              style: theme.textTheme.titleSmall,
                                            ),
                                          ),
                                          Expanded(
                                            child: Text(
                                              "$teamName${location.isEmpty ? "" : "  $location"}",
                                              style: theme.textTheme.bodyLarge?.copyWith(
                                                color: theme.colorScheme.onSurfaceVariant,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                              const SizedBox(height: 12),
                              _SummarySurfaceCard(
                                borderColor: const Color(0xFF5E6A84),
                                title: "Takima Gore Antrenmanlar",
                                child: Column(
                                  children: [
                                    for (final row in teamCounts)
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 6),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                row.key.toUpperCase(),
                                                style: theme.textTheme.titleSmall,
                                              ),
                                            ),
                                            Text("${row.value} antrenman"),
                                          ],
                                        ),
                                      ),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: Text(
                                        "$totalMinutes dk",
                                        style: theme.textTheme.titleSmall,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              _SummarySurfaceCard(
                                borderColor: const Color(0xFFFF8A00),
                                title: "Antrenman Lokasyonlari",
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: locations
                                      .map(
                                        (location) => Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFF8A00),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            location,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                ),
                              ),
                              const SizedBox(height: 14),
                              ...dayKeys.asMap().entries.map((entry) {
                                final index = entry.key;
                                final day = entry.value;
                                final dayRows = grouped[day] ?? <Map<String, dynamic>>[];
                                final dayTitle = _dayLabel(day, dayRows);
                                final startColor =
                                    _dayHeaderStartColors[index % _dayHeaderStartColors.length];

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Column(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          borderRadius: const BorderRadius.only(
                                            topLeft: Radius.circular(14),
                                            topRight: Radius.circular(14),
                                          ),
                                          gradient: LinearGradient(
                                            colors: <Color>[startColor, const Color(0xFF0A8BC7)],
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Text(
                                              dayTitle,
                                              style: theme.textTheme.titleMedium?.copyWith(
                                                color: Colors.black.withValues(alpha: 0.9),
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                            const Spacer(),
                                            Container(
                                              width: 30,
                                              height: 26,
                                              decoration: BoxDecoration(
                                                color: Colors.white.withValues(alpha: 0.92),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: const Icon(Icons.add, size: 18),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Column(
                                          children: dayRows.map((training) {
                                            final team = Map<String, dynamic>.from(
                                              (training["team"] as Map?) ?? <String, dynamic>{},
                                            );
                                            final teamName =
                                                (team["name"]?.toString() ?? "TAKIM").toUpperCase();
                                            final startTime = _timeOnly(training, key: "time");
                                            final endTime = _timeOnly(training, key: "end_time");
                                            final location =
                                                (training["location"]?.toString() ?? "").toUpperCase();

                                            return Container(
                                              margin: const EdgeInsets.only(bottom: 10),
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 8,
                                              ),
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(10),
                                                color: theme.colorScheme.surfaceContainerLow,
                                              ),
                                              child: Row(
                                                children: [
                                                  SizedBox(
                                                    width: 98,
                                                    child: Text(
                                                      "$startTime - $endTime",
                                                      style: theme.textTheme.titleSmall,
                                                    ),
                                                  ),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          teamName,
                                                          style: theme.textTheme.titleSmall,
                                                        ),
                                                        if (location.isNotEmpty)
                                                          Text(
                                                            location,
                                                            style:
                                                                theme.textTheme.bodySmall?.copyWith(
                                                                  color: theme.colorScheme
                                                                      .onSurfaceVariant,
                                                                ),
                                                          ),
                                                      ],
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  const Icon(Icons.edit_outlined, size: 18),
                                                  const SizedBox(width: 6),
                                                  const Icon(Icons.delete_outline, size: 18),
                                                ],
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                    ],
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

class _SummarySurfaceCard extends StatelessWidget {
  const _SummarySurfaceCard({
    required this.title,
    required this.child,
    required this.borderColor,
  });

  final String title;
  final Widget child;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: borderColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                child,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniDayBadge extends StatelessWidget {
  const _MiniDayBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFF6E6E),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
