import "package:flutter/material.dart";

import "../../core/app_nav_drawer.dart";
import "../../core/app_top_bar.dart";
import "../../core/team_logo_avatar.dart";
import "../dashboard/club_service.dart";
import "../dashboard/team_list_page.dart";
import "../dashboard/training_weekly_page.dart";
import "../manage/payment_create_page.dart";
import "../questionnaire/questionnaire_list_page.dart";
import "payment_detail_page.dart";

class PaymentListPage extends StatefulWidget {
  const PaymentListPage({super.key, required this.onLogout});

  final VoidCallback onLogout;

  @override
  State<PaymentListPage> createState() => _PaymentListPageState();
}

class _PaymentListPageState extends State<PaymentListPage> {
  final ClubService _clubService = ClubService();

  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _payments = <Map<String, dynamic>>[];

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final payments = await _clubService.fetchPayments();
      if (!mounted) {
        return;
      }
      setState(() {
        _payments = payments;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = "Odemeler yuklenemedi: $e";
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  int _paidCount() => _payments.where((payment) => payment["is_paid"] == true).length;

  double _totalAmount() {
    return _payments.fold<double>(0, (sum, payment) {
      final value = payment["amount"];
      if (value is num) {
        return sum + value.toDouble();
      }
      return sum + (double.tryParse(value?.toString() ?? "") ?? 0);
    });
  }

  String _formatMonth(dynamic value) {
    final text = value?.toString() ?? "";
    if (text.length >= 7) {
      return text.substring(0, 7);
    }
    return text;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unpaidCount = _payments.length - _paidCount();

    return Scaffold(
      drawer: AppNavDrawer(
        fullName: "Alpha",
        currentSection: AppNavSection.payments,
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
        onPayments: () {
          Navigator.of(context).pop();
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
        title: const Text("Odemeler"),
        actions: [
          IconButton(
            onPressed: _openCreatePayment,
            icon: const Icon(Icons.add),
            tooltip: "Yeni odeme",
          ),
          IconButton(
            onPressed: _loadPayments,
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
                  onRefresh: _loadPayments,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _SummaryTile(
                                    label: "Toplam",
                                    value: _payments.length.toString(),
                                  ),
                                ),
                                Expanded(
                                  child: _SummaryTile(
                                    label: "Odendi",
                                    value: _paidCount().toString(),
                                  ),
                                ),
                                Expanded(
                                  child: _SummaryTile(
                                    label: "Bakiye",
                                    value: unpaidCount.toString(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                const Icon(Icons.payments_outlined),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    "Toplam tahsilat tutari",
                                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                ),
                                Text(
                                  _totalAmount().toStringAsFixed(2),
                                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        ..._payments.map((payment) {
                          final member = Map<String, dynamic>.from(
                            (payment["member"] as Map?) ?? <String, dynamic>{},
                          );
                          final team = Map<String, dynamic>.from(
                            (member["team"] as Map?) ?? <String, dynamic>{},
                          );
                          final memberName = "${member["name"] ?? ""} ${member["surname"] ?? ""}".trim();
                          final amount = payment["amount"]?.toString() ?? "0";
                          final month = _formatMonth(payment["month"]);
                          final isPaid = payment["is_paid"] == true;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => PaymentDetailPage(
                                      payment: payment,
                                      onLogout: widget.onLogout,
                                    ),
                                  ),
                                );
                              },
                              leading: TeamLogoAvatar(
                                team: team,
                                size: 46,
                                borderRadius: 14,
                              ),
                              title: Text(
                                memberName.isEmpty ? "Uye" : memberName,
                                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              subtitle: Text(
                                "${team["name"]?.toString() ?? "Takim"}  •  $month",
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    amount,
                                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isPaid
                                          ? theme.colorScheme.tertiaryContainer
                                          : theme.colorScheme.secondaryContainer,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      isPaid ? "Odendi" : "Bekliyor",
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        color: isPaid
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
                        }),
                    ],
                  ),
                ),
    );
  }

  Future<void> _openCreatePayment() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PaymentCreatePage(onLogout: widget.onLogout),
      ),
    );
    if (created == true && mounted) {
      await _loadPayments();
    }
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(label, style: theme.textTheme.bodyMedium),
      ],
    );
  }
}