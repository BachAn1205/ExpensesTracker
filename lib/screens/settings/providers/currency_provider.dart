import 'package:flutter/material.dart';

class CurrencyProvider extends ChangeNotifier {
  String _currency = 'VND';
  String get currency => _currency;

  void setCurrency(String newCurrency) {
    if (_currency != newCurrency) {
      _currency = newCurrency;
      notifyListeners();
    }
  }
}

