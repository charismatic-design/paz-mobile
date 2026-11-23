class ApiConfig {
  ApiConfig._();

  // Central live backend URL
  static const String baseUrl = 'https://paz-backend-onat.onrender.com';

  // Auth endpoints
  static const String login = '$baseUrl/api/auth/login';
  static const String register = '$baseUrl/api/auth/register';
  static const String me = '$baseUrl/api/auth/me';
  static const String preferences = '$baseUrl/api/auth/preferences';
  static const String deleteAccount = '$baseUrl/auth/account';

  // Market & Macro data
  static const String fxRates = '$baseUrl/api/fx/rates';
  static const String fxBanks = '$baseUrl/api/fx/banks';
  static String remittance({required double amount, required String currency}) =>
      '$baseUrl/api/fx/remittance?amount=$amount&currency=$currency';
  static const String goldLive = '$baseUrl/api/gold/live';
  static const String macroIndicators = '$baseUrl/api/macro/indicators';
  static const String macroNews = '$baseUrl/api/macro/news';

  // Portfolio & Bank Accounts
  static const String bankSummary = '$baseUrl/api/bank/summary';
  static const String bankAccounts = '$baseUrl/api/bank/accounts';
  static String deleteBankAccount(dynamic id) => '$baseUrl/api/bank/accounts/$id';

  // Watchlist & Price Alerts
  static const String alerts = '$baseUrl/api/watchlist/alerts';
  static const String createAlert = '$baseUrl/api/watchlist/alert';
  static String deleteAlert(dynamic id) => '$baseUrl/api/watchlist/alert/$id';

  // Conversational AI (Ask PAZ)
  static const String aiChat = '$baseUrl/api/ai/chat';
}
