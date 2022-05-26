import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../providers/passf_provider.dart';
import '../widgets/dialogs.dart';
import '../constants.dart';


enum MenuItems { generateKeys }

class SetSignatureRoute extends StatefulWidget {
  static const String routeName = "/setsignature";
  SetSignatureRoute({
    Key key,
  }) : super(key: key);
  @override
  SetSignatureRouteState createState() => SetSignatureRouteState();
}

class SetSignatureRouteState extends State<SetSignatureRoute> {
  final _formKey = GlobalKey<FormState>();
  final _tecGitName = TextEditingController();
  final _tecGitEmail = TextEditingController();

  String _gitName, _gitEmail;
  SharedPreferences prefs;
  bool _askDialogs = true;
  bool _altered = false;
  @override
  void initState() {
    super.initState();
    loadSettings();
  }

  loadSettings() async {

    SharedPreferences.getInstance().then((SharedPreferences content) {
      prefs = content;
      _tecGitName.text = prefs.getString('git_commitname');
      _tecGitEmail.text = prefs.getString('git_commitemail');
      _askDialogs = prefs.getBool('advanced_askdialogs') ?? true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final passwords = Provider.of<Passwords>(context);
    return WillPopScope(
      onWillPop: () async {
        //Navigator.pop(context, false);
        if (_altered) {
          if (!_askDialogs || await confirmDialog(context)) {
            Navigator.pop(context, 'Edit canceled');
            return Future.value(true);
          } else {
            return Future.value(false);
          }
        } else {
          Navigator.pop(context, 'Edit canceled');
          return Future.value(true);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: Builder(
            builder: (BuildContext context) {
              return IconButton(
                icon: const Icon(Icons.close),
                onPressed: () async {
                  if (_altered) {
                    if (!_askDialogs || await confirmDialog(context))
                      Navigator.of(context).pop(context);
                  } else {
                    Navigator.of(context).pop(context);
                  }
                },
                tooltip: MaterialLocalizations.of(context).cancelButtonLabel,
              );
            },
          ),
          title: Text('Signature'),
          actions: <Widget>[
            IconButton(
                icon: const Icon(Icons.save),
                onPressed: () async {
                  if (await validateAndSaveForm()) {
                    passwords.loadSettings();
                    Navigator.of(context).pop(context);
                  }
                }),
               ],
        ),
        body: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Form(
            key: _formKey,
            child: Column(children: <Widget>[
              SizedBox(height: 24.0),
              TextFormField(
                controller: _tecGitName,
                autocorrect: false,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  icon: Icon(Icons.person, color: Theme.of(context).colorScheme.secondary),
                  filled: false,
                  labelText: 'Name',
                  hintText: appName,
                ),
                onSaved: (String value) {
                  _gitName = value;
                },
                onChanged: (text) {
                  setState(() {
                    _altered = true;
                  });
                },
                validator: (value) {
                  if (value.isEmpty) return 'Name is required';
                  return null;
                },
              ),
              SizedBox(height: 24.0),
              TextFormField(
                controller: _tecGitEmail,
                autocorrect: false,
                textInputAction: TextInputAction.done,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  icon: Icon(Icons.email, color: Theme.of(context).colorScheme.secondary),
                  filled: false,
                  labelText: 'Email',
                  hintText: authorEMail,
                ),
                onSaved: (String value) {
                  _gitEmail = value;
                },
                onChanged: (text) {
                  setState(() {
                    _altered = true;
                  });
                },
                validator: (value) {
                  if (value.isEmpty) return 'Email is required';
                  return null;
                },
              ),
            ]),
          ),
        ),
      ),
    );
  }


  Future<bool> validateAndSaveForm() async {
    // Validate returns true if the form is valid, or false
    // otherwise.
    if (_formKey.currentState.validate()) {
      _formKey.currentState.save();
      prefs.setString('git_commitname', _gitName.trim());
      prefs.setString('git_commitemail', _gitEmail.trim());
      return true;
    }
    return false;
  }
}
