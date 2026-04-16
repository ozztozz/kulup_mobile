import "package:dio/dio.dart";
import "package:flutter/material.dart";

import "../../core/app_nav_drawer.dart";
import "../../core/app_top_bar.dart";
import "../dashboard/club_service.dart";
import "../dashboard/team_list_page.dart";
import "../payments/payment_list_page.dart";
import "../questionnaire/questionnaire_list_page.dart";

class TrainingCreatePage extends StatefulWidget {
  const TrainingCreatePage({super.key, required this.onLogout});

  final VoidCallback onLogout;

  @override
  State<TrainingCreatePage> createState() => _TrainingCreatePageState();
}

class _TrainingCreatePageState extends State<TrainingCreatePage> {
  final ClubService _clubService = ClubService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _endTimeController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  bool _isSubmitting = false;
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _teams = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _users = <Map<String, dynamic>>[];
  Map<String, dynamic>? _selectedTeam;
  Map<String, dynamic>? _selectedTrainer;
  int _dayOfWeek = 1;
  String? _selectedLocation;

  static const List<Map<String, String>> _locations = <Map<String, String>>[
    {"label": "TOBB", "value": "TOBB"},
    {"label": "AYTEN SABAN", "value": "AYTEN SABAN"},
    {"label": "SPORTIF YASAM", "value": "SPORTIF YASAM"},
    {"label": "FENERBAHCE", "value": "FENERBAHCE"},
    {"label": "Diger", "value": "Diğer"},
  ];

  static const List<Map<String, Object>> _days = <Map<String, Object>>[
    {"value": 1, "label": "Pazartesi"},
    {"value": 2, "label": "Sali"},
    {"value": 3, "label": "Carsamba"},
    {"value": 4, "label": "Persembe"},
    {"value": 5, "label": "Cuma"},
    {"value": 6, "label": "Cumartesi"},
    {"value": 7, "label": "Pazar"},
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _timeController.dispose();
    _endTimeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait<dynamic>([
        _clubService.fetchTeams(),
        _clubService.fetchUsers(),
      ]);
      if (!mounted) {
        return;
      }
      setState(() {
        _teams = results[0] as List<Map<String, dynamic>>;
        _users = results[1] as List<Map<String, dynamic>>;
        _selectedTeam = _teams.isNotEmpty ? _teams.first : null;
        _selectedTrainer = _users.isNotEmpty ? _users.first : null;
        _selectedLocation = _locations.first["value"];
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = "Veriler yuklenemedi: $e";
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _error = null;
    });

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final teamId = (_selectedTeam?["id"] as num?)?.toInt();
    if (teamId == null || _selectedLocation == null) {
      setState(() {
        _error = "Gecerli takim veya lokasyon secin.";
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _clubService.createTraining(
        teamId: teamId,
        dayOfWeek: _dayOfWeek,
        time: _timeController.text.trim(),
        endTime: _endTimeController.text.trim(),
        location: _selectedLocation!,
        trainerId: (_selectedTrainer?["id"] as num?)?.toInt(),
        notes: _notesController.text.trim(),
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
        _error = e.response?.data?.toString() ?? e.message ?? "Antrenman olusturulamadi.";
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
        currentSection: AppNavSection.trainings,
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
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => PaymentListPage(onLogout: widget.onLogout)),
          );
        },
        onTrainings: () {
          Navigator.of(context).pop();
        },
        onQuestionnaires: () {
          Navigator.of(context).pop();
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => QuestionnaireListPage(onLogout: widget.onLogout)),
          );
        },
        onLogout: widget.onLogout,
      ),
      appBar: AppTopBar(title: const Text("Yeni Antrenman")),
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
                            "Antrenman Bilgileri",
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
                            onChanged: (value) {
                              setState(() {
                                _selectedTeam = value;
                              });
                            },
                            validator: (value) {
                              if (value == null) {
                                return "Takim secin.";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<int>(
                            value: _dayOfWeek,
                            decoration: const InputDecoration(labelText: "Gun"),
                            items: _days.map((day) {
                              return DropdownMenuItem<int>(
                                value: day["value"] as int,
                                child: Text(day["label"] as String),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _dayOfWeek = value;
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _timeController,
                            decoration: const InputDecoration(
                              labelText: "Baslama saati",
                              hintText: "HH:MM",
                            ),
                            keyboardType: TextInputType.datetime,
                            validator: (value) {
                              final text = value?.trim() ?? "";
                              if (text.isEmpty) {
                                return "Baslama saati gerekli.";
                              }
                              if (!RegExp(r"^\d{2}:\d{2}$").hasMatch(text)) {
                                return "Saat HH:MM formatinda olmali.";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _endTimeController,
                            decoration: const InputDecoration(
                              labelText: "Bitis saati",
                              hintText: "HH:MM",
                            ),
                            keyboardType: TextInputType.datetime,
                            validator: (value) {
                              final text = value?.trim() ?? "";
                              if (text.isEmpty) {
                                return null;
                              }
                              if (!RegExp(r"^\d{2}:\d{2}$").hasMatch(text)) {
                                return "Saat HH:MM formatinda olmali.";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: _selectedLocation,
                            decoration: const InputDecoration(labelText: "Lokasyon"),
                            items: _locations.map((location) {
                              return DropdownMenuItem<String>(
                                value: location["value"],
                                child: Text(location["label"] ?? "Lokasyon"),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedLocation = value;
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Lokasyon secin.";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<Map<String, dynamic>>(
                            value: _selectedTrainer,
                            decoration: const InputDecoration(labelText: "Antrenor"),
                            items: _users.map((user) {
                              final displayName = user["display_name"]?.toString() ?? user["email"]?.toString() ?? "Kullanici";
                              return DropdownMenuItem<Map<String, dynamic>>(
                                value: user,
                                child: Text(displayName),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedTrainer = value;
                              });
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _notesController,
                            decoration: const InputDecoration(labelText: "Notlar"),
                            minLines: 3,
                            maxLines: 5,
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
                                : const Text("Antrenman Olustur"),
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
