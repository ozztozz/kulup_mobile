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
                            children: const [
                              SizedBox(height: 200),
                              Center(child: Text("Takim bulunamadi.")),
                            ],
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: _teams.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final team = _teams[index];
                              final name = team["name"]?.toString() ?? "-";
                              final description = team["description"]?.toString() ?? "";

                              return Card(
                                child: ListTile(
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => TeamDetailPage(team: team),
                                      ),
                                    );
                                  },
                                  leading: const CircleAvatar(
                                    child: Icon(Icons.groups),
                                  ),
                                  title: Text(name),
                                  subtitle: description.isEmpty ? null : Text(description),
                                  trailing: const Icon(Icons.chevron_right),
                                ),
                              );
                            },
                          ),
                  ),
      ),
    );
  }
}
