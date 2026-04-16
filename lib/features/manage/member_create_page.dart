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

class MemberCreatePage extends StatefulWidget {
  const MemberCreatePage({super.key, required this.team, required this.onLogout});

  final Map<String, dynamic> team;
  final VoidCallback onLogout;

  @override
  State<MemberCreatePage> createState() => _MemberCreatePageState();
}

class _MemberCreatePageState extends State<MemberCreatePage> {
  final ClubService _clubService = ClubService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _surnameController = TextEditingController();
  final TextEditingController _birthdateController = TextEditingController();
  final TextEditingController _schoolController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  bool _isSubmitting = false;
  bool _isActive = true;
  String? _error;
  bool _isLoadingUsers = true;
  List<Map<String, dynamic>> _users = <Map<String, dynamic>>[];
  Map<String, dynamic>? _selectedUser;
  XFile? _selectedPhoto;
  Uint8List? _selectedPhotoBytes;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _birthdateController.dispose();
    _schoolController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    try {
      final users = await _clubService.fetchUsers();
      if (!mounted) {
        return;
      }
      setState(() {
        _users = users;
        if (_users.isNotEmpty) {
          _selectedUser = _users.first;
        }
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = "Kullanici listesi yuklenemedi: $e";
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingUsers = false;
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

    final selectedUser = _selectedUser;
    if (selectedUser == null) {
      setState(() {
        _error = "Lutfen bir kullanici secin.";
      });
      return;
    }

    final userId = (selectedUser["id"] as num?)?.toInt();
    final teamId = (widget.team["id"] as num?)?.toInt();
    if (userId == null || teamId == null) {
      setState(() {
        _error = "Gecerli kullanici veya takim bulunamadi.";
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _clubService.createTeamMember(
        teamId: teamId,
        userId: userId,
        name: _nameController.text.trim(),
        surname: _surnameController.text.trim(),
        birthdate: _birthdateController.text.trim(),
        school: _schoolController.text.trim(),
        isActive: _isActive,
        notes: _notesController.text.trim(),
        photoPath: _selectedPhoto?.path,
        photoBytes: _selectedPhotoBytes,
        photoFileName: _selectedPhoto?.name,
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
        _error = e.response?.data?.toString() ?? e.message ?? "Uye olusturulamadi.";
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

  Future<void> _pickPhoto() async {
    final source = await _selectImageSource();
    if (source == null) {
      return;
    }
    await _pickPhotoFromSource(source);
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

  Future<void> _pickPhotoFromSource(ImageSource source) async {
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
      _selectedPhoto = picked;
      _selectedPhotoBytes = bytes;
    });
  }

  void _clearPhoto() {
    setState(() {
      _selectedPhoto = null;
      _selectedPhotoBytes = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final teamName = widget.team["name"]?.toString() ?? "Takim";

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
      appBar: AppTopBar(title: Text("Yeni Uye - $teamName")),
      body: _isLoadingUsers
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
                            "Uye Bilgileri",
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<Map<String, dynamic>>(
                            value: _selectedUser,
                            decoration: const InputDecoration(labelText: "Kullanici"),
                            items: _users.map((user) {
                              final displayName = user["display_name"]?.toString() ?? user["email"]?.toString() ?? "Kullanici";
                              final email = user["email"]?.toString() ?? "";
                              return DropdownMenuItem<Map<String, dynamic>>(
                                value: user,
                                child: Text(email.isEmpty ? displayName : "$displayName  •  $email"),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedUser = value;
                              });
                            },
                            validator: (value) {
                              if (value == null) {
                                return "Kullanici secin.";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(labelText: "Ad"),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return "Ad gerekli.";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _surnameController,
                            decoration: const InputDecoration(labelText: "Soyad"),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return "Soyad gerekli.";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _birthdateController,
                            decoration: const InputDecoration(
                              labelText: "Dogum tarihi",
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
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _schoolController,
                            decoration: const InputDecoration(labelText: "Okul"),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "Uye fotografi",
                            style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 8),
                          InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: _pickPhoto,
                            child: Container(
                              width: double.infinity,
                              height: 136,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: theme.colorScheme.outlineVariant),
                                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                              ),
                              child: _selectedPhotoBytes == null
                                  ? Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.add_photo_alternate_outlined,
                                          color: theme.colorScheme.onSurfaceVariant,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          "Galeriden fotograf sec",
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
                                        _selectedPhotoBytes!,
                                        width: double.infinity,
                                        height: double.infinity,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                            ),
                          ),
                          if (_selectedPhoto != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              _selectedPhoto!.name,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: _clearPhoto,
                              icon: const Icon(Icons.delete_outline),
                              label: const Text("Fotografi kaldir"),
                            ),
                          ],
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _notesController,
                            decoration: const InputDecoration(labelText: "Notlar"),
                            minLines: 3,
                            maxLines: 5,
                          ),
                          const SizedBox(height: 12),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text("Aktif"),
                            value: _isActive,
                            onChanged: (value) {
                              setState(() {
                                _isActive = value;
                              });
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
                                : const Text("Uye Olustur"),
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
