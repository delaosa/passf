import 'dart:io';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'routes/editpass_route.dart';
import 'routes/viewpass_route.dart';
import 'routes/addpass_route.dart';
import 'routes/settings_route.dart';
import 'routes/setgit_router.dart';
import 'routes/setsignature_router.dart';
import 'routes/setgpg_route.dart';
import 'routes/setadvanced_route.dart';
import 'routes/lockscreen_route.dart';
import 'routes/about_route.dart';
import 'routes/welcome_route.dart';
import 'providers/passf_provider.dart';
import 'theme/custom_theme.dart';
import 'constants.dart';
import 'widgets/password_list.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(PassF());
}

class PassF extends StatefulWidget {
  const PassF({Key key}) : super(key: key);
  @override
  _PassFState createState() => _PassFState();
}

class _PassFState extends State {
  @override
  void initState() {
    super.initState();
    currentTheme.addListener(() {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => Passwords(),
      child: MaterialApp(
        title: appName,
        theme: CustomTheme.lightTheme,
        darkTheme: CustomTheme.darkTheme,
        //themeMode: currentTheme.currentTheme,
        //themeMode: ThemeMode.system,
        initialRoute: ListRoute.routeName,
        routes: {
          AddPassRoute.routeName: (context) => AddPassRoute(),
          EditPassRoute.routeName: (context) => EditPassRoute(),
          SettingsRoute.routeName: (context) => SettingsRoute(),
          ViewPassRoute.routeName: (context) => ViewPassRoute(),
          ListRoute.routeName: (context) => ListRoute(),
          SetGitRoute.routeName: (context) => SetGitRoute(),
          SetSignatureRoute.routeName: (context) => SetSignatureRoute(),
          SetGpgRoute.routeName: (context) => SetGpgRoute(),
          SetAdvanced.routeName: (context) => SetAdvanced(),
          LockScreenRoute.routeName: (context) => LockScreenRoute(),
          About.routeName: (context) => About(),
          WelcomeRoute.routeName: (context) => WelcomeRoute(),
        },
      ),
    );
  }
}

class ListRoute extends StatefulWidget {
  static const String routeName = "/folder";
  @override
  _ListRouteState createState() => new _ListRouteState();
}

class _ListRouteState extends State<ListRoute> with WidgetsBindingObserver {
  final key = new GlobalKey<PasswordListState>();
  TextEditingController controller = new TextEditingController();
  FocusNode _focusNode;
  bool _authorizedBiometric;

  @override
  void initState() {
    super.initState();
    _focusNode = new FocusNode();
    WidgetsBinding.instance.addObserver(this);
    appLock();
    //This block of code will execute after 1 sec of app launch
    Future.delayed(Duration(seconds: 1), () {
      showWelcome();
    });
  }

