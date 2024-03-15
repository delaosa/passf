import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../providers/passf_provider.dart';
import '../widgets/dialogs.dart';
import 'package:file_picker/file_picker.dart';


enum MenuItems { generateKeys }

final GlobalKey<State> _keyLoader = new GlobalKey<State>();

class SetGpgRoute extends StatefulWidget {
  static const String routeName = "/setgpg";
  SetGpgRoute({
    Key key,
  }) : super(key: key);
  @override
  SetGpgRouteState createState() => SetGpgRouteState();
}

class SetGpgRouteState extends State<SetGpgRoute> {
  final _formKey = GlobalKey<FormState>();
  final _tecGpgPassphrase = TextEditingController();
  final _tecPrivate = TextEditingController();
  final _tecPublic = TextEditingController();
  SharedPreferences prefs;
  final secureStorage = new FlutterSecureStorage();
  String _privateKey = "";
  String _publicKey = "";
  String _gpgPassphrase = "";
  bool _gpgSavePassphrase = false;
  bool _askDialogs = true;
  bool _altered = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  _loadSettings() async {
    _tecGpgPassphrase.text = await secureStorage.read(key: 'gpg_passphrase');
    _tecPrivate.text = await secureStorage.read(key: 'gpg_privatekey');
    _tecPublic.text = await secureStorage.read(key: 'gpg_publickey');
    SharedPreferences.getInstance().then((SharedPreferences content) {
      prefs = content;
      _gpgSavePassphrase = prefs.getBool('gpg_savepassphrase') ?? false;
      _askDialogs = prefs.getBool('advanced_askdialogs') ?? true;
      setState(() {});
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
          title: Text('PGP Keys'),
          actions: <Widget>[
            IconButton(
                icon: const Icon(Icons.save),
                tooltip: 'Save',
                onPressed: () async {
                  if (await _validateAndSaveForm()) {
                    passwords.loadSettings();
                    Navigator.of(context).pop(context);
                  }
                }),
            PopupMenuButton<MenuItems>(
              onSelected: (MenuItems result) {
                if (result == MenuItems.generateKeys) {
                  setState(() {
                    _altered = true;
                  });
                  _generateKeys();
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
            child: Column(
              children: <Widget>[
                SizedBox(height: 24.0),
                SwitchListTile(
                  title: Text('Save PGP Passphrase'),
                  value: _gpgSavePassphrase,
                  onChanged: (bool value) {
                    setState(() {
                      _gpgSavePassphrase = value;
                      _altered = true;
                    });
                  },
                  secondary: Icon(Icons.lock_outline,
                      color: Theme.of(context).colorScheme.secondary),
                ),
                _gpgSavePassphrase
                    ? PasswordField(
                        controller: _tecGpgPassphrase,
                        helperText: 'Type passphrase',
                        labelText: 'Passphrase',
                        onSaved: (String value) {
                          _gpgPassphrase = value;
                        },
                        onChanged: (text) {
                          setState(() {
                            _altered = true;
                          });
                        },
                        validator: (value) {
                          if (value.isEmpty) return 'Passphrase is required';
                          return null;
                        },
                      )
                    : SizedBox(height: 2.0),
                SizedBox(height: 24.0),
                TextFormField(
                  readOnly:true,
                  obscureText: true,
                  obscuringCharacter: "*",
                  maxLines: 1,
                  minLines: 1,
                  controller: _tecPrivate,
                  autocorrect: false,
                  enableSuggestions: false,
                  textInputAction: TextInputAction.none,
                  autofocus: false,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Private key in ASCII-Armor format',
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
                    } else if (value.contains('PGP PRIVATE KEY')) {
                      return null;
                    }else {
                      return 'Private key must begin with -----BEGIN PGP PRIVATE KEY BLOCK-----';
                    }
                  },
                ),
                Row(mainAxisAlignment: MainAxisAlignment.end, children: <
                    Widget>[
                  IconButton(
                    icon: Icon(Icons.input,
                        color: Theme.of(context).colorScheme.secondary),
                    tooltip: 'Load from file',
                    onPressed: () async {
                      _tecPrivate.text = await _loadFile() ?? _tecPrivate.text;
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
                        final passphrase = passwords.debugMode ?  "debugging" : passwords.generatePassword(true, true, true, true, 20 );
                        final dialogResult = await confirmDialog(context, "Write down this code to decrypt exported file: \n\n" + passphrase);
                        if (dialogResult) {
                          final result = await passwords.exportKeyToFile(true,passphrase,"pgp_private",_tecPrivate.text);
                          final message = result ? "Private Key exported" : "Error exporting private Key";
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
                  readOnly:true,
                  maxLines: 12,
                  minLines: 12,
                  controller: _tecPublic,
                  autofocus: false,
                  autocorrect: false,
                  enableSuggestions: false,
                  textInputAction: TextInputAction.none,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Public key in ASCII-Armor format',
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
                    } else if (value.contains('PGP PUBLIC KEY')) {
                      return null;
                    }else {
                      return 'Public key must begin with -----BEGIN PGP PUBLIC KEY BLOCK-----';
                    }
                  },
                ),
                Row(mainAxisAlignment: MainAxisAlignment.end, children: <
                    Widget>[
                  IconButton(
                    icon: Icon(Icons.input,
                        color: Theme.of(context).colorScheme.secondary),
                    tooltip: 'Load from file',
                    onPressed: () async {
                      _tecPublic.text = await _loadFile() ?? _tecPublic.text;
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
                        final result = await passwords.exportKeyToFile(false,"","pgp_public",_tecPublic.text);
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<String> _loadFile() async {
    String key, content;

    final passwords = Provider.of<Passwords>(context, listen: false);

    FilePickerResult result = await FilePicker.platform.pickFiles();

    if(result != null) {

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

  void _generateKeys() async {
    final passwords = Provider.of<Passwords>(context, listen: false);
    final passphrase = passwords.generatePassword(true, true, true, true, 20);
    WaitDialog.showLoadingDialog(context, _keyLoader);
    final result = await passwords.generateGpgKeys(passphrase);
    Navigator.of(_keyLoader.currentContext, rootNavigator: true).pop();

    if (result != null) {
      _altered = true;
      setState(() {
        _tecGpgPassphrase.text = passphrase;
        _tecPrivate.text = result.privateKey;
        _tecPublic.text = result.publicKey;
        _gpgSavePassphrase = true;
      });
      ScaffoldMessenger.of(context)
        ..removeCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('Keys successfully generated')));
    } else {
      ScaffoldMessenger.of(context)
        ..removeCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('Failed to generate keys')));
    }
  }

  Future<bool> _validateAndSaveForm() async {
    // Validate returns true if the form is valid, or false
    // otherwise.
    if (_formKey.currentState.validate()) {
      _formKey.currentState.save();
      prefs.setBool('gpg_savepassphrase', _gpgSavePassphrase);
      await secureStorage.write(
          key: 'gpg_passphrase', value: _gpgPassphrase.trim());
      await secureStorage.write(
          key: 'gpg_privatekey', value: _privateKey.trim());
      await secureStorage.write(key: 'gpg_publickey', value: _publicKey.trim());
      return true;
    }
    return false;
  }
}

class PasswordField extends StatefulWidget {
  const PasswordField({
    this.fieldKey,
    this.hintText,
    this.labelText,
    this.helperText,
    this.onSaved,
    this.validator,
    this.onFieldSubmitted,
    this.controller,
    this.readOnly,
    this.focusNode,
    this.onChanged,
    this.onEditingComplete,
  });

  final Key fieldKey;
  final String hintText;
  final String labelText;
  final String helperText;
  final FormFieldSetter<String> onSaved;
  final FormFieldValidator<String> validator;
  final ValueChanged<String> onFieldSubmitted;
  final TextEditingController controller;
  final bool readOnly;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onEditingComplete;

  @override
  _PasswordFieldState createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      focusNode: widget.focusNode,
      enableSuggestions: false,
      keyboardType: TextInputType.visiblePassword,
      controller: widget.controller,
      obscureText: _obscureText,
      enableInteractiveSelection: true,
      onSaved: widget.onSaved,
      onChanged: widget.onChanged,
      validator: widget.validator,
      decoration: InputDecoration(
        border: OutlineInputBorder(),
        //border: const UnderlineInputBorder(),
        filled: false,
        hintText: widget.hintText,
        labelText: widget.labelText,
        //helperText: widget.helperText,
        suffixIcon: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween, // added line
          mainAxisSize: MainAxisSize.min, // added line
          children: <Widget>[
            IconButton(
              icon:
                  Icon(_obscureText ? Icons.visibility : Icons.visibility_off, color: Theme.of(context).colorScheme.secondary),
              onPressed: () {
                setState(() {
                  _obscureText = !_obscureText;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
