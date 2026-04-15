import "package:flutter/material.dart";

import "club_service.dart";
import "member_detail_page.dart";

class TeamDetailPage extends StatefulWidget {
  const TeamDetailPage({super.key, required this.team});

  final Map<String, dynamic> team;

  @override
  State<TeamDetailPage> createState() => _TeamDetailPageState();
}

class _TeamDetailPageState extends State<TeamDetailPage> {
  final ClubService _clubService = ClubService();

  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _members = <Map<String, dynamic>>[];

  int? get _teamId => (widget.team["id"] as num?)?.toInt();

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    final teamId = _teamId;
    if (teamId == null) {
      setState(() {
        _error = "Gecerli takim bilgisi bulunamadi.";
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final members = await _clubService.fetchTeamMembers(teamId: teamId);
      if (!mounted) {
        return;
      }
      setState(() {
        _members = members;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = "Takim uyeleri yuklenemedi: $e";
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
    final teamName = widget.team["name"]?.toString() ?? "Takim";
    final description = widget.team["description"]?.toString() ?? "";

    return Scaffold(
      appBar: AppBar(
        title: Text(teamName),
        actions: [
          IconButton(
            onPressed: _loadMembers,
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
                    onRefresh: _loadMembers,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        if (description.isNotEmpty)
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Text(description),
                            ),
                          ),
                        if (description.isNotEmpty) const SizedBox(height: 12),
                        Text(
                          "Uyeler (${_members.length})",
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        if (_members.isEmpty)
                          const Card(
                            child: Padding(
                              padding: EdgeInsets.all(12),
                              child: Text("Bu takim icin uye bulunamadi."),
                            ),
                          )
                        else
                          ..._members.map((member) {
                            final fullName =
                                "${member["name"] ?? ""} ${member["surname"] ?? ""}".trim();
                            final school = member["school"]?.toString() ?? "";

                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: ListTile(
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => MemberDetailPage(member: member),
                                    ),
                                  );
                                },
                                leading: const CircleAvatar(
                                  child: Icon(Icons.person),
                                ),
                                title: Text(fullName.isEmpty ? "Uye" : fullName),
                                subtitle: school.isEmpty ? null : Text(school),
                                trailing: const Icon(Icons.chevron_right),
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
