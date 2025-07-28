import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../settings/providers/currency_provider.dart';

class AppSettingsScreen extends StatefulWidget {
  const AppSettingsScreen({super.key});

  @override
  State<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends State<AppSettingsScreen> {
  String _selectedLanguage = 'vi';
  String _selectedCurrency = 'VND';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _selectedCurrency = Provider.of<CurrencyProvider>(context).currency;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cài đặt ứng dụng'),
      ),
      body: ListView(
        children: [
          ListTile(
            title: Text('Ngôn ngữ'),
            trailing: Text(_getLanguageName(_selectedLanguage)),
            onTap: () => _showLanguageDialog(context),
          ),
          ListTile(
            title: Text('Đơn vị tiền tệ'),
            trailing: Text(_selectedCurrency),
            onTap: () => _showCurrencyDialog(context),
          ),
        ],
      ),
    );
  }

  String _getLanguageName(String code) {
    switch (code) {
      case 'vi':
        return 'Tiếng Việt';
      case 'en':
        return 'Tiếng Anh';
      case 'zh':
        return 'Tiếng Trung';
      case 'de':
        return 'Tiếng Đức';
      case 'fr':
        return 'Tiếng Pháp';
      case 'es':
        return 'Tiếng Tây Ban Nha';
      case 'pt':
        return 'Tiếng Bồ Đào Nha';
      case 'ko':
        return 'Tiếng Hàn';
      case 'ja':
        return 'Tiếng Nhật';
      default:
        return 'Tiếng Việt';
    }
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Chọn ngôn ngữ'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _languageListTile('vi', 'Tiếng Việt'),
                _languageListTile('en', 'Tiếng Anh'),
                _languageListTile('zh', 'Tiếng Trung'),
                _languageListTile('de', 'Tiếng Đức'),
                _languageListTile('fr', 'Tiếng Pháp'),
                _languageListTile('es', 'Tiếng Tây Ban Nha'),
                _languageListTile('pt', 'Tiếng Bồ Đào Nha'),
                _languageListTile('ko', 'Tiếng Hàn'),
                _languageListTile('ja', 'Tiếng Nhật'),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _languageListTile(String code, String name) {
    return ListTile(
      title: Text(name),
      selected: _selectedLanguage == code,
      onTap: () {
        setState(() {
          _selectedLanguage = code;
        });
        Navigator.pop(context);
      },
    );
  }

  void _showCurrencyDialog(BuildContext context) {
    final currencies = [
      {'code': 'VND', 'name': 'VND (Việt Nam Đồng)'},
      {'code': 'USD', 'name': 'USD (Đô la Mỹ)'},
      {'code': 'JPY', 'name': 'JPY (Yên Nhật)'},
      {'code': 'KRW', 'name': 'KRW (Won Hàn Quốc)'},
      {'code': 'EUR', 'name': 'EUR (Euro)'},
      {'code': 'CNY', 'name': 'CNY (Nhân dân tệ)'},
      {'code': 'INR', 'name': 'INR (Rupee Ấn Độ)'},
      {'code': 'BRL', 'name': 'BRL (Real Brazil)'},
    ];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Chọn đơn vị tiền tệ'),
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
