import "../../core/api_client.dart";

class ClubService {
  Future<List<Map<String, dynamic>>> fetchTeams() async {
    final response = await ApiClient.dio.get<dynamic>("/teams/");
    final list = (response.data as List<dynamic>?) ?? <dynamic>[];
    return list.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  Future<List<Map<String, dynamic>>> fetchTeamMembers({required int teamId}) async {
    final response = await ApiClient.dio.get<dynamic>("/teams/$teamId/members/");
    final list = (response.data as List<dynamic>?) ?? <dynamic>[];
    return list.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  Future<List<Map<String, dynamic>>> fetchTrainings() async {
    final response = await ApiClient.dio.get<dynamic>("/trainings/");
    final list = (response.data as List<dynamic>?) ?? <dynamic>[];
    return list.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  Future<List<Map<String, dynamic>>> fetchPayments({String? month}) async {
    final response = await ApiClient.dio.get<dynamic>(
      "/payments/",
      queryParameters: month == null ? null : <String, dynamic>{"month": month},
    );
    final list = (response.data as List<dynamic>?) ?? <dynamic>[];
    return list.map((item) => Map<String, dynamic>.from(item as Map)).toList();
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
