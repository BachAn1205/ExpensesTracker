class CurrencyService {
  static final Map<String, double> _exchangeRates = {
    'VND': 1.0,
    'USD': 0.000042, // 1 VND = 0.000042 USD
    'CNY': 0.00030,  // 1 VND = 0.00030 CNY
    'EUR': 0.000038, // 1 VND = 0.000038 EUR
    'JPY': 0.0059,   // 1 VND = 0.0059 JPY
    'KRW': 0.054,    // 1 VND = 0.054 KRW
    'MXN': 0.00071,  // 1 VND = 0.00071 MXN
    'BRL': 0.00020,  // 1 VND = 0.00020 BRL
  };

  static String _currentCurrency = 'VND';

  static String get currentCurrency => _currentCurrency;

  static void setCurrentCurrency(String currency) {
    if (_exchangeRates.containsKey(currency)) {
      _currentCurrency = currency;
    }
  }

  static double convertFromVND(double amount, String targetCurrency) {
    if (!_exchangeRates.containsKey(targetCurrency)) return amount;
    return amount * _exchangeRates[targetCurrency]!;
  }

  static double convertToVND(double amount, String sourceCurrency) {
    if (!_exchangeRates.containsKey(sourceCurrency)) return amount;
    return amount / _exchangeRates[sourceCurrency]!;
  }

  static String formatCurrency(double amount, String currency) {
    if (currency == 'VND') {
      return '${amount.toStringAsFixed(0)}₫';
    }

    final symbols = {
      'USD': '\$',
      'CNY': '¥',
      'EUR': '€',
      'JPY': '¥',
      'KRW': '₩',
      'MXN': '\$',
      'BRL': 'R\$',
    };

    String symbol = symbols[currency] ?? currency;
    return '$symbol${amount.toStringAsFixed(2)}';
  }
}
