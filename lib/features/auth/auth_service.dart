import "package:dio/dio.dart";

import "../../core/api_client.dart";
import "../../core/token_storage.dart";

class AuthService {
  AuthService({TokenStorage? tokenStorage}) : _tokenStorage = tokenStorage ?? TokenStorage();

  final TokenStorage _tokenStorage;

  Future<void> login({required String email, required String password}) async {
    final response = await ApiClient.dio.post<dynamic>(
      "/auth/token/",
      data: <String, dynamic>{
        "email": email,
        "password": password,
      },
    );

    final access = response.data["access"] as String?;
    final refresh = response.data["refresh"] as String?;

    if (access == null || refresh == null) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: "Token response is missing access or refresh values.",
      );
    }

    await _tokenStorage.saveTokens(accessToken: access, refreshToken: refresh);
  }

  Future<Map<String, dynamic>> me() async {
    final response = await ApiClient.dio.get<dynamic>("/auth/me/");
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<void> logout() => _tokenStorage.clear();

  Future<bool> hasSession() async {
    final token = await _tokenStorage.readAccessToken();
    return token != null && token.isNotEmpty;
  }
}
