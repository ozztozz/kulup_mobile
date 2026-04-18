import "package:flutter/material.dart";

import "../../core/app_footer_menu.dart";
import "../../core/app_nav_drawer.dart";
import "../../core/app_top_bar.dart";
import "../../core/team_logo_avatar.dart";
import "club_service.dart";
import "../manage/member_create_page.dart";
import "member_detail_page.dart";
import "../payments/payment_list_page.dart";
import "team_list_page.dart";
import "training_weekly_page.dart";
import "../questionnaire/questionnaire_list_page.dart";

class TeamDetailPage extends StatefulWidget {
  const TeamDetailPage({super.key, required this.team, required this.onLogout});

  final Map<String, dynamic> team;
  final VoidCallback onLogout;

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
    final theme = Theme.of(context);
    final teamName = widget.team["name"]?.toString() ?? "Takim";
    final description = widget.team["description"]?.toString() ?? "";

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
          Navigator.of(context).pushReplacement(
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
        onLogout: widget.onLogout,
      ),
      appBar: AppTopBar(
        title: Text(teamName),
        actions: [
          IconButton(
            onPressed: _openCreateMember,
            icon: const Icon(Icons.person_add_alt_1_outlined),
            tooltip: "Yeni uye",
          ),
          IconButton(
            onPressed: _loadMembers,
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
              : Stack(
                  children: [
                    Container(
                      height: 220,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            theme.colorScheme.primary,
                            theme.colorScheme.primary.withValues(alpha: 0.88),
                          ],
                        ),
                      ),
                    ),
                    SafeArea(
                      child: RefreshIndicator(
                        onRefresh: _loadMembers,
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                          children: [
                            const SizedBox(height: 6),
                            Stack(
                              clipBehavior: Clip.none,
                              alignment: Alignment.topCenter,
                              children: [
                                Card(
                                  margin: const EdgeInsets.only(top: 56),
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(20, 72, 20, 22),
                                    child: Column(
                                      children: [
                                        Text(
                                          teamName,
                                          textAlign: TextAlign.center,
                                          style: theme.textTheme.headlineSmall?.copyWith(
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          description.isEmpty ? "Takim aciklamasi yok" : description,
                                          textAlign: TextAlign.center,
                                          style: theme.textTheme.titleMedium?.copyWith(
                                            color: theme.colorScheme.onSurfaceVariant,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 14),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Expanded(
                                              child: FilledButton.icon(
                                                onPressed: _openCreateMember,
                                                icon: const Icon(Icons.person_add_alt_1_outlined),
                                                label: const Text("Uye Ekle"),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: FilledButton.icon(
                                                style: FilledButton.styleFrom(
                                                  backgroundColor: theme.colorScheme.secondary,
                                                  foregroundColor: theme.colorScheme.onSecondary,
                                                ),
                                                onPressed: _loadMembers,
                                                icon: const Icon(Icons.refresh),
                                                label: const Text("Yenile"),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 0,
                                  child: TeamLogoAvatar(
                                    team: widget.team,
                                    size: 112,
                                    borderRadius: 56,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 42,
                                      height: 42,
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primaryContainer,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        Icons.groups_2_outlined,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        "Takim Uyeleri",
                                        style: theme.textTheme.titleLarge?.copyWith(
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                    TextButton.icon(
                                      onPressed: _openCreateMember,
                                      icon: const Icon(Icons.add),
                                      label: const Text("Ekle"),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            if (_members.isEmpty)
                              Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      "Bu takim icin uye bulunamadi.",
                                      style: theme.textTheme.bodyLarge,
                                    ),
                                  ),
                                ),
                              )
                            else
                              ..._members.map(
                                (member) => _MemberListRow(
                                  member: member,
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => MemberDetailPage(
                                          member: member,
                                          onLogout: widget.onLogout,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Future<void> _openCreateMember() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => MemberCreatePage(
          team: widget.team,
          onLogout: widget.onLogout,
        ),
      ),
    );
    if (created == true && mounted) {
      await _loadMembers();
    }
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
    final ageLabel = _ageLabelFromBirthdate(birthdate);
    final isActive = member["is_active"] != false;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: ListTile(
        onTap: onTap,
        leading: _MemberSmallAvatar(member: member),
        title: Text(
          fullName.isEmpty ? "Uye" : fullName,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          "$school  •  $birthdate",
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              ageLabel,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isActive
                    ? theme.colorScheme.tertiaryContainer
                    : theme.colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                isActive ? "Aktif" : "Pasif",
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isActive
                      ? theme.colorScheme.onTertiaryContainer
                      : theme.colorScheme.onSecondaryContainer,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _ageLabelFromBirthdate(String birthdate) {
    if (birthdate.trim().isEmpty || birthdate == "-") {
      return "-";
    }

    final parsed = DateTime.tryParse(birthdate);
    if (parsed == null) {
      return "-";
    }

    final now = DateTime.now();
    var age = now.year - parsed.year;
    final hadBirthdayThisYear =
        (now.month > parsed.month) ||
        (now.month == parsed.month && now.day >= parsed.day);
    if (!hadBirthdayThisYear) {
      age -= 1;
    }

    if (age < 0) {
      return "-";
    }
    return "$age Yas";
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
          width: 46,
          height: 46,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) {
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
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Center(
        child: Text(
          initials.isEmpty ? "u" : initials,
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
