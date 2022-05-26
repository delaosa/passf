import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as p;
import 'package:git_bindings/git_bindings.dart';
import 'package:path_provider/path_provider.dart';
import '../providers/passf_provider.dart';
import '../widgets/dialogs.dart';
import 'package:file_picker/file_picker.dart';

enum MenuItems { generateKeys }
final GlobalKey<State> _keyLoader = new GlobalKey<State>();

class SetGitRoute extends StatefulWidget {
  static const String routeName = "/setgit";
  SetGitRoute({
    Key key,
  }) : super(key: key);
  @override
  SetGitRouteState createState() => SetGitRouteState();
}

class SetGitRouteState extends State<SetGitRoute> {
  final _formKey = GlobalKey<FormState>();
  final _tecGitUrl = TextEditingController();
  final _tecPrivate = TextEditingController();
  final _tecPublic = TextEditingController();

  bool _isButtonDisabled;
  SharedPreferences prefs;
  final secureStorage = new FlutterSecureStorage();
  String _privateKey = "";
  String _publicKey = "";
  String _gitUrl = "";
  bool _askDialogs = true;
  bool _altered = false;
  bool _dirtyKeys = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  _loadSettings() async {
    _isButtonDisabled = false;
    _tecPrivate.text = await secureStorage.read(key: 'git_privatekey');
    _tecPublic.text = await secureStorage.read(key: 'git_publickey');
    SharedPreferences.getInstance().then((SharedPreferences content) {
      prefs = content;
      _tecGitUrl.text = prefs.getString('git_url');
      _askDialogs = prefs.getBool('advanced_askdialogs') ?? true;
      _privateKey = _tecPrivate.text;
      _publicKey = _tecPublic.text;
    });
  }

