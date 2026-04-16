import "package:dio/dio.dart";
import "package:flutter/material.dart";

import "../../core/app_nav_drawer.dart";
import "../../core/app_top_bar.dart";
import "../dashboard/club_service.dart";
import "../dashboard/team_list_page.dart";
import "../payments/payment_list_page.dart";
import "../dashboard/training_weekly_page.dart";
import "questionnaire_list_page.dart";

class QuestionnaireResponsePage extends StatefulWidget {
  const QuestionnaireResponsePage({super.key, required this.row, required this.onLogout});

  final Map<String, dynamic> row;
  final VoidCallback onLogout;

  @override
  State<QuestionnaireResponsePage> createState() => _QuestionnaireResponsePageState();
}

class _QuestionnaireResponsePageState extends State<QuestionnaireResponsePage> {
  final ClubService _clubService = ClubService();

  bool _isSubmitting = false;
  String? _error;

  final Map<String, TextEditingController> _textControllers =
      <String, TextEditingController>{};
  final Map<String, dynamic> _answers = <String, dynamic>{};

  late final Map<String, dynamic> _member;
  late final Map<String, dynamic> _questionnaire;
  late final List<Map<String, dynamic>> _questions;

  @override
  void initState() {
    super.initState();
    _member = Map<String, dynamic>.from(
      (widget.row["member"] as Map?) ?? <String, dynamic>{},
    );
    _questionnaire = Map<String, dynamic>.from(
      (widget.row["questionnaire"] as Map?) ?? <String, dynamic>{},
    );

    final schema = Map<String, dynamic>.from(
      (_questionnaire["schema"] as Map?) ?? <String, dynamic>{},
    );
    final questions = (schema["questions"] as List<dynamic>?) ?? <dynamic>[];
    _questions = questions
        .whereType<Map>()
        .map((q) => Map<String, dynamic>.from(q))
        .toList();

    for (final question in _questions) {
      final qid = question["id"]?.toString() ?? "";
      if (qid.isEmpty) {
        continue;
      }
      final qtype = question["type"]?.toString() ?? "text";
      if (qtype == "multi") {
        _answers[qid] = <String>[];
      } else {
        _answers[qid] = null;
      }
      if (qtype == "text") {
        _textControllers[qid] = TextEditingController();
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _textControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  bool _validateRequired() {
    for (final question in _questions) {
      final qid = question["id"]?.toString() ?? "";
      if (qid.isEmpty) {
        continue;
      }
      final required = question["required"] != false;
      if (!required) {
        continue;
      }

      final qtype = question["type"]?.toString() ?? "text";
      final value = _answers[qid];

      if (qtype == "multi") {
        final listValue = (value as List<dynamic>?) ?? <dynamic>[];
        if (listValue.isEmpty) {
          setState(() {
            _error = "Zorunlu sorulari cevaplayin.";
          });
          return false;
        }
      } else {
        final text = value?.toString().trim() ?? "";
        if (text.isEmpty) {
          setState(() {
            _error = "Zorunlu sorulari cevaplayin.";
          });
          return false;
        }
      }
    }
    return true;
  }

  Future<void> _submit() async {
    setState(() {
      _error = null;
    });

    if (!_validateRequired()) {
      return;
    }

    final questionnaireId = (_questionnaire["id"] as num?)?.toInt();
    final memberId = (_member["id"] as num?)?.toInt();
    if (questionnaireId == null || memberId == null) {
      setState(() {
        _error = "Gecerli anket veya uye bulunamadi.";
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final cleanedAnswers = <String, dynamic>{};
      for (final question in _questions) {
        final qid = question["id"]?.toString() ?? "";
        if (qid.isEmpty) {
          continue;
        }

        final qtype = question["type"]?.toString() ?? "text";
        final value = _answers[qid];

        if (qtype == "multi") {
          cleanedAnswers[qid] = ((value as List<dynamic>?) ?? <dynamic>[])
              .map((v) => v.toString())
              .toList();
        } else {
          cleanedAnswers[qid] = value?.toString();
        }
      }

      await _clubService.submitQuestionnaireResponse(
        questionnaireId: questionnaireId,
        memberId: memberId,
        answers: cleanedAnswers,
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
        _error = "Kayit basarisiz: ${e.response?.data ?? e.message}";
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = "Kayit basarisiz: $e";
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
    final memberName = "${_member["name"] ?? ""} ${_member["surname"] ?? ""}".trim();
    final team = Map<String, dynamic>.from(
      (_member["team"] as Map?) ?? <String, dynamic>{},
    );

    return Scaffold(
      drawer: AppNavDrawer(
        fullName: memberName.isEmpty ? "Alpha" : memberName,
        currentSection: AppNavSection.questionnaires,
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
        title: Text(_questionnaire["title"]?.toString() ?? "Anket Cevapla"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(memberName, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(team["name"]?.toString() ?? ""),
                    const SizedBox(height: 8),
                    Text(_questionnaire["description"]?.toString() ?? ""),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            ..._questions.map(_buildQuestionWidget),
            const SizedBox(height: 12),
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _error!,
                  style: TextStyle(color: theme.colorScheme.onErrorContainer),
                ),
              ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text("Cevaplari Gonder"),
            ),
        ],
      ),
    );
  }

  Widget _buildQuestionWidget(Map<String, dynamic> question) {
    final qid = question["id"]?.toString() ?? "";
    final label = question["label"]?.toString() ?? "Soru";
    final qtype = question["type"]?.toString() ?? "text";
    final required = question["required"] != false;
    final help = question["help"]?.toString();

    final title = required ? "$label *" : label;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            if (help != null && help.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(help, style: Theme.of(context).textTheme.bodySmall),
            ],
            const SizedBox(height: 8),
            if (qtype == "text")
              TextField(
                controller: _textControllers[qid],
                maxLines: 3,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: "Cevabinizi yazin",
                ),
                onChanged: (value) {
                  _answers[qid] = value;
                },
              )
            else if (qtype == "single")
              _SingleChoiceWidget(
                question: question,
                selected: _answers[qid]?.toString(),
                onChanged: (value) {
                  setState(() {
                    _answers[qid] = value;
                  });
                },
              )
            else
              _MultiChoiceWidget(
                question: question,
                selected: ((_answers[qid] as List<dynamic>?) ?? <dynamic>[])
                    .map((v) => v.toString())
                    .toList(),
                onChanged: (list) {
                  setState(() {
                    _answers[qid] = list;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _SingleChoiceWidget extends StatelessWidget {
  const _SingleChoiceWidget({
    required this.question,
    required this.selected,
    required this.onChanged,
  });

  final Map<String, dynamic> question;
  final String? selected;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final choices = (question["choices"] as List<dynamic>?) ?? <dynamic>[];

    return DropdownButtonFormField<String>(
      initialValue: selected,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
      ),
      items: choices.map((choice) {
        final item = Map<String, dynamic>.from((choice as Map?) ?? <String, dynamic>{});
        final value = item["value"]?.toString() ?? "";
        final label = item["label"]?.toString() ?? value;

        return DropdownMenuItem<String>(
          value: value,
          child: Text(label),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}

class _MultiChoiceWidget extends StatelessWidget {
  const _MultiChoiceWidget({
    required this.question,
    required this.selected,
    required this.onChanged,
  });

  final Map<String, dynamic> question;
  final List<String> selected;
  final ValueChanged<List<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    final choices = (question["choices"] as List<dynamic>?) ?? <dynamic>[];

    return Column(
      children: choices.map((choice) {
        final item = Map<String, dynamic>.from((choice as Map?) ?? <String, dynamic>{});
        final value = item["value"]?.toString() ?? "";
        final label = item["label"]?.toString() ?? value;
        final isChecked = selected.contains(value);

        return CheckboxListTile(
          value: isChecked,
          onChanged: (checked) {
            final next = <String>[...selected];
            if (checked == true && !next.contains(value)) {
              next.add(value);
            } else if (checked == false) {
              next.remove(value);
            }
            onChanged(next);
          },
          title: Text(label),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
        );
      }).toList(),
    );
  }
}
