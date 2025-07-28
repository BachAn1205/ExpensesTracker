
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../generated/l10n/app_localizations.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
      ),
      body: ListView(
        children: [
          ListTile(
            title: Text(l10n.editProfile),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => Navigator.of(context).pushNamed('/settings/edit_profile'),
          ),

          ListTile(
            title: Text(l10n.appSettings),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => Navigator.of(context).pushNamed('/settings/app_settings'),
          ),
          ListTile(
            title: Text(l10n.logout),
            trailing: const Icon(Icons.logout),
            onTap: () => _logout(context),
          ),
        ],
      ),
    );
  }
}

