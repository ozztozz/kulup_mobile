import "package:flutter/material.dart";

import "../../core/app_nav_drawer.dart";
import "../../core/app_top_bar.dart";
import "../auth/auth_service.dart";
import "../dashboard/dashboard_page.dart";
import "../dashboard/team_list_page.dart";
import "../dashboard/training_weekly_page.dart";
import "../payments/payment_list_page.dart";
import "../questionnaire/questionnaire_list_page.dart";
import "startlist_service.dart";

class StartListPage extends StatefulWidget {
  final Map<String, dynamic> event;
  final Map<String, dynamic> club;
  final VoidCallback onLogout;

  const StartListPage({
    super.key,
    required this.event,
    required this.club,
    required this.onLogout,
  });

  @override
  State<StartListPage> createState() => _StartListPageState();
}

class _StartListPageState extends State<StartListPage> {
  final StartListService _service = StartListService();
  final AuthService _authService = AuthService();

  bool _isLoading = true;
  String? _error;

  List<Map<String, dynamic>> _items = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _entries = <Map<String, dynamic>>[];

  Map<String, dynamic>? _selectedItem;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final items = await _service.fetchItems(
        event: widget.event,
        club: widget.club,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _items = items;
        _selectedItem = items.isNotEmpty ? items.first : null;
      });
      if (_selectedItem != null) {
        await _loadEntries();
      }
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = "Brans listesi yuklenemedi: $e";
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadEntries() async {
    if (_selectedItem == null) {
      setState(() {
        _entries = <Map<String, dynamic>>[];
      });
      return;
    }

    try {
      final entries = await _service.fetchEntries(
        event: widget.event,
        club: widget.club,
        item: _selectedItem!,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _entries = entries;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = "Sporcu listesi yuklenemedi: $e";
      });
    }
  }

  Future<void> _logout() async {
    await _authService.logout();
    widget.onLogout();
  }

  void _selectItem(Map<String, dynamic> item) {
    setState(() {
      _selectedItem = item;
      _entries = <Map<String, dynamic>>[];
    });
    _loadEntries();
  }

  String _itemKey(Map<String, dynamic> item) {
    return [
      item["race_number"]?.toString() ?? "",
      item["cinsiyet"]?.toString() ?? "",
      item["stroke"]?.toString() ?? "",
      item["distance"]?.toString() ?? "",
    ].join("|");
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

  String _itemLabel(Map<String, dynamic> item) {
    final race_number = item["race_number"]?.toString() ?? "";
    final gender = item["cinsiyet"]?.toString() ?? "";
    final stroke = item["stroke"]?.toString() ?? "";
    final distance = item["distance"]?.toString() ?? "";
    return "${gender.isNotEmpty ? '$race_number • $gender • ' : ''}$stroke ${distance}m".trim();
  }

  @override
  Widget build(BuildContext context) {
    final eventTitle = widget.event["event_title"]?.toString() ?? "Etkinlik";
    final clubName = widget.club["club_raw"]?.toString() ?? "Kulup";

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
          Navigator.of(context).popUntil((route) => route.isFirst);
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
        title: Text("$clubName"),
        actions: [
          IconButton(
            onPressed: _loadItems,
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
              onRefresh: _loadItems,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      color: const Color(0xFFF0F4FF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "$eventTitle", overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "$clubName",
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 600,
                      child: _sectionCard(
                        title: "Yarışlar",
                        subtitle:
                            "",
                        child: _items.isEmpty
                            ? const Center(
                                child: Text("Brans bulunamadi."),
                              )
                            : ListView.builder(
                                itemCount: _items.length,
                                itemBuilder: (context, index) {
                                  final item = _items[index];
                                  final itemKey = _itemKey(item);
                                  final selected =
                                      _selectedItem != null &&
                                      _itemKey(_selectedItem!) == itemKey;
                                  final itemEntries = selected
                                      ? _entries
                                      : const <Map<String, dynamic>>[];

                                  return Padding(
                                    padding:
                                        const EdgeInsets.only(bottom: 10),
                                    child: Material(
                                      color: selected
                                          ? const Color(0xFFE4ECFF)
                                          : const Color(0xFFF7F8FA),
                                      borderRadius:
                                          BorderRadius.circular(18),
                                      child: ExpansionTile(
                                        key: PageStorageKey<String>(
                                            itemKey),
                                        initiallyExpanded: selected,
                                        onExpansionChanged: (isExpanded) {
                                          if (isExpanded) {
                                            _selectItem(item);
                                          }
                                        },
                                        collapsedBackgroundColor:
                                            Colors.transparent,
                                        backgroundColor:
                                            Colors.transparent,
                                        shape:
                                            RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(
                                                  3),
                                        ),
                                        collapsedShape:
                                            RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(
                                                  18),
                                        ),
                                        leading: const Icon(
                                          Icons.chevron_right_rounded,
                                          size: 20,
                                        ),
                                        title:
                                            Text(_itemLabel(item)),
                                        childrenPadding:
                                            const EdgeInsets
                                                .fromLTRB(
                                                16, 0, 16, 14),
                                        children: [
                                          if (itemEntries.isEmpty)
                                            const Align(
                                              alignment:
                                                  Alignment.centerLeft,
                                              child: Padding(
                                                padding:
                                                    EdgeInsets.only(top: 6),
                                                child: Text(
                                                  "Sporcu bulunamadi.",
                                                ),
                                              ),
                                            )
                                          else
                                            ...itemEntries
                                                .map(
                                                  (entry) => Padding(
                                                    padding:
                                                        const EdgeInsets
                                                            .only(top: 1),
                                                    child: Material(
                                                      color: Colors.white,
                                                      borderRadius:
                                                          BorderRadius
                                                              .circular(14),
                                                      child: Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(12),
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .stretch,
                                                          children: [
                                                            Text(
                                                              entry[
                                                                  "name_raw"]
                                                                  ?.toString() ??
                                                                  "Bilinmeyen sporcu",
                                                              style: const TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w700,
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                              height: 4,
                                                            ),
                                                            Text(                         

                                                              "Seri ${entry["serie"]?.toString() ?? "-"} • ${entry["start_line"]?.toString() ?? "-"} • Giriş ${entry["entry_time_txt"]?.toString() ?? "—"} • Sonuç ${entry["time_txt"]?.toString() ?? "—"}",
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                )
                                                ,
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
