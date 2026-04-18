import "package:flutter/material.dart";

import "../../core/app_footer_menu.dart";
import "../../core/app_nav_drawer.dart";
import "../../core/app_top_bar.dart";
import "../../core/team_logo_avatar.dart";
import "club_service.dart";
import "team_detail_page.dart";
import "../manage/team_create_page.dart";
import "../payments/payment_list_page.dart";
import "training_weekly_page.dart";
import "../questionnaire/questionnaire_list_page.dart";

class TeamListPage extends StatefulWidget {
  const TeamListPage({super.key, required this.onLogout});

  final VoidCallback onLogout;

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

  ({Color bg, Color fg}) _teamColorStyle(String teamName) {
    final normalized = teamName.trim().toUpperCase();
    if (normalized.contains("KIRMIZI")) {
      return (bg: const Color(0xFFB3262D), fg: Colors.white);
    }
    if (normalized.contains("TURUNCU")) {
      return (bg: const Color(0xFFCB6A14), fg: Colors.white);
    }
    if (normalized.contains("MAVI") || normalized.contains("BLUE")) {
      return (bg: const Color(0xFF145EA8), fg: Colors.white);
    }
    if (normalized.contains("YESIL") || normalized.contains("GREEN")) {
      return (bg: const Color(0xFF18864A), fg: Colors.white);
    }
    return (bg: const Color(0xFF12233F), fg: Colors.white);
  }

  void _handleBottomTap(int index) {
    if (index == 0) {
      Navigator.of(context).popUntil((route) => route.isFirst);
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

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => targetPage!),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AppNavDrawer(
        fullName: "Alpha",
        currentSection: AppNavSection.teams,
        onHome: () {
          Navigator.of(context).pop();
          Navigator.of(context).popUntil((route) => route.isFirst);
        },
        onTeams: () {
          Navigator.of(context).pop();
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
        onLogout: widget.onLogout,
      ),
      appBar: AppTopBar(
        title: const Text("Takimlar"),
        actions: [
          IconButton(
            onPressed: _openCreateTeam,
            icon: const Icon(Icons.add),
            tooltip: "Yeni takim",
          ),
          IconButton(
            onPressed: _loadTeams,
            icon: const Icon(Icons.refresh),
            tooltip: "Yenile",
          ),
        ],
      ),
      bottomNavigationBar: AppFooterMenu(
        selectedIndex: null,
        onTap: _handleBottomTap,
      ),
      body: _isLoading
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
                                      _openCreateTeam();
                                    },
                                  ),
                                );
                              }

                              final team = _teams[index - 1];
                              final name = (team["name"]?.toString() ?? "Takim").trim();
                              final teamStyle = _teamColorStyle(name);

                              return Container(
                                margin: const EdgeInsets.only(bottom: 14),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(28),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x1A000000),
                                      blurRadius: 16,
                                      offset: Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(28),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(28),
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => TeamDetailPage(
                                            team: team,
                                            onLogout: widget.onLogout,
                                          ),
                                        ),
                                      );
                                    },
                                    child: SizedBox(
                                      height: 210,
                                      child: Column(
                                        children: [
                                          Expanded(
                                            child: Center(
                                              child: TeamLogoAvatar(
                                                team: team,
                                                size: 108,
                                                borderRadius: 22,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 12,
                                            ),
                                            decoration: BoxDecoration(
                                              color: teamStyle.bg,
                                              borderRadius: const BorderRadius.only(
                                                bottomLeft: Radius.circular(28),
                                                bottomRight: Radius.circular(28),
                                              ),
                                            ),
                                            child: Text(
                                              name,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color: teamStyle.fg,
                                                fontWeight: FontWeight.w800,
                                                fontSize: 20,
                                                letterSpacing: 0.2,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                        ),
                ),
    );
  }

  Future<void> _openCreateTeam() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => TeamCreatePage(onLogout: widget.onLogout),
      ),
    );
    if (created == true && mounted) {
      await _loadTeams();
    }
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
      color: theme.colorScheme.primary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: theme.colorScheme.onPrimary.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.work_outline,
                color: theme.colorScheme.onPrimary,
                size: 32,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Takimlar",
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Kulubunuzdeki tum takimlari kesfedin",
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onPrimary.withValues(alpha: 0.92),
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
                  style: TextButton.styleFrom(foregroundColor: theme.colorScheme.onPrimary),
                  icon: const Icon(Icons.remove_red_eye_outlined, size: 18),
                  label: const Text("Gor"),
                ),
                TextButton.icon(
                  onPressed: onCreateTeam,
                  style: TextButton.styleFrom(foregroundColor: theme.colorScheme.onPrimary),
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
