import "package:flutter/material.dart";

import "../../core/app_nav_drawer.dart";
import "../auth/auth_service.dart";
import "../payments/payment_list_page.dart";
import "../questionnaire/questionnaire_list_page.dart";
import "club_service.dart";
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
  int _bottomIndex = 0;

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
      final results = await Future.wait<dynamic>([
        _authService.me(),
        _clubService.fetchTeams(),
        _clubService.fetchTrainings(),
        _clubService.fetchActiveQuestionnaires(),
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

  Future<void> _handleBottomTap(int index) async {
    setState(() {
      _bottomIndex = index;
    });

    if (index == 0) {
      return;
    }

    Widget? targetPage;
    if (index == 1) {
      targetPage = TrainingWeeklyPage(onLogout: widget.onLogout);
    } else if (index == 2) {
      targetPage = QuestionnaireListPage(onLogout: widget.onLogout);
    } else if (index == 3) {
      targetPage = PaymentListPage(onLogout: widget.onLogout);
    }

    if (targetPage == null) {
      return;
    }

    final navigator = Navigator.of(context);
    await navigator.push(MaterialPageRoute(builder: (_) => targetPage!));

    if (!mounted) {
      return;
    }

    await _loadData();
    if (mounted) {
      setState(() {
        _bottomIndex = 0;
      });
    }
  }

  String _safeName(String source, {String fallback = "Kullanici"}) {
    final value = source.trim();
    return value.isEmpty ? fallback : value;
  }

  int _trainingDayValue(Map<String, dynamic> row) {
    final raw = row["day_of_week"];
    if (raw is num) {
      final value = raw.toInt();
      if (value >= 1 && value <= 7) {
        return value;
      }
      if (value >= 0 && value <= 6) {
        return value + 1;
      }
      return 1;
    }
    if (raw is String) {
      return int.tryParse(raw) ?? 1;
    }
    return 1;
  }

  int _trainingStartMinutes(Map<String, dynamic> row) {
    final value = row["time"]?.toString() ?? "00:00";
    final parts = value.split(":");
    if (parts.length < 2) {
      return 0;
    }
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    return (hour * 60) + minute;
  }

  DateTime _dateForWeekday(int weekday, DateTime from) {
    final monday = from.subtract(Duration(days: from.weekday - 1));
    return DateTime(monday.year, monday.month, monday.day + (weekday - 1));
  }

  List<Map<String, dynamic>> _nearestTrainings(
    List<Map<String, dynamic>> rows,
  ) {
    final now = DateTime.now();
    final withDelta = rows.map((row) {
      final day = _trainingDayValue(row);
      final date = _dateForWeekday(day, now);
      final startMinutes = _trainingStartMinutes(row);
      final startTime = DateTime(
        date.year,
        date.month,
        date.day,
        startMinutes ~/ 60,
        startMinutes % 60,
      );

      var delta = startTime.difference(now);
      if (delta.isNegative) {
        delta += const Duration(days: 7);
      }

      return <String, dynamic>{"row": row, "delta": delta.inMinutes};
    }).toList();

    withDelta.sort((a, b) => (a["delta"] as int).compareTo(b["delta"] as int));

    return withDelta
        .take(3)
        .map((item) => Map<String, dynamic>.from(item["row"] as Map))
        .toList();
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fullName = _safeName(
      "${_me?["adi"] ?? ""} ${_me?["soyadi"] ?? ""}",
      fallback: "Alpha",
    );
    final firstName = _safeName(
      _me?["adi"]?.toString() ?? "",
      fallback: "Sporcu",
    );

    final totalPlanCount =
        (_teams.length + _trainings.length + _questionnaires.length).toDouble();
    final doneLikeCount = (_questionnaires.length + (_trainings.length * 0.5));
    final completion = totalPlanCount == 0
        ? 0.0
        : (doneLikeCount / totalPlanCount).clamp(0.0, 1.0);
    final completionText = "${(completion * 100).round()}%";

    final nearestTrainings = _nearestTrainings(_trainings);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F7),
      drawer: AppNavDrawer(
        fullName: fullName,
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
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF2CC36B),
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => TeamListPage(onLogout: widget.onLogout),
            ),
          );
        },
        child: const Icon(Icons.add, size: 28),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
          child: Container(
            height: 68,
            decoration: BoxDecoration(
              color: const Color(0xFF12233F),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                _BottomNavItem(
                  icon: Icons.home_filled,
                  selected: _bottomIndex == 0,
                  onTap: () => _handleBottomTap(0),
                ),
                _BottomNavItem(
                  icon: Icons.calendar_month_outlined,
                  selected: _bottomIndex == 1,
                  onTap: () => _handleBottomTap(1),
                ),
                const SizedBox(width: 54),
                _BottomNavItem(
                  icon: Icons.assignment_turned_in_outlined,
                  selected: _bottomIndex == 2,
                  onTap: () => _handleBottomTap(2),
                ),
                _BottomNavItem(
                  icon: Icons.payments_outlined,
                  selected: _bottomIndex == 3,
                  onTap: () => _handleBottomTap(3),
                ),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 100),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Welcome Back",
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            firstName,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF12233F),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Bildirimler yakinda eklenecek."),
                          ),
                        );
                      },
                      icon: const Icon(Icons.notifications_none_rounded),
                    ),
                    Builder(
                      builder: (context) => IconButton(
                        onPressed: () => Scaffold.of(context).openDrawer(),
                        icon: const Icon(Icons.menu_rounded),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Card(
                  color: const Color(0xFF10213E),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
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
                                "Excellent, bugunku planin ilerliyor",
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 10),
                              OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(color: Colors.white70),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onPressed: () => _handleBottomTap(1),
                                child: const Text("View Plan"),
                              ),
                            ],
                          ),
                        ),
                        _ProgressRing(value: completion, label: completionText),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Text(
                      "",
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    TextButton(onPressed: () {}, child: const Text("See all")),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _QuickCategoryCard(
                        icon: Icons.groups_2_rounded,
                        title: "Takimlar",
                        subtitle: "${_teams.length} plan",
                        action: "",
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  TeamListPage(onLogout: widget.onLogout),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _QuickCategoryCard(
                        icon: Icons.fitness_center_rounded,
                        title: "Antrenman",
                        subtitle: "${_trainings.length} plan",
                        action: "",
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  TrainingWeeklyPage(onLogout: widget.onLogout),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Text(
                      "Yakın Antrenmanlar",
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => _handleBottomTap(2),
                      child: const Text("See all"),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                if (nearestTrainings.isEmpty)
                  Card(
                    elevation: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        "Su an devam eden plan bulunmuyor.",
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  )
                else ...[
                  ...nearestTrainings.map((training) {
                    final team = Map<String, dynamic>.from(
                      (training["team"] as Map?) ?? <String, dynamic>{},
                    );
                    final teamName =
                        team["name"]?.toString() ??
                        training["team_name"]?.toString() ??
                        "Takim";
                    final teamStyle = _teamColorStyle(teamName);

                    return _TaskTile(
                      title:
                          "${training["day_name"] ?? "Gun"} - ${training["time"] ?? "Saat"}",
                      subtitle: training["location"]?.toString() ?? "Antrenman",
                      teamName: teamName,
                      teamBg: teamStyle.bg,
                      teamFg: teamStyle.fg,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                TrainingWeeklyPage(onLogout: widget.onLogout),
                          ),
                        );
                      },
                    );
                  }),
                ],
              ],
            ),
    );
  }
}

class _ProgressRing extends StatelessWidget {
  const _ProgressRing({required this.value, required this.label});

  final double value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 72,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CircularProgressIndicator(
            value: value,
            strokeWidth: 6,
            backgroundColor: Colors.white24,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          ),
          Center(
            child: Text(
              label,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickCategoryCard extends StatelessWidget {
  const _QuickCategoryCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.action,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: const Color(0xFF10213E)),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    action,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF10213E),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.arrow_forward, size: 14),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.teamName,
    this.teamBg,
    this.teamFg,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final String? teamName;
  final Color? teamBg;
  final Color? teamFg;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: const Color(0xFF2CC36B).withValues(alpha: 0.16),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check, size: 16, color: Color(0xFF18A355)),
        ),
        title: Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (teamName != null && teamName!.trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: teamBg ?? const Color(0xFFE8EBF1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  teamName!,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: teamFg ?? const Color(0xFF3F4653),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkResponse(
        onTap: onTap,
        radius: 26,
        child: Icon(
          icon,
          color: selected ? Colors.white : Colors.white70,
          size: 22,
        ),
      ),
    );
  }
}
