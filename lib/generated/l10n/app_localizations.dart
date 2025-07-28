import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/foundation.dart';

class AppLocalizations {
  AppLocalizations(this.localeName);

  static const AppLocalizationsDelegate delegate = AppLocalizationsDelegate();

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('vi'),
    Locale('zh'),
    Locale('de'),
    Locale('fr'),
    Locale('es'),
    Locale('pt'),
    Locale('ko'),
    Locale('ja'),
  ];

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static AppLocalizations? ofNullable(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  final String localeName;

  String get appTitle {
    switch (localeName) {
      case 'vi':
        return 'Quản lý chi tiêu';
      case 'zh':
        return '支出追踪器';
      case 'de':
        return 'Ausgabenverfolger';
      case 'fr':
        return 'Gestionnaire de dépenses';
      case 'es':
        return 'Gestor de gastos';
      case 'pt':
        return 'Gerenciador de despesas';
      case 'ko':
        return '지출 관리자';
      case 'ja':
        return '支出管理アプリ';
      default:
        return 'Expense Tracker';
    }
  }

  String get login {
    switch (localeName) {
      case 'vi':
        return 'Đăng nhập';
      case 'zh':
        return '登录';
      case 'de':
        return 'Anmelden';
      case 'fr':
        return 'Connexion';
      case 'es':
        return 'Iniciar sesión';
      case 'pt':
        return 'Entrar';
      case 'ko':
        return '로그인';
      case 'ja':
        return 'ログイン';
      default:
        return 'Login';
    }
  }

  String get register {
    switch (localeName) {
      case 'vi':
        return 'Đăng ký';
      case 'zh':
        return '注册';
      case 'de':
        return 'Registrieren';
      case 'fr':
        return 'S\'inscrire';
      case 'es':
        return 'Registrarse';
      case 'pt':
        return 'Registrar';
      case 'ko':
        return '회원가입';
      case 'ja':
        return '登録';
      default:
        return 'Register';
    }
  }

  String get settings {
    switch (localeName) {
      case 'vi':
        return 'Cài đặt';
      case 'zh':
        return '设置';
      case 'de':
        return 'Einstellungen';
      case 'fr':
        return 'Paramètres';
      case 'es':
        return 'Configuración';
      case 'pt':
        return 'Configurações';
      case 'ko':
        return '설정';
      case 'ja':
        return '設定';
      default:
        return 'Settings';
    }
  }

  String get editProfile {
    switch (localeName) {
      case 'vi':
        return 'Chỉnh sửa hồ sơ';
      case 'zh':
        return '编辑资料';
      case 'de':
        return 'Profil bearbeiten';
      case 'fr':
        return 'Modifier le profil';
      case 'es':
        return 'Editar perfil';
      case 'pt':
        return 'Editar perfil';
      case 'ko':
        return '프로필 편집';
      case 'ja':
        return 'プロフィール編集';
      default:
        return 'Edit Profile';
    }
  }

  String get appSettings {
    switch (localeName) {
      case 'vi':
        return 'Cài đặt ứng dụng';
      case 'zh':
        return '应用设置';
      case 'de':
        return 'App-Einstellungen';
      case 'fr':
        return 'Paramètres de l\'application';
      case 'es':
        return 'Configuración de la aplicación';
      case 'pt':
        return 'Configurações do aplicativo';
      case 'ko':
        return '앱 설정';
      case 'ja':
        return 'アプリ設定';
      default:
        return 'App Settings';
    }
  }

  String get language {
    switch (localeName) {
      case 'vi':
        return 'Ngôn ngữ';
      case 'zh':
        return '语言';
      case 'de':
        return 'Sprache';
      case 'fr':
        return 'Langue';
      case 'es':
        return 'Idioma';
      case 'pt':
        return 'Idioma';
      case 'ko':
        return '언어';
      case 'ja':
        return '言語';
      default:
        return 'Language';
    }
  }

  String get currency {
    switch (localeName) {
      case 'vi':
        return 'Đơn vị tiền tệ';
      case 'zh':
        return '货币';
      case 'de':
        return 'Währung';
      case 'fr':
        return 'Devise';
      case 'es':
        return 'Moneda';
      case 'pt':
        return 'Moeda';
      case 'ko':
        return '통화';
      case 'ja':
        return '通貨';
      default:
        return 'Currency';
    }
  }

  String get selectLanguage {
    switch (localeName) {
      case 'vi':
        return 'Chọn ngôn ngữ';
      case 'zh':
        return '选择语言';
      case 'de':
        return 'Sprache auswählen';
      case 'fr':
        return 'Sélectionner la langue';
      case 'es':
        return 'Seleccionar idioma';
      case 'pt':
        return 'Selecionar idioma';
      case 'ko':
        return '언어 선택';
      case 'ja':
        return '言語を選択';
      default:
        return 'Select Language';
    }
  }

  String get selectCurrency {
    switch (localeName) {
      case 'vi':
        return 'Chọn đơn vị tiền tệ';
      case 'zh':
        return '选择货币';
      case 'de':
        return 'Währung auswählen';
      case 'fr':
        return 'Sélectionner la devise';
      case 'es':
        return 'Seleccionar moneda';
      case 'pt':
        return 'Selecionar moeda';
      case 'ko':
        return '통화 선택';
      case 'ja':
        return '通貨を選択';
      default:
        return 'Select Currency';
    }
  }

  String get vnd {
    switch (localeName) {
      case 'vi':
        return 'VND (Việt Nam Đồng)';
      case 'zh':
        return 'VND (越南盾)';
      case 'de':
        return 'VND (Vietnamesischer Dong)';
      case 'fr':
        return 'VND (Dong vietnamien)';
      case 'es':
        return 'VND (Dong vietnamita)';
      case 'pt':
        return 'VND (Dong vietnamita)';
      case 'ko':
        return 'VND (베트남 동)';
      case 'ja':
        return 'VND (ベトナムドン)';
      default:
        return 'VND (Vietnamese Dong)';
    }
  }

  String get usd {
    switch (localeName) {
      case 'vi':
        return 'USD (Đô la Mỹ)';
      case 'zh':
        return 'USD (美元)';
      case 'de':
        return 'USD (US-Dollar)';
      case 'fr':
        return 'USD (Dollar américain)';
      case 'es':
        return 'USD (Dólar estadounidense)';
      case 'pt':
        return 'USD (Dólar americano)';
      case 'ko':
        return 'USD (미국 달러)';
      case 'ja':
        return 'USD (米ドル)';
      default:
        return 'USD (US Dollar)';
    }
  }

  String get cny {
    switch (localeName) {
      case 'vi':
        return 'CNY (Nhân dân tệ)';
      case 'zh':
        return 'CNY (人民币)';
      case 'de':
        return 'CNY (Chinesischer Yuan)';
      case 'fr':
        return 'CNY (Yuan chinois)';
      case 'es':
        return 'CNY (Yuan chino)';
      case 'pt':
        return 'CNY (Yuan chinês)';
      case 'ko':
        return 'CNY (중국 위안)';
      case 'ja':
        return 'CNY (中国元)';
      default:
        return 'CNY (Chinese Yuan)';
    }
  }

  String get eur {
    switch (localeName) {
      case 'vi':
        return 'EUR (Euro)';
      case 'zh':
        return 'EUR (欧元)';
      case 'de':
        return 'EUR (Euro)';
      case 'fr':
        return 'EUR (Euro)';
      case 'es':
        return 'EUR (Euro)';
      case 'pt':
        return 'EUR (Euro)';
      case 'ko':
        return 'EUR (유로)';
      case 'ja':
        return 'EUR (ユーロ)';
      default:
        return 'EUR (Euro)';
    }
  }

  String get jpy {
    switch (localeName) {
      case 'vi':
        return 'JPY (Yên Nhật)';
      case 'zh':
        return 'JPY (日元)';
      case 'de':
        return 'JPY (Japanischer Yen)';
      case 'fr':
        return 'JPY (Yen japonais)';
      case 'es':
        return 'JPY (Yen japonés)';
      case 'pt':
        return 'JPY (Iene japonês)';
      case 'ko':
        return 'JPY (일본 엔)';
      case 'ja':
        return 'JPY (日本円)';
      default:
        return 'JPY (Japanese Yen)';
    }
  }

  String get krw {
    switch (localeName) {
      case 'vi':
        return 'KRW (Won Hàn Quốc)';
      case 'zh':
        return 'KRW (韩元)';
      case 'de':
        return 'KRW (Südkoreanischer Won)';
      case 'fr':
        return 'KRW (Won coréen)';
      case 'es':
        return 'KRW (Won coreano)';
      case 'pt':
        return 'KRW (Won coreano)';
      case 'ko':
        return 'KRW (한국 원)';
      case 'ja':
        return 'KRW (韓国ウォン)';
      default:
        return 'KRW (Korean Won)';
    }
  }

  String get mxn {
    switch (localeName) {
      case 'vi':
        return 'MXN (Peso Mexico)';
      case 'zh':
        return 'MXN (墨西哥比索)';
      case 'de':
        return 'MXN (Mexikanischer Peso)';
      case 'fr':
        return 'MXN (Peso mexicain)';
      case 'es':
        return 'MXN (Peso mexicano)';
      case 'pt':
        return 'MXN (Peso mexicano)';
      case 'ko':
        return 'MXN (멕시코 페소)';
      case 'ja':
        return 'MXN (メキシコペソ)';
      default:
        return 'MXN (Mexican Peso)';
    }
  }

  String get brl {
    switch (localeName) {
      case 'vi':
        return 'BRL (Real Brazil)';
      case 'zh':
        return 'BRL (巴西雷亚尔)';
      case 'de':
        return 'BRL (Brasilianischer Real)';
      case 'fr':
        return 'BRL (Real brésilien)';
      case 'es':
        return 'BRL (Real brasileño)';
      case 'pt':
        return 'BRL (Real brasileiro)';
      case 'ko':
        return 'BRL (브라질 레알)';
      case 'ja':
        return 'BRL (ブラジルレアル)';
      default:
        return 'BRL (Brazilian Real)';
    }
  }

  String get logout {
    switch (localeName) {
      case 'vi':
        return 'Đăng xuất';
      case 'zh':
        return '退出登录';
      case 'de':
        return 'Abmelden';
      case 'fr':
        return 'Se déconnecter';
      case 'es':
        return 'Cerrar sesión';
      case 'pt':
        return 'Sair';
      case 'ko':
        return '로그아웃';
      case 'ja':
        return 'ログアウト';
      default:
        return 'Logout';
    }
  }
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'vi', 'zh', 'de', 'fr', 'es', 'pt', 'ko', 'ja'].contains(locale.languageCode);

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) => false;

  @override
  String toString() => 'AppLocalizations.delegate()';
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  final String languageCode = locale.languageCode;
  switch (languageCode) {
    case 'en':
      return AppLocalizations('en');
    case 'vi':
      return AppLocalizations('vi');
    case 'zh':
      return AppLocalizations('zh');
    case 'de':
      return AppLocalizations('de');
    case 'fr':
      return AppLocalizations('fr');
    case 'es':
      return AppLocalizations('es');
    case 'pt':
      return AppLocalizations('pt');
    case 'ko':
      return AppLocalizations('ko');
    case 'ja':
      return AppLocalizations('ja');
    default:
      return AppLocalizations('en');
  }
}
