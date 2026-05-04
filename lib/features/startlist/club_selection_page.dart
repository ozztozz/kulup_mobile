import "package:flutter/material.dart";

import "../../core/app_nav_drawer.dart";
import "../../core/app_top_bar.dart";
import "../auth/auth_service.dart";
import "../dashboard/team_list_page.dart";
import "../dashboard/training_weekly_page.dart";
import "../payments/payment_list_page.dart";
import "../questionnaire/questionnaire_list_page.dart";
import "startlist_page.dart";
import "startlist_service.dart";

class ClubSelectionPage extends StatefulWidget {
  final Map<String, dynamic> event;
  final VoidCallback onLogout;

  const ClubSelectionPage({
    super.key,
    required this.event,
    required this.onLogout,
  });

  @override
  State<ClubSelectionPage> createState() => _ClubSelectionPageState();
}

class _ClubSelectionPageState extends State<ClubSelectionPage> {
  final StartListService _service = StartListService();
  final AuthService _authService = AuthService();

  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _clubs = <Map<String, dynamic>>[];

  @override
  void initState() {
    super.initState();
    _loadClubs();
  }

  Future<void> _loadClubs() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final clubs = await _service.fetchClubs(event: widget.event);
      if (!mounted) {
        return;
      }
      setState(() {
        _clubs = clubs;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = "Kulup listesi yuklenemedi: $e";
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

  void _selectClub(Map<String, dynamic> club) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StartListPage(
          event: widget.event,
          club: club,
          onLogout: widget.onLogout,
        ),
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }

  Widget _listButton({
    required Widget title,
    Widget? subtitle,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.chevron_right_rounded, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DefaultTextStyle(
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF12233F),
                        ),
                        child: title,
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        DefaultTextStyle(
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                          child: subtitle,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final eventTitle = widget.event["event_title"]?.toString() ?? "Etkinlik";

    return Scaffold(
      drawer: AppNavDrawer(
        fullName: "Alpha",
        currentSection: AppNavSection.startlist,
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
        onStartList: () {
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
        onLogout: _logout,
      ),
      appBar: AppTopBar(
        title: const Text("Kulup Seçimi"),
        actions: [
          IconButton(
            onPressed: _loadClubs,
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
              onRefresh: _loadClubs,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    children: [
                      SizedBox(
                        height: constraints.maxHeight - 32,
                        child: _sectionCard(
                          title: "Kulüp  Seçiniz",
                          subtitle: "$eventTitle",
                          child: _clubs.isEmpty
                              ? const Center(
                                  child: Text("Kulup bulunamadi."),
                                )
                              : ListView.builder(
                                  itemCount: _clubs.length,
                                  itemBuilder: (context, index) {
                                    final club = _clubs[index];
                                    return _listButton(
                                      title: Text(
                                        club["club_raw"]?.toString() ?? "Bilinmeyen kulup",
                                      ),
                                      onTap: () => _selectClub(club),
                                    );
                                  },
                                ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
    );
  }
}
