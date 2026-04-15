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
                        Container(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: theme.colorScheme.outlineVariant),
                          ),
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(14, 14, 12, 12),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 38,
                                      height: 38,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFD6ECFA),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        Icons.group_outlined,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        "Takim\nUyeleri",
                                        style: theme.textTheme.headlineSmall?.copyWith(
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                    TextButton.icon(
                                      onPressed: () {},
                                      icon: const Text("Tumunu Goruntule"),
                                      label: const Icon(Icons.chevron_right),
                                    ),
                                  ],
                                ),
                              ),
                              Divider(
                                height: 1,
                                color: theme.colorScheme.outlineVariant,
                              ),
                              if (_members.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.all(14),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text("Bu takim icin uye bulunamadi."),
                                  ),
                                )
                              else
                                ..._members.map(
                                  (member) => _MemberListRow(
                                    member: member,
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => MemberDetailPage(member: member),
                                        ),
                                      );
                                    },
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

class _MemberListRow extends StatelessWidget {
  const _MemberListRow({required this.member, required this.onTap});

  final Map<String, dynamic> member;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fullName = "${member["name"] ?? ""} ${member["surname"] ?? ""}".trim();
    final school = member["school"]?.toString() ?? "-";
    final birthdate = member["birthdate"]?.toString() ?? "-";

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Row(
          children: [
            _MemberSmallAvatar(member: member),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fullName.isEmpty ? "Uye" : fullName,
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.school_outlined, size: 15, color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(width: 5),
                      Text(
                        school,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 15,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        birthdate,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
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

class _MemberSmallAvatar extends StatelessWidget {
  const _MemberSmallAvatar({required this.member});

  final Map<String, dynamic> member;

  @override
  Widget build(BuildContext context) {
    final photoUrl = member["photo_url"]?.toString() ?? "";
    final first = member["name"]?.toString() ?? "";
    final last = member["surname"]?.toString() ?? "";
    final initials =
        "${first.isNotEmpty ? first[0].toLowerCase() : ""}${last.isNotEmpty ? last[0].toLowerCase() : ""}";

    if (photoUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.network(
          photoUrl,
          width: 68,
          height: 68,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) {
            return _MemberSmallAvatarFallback(initials: initials);
          },
        ),
      );
    }

    return _MemberSmallAvatarFallback(initials: initials);
  }
}

class _MemberSmallAvatarFallback extends StatelessWidget {
  const _MemberSmallAvatarFallback({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 68,
      height: 68,
      decoration: BoxDecoration(
        color: const Color(0xFFBFE0F6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF98CDEF)),
      ),
      child: Center(
        child: Text(
          initials.isEmpty ? "u" : initials,
          style: theme.textTheme.headlineSmall?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
