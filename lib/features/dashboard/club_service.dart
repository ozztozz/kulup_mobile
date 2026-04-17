import "package:dio/dio.dart";

import "../../core/api_client.dart";

class ClubService {
  Future<List<Map<String, dynamic>>> fetchTeams() async {
    final response = await ApiClient.dio.get<dynamic>("/teams/");
    final list = (response.data as List<dynamic>?) ?? <dynamic>[];
    return list.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  Future<List<Map<String, dynamic>>> fetchUsers() async {
    final response = await ApiClient.dio.get<dynamic>("/users/");
    final list = (response.data as List<dynamic>?) ?? <dynamic>[];
    return list.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  Future<void> createTeam({
    required String name,
    String? description,
    String? foundedDate,
    String? logoPath,
    List<int>? logoBytes,
    String? logoFileName,
  }) async {
    final payload = <String, dynamic>{
      "name": name,
      if (description != null && description.trim().isNotEmpty) "description": description.trim(),
      if (foundedDate != null && foundedDate.isNotEmpty) "founded_date": foundedDate,
    };

    if (logoBytes != null && logoBytes.isNotEmpty) {
      payload["logo"] = MultipartFile.fromBytes(
        logoBytes,
        filename: logoFileName ?? "team_logo.jpg",
      );
    } else if (logoPath != null && logoPath.isNotEmpty) {
      payload["logo"] = await MultipartFile.fromFile(
        logoPath,
        filename: logoFileName,
      );
    }

    final hasFile = payload["logo"] != null;
    await ApiClient.dio.post<dynamic>(
      "/teams/",
      data: hasFile ? FormData.fromMap(payload) : payload,
    );
  }

  Future<List<Map<String, dynamic>>> fetchTeamMembers({required int teamId}) async {
    final response = await ApiClient.dio.get<dynamic>("/teams/$teamId/members/");
    final list = (response.data as List<dynamic>?) ?? <dynamic>[];
    return list.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  Future<void> createTeamMember({
    required int teamId,
    required int userId,
    required String name,
    required String surname,
    String? birthdate,
    String? school,
    bool isActive = true,
    String? notes,
    String? photoPath,
    List<int>? photoBytes,
    String? photoFileName,
  }) async {
    final payload = <String, dynamic>{
      "user": userId,
      "name": name,
      "surname": surname,
      if (birthdate != null && birthdate.isNotEmpty) "birthdate": birthdate,
      if (school != null && school.trim().isNotEmpty) "school": school.trim(),
      "is_active": isActive,
      if (notes != null && notes.trim().isNotEmpty) "notes": notes.trim(),
    };

    if (photoBytes != null && photoBytes.isNotEmpty) {
      payload["photo"] = MultipartFile.fromBytes(
        photoBytes,
        filename: photoFileName ?? "member_photo.jpg",
      );
    } else if (photoPath != null && photoPath.isNotEmpty) {
      payload["photo"] = await MultipartFile.fromFile(
        photoPath,
        filename: photoFileName,
      );
    }

    final hasFile = payload["photo"] != null;
    await ApiClient.dio.post<dynamic>(
      "/teams/$teamId/members/",
      data: hasFile ? FormData.fromMap(payload) : payload,
    );
  }

  Future<List<Map<String, dynamic>>> fetchTrainings() async {
    final response = await ApiClient.dio.get<dynamic>("/trainings/");
    final data = response.data;
    final list = data is List<dynamic>
      ? data
      : data is Map
        ? (data["results"] as List<dynamic>?) ??
          (data["data"] as List<dynamic>?) ??
          <dynamic>[]
        : <dynamic>[];
    return list.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  Future<void> createTraining({
    required int teamId,
    required int dayOfWeek,
    required String time,
    String? endTime,
    required String location,
    int? trainerId,
    String? notes,
  }) async {
    await ApiClient.dio.post<dynamic>(
      "/trainings/",
      data: <String, dynamic>{
        "team": teamId,
        "day_of_week": dayOfWeek,
        "time": time,
        if (endTime != null && endTime.isNotEmpty) "end_time": endTime,
        "location": location,
        "trainer": ?trainerId,
        if (notes != null && notes.trim().isNotEmpty) "notes": notes.trim(),
      },
    );
  }

  Future<List<Map<String, dynamic>>> fetchPayments({String? month}) async {
    final response = await ApiClient.dio.get<dynamic>(
      "/payments/",
      queryParameters: month == null ? null : <String, dynamic>{"month": month},
    );
    final list = (response.data as List<dynamic>?) ?? <dynamic>[];
    return list.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  Future<void> createPayment({
    required int memberId,
    required String month,
    required String amount,
    required bool isPaid,
    String? paidDate,
  }) async {
    await ApiClient.dio.post<dynamic>(
      "/payments/",
      data: <String, dynamic>{
        "member": memberId,
        "month": month,
        "amount": amount,
        "is_paid": isPaid,
        if (paidDate != null && paidDate.isNotEmpty) "paid_date": paidDate,
      },
    );
  }

  Future<List<Map<String, dynamic>>> fetchActiveQuestionnaires() async {
    final response = await ApiClient.dio.get<dynamic>("/questionnaires/active/");
    final list = (response.data as List<dynamic>?) ?? <dynamic>[];
    return list.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  Future<void> submitQuestionnaireResponse({
    required int questionnaireId,
    required int memberId,
    required Map<String, dynamic> answers,
  }) async {
    await ApiClient.dio.post<dynamic>(
      "/questionnaire-responses/",
      data: <String, dynamic>{
        "questionnaire": questionnaireId,
        "member": memberId,
        "answers": answers,
      },
    );
  }
}
