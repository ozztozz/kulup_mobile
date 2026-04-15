import "package:flutter/material.dart";

import "../auth/auth_service.dart";
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

  Map<String, dynamic>? _me;
  List<Map<String, dynamic>> _teams = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _trainings = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _payments = <Map<String, dynamic>>[];
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
      final now = DateTime.now();
      final month = DateTime(now.year, now.month, 1).toIso8601String().split("T").first;

      final meFuture = _authService.me();
      final teamsFuture = _clubService.fetchTeams();
      final trainingsFuture = _clubService.fetchTrainings();
      final paymentsFuture = _clubService.fetchPayments(month: month);
      final questionnairesFuture = _clubService.fetchActiveQuestionnaires();

      final results = await Future.wait<dynamic>([
        meFuture,
        teamsFuture,
        trainingsFuture,
        paymentsFuture,
        questionnairesFuture,
      ]);

      if (!mounted) {
        return;
      }

      setState(() {
        _me = results[0] as Map<String, dynamic>;
        _teams = results[1] as List<Map<String, dynamic>>;
        _trainings = results[2] as List<Map<String, dynamic>>;
        _payments = results[3] as List<Map<String, dynamic>>;
        _questionnaires = results[4] as List<Map<String, dynamic>>;
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fullName = "${_me?["adi"] ?? ""} ${_me?["soyadi"] ?? ""}".trim();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                "assets/images/logo.png",
                width: 28,
                height: 28,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 10),
            const Text("Kulup Dashboard"),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            tooltip: "Refresh",
          ),
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            tooltip: "Logout",
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          image: const DecorationImage(
            image: AssetImage("assets/images/background.jpg"),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                theme.scaffoldBackgroundColor.withValues(alpha: 0.90),
                theme.scaffoldBackgroundColor.withValues(alpha: 0.97),
              ],
            ),
          ),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(child: Text(_error!))
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                      Container(
                        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: theme.colorScheme.outlineVariant),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fullName.isEmpty ? "Kulup Yonetimi" : fullName,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "Kulubunuzdeki tum takimlari ve antrenmanlari yonetin",
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _StatPill(label: "Takim", value: _teams.length.toString()),
                                _StatPill(
                                  label: "Antrenman",
                                  value: _trainings.length.toString(),
                                ),
                                _StatPill(
                                  label: "Anket",
                                  value: _questionnaires.length.toString(),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _ActionMenuCard(
                        title: "Takimlari Goruntule",
                        subtitle: "Kulubunuzdeki tum takimlari kesfedin",
                        icon: Icons.inventory_2_outlined,
                        color: const Color(0xFF0A84D0),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const TeamListPage(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      _ActionMenuCard(
                        title: "Yeni Takim Olustur",
                        subtitle: "Kulube yeni bir takim ekleyin",
                        icon: Icons.add,
                        color: const Color(0xFF14A443),
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Takim olusturma yakinda eklenecek.")),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      _ActionMenuCard(
                        title: "Anketler",
                        subtitle: "Kulup genelindeki anketleri goruntuleyin",
                        icon: Icons.assignment_outlined,
                        color: const Color(0xFFF4C300),
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const QuestionnaireListPage(),
                            ),
                          );
                          if (mounted) {
                            await _loadData();
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      const _ActionMenuCard(
                        title: "Ayarlar",
                        subtitle: "Tercihlerinizi yapilandirin\nYakinda Geliyor",
                        icon: Icons.settings,
                        color: Color(0xFFB3BDCC),
                        enabled: false,
                      ),
                      const SizedBox(height: 12),
                      _ActionMenuCard(
                        title: "Haftalik Antrenman",
                        subtitle: "Programi gunlere gore goruntuleyin",
                        icon: Icons.calendar_view_week,
                        color: const Color(0xFF5A67D8),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const TrainingWeeklyPage(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        "$label: $value",
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ActionMenuCard extends StatelessWidget {
  const _ActionMenuCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.onTap,
    this.enabled = true,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: enabled ? 2 : 0,
      color: enabled ? theme.colorScheme.surface : theme.colorScheme.surface.withValues(alpha: 0.6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: enabled ? color : const Color(0xFFC7CFDC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: enabled ? null : theme.colorScheme.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.2,
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
  }
}
