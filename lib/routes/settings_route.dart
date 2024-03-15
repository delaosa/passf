import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
//import 'package:local_auth/error_codes.dart' as auth_error;
import 'setgit_router.dart';
import 'setgpg_route.dart';
import 'about_route.dart';
import 'setadvanced_route.dart';
import '../providers/passf_provider.dart';
import '../constants.dart' show appName;

class SettingsRoute extends StatefulWidget {
  static const String routeName = "/settings";

  SettingsRoute({
    Key key,
  }) : super(key: key);

  @override
  SettingsRouteState createState() => SettingsRouteState();
}

class SettingsRouteState extends State<SettingsRoute> {
  static const String title = "Settings";
  SharedPreferences prefs;
  final LocalAuthentication auth = LocalAuthentication();
  bool _securityBiometric = false;
  bool _biometricSupportState = false;
  bool _authorized = false;
  bool _isAuthenticating = false;


  @override
  void initState() {
    super.initState();
    auth.isDeviceSupported().then(
          (isSupported) => setState(() => _biometricSupportState = isSupported));
    SharedPreferences.getInstance().then((SharedPreferences content) {
      prefs = content;
      _securityBiometric = prefs.getBool('security_biometric');
      setState(() {});
    });
  }

  Future<bool> _authenticateWithBiometrics() async {
    bool authenticated = false;
    try {
      setState(() {
        _isAuthenticating = true;
      });
      authenticated = await auth.authenticate(
          localizedReason: appName,
          options: const AuthenticationOptions(useErrorDialogs: true, stickyAuth: true, biometricOnly: true));
      setState(() {
        _isAuthenticating = false;
      });
    } on PlatformException catch (e) {
      print(e);
      setState(() {
        _isAuthenticating = false;
      });
      return false;
    }
    if (!mounted) return false;

    setState(() {
      _authorized = authenticated;
    });

    return authenticated;
  }

  @override
  Widget build(BuildContext context) {
    final passwords = Provider.of<Passwords>(context);
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context);
        await passwords.loadSettings();
        //await passwords.cloneGit();
        passwords.reloadPasswords();
        return Future.value(true);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
        ),
        body: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            //mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              SizedBox(height: 24),
              Text("Repository",
                  textAlign: TextAlign.left,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.secondary,
                      fontWeight: FontWeight.bold)),
              SizedBox(height: 12.0),
              ListTile(
                title: Text("Git"),
                //subtitle: Text(_gitUrl ?? "", maxLines: 1),
                leading: Icon(Icons.public, color: Theme.of(context).colorScheme.secondary),
                onTap: () {
                  Navigator.pushNamed(context, SetGitRoute.routeName,
                      arguments: 'git');
                },
                //dense: true,
              ),
              const Divider(
                height: 0,
                thickness: 0,
              ),
              SizedBox(height: 24.0),
              Text("PGP",
                  textAlign: TextAlign.left,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.secondary,
                      fontWeight: FontWeight.bold)),
              SizedBox(height: 12.0),
              ListTile(
                title: Text("Keys"),
                //dense: true,
                //subtitle: Text(_gpgHash ?? "" , maxLines: 1),
                leading: Icon(Icons.security, color: Theme.of(context).colorScheme.secondary),
                onTap: () {
                  Navigator.pushNamed(context, SetGpgRoute.routeName,
                      arguments: 'gpg');
                },
              ),
              const Divider(
                height: 0,
                thickness: 0,
              ),
              SizedBox(height: 24.0),
              Text(" Security",
                  textAlign: TextAlign.left,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.secondary,
                      fontWeight: FontWeight.bold)),
              SizedBox(height: 12.0),
              SwitchListTile(
                title: Text('Biometric Auth on Startup'),
                value: _securityBiometric,
                onChanged: (bool value) async {
                  if(await _authenticateWithBiometrics()) {
                    setState(() {
                      _securityBiometric = value;
                      prefs.setBool('security_biometric', _securityBiometric);
                    });
                  }
                },
                secondary: Icon(Icons.fingerprint, color: Theme.of(context).colorScheme.secondary),
              ),
              const Divider(
                height: 0,
                thickness: 0,
              ),
              SizedBox(height: 24.0),
              ListTile(
                title: Text("Advanced"),
                leading: Icon(Icons.offline_bolt, color: Theme.of(context).colorScheme.secondary),
                //dense: true,
                //leading: Icon(Icons.more),
                onTap: () {
                  Navigator.pushNamed(context, SetAdvanced.routeName);
                },
              ),
              const Divider(
                height: 0,
                thickness: 0,
              ),
              SizedBox(height: 24.0),
              ListTile(
                title: Text("About"),
                leading: Icon(Icons.info_outline, color: Theme.of(context).colorScheme.secondary),
                onTap: () {
                  Navigator.pushNamed(context, About.routeName);
                }, //leading: Icon(Icons.info),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
