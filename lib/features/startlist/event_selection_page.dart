import "package:flutter/material.dart";

import "../../core/app_nav_drawer.dart";
import "../../core/app_top_bar.dart";
import "../auth/auth_service.dart";
import "../dashboard/team_list_page.dart";
import "../dashboard/training_weekly_page.dart";
import "../payments/payment_list_page.dart";
import "../questionnaire/questionnaire_list_page.dart";
import "club_selection_page.dart";
import "startlist_service.dart";

class EventSelectionPage extends StatefulWidget {
  const EventSelectionPage({super.key, required this.onLogout});

  final VoidCallback onLogout;

  @override
  State<EventSelectionPage> createState() => _EventSelectionPageState();
}

class _EventSelectionPageState extends State<EventSelectionPage> {
  final StartListService _service = StartListService();
  final AuthService _authService = AuthService();

  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _events = <Map<String, dynamic>>[];

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final events = await _service.fetchEvents();
      if (!mounted) {
        return;
      }
      setState(() {
        _events = events;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = "Start list verisi yuklenemedi: $e";
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

  void _selectEvent(Map<String, dynamic> event) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ClubSelectionPage(
          event: event,
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

  String _eventLabel(Map<String, dynamic> event) {
    final title = event["event_title"]?.toString() ?? "Etkinlik";
    final location = event["event_location"]?.toString() ?? "";
    final date = event["event_date"]?.toString() ?? "";
    final parts = <String>[
      if (location.isNotEmpty) location,
      if (date.isNotEmpty) date,
    ];
    return parts.isEmpty ? title : "$title • ${parts.join(' • ')}";
  }

  @override
  Widget build(BuildContext context) {
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
        title: const Text("Etkinlik Seçimi"),
        actions: [
          IconButton(
            onPressed: _loadEvents,
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
              onRefresh: _loadEvents,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    children: [
                      SizedBox(
                        height: constraints.maxHeight - 32,
                        child: _sectionCard(
                          title: "Etkinlik  Seçiniz",
                          subtitle: "Bir etkinlik seçin",
                          child: _events.isEmpty
                              ? const Center(
                                  child: Text("Event bulunamadi."),
                                )
                              : ListView.builder(
                                  itemCount: _events.length,
                                  itemBuilder: (context, index) {
                                    final event = _events[index];
                                    return _listButton(
                                      title: Text(
                                        event["event_title"]?.toString() ?? "Etkinlik",
                                      ),
                                      subtitle: Text(_eventLabel(event)),
                                      onTap: () => _selectEvent(event),
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
