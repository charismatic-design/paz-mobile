import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../core/config/api_config.dart';
import 'storage_service.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final StorageService _storage = StorageService();

  Future<Map<String, String>> _headers({bool requiresAuth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (requiresAuth) {
      final token = await _storage.getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  dynamic _processResponse(http.Response response) {
    dynamic body;
    try {
      body = jsonDecode(response.body);
    } catch (_) {
      body = null;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    String errorMessage = 'Request failed (${response.statusCode})';
    if (body is Map && body.containsKey('detail')) {
      final detail = body['detail'];
      if (detail is List) {
        errorMessage = detail.map((d) => d['msg'] ?? d.toString()).join(', ');
      } else {
        errorMessage = detail.toString();
      }
    } else if (body is Map && body.containsKey('message')) {
      errorMessage = body['message'].toString();
    }

    throw ApiException(errorMessage, statusCode: response.statusCode);
  }

  // ==================== AUTH ====================

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final res = await http.post(
        Uri.parse(ApiConfig.login),
        headers: await _headers(requiresAuth: false),
        body: jsonEncode({
          'email': email.trim().toLowerCase(),
          'password': password,
        }),
      );

      final data = _processResponse(res) as Map<String, dynamic>;
      final token = data['access_token'] as String?;
      final user = data['user'] as Map<String, dynamic>?;

      if (token != null) {
        await _storage.saveToken(token);
      }
      if (user != null) {
        await _storage.saveUser(user);
      }

      return data;
    } on SocketException {
      throw ApiException('Unable to connect to PAZ backend. Check network connection.');
    }
  }

  Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String password,
    String preferredCurrency = 'USD',
    String preferredBank = 'CBE',
  }) async {
    try {
      final res = await http.post(
        Uri.parse(ApiConfig.register),
        headers: await _headers(requiresAuth: false),
        body: jsonEncode({
          'full_name': fullName.trim(),
          'email': email.trim().toLowerCase(),
          'password': password,
          'preferred_currency': preferredCurrency,
          'preferred_bank': preferredBank,
        }),
      );

      final data = _processResponse(res) as Map<String, dynamic>;
      final token = data['access_token'] as String?;
      final user = data['user'] as Map<String, dynamic>?;

      if (token != null) {
        await _storage.saveToken(token);
      }
      if (user != null) {
        await _storage.saveUser(user);
      }

      return data;
    } on SocketException {
      throw ApiException('Unable to connect to PAZ backend. Check network connection.');
    }
  }

  Future<Map<String, dynamic>?> getMe() async {
    try {
      final res = await http.get(
        Uri.parse(ApiConfig.me),
        headers: await _headers(requiresAuth: true),
      );

      final data = _processResponse(res) as Map<String, dynamic>;
      final user = data['user'] as Map<String, dynamic>?;
      if (user != null) {
        await _storage.saveUser(user);
      }
      return user;
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        await _storage.clearAll();
      }
      rethrow;
    } on SocketException {
      // Offline fallback: return cached user if present
      return await _storage.getUser();
    }
  }

  Future<Map<String, dynamic>> updatePreferences({
    String? preferredCurrency,
    String? preferredBank,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (preferredCurrency != null) body['preferred_currency'] = preferredCurrency;
      if (preferredBank != null) body['preferred_bank'] = preferredBank;

      final res = await http.post(
        Uri.parse(ApiConfig.preferences),
        headers: await _headers(requiresAuth: true),
        body: jsonEncode(body),
      );
      final data = _processResponse(res) as Map<String, dynamic>;
      final user = data['user'] as Map<String, dynamic>?;
      if (user != null) {
        await _storage.saveUser(user);
      }
      return data;
    } on SocketException {
      throw ApiException('Network error updating preferences');
    }
  }

  Future<void> deleteAccount() async {
    final res = await http.delete(
      Uri.parse(ApiConfig.deleteAccount),
      headers: await _headers(requiresAuth: true),
    );
    _processResponse(res);
    await _storage.clearAll();
  }

  Future<void> logout() async {
    await _storage.clearAll();
  }

  // ==================== MARKET DATA ====================

  Future<Map<String, dynamic>> getFxRates() async {
    try {
      final res = await http.get(
        Uri.parse(ApiConfig.fxRates),
        headers: await _headers(requiresAuth: false),
      );
      return _processResponse(res) as Map<String, dynamic>;
    } on SocketException {
      throw ApiException('Network error fetching live FX rates');
    }
  }

  Future<Map<String, dynamic>> getFxBanks() async {
    try {
      final res = await http.get(
        Uri.parse(ApiConfig.fxBanks),
        headers: await _headers(requiresAuth: false),
      );
      return _processResponse(res) as Map<String, dynamic>;
    } on SocketException {
      throw ApiException('Network error fetching commercial banks FX rates');
    }
  }

  Future<Map<String, dynamic>> getRemittance({
    required double amount,
    required String currency,
  }) async {
    try {
      final res = await http.get(
        Uri.parse(ApiConfig.remittance(amount: amount, currency: currency)),
        headers: await _headers(requiresAuth: false),
      );
      return _processResponse(res) as Map<String, dynamic>;
    } on SocketException {
      throw ApiException('Network error fetching diaspora remittance corridors');
    }
  }

  Future<Map<String, dynamic>> getGoldLive() async {
    try {
      final res = await http.get(
        Uri.parse(ApiConfig.goldLive),
        headers: await _headers(requiresAuth: false),
      );
      return _processResponse(res) as Map<String, dynamic>;
    } on SocketException {
      throw ApiException('Network error fetching physical gold spot rate');
    }
  }

  Future<Map<String, dynamic>> getMacroIndicators() async {
    try {
      final res = await http.get(
        Uri.parse(ApiConfig.macroIndicators),
        headers: await _headers(requiresAuth: false),
      );
      return _processResponse(res) as Map<String, dynamic>;
    } on SocketException {
      throw ApiException('Network error fetching macro indicators');
    }
  }

  Future<Map<String, dynamic>> getMacroNews() async {
    try {
      final res = await http.get(
        Uri.parse(ApiConfig.macroNews),
        headers: await _headers(requiresAuth: false),
      );
      return _processResponse(res) as Map<String, dynamic>;
    } on SocketException {
      throw ApiException('Network error fetching Ethiopian financial news');
    }
  }

  // ==================== PORTFOLIO & BANK ACCOUNTS ====================

  Future<Map<String, dynamic>> getBankSummary() async {
    try {
      final res = await http.get(
        Uri.parse(ApiConfig.bankSummary),
        headers: await _headers(requiresAuth: true),
      );
      return _processResponse(res) as Map<String, dynamic>;
    } on SocketException {
      throw ApiException('Network error fetching portfolio summary');
    }
  }

  Future<Map<String, dynamic>> addBankAccount({
    required String bankName,
    required String accountNumber,
    required double balance,
    String currency = 'ETB',
  }) async {
    try {
      final res = await http.post(
        Uri.parse(ApiConfig.bankAccounts),
        headers: await _headers(requiresAuth: true),
        body: jsonEncode({
          'bank_name': bankName.trim(),
          'account_number': accountNumber.trim(),
          'balance': balance,
          'currency': currency.trim().toUpperCase(),
        }),
      );
      return _processResponse(res) as Map<String, dynamic>;
    } on SocketException {
      throw ApiException('Network error adding bank account');
    }
  }

  Future<void> deleteBankAccount(dynamic id) async {
    try {
      final res = await http.delete(
        Uri.parse(ApiConfig.deleteBankAccount(id)),
        headers: await _headers(requiresAuth: true),
      );
      _processResponse(res);
    } on SocketException {
      throw ApiException('Network error deleting bank account');
    }
  }

  // ==================== WATCHLIST ALERTS ====================

  Future<List<Map<String, dynamic>>> getAlerts() async {
    try {
      final res = await http.get(
        Uri.parse(ApiConfig.alerts),
        headers: await _headers(requiresAuth: true),
      );
      final data = _processResponse(res) as Map<String, dynamic>;
      final rawList = data['alerts'] as List? ?? [];
      return rawList.map((item) => Map<String, dynamic>.from(item as Map)).toList();
    } on SocketException {
      throw ApiException('Network error fetching alerts');
    }
  }

  Future<Map<String, dynamic>> createAlert({
    required String ticker,
    required double targetPrice,
    required String direction,
  }) async {
    try {
      final res = await http.post(
        Uri.parse(ApiConfig.createAlert),
        headers: await _headers(requiresAuth: true),
        body: jsonEncode({
          'ticker': ticker.trim().toUpperCase(),
          'target_price': targetPrice,
          'direction': direction.trim().toLowerCase(),
        }),
      );
      return _processResponse(res) as Map<String, dynamic>;
    } on SocketException {
      throw ApiException('Network error creating alert');
    }
  }

  Future<void> deleteAlert(dynamic id) async {
    try {
      final res = await http.delete(
        Uri.parse(ApiConfig.deleteAlert(id)),
        headers: await _headers(requiresAuth: true),
      );
      _processResponse(res);
    } on SocketException {
      throw ApiException('Network error deleting alert');
    }
  }

  // ==================== ASK PAZ (CONVERSATIONAL AI) ====================

  Future<Map<String, dynamic>> sendAiChat(String message) async {
    try {
      final res = await http.post(
        Uri.parse(ApiConfig.aiChat),
        headers: await _headers(requiresAuth: true),
        body: jsonEncode({
          'message': message.trim(),
        }),
      );
      return _processResponse(res) as Map<String, dynamic>;
    } on SocketException {
      throw ApiException('Network error contacting PAZ financial intelligence agent');
    }
  }
}
