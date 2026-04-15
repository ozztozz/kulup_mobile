import "package:flutter/material.dart";

import "club_service.dart";
import "team_detail_page.dart";

class TeamListPage extends StatefulWidget {
  const TeamListPage({super.key});

  @override
  State<TeamListPage> createState() => _TeamListPageState();
}

class _TeamListPageState extends State<TeamListPage> {
  final ClubService _clubService = ClubService();

  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _teams = <Map<String, dynamic>>[];

  @override
  void initState() {
    super.initState();
    _loadTeams();
  }

  Future<void> _loadTeams() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final teams = await _clubService.fetchTeams();
      if (!mounted) {
        return;
      }
      setState(() {
        _teams = teams;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = "Takimlar yuklenemedi: $e";
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final monthLabel = _monthLabel(now.month);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Takimlar"),
        actions: [
          IconButton(
            onPressed: _loadTeams,
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
              theme.colorScheme.primaryContainer.withValues(alpha: 0.22),
              theme.scaffoldBackgroundColor,
            ],
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!))
                : RefreshIndicator(
                    onRefresh: _loadTeams,
                    child: _teams.isEmpty
                        ? ListView(
                            padding: const EdgeInsets.all(16),
                            children: const [
                              SizedBox(height: 120),
                              Center(child: Text("Takim bulunamadi.")),
                            ],
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _teams.length + 1,
                            itemBuilder: (context, index) {
                              if (index == 0) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 14),
                                  child: _TopActionCard(
                                    onViewTeams: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text("Takim listesi guncel goruntuleniyor."),
                                        ),
                                      );
                                    },
                                    onCreateTeam: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text("Yeni takim olusturma yakinda eklenecek."),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              }

                              final team = _teams[index - 1];
                              final name = (team["name"]?.toString() ?? "-").toUpperCase();
                              final description = team["description"]?.toString() ?? "";
                              final memberCount =
                                  (team["member_count"] as num?)?.toInt().toString() ?? "-";

                              return Card(
                                margin: const EdgeInsets.only(bottom: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  side: BorderSide(color: theme.colorScheme.outlineVariant),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(14, 16, 14, 12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Center(
                                        child: Container(
                                          width: 82,
                                          height: 82,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: theme.colorScheme.primary,
                                            boxShadow: const [
                                              BoxShadow(
                                                color: Color(0x33000000),
                                                blurRadius: 10,
                                                offset: Offset(0, 6),
                                              ),
                                            ],
                                          ),
                                          child: const Icon(
                                            Icons.groups_2_outlined,
                                            color: Colors.white,
                                            size: 38,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 14),
                                      Text(
                                        name,
                                        style: theme.textTheme.headlineSmall?.copyWith(
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      if (description.isNotEmpty) ...[
                                        const SizedBox(height: 6),
                                        Text(
                                          description,
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            color: theme.colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 14),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.groups_2_outlined,
                                                  size: 16,
                                                  color: theme.colorScheme.onSurfaceVariant,
                                                ),
                                                const SizedBox(width: 6),
                                                Text("$memberCount Uye"),
                                              ],
                                            ),
                                          ),
                                          Expanded(
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.end,
                                              children: [
                                                Icon(
                                                  Icons.calendar_today_outlined,
                                                  size: 16,
                                                  color: theme.colorScheme.onSurfaceVariant,
                                                ),
                                                const SizedBox(width: 6),
                                                Text("$monthLabel ${now.year}"),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: TextButton(
                                              onPressed: () {
                                                Navigator.of(context).push(
                                                  MaterialPageRoute(
                                                    builder: (_) => TeamDetailPage(team: team),
                                                  ),
                                                );
                                              },
                                              child: const Text("Detaylar"),
                                            ),
                                          ),
                                          Expanded(
                                            child: TextButton(
                                              onPressed: () {
                                                Navigator.of(context).push(
                                                  MaterialPageRoute(
                                                    builder: (_) => TeamDetailPage(team: team),
                                                  ),
                                                );
                                              },
                                              child: const Text("Uyeler"),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
      ),
    );
  }

  String _monthLabel(int month) {
    const months = <String>[
      "Oca",
      "Sub",
      "Mar",
      "Nis",
      "May",
      "Haz",
      "Tem",
      "Agu",
      "Eyl",
      "Eki",
      "Kas",
      "Ara",
    ];

    if (month < 1 || month > 12) {
      return "-";
    }
    return months[month - 1];
  }
}

class _TopActionCard extends StatelessWidget {
  const _TopActionCard({required this.onViewTeams, required this.onCreateTeam});

  final VoidCallback onViewTeams;
  final VoidCallback onCreateTeam;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: const Color(0xFF0A84D0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.work_outline, color: Colors.white, size: 32),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Takimlar",
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Kulubunuzdeki tum takimlari kesfedin",
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withValues(alpha: 0.92),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              children: [
                TextButton.icon(
                  onPressed: onViewTeams,
                  style: TextButton.styleFrom(foregroundColor: Colors.white),
                  icon: const Icon(Icons.remove_red_eye_outlined, size: 18),
                  label: const Text("Gor"),
                ),
                TextButton.icon(
                  onPressed: onCreateTeam,
                  style: TextButton.styleFrom(foregroundColor: Colors.white),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text("Yeni Takim"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
