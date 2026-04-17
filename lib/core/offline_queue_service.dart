import "dart:convert";
import "dart:io";

import "package:dio/dio.dart";
import "package:path_provider/path_provider.dart";

import "../features/dashboard/club_service.dart";

class OfflineQueueService {
  OfflineQueueService({ClubService? clubService}) : _clubService = clubService ?? ClubService();

  final ClubService _clubService;

  static const String _queueFileName = "offline_create_queue.json";

  Future<File> _queueFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File("${directory.path}${Platform.pathSeparator}$_queueFileName");
  }

  Future<List<Map<String, dynamic>>> _readQueue() async {
    final file = await _queueFile();
    if (!await file.exists()) {
      return <Map<String, dynamic>>[];
    }

    final raw = await file.readAsString();
    if (raw.trim().isEmpty) {
      return <Map<String, dynamic>>[];
    }

    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  Future<void> _writeQueue(List<Map<String, dynamic>> queue) async {
    final file = await _queueFile();
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonEncode(queue));
  }

  Future<void> enqueueTeam({
    required String name,
    String? description,
    String? foundedDate,
    List<int>? logoBytes,
    String? logoFileName,
  }) async {
    final queue = await _readQueue();
    queue.add(<String, dynamic>{
      "type": "team",
      "created_at": DateTime.now().toIso8601String(),
      "payload": <String, dynamic>{
        "name": name,
        if (description != null && description.trim().isNotEmpty) "description": description.trim(),
        if (foundedDate != null && foundedDate.trim().isNotEmpty) "founded_date": foundedDate.trim(),
        if (logoBytes != null && logoBytes.isNotEmpty) "logo_bytes": base64Encode(logoBytes),
        if (logoFileName != null && logoFileName.isNotEmpty) "logo_file_name": logoFileName,
      },
    });
    await _writeQueue(queue);
  }

  Future<void> enqueueMember({
    required int teamId,
    required int userId,
    required String name,
    required String surname,
    String? birthdate,
    String? school,
    required bool isActive,
    String? notes,
    List<int>? photoBytes,
    String? photoFileName,
  }) async {
    final queue = await _readQueue();
    queue.add(<String, dynamic>{
      "type": "member",
      "created_at": DateTime.now().toIso8601String(),
      "payload": <String, dynamic>{
        "team_id": teamId,
        "user_id": userId,
        "name": name,
        "surname": surname,
        if (birthdate != null && birthdate.trim().isNotEmpty) "birthdate": birthdate.trim(),
        if (school != null && school.trim().isNotEmpty) "school": school.trim(),
        "is_active": isActive,
        if (notes != null && notes.trim().isNotEmpty) "notes": notes.trim(),
        if (photoBytes != null && photoBytes.isNotEmpty) "photo_bytes": base64Encode(photoBytes),
        if (photoFileName != null && photoFileName.isNotEmpty) "photo_file_name": photoFileName,
      },
    });
    await _writeQueue(queue);
  }

  Future<int> pendingCount() async {
    return (await _readQueue()).length;
  }

  Future<void> syncPendingCreates() async {
    final queue = await _readQueue();
    if (queue.isEmpty) {
      return;
    }

    final remaining = <Map<String, dynamic>>[];

    for (final item in queue) {
      final type = item["type"]?.toString();
      final payload = Map<String, dynamic>.from(item["payload"] as Map);

      try {
        if (type == "team") {
          await _clubService.createTeam(
            name: payload["name"] as String,
            description: payload["description"] as String?,
            foundedDate: payload["founded_date"] as String?,
            logoBytes: payload["logo_bytes"] == null ? null : base64Decode(payload["logo_bytes"] as String),
            logoFileName: payload["logo_file_name"] as String?,
          );
        } else if (type == "member") {
          await _clubService.createTeamMember(
            teamId: (payload["team_id"] as num).toInt(),
            userId: (payload["user_id"] as num).toInt(),
            name: payload["name"] as String,
            surname: payload["surname"] as String,
            birthdate: payload["birthdate"] as String?,
            school: payload["school"] as String?,
            isActive: payload["is_active"] as bool? ?? true,
            notes: payload["notes"] as String?,
            photoBytes: payload["photo_bytes"] == null ? null : base64Decode(payload["photo_bytes"] as String),
            photoFileName: payload["photo_file_name"] as String?,
          );
        } else {
          remaining.add(item);
        }
      } on DioException catch (_) {
        remaining.add(item);
      } catch (_) {
        remaining.add(item);
      }
    }

    await _writeQueue(remaining);
  }
}