import "package:dio/dio.dart";
import "package:flutter/material.dart";
import "package:image_picker/image_picker.dart";
import "dart:typed_data";

import "../../core/app_nav_drawer.dart";
import "../../core/app_top_bar.dart";
import "../dashboard/club_service.dart";
import "../dashboard/team_list_page.dart";
import "../dashboard/training_weekly_page.dart";
import "../payments/payment_list_page.dart";
import "../questionnaire/questionnaire_list_page.dart";

class TeamCreatePage extends StatefulWidget {
  const TeamCreatePage({super.key, required this.onLogout});

  final VoidCallback onLogout;

  @override
  State<TeamCreatePage> createState() => _TeamCreatePageState();
}

class _TeamCreatePageState extends State<TeamCreatePage> {
  final ClubService _clubService = ClubService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _foundedDateController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  bool _isSubmitting = false;
  String? _error;
  XFile? _selectedLogo;
  Uint8List? _selectedLogoBytes;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _foundedDateController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _error = null;
    });

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _clubService.createTeam(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        foundedDate: _foundedDateController.text.trim(),
        logoPath: _selectedLogo?.path,
        logoBytes: _selectedLogoBytes,
        logoFileName: _selectedLogo?.name,
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
        _error = e.response?.data?.toString() ?? e.message ?? "Takim olusturulamadi.";
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

  Future<void> _pickLogo() async {
    final source = await _selectImageSource();
    if (source == null) {
      return;
    }
    await _pickLogoFromSource(source);
  }

  Future<ImageSource?> _selectImageSource() async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text("Galeriden sec"),
                onTap: () => Navigator.of(sheetContext).pop(ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text("Kamerayi kullan"),
                onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickLogoFromSource(ImageSource source) async {
    final picked = await _imagePicker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1600,
    );
    if (picked == null) {
      return;
    }
    final bytes = await picked.readAsBytes();
    if (!mounted) {
      return;
    }
    setState(() {
      _selectedLogo = picked;
      _selectedLogoBytes = bytes;
    });
  }

  void _clearLogo() {
    setState(() {
      _selectedLogo = null;
      _selectedLogoBytes = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
      appBar: AppTopBar(title: const Text("Yeni Takim")),
      body: ListView(
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
                      "Takim Bilgileri",
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: "Takim adi"),
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Takim adi gerekli.";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(labelText: "Aciklama"),
                      minLines: 3,
                      maxLines: 5,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Takim logosu",
                      style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: _pickLogo,
                      child: Container(
                        width: double.infinity,
                        height: 136,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: theme.colorScheme.outlineVariant),
                          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                        ),
                        child: _selectedLogoBytes == null
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_a_photo_outlined,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "Galeriden logo sec",
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "Dokun: Kamera veya Galeri",
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(11),
                                child: Image.memory(
                                  _selectedLogoBytes!,
                                  width: double.infinity,
                                  height: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                      ),
                    ),
                    if (_selectedLogo != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _selectedLogo!.name,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _clearLogo,
                        icon: const Icon(Icons.delete_outline),
                        label: const Text("Logoyu kaldir"),
                      ),
                    ],
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _foundedDateController,
                      decoration: const InputDecoration(
                        labelText: "Kurulus tarihi",
                        hintText: "YYYY-MM-DD",
                      ),
                      keyboardType: TextInputType.datetime,
                      validator: (value) {
                        final text = value?.trim() ?? "";
                        if (text.isEmpty) {
                          return null;
                        }
                        if (!RegExp(r"^\d{4}-\d{2}-\d{2}$").hasMatch(text)) {
                          return "Tarih YYYY-MM-DD formatinda olmali.";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
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
                          : const Text("Takim Olustur"),
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
