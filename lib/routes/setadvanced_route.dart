import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/passf_provider.dart';
import '../widgets/dialogs.dart';
import 'setsignature_router.dart';


class SetAdvanced extends StatefulWidget {
  static const String routeName = "/setadvanced";
  SetAdvanced({
    Key key,
  }) : super(key: key);
  @override
  SetAdvancedState createState() => SetAdvancedState();
}

class SetAdvancedState extends State<SetAdvanced> {

  SharedPreferences prefs;
  bool _askDialogs=false;
  bool _askShowFolders=false;
  String _clipboardTimeout='15s';
  String _archiveFilename;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((SharedPreferences content) {
       prefs = content;
      _askDialogs = prefs.getBool('advanced_askdialogs') ?? true;
      _askShowFolders = prefs.getBool('advanced_showfolders') ?? true;
      _clipboardTimeout = prefs.getString('advanced_clipboardtimeout') ?? '15s';
       setState(() {});
    });
  }


  @override
  Widget build(BuildContext context) {
    final passwords = Provider.of<Passwords>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Advanced'),
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Form(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(height: 24.0),
              Text (
                  "Interface",
                  textAlign: TextAlign.left,
                  style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontWeight: FontWeight.bold)
              ),
              SizedBox(height: 12.0),
              SwitchListTile(
                title: Text('Show confirmation dialogs'),
                value: _askDialogs,
                onChanged: (bool value) {
                  setState(() {
                    _askDialogs = value;
                    prefs.setBool('advanced_askdialogs', _askDialogs);
                  });
                },
                secondary: Icon(Icons.question_answer, color: Theme.of(context).colorScheme.secondary),
              ),
              SizedBox(height: 24.0),
              SwitchListTile(
                title: Text('Show folders'),
                value: _askShowFolders,
                onChanged: (bool value) {
                  setState(() {
                    _askShowFolders = value;
                    prefs.setBool('advanced_showfolders', _askShowFolders);
                  });
                  passwords.backToRoot();
                },
                secondary: Icon(Icons.folder, color: Theme.of(context).colorScheme.secondary),
              ),
              Divider(),
              SizedBox(height: 24.0),
              Text (
                  "Security",
                  textAlign: TextAlign.left,
                  style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontWeight: FontWeight.bold)
              ),
            PopupMenuButton<String>(
              onSelected: (String value) {
                setState(() {
                  _clipboardTimeout = value;
                  prefs.setString('advanced_clipboardtimeout', _clipboardTimeout);
                });
              },
              child: ListTile(
                leading: Icon(Icons.timer, color: Theme.of(context).colorScheme.secondary),
                title: Text('Clipboard cleanup timeout'),
                subtitle: Text(_clipboardTimeout),
              ),
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: '15s',
                  child: Text('15s'),
                ),
                const PopupMenuItem<String>(
                  value: '30s',
                  child: Text('30s'),
                ),
                const PopupMenuItem<String>(
                  value: '60s',
                  child: Text('60s'),
                ),
                const PopupMenuItem<String>(
                  value: '120s',
                  child: Text('120s'),
                ),
                const PopupMenuItem<String>(
                  value: '300s',
                  child: Text('300s'),
                ),
              ],
            ),
              Divider(),
              SizedBox(height: 24.0),
              Text (
                  "Repository",
                  textAlign: TextAlign.left,
                  style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontWeight: FontWeight.bold)
              ),
              SizedBox(height: 12.0),
              ListTile(
                title: Text("Signature"),
                //dense: true,
                //subtitle: Text("" , maxLines: 1),
                leading: Icon(Icons.contact_mail, color: Theme.of(context).colorScheme.secondary),
                onTap:  () async {
                  Navigator.pushNamed(context, SetSignatureRoute.routeName);
                },
              ),
              SizedBox(height: 12.0),
              ListTile(
                title: Text("Reset last commit"),
                //dense: true,
                //subtitle: Text("" , maxLines: 1),
                leading: Icon(Icons.undo_rounded, color: Theme.of(context).colorScheme.secondary),
                onTap:  () async {
                  //FilePickerResult result = await FilePicker.platform.pickFiles();
                  passwords.undoLast();
                  ScaffoldMessenger.of(context)
                    ..removeCurrentSnackBar()
                    ..showSnackBar(SnackBar(content: Text("Reset done")));
                },
              ),
              SizedBox(height: 12.0),
              ListTile(
                title: Text("Export passwords"),
                //dense: true,
                //subtitle: Text("" , maxLines: 1),
                leading: Icon(Icons.archive_rounded, color: Theme.of(context).colorScheme.secondary),
                onTap:  () async {
                  //FilePickerResult result = await FilePicker.platform.pickFiles();
                  final result = await passwords.archivePasswords();
                  final message = result ? "Passwords repository exported": "Error exporting passwords repository";
                  ScaffoldMessenger.of(context)
                    ..removeCurrentSnackBar()
                    ..showSnackBar(SnackBar(content: Text(message)));
                  //if (_archiveFilename != null ) print ("archiveFilename: " + _archiveFilename);
                },
              ),
              SizedBox(height: 12.0),
              ListTile(
                title: Text("Remove local repository"),
                //dense: true,
                //subtitle: Text("" , maxLines: 1),
                leading: Icon(Icons.warning, color: Theme.of(context).colorScheme.secondary),
                onTap:  () async {
                  if (await confirmDialog(context, 'Do you want to remove local repository?\n\nLocal files will be removed.')) {
                    await passwords.discardLocal();
                    await passwords.loadSettings();
                    ScaffoldMessenger.of(context)
                      ..removeCurrentSnackBar()
                      ..showSnackBar(SnackBar(content: Text("Local repository deleted")));
                  }
                  },
              ),
            ],
          ),
        ),
      ),
    );
  }

}


