import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'storage_service.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;
  const ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiService {
  final StorageService _storage;

  ApiService(this._storage);

  Future<Map<String, String>> _authHeaders() async {
    final token = await _storage.getAccessToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<dynamic> post(String path, Map<String, dynamic> body,
      {bool requiresAuth = true}) async {
    final headers = requiresAuth
        ? await _authHeaders()
        : {'Content-Type': 'application/json'};
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}$path'),
      headers: headers,
      body: jsonEncode(body),
    );
    if (response.statusCode == 401 && requiresAuth) {
      final retried = await _refreshAndRetry('POST', path, body);
      if (retried != null) return retried;
    }
    return _handle(response);
  }

  Future<dynamic> get(String path) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}$path'),
      headers: await _authHeaders(),
    );
    if (response.statusCode == 401) {
      final retried = await _refreshAndRetry('GET', path, null);
      if (retried != null) return retried;
    }
    return _handle(response);
  }

  /// Like [get] but always returns a flat List, handling both paginated
  /// (`{"count":N,"results":[...]}`) and plain-list responses.
  Future<List<dynamic>> getList(String path) async {
    final data = await get(path);
    if (data is List) return data;
    if (data is Map && data.containsKey('results')) {
      return data['results'] as List<dynamic>;
    }
    return [];
  }

  Future<dynamic> patch(String path, Map<String, dynamic> body,
      {bool requiresAuth = true}) async {
    final headers = requiresAuth
        ? await _authHeaders()
        : {'Content-Type': 'application/json'};
    final response = await http.patch(
      Uri.parse('${ApiConfig.baseUrl}$path'),
      headers: headers,
      body: jsonEncode(body),
    );
    if (response.statusCode == 401 && requiresAuth) {
      final retried = await _refreshAndRetry('PATCH', path, body);
      if (retried != null) return retried;
    }
    return _handle(response);
  }

  /// Upload a file as multipart/form-data alongside JSON fields (named-parameter form).
  Future<dynamic> postMultipart(
    String path, {
    required File file,
    required String fileField,
    Map<String, String> fields = const {},
  }) async {
    final token = await _storage.getAccessToken();
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    final request = http.MultipartRequest('POST', uri);
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    request.fields.addAll(fields);
    request.files.add(await http.MultipartFile.fromPath(fileField, file.path));
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    return _handle(response);
  }

  /// Upload fields and an optional photo as multipart/form-data (positional-fields form).
  Future<dynamic> postMultipartFields(
    String path,
    Map<String, String> fields, {
    File? photoFile,
    String photoField = 'photo',
  }) async {
    final token = await _storage.getAccessToken();
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    final request = http.MultipartRequest('POST', uri);
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    request.fields.addAll(fields);
    if (photoFile != null) {
      request.files
          .add(await http.MultipartFile.fromPath(photoField, photoFile.path));
    }
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    return _handle(response);
  }

  Future<dynamic> delete(String path) async {
    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}$path'),
      headers: await _authHeaders(),
    );
    if (response.statusCode == 401) {
      final retried = await _refreshAndRetry('DELETE', path, null);
      if (retried != null) return retried;
    }
    return _handle(response);
  }

  Future<dynamic> _refreshAndRetry(
      String method, String path, Map<String, dynamic>? body) async {
    final refreshToken = await _storage.getRefreshToken();
    if (refreshToken == null) throw const ApiException(401, 'Session expired');

    try {
      final refreshResponse = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/token/refresh/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh': refreshToken}),
      );
      if (refreshResponse.statusCode != 200) {
        await _storage.clearAll();
        throw const ApiException(401, 'Session expired. Please sign in again.');
      }
      final data = jsonDecode(refreshResponse.body) as Map<String, dynamic>;
      final newAccess  = data['access']  as String;
      final newRefresh = data['refresh'] as String?;
      await _storage.saveTokens(
        accessToken:  newAccess,
        refreshToken: newRefresh ?? refreshToken,
      );

      // Retry original request with fresh token
      final headers = await _authHeaders();
      late http.Response retryResponse;
      switch (method) {
        case 'GET':
          retryResponse = await http.get(
              Uri.parse('${ApiConfig.baseUrl}$path'), headers: headers);
        case 'PATCH':
          retryResponse = await http.patch(
              Uri.parse('${ApiConfig.baseUrl}$path'),
              headers: headers, body: jsonEncode(body));
        case 'POST':
          retryResponse = await http.post(
              Uri.parse('${ApiConfig.baseUrl}$path'),
              headers: headers, body: jsonEncode(body));
        case 'DELETE':
          retryResponse = await http.delete(
              Uri.parse('${ApiConfig.baseUrl}$path'), headers: headers);
        default:
          return null;
      }
      return _handle(retryResponse);
    } catch (e) {
      await _storage.clearAll();
      rethrow;
    }
  }

  dynamic _handle(http.Response response) {
    if (response.body.isEmpty) {
      if (response.statusCode >= 200 && response.statusCode < 300) return null;
      throw ApiException(response.statusCode, 'Empty response');
    }
    final body = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) return body;
    final message =
        body is Map ? (body['detail'] ?? body.toString()) : body.toString();
    throw ApiException(response.statusCode, message.toString());
  }
}
