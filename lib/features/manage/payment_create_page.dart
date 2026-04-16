import "package:dio/dio.dart";
import "package:flutter/material.dart";

import "../../core/app_nav_drawer.dart";
import "../../core/app_top_bar.dart";
import "../dashboard/club_service.dart";
import "../dashboard/team_list_page.dart";
import "../dashboard/training_weekly_page.dart";
import "../questionnaire/questionnaire_list_page.dart";

class PaymentCreatePage extends StatefulWidget {
  const PaymentCreatePage({super.key, required this.onLogout});

  final VoidCallback onLogout;

  @override
  State<PaymentCreatePage> createState() => _PaymentCreatePageState();
}

class _PaymentCreatePageState extends State<PaymentCreatePage> {
  final ClubService _clubService = ClubService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _monthController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _paidDateController = TextEditingController();

  bool _isSubmitting = false;
  bool _isPaid = false;
  String? _error;
  bool _isLoading = true;
  List<Map<String, dynamic>> _teams = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _members = <Map<String, dynamic>>[];
  Map<String, dynamic>? _selectedTeam;
  Map<String, dynamic>? _selectedMember;

  @override
  void initState() {
    super.initState();
    _loadTeams();
  }

  @override
  void dispose() {
    _monthController.dispose();
    _amountController.dispose();
    _paidDateController.dispose();
    super.dispose();
  }

  Future<void> _loadTeams() async {
    try {
      final teams = await _clubService.fetchTeams();
      if (!mounted) {
        return;
      }
      setState(() {
        _teams = teams;
        _selectedTeam = _teams.isNotEmpty ? _teams.first : null;
      });
      await _loadMembersForSelectedTeam();
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

  Future<void> _loadMembersForSelectedTeam() async {
    final teamId = (_selectedTeam?["id"] as num?)?.toInt();
    if (teamId == null) {
      setState(() {
        _members = <Map<String, dynamic>>[];
        _selectedMember = null;
      });
      return;
    }

    final members = await _clubService.fetchTeamMembers(teamId: teamId);
    if (!mounted) {
      return;
    }
    setState(() {
      _members = members;
      _selectedMember = _members.isNotEmpty ? _members.first : null;
    });
  }

  String _formatDate(DateTime dateTime) {
    final year = dateTime.year.toString().padLeft(4, "0");
    final month = dateTime.month.toString().padLeft(2, "0");
    final day = dateTime.day.toString().padLeft(2, "0");
    return "$year-$month-$day";
  }

  Future<void> _pickPaidDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
    );
    if (picked == null) {
      return;
    }
    setState(() {
      _paidDateController.text = _formatDate(picked);
    });
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _error = null;
    });

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final selectedMember = _selectedMember;
    if (selectedMember == null) {
      setState(() {
        _error = "Lutfen bir uye secin.";
      });
      return;
    }

    final memberId = (selectedMember["id"] as num?)?.toInt();
    if (memberId == null) {
      setState(() {
        _error = "Gecerli uye bulunamadi.";
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _clubService.createPayment(
        memberId: memberId,
        month: _monthController.text.trim(),
        amount: _amountController.text.trim(),
        isPaid: _isPaid,
        paidDate: _paidDateController.text.trim(),
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } on DioException catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = e.response?.data?.toString() ?? e.message ?? "Odeme olusturulamadi.";
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
            MaterialPageRoute(builder: (_) => TeamListPage(onLogout: widget.onLogout)),
          );
        },
        onPayments: () {
          Navigator.of(context).pop();
        },
        onTrainings: () {
          Navigator.of(context).pop();
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => TrainingWeeklyPage(onLogout: widget.onLogout)),
          );
        },
        onQuestionnaires: () {
          Navigator.of(context).pop();
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => QuestionnaireListPage(onLogout: widget.onLogout)),
          );
        },
        onLogout: widget.onLogout,
      ),
      appBar: AppTopBar(title: const Text("Yeni Odeme")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Odeme Bilgileri",
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<Map<String, dynamic>>(
                            value: _selectedTeam,
                            decoration: const InputDecoration(labelText: "Takim"),
                            items: _teams.map((team) {
                              return DropdownMenuItem<Map<String, dynamic>>(
                                value: team,
                                child: Text(team["name"]?.toString() ?? "Takim"),
                              );
                            }).toList(),
                            onChanged: (value) async {
                              setState(() {
                                _selectedTeam = value;
                              });
                              await _loadMembersForSelectedTeam();
                            },
                            validator: (value) {
                              if (value == null) {
                                return "Takim secin.";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<Map<String, dynamic>>(
                            value: _selectedMember,
                            decoration: const InputDecoration(labelText: "Uye"),
                            items: _members.map((member) {
                              final name = "${member["name"] ?? ""} ${member["surname"] ?? ""}".trim();
                              return DropdownMenuItem<Map<String, dynamic>>(
                                value: member,
                                child: Text(name.isEmpty ? "Uye" : name),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedMember = value;
                              });
                            },
                            validator: (value) {
                              if (value == null) {
                                return "Uye secin.";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _monthController,
                            decoration: const InputDecoration(
                              labelText: "Ay",
                              hintText: "YYYY-MM-DD",
                            ),
                            keyboardType: TextInputType.datetime,
                            validator: (value) {
                              final text = value?.trim() ?? "";
                              if (text.isEmpty) {
                                return "Ay gerekli.";
                              }
                              if (!RegExp(r"^\d{4}-\d{2}-\d{2}$").hasMatch(text)) {
                                return "Ay YYYY-MM-DD formatinda olmali.";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _amountController,
                            decoration: const InputDecoration(labelText: "Tutar"),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return "Tutar gerekli.";
                              }
                              if (double.tryParse(value.trim()) == null) {
                                return "Gecerli bir tutar girin.";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text("Odendi"),
                            value: _isPaid,
                            onChanged: (value) {
                              setState(() {
                                _isPaid = value;
                                if (!value) {
                                  _paidDateController.clear();
                                }
                              });
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _paidDateController,
                            decoration: InputDecoration(
                              labelText: "Odeme tarihi",
                              hintText: "YYYY-MM-DD",
                              suffixIcon: IconButton(
                                onPressed: _pickPaidDate,
                                icon: const Icon(Icons.calendar_month_outlined),
                              ),
                            ),
                            readOnly: true,
                            validator: (value) {
                              final text = value?.trim() ?? "";
                              if (_isPaid && text.isEmpty) {
                                return "Odeme tarihi gerekli.";
                              }
                              if (!_isPaid && text.isNotEmpty) {
                                return "Odeme yapilmadiysa tarih bos olmali.";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          if (_error != null) ...[
                            Text(
                              _error!,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          FilledButton(
                            onPressed: _isSubmitting ? null : _submit,
                            child: _isSubmitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Text("Odeme Olustur"),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
