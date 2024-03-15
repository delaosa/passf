import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
//import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:flutter/services.dart';
import '../constants.dart' show appName;


class LockScreenRoute extends StatefulWidget {
  static const String routeName = "/lockscreen";

  LockScreenRoute({
    Key key,
  }) : super(key: key);

  @override
  LockScreenRouteState createState() => LockScreenRouteState();
}

class LockScreenRouteState extends State<LockScreenRoute> {

  final LocalAuthentication auth = LocalAuthentication();
  bool _securityBiometric = false;
  bool _biometricSupportState = false;
  String _authorized = 'Not Authorized';
  bool _isAuthenticating = false;


  @override
  void initState() {
    super.initState();
    auth.isDeviceSupported().then(
          (isSupported) =>
          setState(() => _biometricSupportState = isSupported),);
    _authenticateWithBiometrics();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            SizedBox(height: 96),
            Icon(Icons.https, size: 250),
            //SizedBox(height: 64),
            ListTile(
              title: Text(_authorized),
              leading: Icon(Icons.fingerprint, color: Theme
                  .of(context).colorScheme.secondary),
              //dense: true,
              //leading: Icon(Icons.more),
              onTap: () {
                SystemChannels.platform.invokeMethod('SystemNavigator.pop');
              },
            ),
          ],
        ),
      ),
    );
  }


  Future<void> _authenticateWithBiometrics() async {
    bool authenticated = false;
    try {
      setState(() {
        _isAuthenticating = true;
        _authorized = 'Authenticating';
      });
      authenticated = await auth.authenticate(
          localizedReason: appName,
          options: const AuthenticationOptions(useErrorDialogs: true, stickyAuth: true, biometricOnly: true));
      setState(() {
        _isAuthenticating = false;
        _authorized = 'Authenticating';
      });
    } on PlatformException catch (e) {
      print(e);
      setState(() {
        _isAuthenticating = false;
        _authorized = "Error - ${e.message}";
      });
      return;
    }
    if (!mounted) return;

    final String message = authenticated ? 'Authorized' : 'Not Authorized';
    setState(() {
      _authorized = message;
    });

    Navigator.pop(context, authenticated);
  }
}