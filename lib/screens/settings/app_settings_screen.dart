import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../settings/providers/currency_provider.dart';
import '../settings/providers/language_provider.dart';
import '../../../generated/l10n/app_localizations.dart';

class AppSettingsScreen extends StatefulWidget {
  const AppSettingsScreen({super.key});

  @override
  State<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends State<AppSettingsScreen> {
  String _selectedCurrency = 'VND';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _selectedCurrency = Provider.of<CurrencyProvider>(context).currency;
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appSettings),
      ),
      body: ListView(
        children: [
          ListTile(
            title: Text(l10n.language),
            trailing: Text(languageProvider.getLanguageName(languageProvider.currentLanguage)),
            onTap: () => _showLanguageDialog(context),
          ),
          ListTile(
            title: Text(l10n.currency),
            trailing: Text(_selectedCurrency),
            onTap: () => _showCurrencyDialog(context),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final l10n = AppLocalizations.of(context)!;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(l10n.selectLanguage),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: languageProvider.supportedLanguages.map((lang) => 
                _languageListTile(lang['code']!, lang['name']!)
              ).toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _languageListTile(String code, String name) {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    
    return ListTile(
      title: Text(name),
      selected: languageProvider.currentLanguage == code,
      onTap: () async {
        await languageProvider.setLanguage(code);
        if (mounted) {
          Navigator.pop(context);
          // Hiển thị thông báo restart app
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ngôn ngữ đã được thay đổi. Vui lòng khởi động lại ứng dụng để áp dụng.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      },
    );
  }

  void _showCurrencyDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currencies = [
      {'code': 'VND', 'name': l10n.vnd},
      {'code': 'USD', 'name': l10n.usd},
      {'code': 'JPY', 'name': l10n.jpy},
      {'code': 'KRW', 'name': l10n.krw},
      {'code': 'EUR', 'name': l10n.eur},
      {'code': 'CNY', 'name': l10n.cny},
      {'code': 'INR', 'name': 'INR (Rupee Ấn Độ)'},
      {'code': 'BRL', 'name': l10n.brl},
    ];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(l10n.selectCurrency),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: currencies.map((currency) => ListTile(
                title: Text(currency['name']!),
                selected: _selectedCurrency == currency['code'],
                onTap: () {
                  Provider.of<CurrencyProvider>(context, listen: false)
                      .setCurrency(currency['code']!);
                  setState(() {
                    _selectedCurrency = currency['code']!;
                  });
                  Navigator.pop(context);
                },
              )).toList(),
            ),
          ),
        );
      },
    );
  }
}
