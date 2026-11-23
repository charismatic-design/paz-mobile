class ApiConfig {
  ApiConfig._();

  // Central live backend URL
  static const String baseUrl = 'https://paz-backend-onat.onrender.com';

  // Auth endpoints
  static const String login = '$baseUrl/api/auth/login';
  static const String register = '$baseUrl/api/auth/register';
  static const String me = '$baseUrl/api/auth/me';
  static const String deleteAccount = '$baseUrl/auth/account';

  // Market & Macro data
  static const String fxRates = '$baseUrl/api/fx/rates';
  static const String goldLive = '$baseUrl/api/gold/live';
  static const String macroIndicators = '$baseUrl/api/macro/indicators';

  // Watchlist & Price Alerts
  static const String alerts = '$baseUrl/api/watchlist/alerts';
  static const String createAlert = '$baseUrl/api/watchlist/alert';
  static String deleteAlert(int id) => '$baseUrl/api/watchlist/alert/$id';

  // Conversational AI (Ask PAZ)
  static const String aiChat = '$baseUrl/api/ai/chat';
}