  @override
  Widget build(BuildContext context) {
    final passwords = Provider.of<Passwords>(context);
    return WillPopScope(
      onWillPop: () async {
        //
        if (_dirtyKeys) {
          await saveKeys();
        }
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
                  if (_dirtyKeys) saveKeys();
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
          title: Text('Git Repository'),
          actions: <Widget>[
            IconButton(
                icon: const Icon(Icons.save),
                onPressed: () async {
                  if (await validateAndSaveForm()) {
                    passwords.loadSettings();
                    passwords.syncPasswords();
                    Navigator.of(context).pop(context);
                  }
                }),
            PopupMenuButton<MenuItems>(
              onSelected: (MenuItems result) {
                if (result == MenuItems.generateKeys) {
                  generateKeys();
                }
              },
              itemBuilder: (BuildContext context) => [
                const PopupMenuItem(
                  value: MenuItems.generateKeys,
                  child: Text('Generate Keys'),
                ),
              ],
            ),
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
                readOnly: passwords.gitInitialized,
                controller: _tecGitUrl,
                autocorrect: false,
                textInputAction: TextInputAction.done,
                keyboardType: TextInputType.url,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  //icon: Icon(Icons.person),
                  filled: false,
                  labelText: 'Git URL',
                  hintText: 'git@hostname.com:user/repo.git',
                ),
                onSaved: (String value) {
                  _gitUrl = value;
                },
                onChanged: (text) {
                  setState(() {
                    _altered = true;
                  });
                },
                validator: (value) {
                  if (value.isEmpty) return 'Git URL is required';
                  return null;
                },
              ),
              SizedBox(height: 24.0),
              TextFormField(
                readOnly: true,
                obscureText: true,
                obscuringCharacter: "*",
                maxLines: 1,
                minLines: 1,
                controller: _tecPrivate,
                autofocus: false,
                autocorrect: false,
                enableSuggestions: false,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Private key in PEM format',
                  labelText: 'Private Key',
                  filled: false,
                  //helperText: 'Paste Private key in PEM format',
                ),
                //maxLines: 10,
                onSaved: (String value) {
                  _privateKey = value;
                },
                onChanged: (text) {
                  setState(() {
                    _altered = true;
                  });
                },
                validator: (value) {
                  if (value.isEmpty) {
                    return 'Private key is required';
                  } else if (value.contains(RegExp('BEGIN .+ PRIVATE KEY'))) {
                    return null;
                  }else {
                    return 'Private key must begin with -----BEGIN RSA/OPENSSH PRIVATE KEY-----';
                  }
                },
              ),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: <Widget>[
                IconButton(
                  icon: Icon(Icons.input,
                      color: Theme.of(context).colorScheme.secondary),
                  tooltip: 'Load from file',
                  onPressed: () async {
                    _tecPrivate.text = await loadFile() ?? _tecPrivate.text;
                  },
                ),
                IconButton(
                  icon: Icon(Icons.content_paste,
                      color: Theme.of(context).colorScheme.secondary),
                  tooltip: 'Paste from clipboard',
                  onPressed: () async {
                    ClipboardData content =
                    await Clipboard.getData('text/plain');
                    _tecPrivate.text = content.text;
                    _altered = true;
                  },
                ),
                IconButton(
                    icon: Icon(Icons.share,
                        color: Theme.of(context).colorScheme.secondary),
                    tooltip: 'Share',
                    onPressed: () async {
                      final passphrase = passwords.debugMode ?  "debugging" : passwords.generatePassword(true, true, true, true, 20);
                      final dialogResult = await confirmDialog(
                          context,
                          "Write down this code to decrypt exported file: \n\n" +
                              passphrase);
                      if (dialogResult) {
                        final result = await passwords.exportKeyToFile(
                            true, passphrase, "ssh_private", _tecPrivate.text);
                        final message = result
                            ? "Private Key exported"
                            : "Error exporting private Key";
                        ScaffoldMessenger.of(context)
                          ..removeCurrentSnackBar()
                          ..showSnackBar(SnackBar(
                              duration: Duration(seconds: 5),
                              content: Text(message)));
                      }
                    }),
              ]),
              SizedBox(height: 12.0),
              TextFormField(
                readOnly: true,
                maxLines: 12,
                minLines: 12,
                controller: _tecPublic,
                autofocus: false,
                autocorrect: false,
                enableSuggestions: false,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Public key in PEM format',
                  labelText: 'Public Key',
                  filled: false,
                  //helperText: 'Paste public key in PEM format',
                ),
                //maxLines: 10,
                onSaved: (String value) {
                  _publicKey = value;
                },
                onChanged: (text) {
                  setState(() {
                    _altered = true;
                  });
                },
                validator: (value) {
                  if (value.isEmpty) {
                    return 'Public key is required';
                  } else if (value.contains('ssh-')) {
                    return null;
                  }else {
                    return 'Public key must begin with ssh-';
                  }
                },
              ),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: <Widget>[
                IconButton(
                  icon: Icon(Icons.input,
                      color: Theme.of(context).colorScheme.secondary),
                  tooltip: 'Load from file',
                  onPressed: () async {
                    _tecPublic.text = await loadFile() ?? _tecPublic.text;
                  },
                ),
                IconButton(
                  icon: Icon(Icons.content_paste,
                      color: Theme.of(context).colorScheme.secondary),
                  tooltip: 'Paste from clipboard',
                  onPressed: () async {
                    ClipboardData content =
                        await Clipboard.getData('text/plain');
                    _tecPublic.text = content.text;
                    _altered = true;
                  },
                ),
                IconButton(
                  icon: Icon(Icons.content_copy,
                      color: Theme.of(context).colorScheme.secondary),
                  tooltip: 'Copy to clipboard',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _tecPublic.text));
                    ScaffoldMessenger.of(context)
                      ..removeCurrentSnackBar()
                      ..showSnackBar(SnackBar(
                          duration: Duration(seconds: 2),
                          content: Text('Public Key copied to clipboard')));
                  },
                ),
                IconButton(
                    icon: Icon(Icons.share,
                        color: Theme.of(context).colorScheme.secondary),
                    tooltip: 'Share',
                    onPressed: () async {
                      final result = await passwords.exportKeyToFile(
                          false, "", "ssh_public", _tecPublic.text);
                      final message = result
                          ? "Public Key exported"
                          : "Error exporting public Key";
                      ScaffoldMessenger.of(context)
                        ..removeCurrentSnackBar()
                        ..showSnackBar(SnackBar(
                            duration: Duration(seconds: 5),
                            content: Text(message)));
                    }),
              ]),
              SizedBox(height: 12.0),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: <Widget>[
                OutlinedButton(
                  child: Text(
                      _isButtonDisabled ? 'Please wait' : 'Test credentials'),
                  onPressed: _isButtonDisabled ? null : testGit,
                ),
              ]),
            ]),
          ),
        ),
      ),
    );
  }

  Future<String> loadFile() async {
    String key, content;

    final passwords = Provider.of<Passwords>(context, listen: false);
    FilePickerResult result = await FilePicker.platform.pickFiles();

    if (result != null) {
      File file = File(result.files.single.path);

      try {
        content = file.readAsStringSync();
      } catch (e) {
        print('ERROR: $e');
        ScaffoldMessenger.of(context)
          ..removeCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text('Failed to import key')));
        FilePicker.platform.clearTemporaryFiles();
        return null;
      }

      if (content.contains('BEGIN PGP MESSAGE')) {
        final passphrase = await askPassphraseDialog(context) ?? '';
        key = await passwords.decryptSymmetricFile(file, passphrase);
        FilePicker.platform.clearTemporaryFiles();
      } else {
        key = content;
      }

      if (key != null) {
        ScaffoldMessenger.of(context)
          ..removeCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text('Key imported')));
        _altered = true;
        return key;
      } else {
        ScaffoldMessenger.of(context)
          ..removeCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text('Failed to import key')));
        return null;
      }
    }
    return null;
  }

  void generateKeys() async {
    final passwords = Provider.of<Passwords>(context, listen: false);
    _dirtyKeys = true;
    _altered = true;
    WaitDialog.showLoadingDialog(context, _keyLoader);
    final result = await passwords.generateGitKeys();
    Navigator.of(_keyLoader.currentContext, rootNavigator: true).pop();

    if (result != null) {
      _tecPrivate.text = await passwords.getGitPrivateKey();
      _tecPublic.text = result;
      ScaffoldMessenger.of(context)
        ..removeCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('Keys generated')));
    } else {
      ScaffoldMessenger.of(context)
        ..removeCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('Failed to generate keys')));
    }
  }

  Future<bool> validateAndSaveForm() async {
    // Validate returns true if the form is valid, or false
    // otherwise.
    if (_formKey.currentState.validate()) {
      _formKey.currentState.save();
      prefs.setString('git_url', _gitUrl.trim());
      await secureStorage.write(
          key: 'git_privatekey', value: _privateKey.trim());
      await secureStorage.write(key: 'git_publickey', value: _publicKey.trim());
      _dirtyKeys = false;
      await saveKeys();

      return true;
    }
    return false;
  }

  Future<void> saveKeys() async {
    if (_privateKey.isNotEmpty && _publicKey.isNotEmpty) {
      final passwords = Provider.of<Passwords>(context, listen: false);
      await passwords.saveGitKeys(_privateKey.trim(), _publicKey.trim());
    }
  }

  void testGit() async {
    final _path = await getApplicationSupportDirectory();
    final _gitPath = p.join(_path.path, "testGit");

    setState(() {
      _isButtonDisabled = true;
    });

    if (await validateAndSaveForm()) {
      await Directory(_gitPath).exists().then((exist) {
        if (exist) Directory(_gitPath).deleteSync(recursive: true);
      });
      GitRepo _gitRepo = GitRepo(folderPath: _gitPath);
      try {
        await GitRepo.clone(_gitRepo.folderPath, _gitUrl.trim());
        setState(() {
          ScaffoldMessenger.of(context)
            ..removeCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text('Credentials are valid')));
        });
      } on GitException {
        setState(() {
          ScaffoldMessenger.of(context)
            ..removeCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text('Invalid credentials')));
        });
      }
      Directory(_gitPath).exists().then((exist) {
        if (exist) Directory(_gitPath).deleteSync(recursive: true);
      });
    }
    setState(() {
      _isButtonDisabled = false;
    });
  }
}