  @override
  void dispose() {
    super.dispose();
    _focusNode.dispose();
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  Widget build(BuildContext context) {
    DateTime currentBackPressTime;
    final passwords = Provider.of<Passwords>(context);
    final _title =
        (passwords.path == null || passwords.path.endsWith(gitFolderName))
            ? appName
            : passwords.path.split('/').last;

    return WillPopScope(
      onWillPop: () {
        if (controller.text.isNotEmpty) {
          controller.clear();
          onSearchTextChanged('');
          FocusScope.of(context).unfocus();
          return Future.value(false);
        }

        if (!passwords.path.endsWith(gitFolderName)) {
          passwords.path = Directory(passwords.path).parent.path;
          passwords.reloadPasswords();
          return Future.value(false);
        } else {
          DateTime now = DateTime.now();
          if (currentBackPressTime == null ||
              now.difference(currentBackPressTime) > Duration(seconds: 3)) {
            currentBackPressTime = now;
            return Future.value(false);
          }
          return Future.value(true);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_title),
          actions: <Widget>[
            //  Show icon just on debug mode
            !passwords.debugMode
                ? Container()
                : IconButton(
                    icon: Icon(Icons.whatshot),
                    tooltip: 'Debug mode',
                    onPressed: () async {
                      //currentTheme.toggleTheme();
                      if (testGitUrl!="") {
                        await passwords.setTestSettings();
                        await passwords.loadSettings();
                        await passwords.cloneGit();
                        passwords.reloadPasswords();
                      }
                    },
                  ),
            PopupMenuButton(
              icon: Icon(Icons.more_vert),
              onSelected: (selectedValue) async {
                if (selectedValue == "Settings") {
                  _openSettings();
                } else if (selectedValue == "Sync") {
                  key.currentState.callRefresh();
                } else if (selectedValue == "Debug") {
                  //passwords.getDirectoriesList();
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry>[
                PopupMenuItem(
                  value: 'Sync',
                  child: ListTile(
                    leading: Icon(Icons.sync_alt_rounded,
                        color: Theme.of(context).colorScheme.secondary),
                    title: Text('Sync'),
                  ),
                ),
                PopupMenuItem(
                  value: 'Settings',
                  child: ListTile(
                    leading: Icon(Icons.settings,
                        color: Theme.of(context).colorScheme.secondary),
                    title: Text('Settings'),
                  ),
                ),
                if (!kReleaseMode)
                  PopupMenuItem(
                    value: 'Debug',
                    child: ListTile(
                      leading: Icon(Icons.whatshot_rounded,
                          color: Theme.of(context).colorScheme.secondary),
                      title: Text('Debug'),
                    ),
                  ),
              ],
            ),
          ],
        ),
        body: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
              child: ListTile(
                dense: true,
                title: TextField(
                    focusNode: _focusNode,
                    controller: controller,
                    enableSuggestions: false,
                    keyboardType: TextInputType.text,
                    decoration: InputDecoration(
                        prefixIcon: Icon(Icons.search,
                            color: Theme.of(context).hintColor),
                        hintText: 'Search',
                        border: InputBorder.none),
                    onChanged: onSearchTextChanged),
                trailing: _focusNode.hasFocus
                    ? IconButton(
                        icon: Icon(Icons.cancel,
                            color: Theme.of(context).hintColor),
                        onPressed: () {
                          controller.clear();
                          onSearchTextChanged('');
                          FocusScope.of(context).unfocus();
                        },
                      )
                    : null,
              ),
            ),
            Expanded(child: PasswordList(key: key))
          ],
        ),
        floatingActionButton: passwords.gitInitialized
            ? Builder(builder: (BuildContext context) {
                return FloatingActionButton(
                  mini: false,
                  onPressed: () {
                    //showFancyCustomDialog(context);
                    _addPassword();
                  },
                  tooltip: 'Add',
                  child: Icon(Icons.add),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(16.0))),
                );
              })
            : null,
      ),
    );
  }

  onSearchTextChanged(String text) async {
    final passwords = Provider.of<Passwords>(context, listen: false);

    passwords.recursive = text.isEmpty ? !passwords.showFolders : true;
    passwords.searchFilter = text;
    passwords.reloadPasswords();
    //setState(() {});
  }

  Future<void> _addPassword() async {
    final result = await Navigator.pushNamed(context, AddPassRoute.routeName);
    if (verboseSnack) {
      ScaffoldMessenger.of(context)
        ..removeCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(result.toString())));
    }
  }

  Future<void> _openSettings() async {
    await Navigator.pushNamed(context, SettingsRoute.routeName);
    //await passwords.loadSettings();
    //await passwords.cloneGit();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final passwords = Provider.of<Passwords>(context, listen: false);

    print('state = $state @ ' + DateTime.now().toString());

    if (state == AppLifecycleState.inactive) {
      passwords.pausedDate = DateTime.now();
    }

    if (state == AppLifecycleState.resumed) {
      print('minutesAway = ' +
          DateTime.now().difference(passwords.pausedDate).inMinutes.toString());
      if ((DateTime.now().difference(passwords.pausedDate).inMinutes >=
              appLockTimeout) ||
          !_authorizedBiometric) {
        appLock();
      }
    }
  }

  void appLock() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool securityBiometric = prefs.getBool('security_biometric') ?? false;
    if (securityBiometric) {
      final result =
          await Navigator.pushNamed(context, LockScreenRoute.routeName);
      _authorizedBiometric = result;
      if (!_authorizedBiometric)
        SystemChannels.platform.invokeMethod('SystemNavigator.pop');
    } else {
      _authorizedBiometric = true;
    }
  }


  void showWelcome() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('git_url')) {
      Navigator.pushNamed(context, WelcomeRoute.routeName);
    }
  }
}
