import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../models/passf_model.dart';
import '../providers/passf_provider.dart';
import '../constants.dart';
import '../widgets/dialogs.dart';

class PasswordForm extends StatefulWidget {
  PasswordForm({
    Key key,
    this.index,
    this.readOnly: true,
  }) : super(key: key);
  final int index;
  final bool readOnly;

  @override
  PasswordFormState createState() => PasswordFormState();
}

class PasswordFormState extends State<PasswordForm> {
  final _formKey = GlobalKey<FormState>();
  final _tecName = TextEditingController();
  final _tecPass = TextEditingController();
  final _tecExtra = TextEditingController();
  final _tecLastModified = TextEditingController();
  final _tecFilePath = TextEditingController();
  final String defaultLocale = Platform.localeName;

  FocusNode _passwordFocusNode;
  FocusNode _extraFieldsFocusNode;

  String name;
  String _password;
  String _extraFields;
  String _id;
  bool altered = false;
  var hiddenCounter = 0;
  DateFormat timeFormat;
  List<String> _kOptions = <String>[];

  @override
  void initState() {
    super.initState();
    _passwordFocusNode = FocusNode();
    _extraFieldsFocusNode = FocusNode();
    _tecPass.addListener(() {
      altered = true;
    });
    initializeDateFormatting(defaultLocale).then((_) {
      timeFormat = DateFormat.yMd(defaultLocale).add_jm();
    });
  }

  @override
  void dispose() {
    // Clean up the focus node when the Form is disposed.
    _passwordFocusNode.dispose();
    _extraFieldsFocusNode.dispose();
    _tecLastModified.dispose();
    _tecFilePath.dispose();
    _tecName.dispose();
    _tecPass.dispose();
    _tecExtra.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final index = widget.index;
    final readOnly = widget.readOnly;
    final passwords = Provider.of<Passwords>(context, listen: false);

    //Load and set
    if (index != null) {
      // edit
      _tecName.text = passwords.items[index].path.substring(
          passwords.gitPath.length + 1,
          passwords.items[index].path.length -
              passwordFilesExtension.length -
              1);
      _id = passwords.items[index].id;
      _readPassword(context, index).then((String content) {
        if (content == null) {
          Navigator.pop(context, 'Error decrypting password file');
        } else {
          _tecPass.text = content.split('\n')[0];
          _tecExtra.text =
              content.substring(content.indexOf('\n') + 1).trimRight();
          passwords.getLastModified(index).then((value) => _tecLastModified
              .text = "Last modified: " + timeFormat.format(value));
          passwords
              .getFilePath(index)
              .then((value) => _tecFilePath.text = value);
        }
      });
    } else {
      // add
      _tecName.text = (passwords.path != passwords.gitPath)
          ? passwords.path.substring(passwords.gitPath.length + 1) + "/"
          : '';
    }

    //Load Directories list
    passwords
        .getDirectoriesList()
        .then((value) {
      _kOptions = value;
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Form(
        key: _formKey,
        child: Column(
          children: <Widget>[
            SizedBox(height: 24.0),
            Autocomplete<String>(
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text == '') {
                  return const Iterable<String>.empty();
                }
                return _kOptions.where((String option) {
                  return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                });
              },
              fieldViewBuilder: (
                  BuildContext context,
                  TextEditingController fieldTextEditingController,
                  FocusNode fieldFocusNode,
                  VoidCallback onFieldSubmitted
                  ) {
                return TextFormField(
                  controller: _tecName.text.isNotEmpty?_tecName:fieldTextEditingController,
                  focusNode: fieldFocusNode,
                  enableSuggestions: false,
                  //onTap: () => _tecName.selection = TextSelection(baseOffset: 0, extentOffset: _tecName.value.text.length),
                  textInputAction: TextInputAction.next,
                  //autofocus: (index == null) ? true : false,
                  readOnly: readOnly,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    filled: false,
                    labelText: 'Name',
                    hintText: 'DIRECTORY/name',
                    //helperText: _tecName.text.isEmpty ? 'e.g., work/git' : '',
                    suffixIcon: widget.readOnly
                        ? IconButton(
                      tooltip: 'Copy to clipboard',
                      icon: Icon(Icons.content_copy,
                          color: Theme.of(context).colorScheme.secondary),
                      onPressed: () {
                        Clipboard.setData(
                            new ClipboardData(text: _tecName.text));
                        ScaffoldMessenger.of(context)
                          ..removeCurrentSnackBar()
                          ..showSnackBar(SnackBar(
                              duration: Duration(seconds: 2),
                              content: Text('Name copied to clipboard')));
                      },
                    )
                        : null,
                  ),
                  onSaved: (String value) {
                    name = value;
                  },
                  onChanged: (text) {
                    altered = true;
                  },
                  validator: (value) {
                    if (value.isEmpty) return 'Name is required.';
                    //final RegExp reservedChars = RegExp(r'^[|\\?*<\":>+[]/]+$');
                    final RegExp nameExp = RegExp(r'^[0-9A-zÀ-ú_\-.@/ ]+(?<!/)$');
                    if (!nameExp.hasMatch(value))
                      return 'Only [0-9A-zÀ-ú_\-.@/ ] characters are allowed';
                    return null;
                  },
                  onEditingComplete: () => _passwordFocusNode.requestFocus(),
                );
              },
              onSelected: (String selection) {
                debugPrint('You just selected $selection');
              },
            ),
            SizedBox(height: 24.0),
            PasswordField(
              controller: _tecPass,
              readOnly: readOnly,
              helperText: 'Type password',
              labelText: 'Password',
              onSaved: (String value) {
                _password = value;
              },
              onChanged: (text) {
                altered = true;
              },
              onEditingComplete: () {
                _passwordFocusNode.unfocus();
              },
              focusNode: _passwordFocusNode,
            ),
            SizedBox(height: 24.0),
            TextFormField(
              controller: _tecExtra,
              focusNode: _extraFieldsFocusNode,
              textInputAction: TextInputAction.none,
              autocorrect: false,
              enableSuggestions: false,
              readOnly: readOnly,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'key:vault',
                labelText: 'Additional fields',
                //helperText: 'Additional fields',
              ),
              maxLines: 12,
              onSaved: (String value) {
                _extraFields = value;
              },
            ),
            (hiddenCounter >= 3)
                ? TextFormField(
                    controller: _tecLastModified,
                    readOnly: true,
                    enableInteractiveSelection: false,
                    textInputAction: TextInputAction.none,
                    autocorrect: false,
                    enableSuggestions: false,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    decoration: InputDecoration(
                      isCollapsed: true,
                      border: InputBorder.none,
                    ),
                  )
                : Container(),
            (hiddenCounter >= 5)
                ? TextFormField(
                    controller: _tecFilePath,
                    readOnly: true,
                    enableInteractiveSelection: false,
                    textInputAction: TextInputAction.none,
                    autocorrect: false,
                    enableSuggestions: false,
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    decoration: InputDecoration(
                      isCollapsed: true,
                      border: InputBorder.none,
                    ),
                  )
                : Container(),
            GestureDetector(
              onTap: () {
                setState(() {
                  hiddenCounter++;
                });
              },
              // The custom button
              child: Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                    //color: Colors.lightBlue,
                    //borderRadius: BorderRadius.circular(8.0),
                    ),
                child: const SizedBox(width: double.infinity, height: 8),
              ),
            ),
            //Text((index != null ) ? passwords.items[index].meta : ''),
          ],
        ),
      ),
    );
  }

  Future<bool> validateAndSaveForm(BuildContext context) async {
    final index = widget.index;
    final passwords = Provider.of<Passwords>(context, listen: false);

    // Validate returns true if the form is valid, or false
    // otherwise.
    if (_formKey.currentState.validate()) {
      _formKey.currentState.save();
      _password = _extraFields.isNotEmpty
          ? _password + '\n' + _extraFields + '\n'
          : _password + '\n';
      await passwords.savePassword(
          index,
          PasswordEntry(name: name.trim(), id: _id),
          _password,
          (index == null) ? 'add' : 'edit');
      return true;
    }
    return false;
  }

  Future<String> _readPassword(BuildContext context, int index) async {
    final passwords = Provider.of<Passwords>(context, listen: false);
    String _pass;

    _pass = await passwords.readPassword(index);

    //In case passphrase is wrong ask for it once
    if (_pass == "###WK###") {
      passwords.gpgPassphrase = await askPassphraseDialog(context) ?? '';
      _pass = await passwords.readPassword(index);
    }

    if (_pass == null || _pass == "###WK###") {
      ScaffoldMessenger.of(context)
        ..removeCurrentSnackBar()
        ..showSnackBar(SnackBar(
            duration: Duration(seconds: 2),
            content: Text('Error decrypting password file')));

      return null;
    }

    return _pass;
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
    final passwords = Provider.of<Passwords>(context, listen: false);
    return TextFormField(
      focusNode: widget.focusNode,
      enableSuggestions: false,
      keyboardType: TextInputType.visiblePassword,
      controller: widget.controller,
      obscureText: _obscureText,
      enableInteractiveSelection: true,
      readOnly: widget.readOnly,
      onSaved: widget.onSaved,
      onChanged: widget.onChanged,
      onEditingComplete: widget.onEditingComplete,
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
            !widget.readOnly
                ? IconButton(
                tooltip: 'Generate password',
                icon: Icon(Icons.autorenew,
                        color: Theme.of(context).colorScheme.secondary),
                    onPressed: widget.readOnly
                        ? null
                        : () {
                            widget.controller.text =
                                Provider.of<Passwords>(context, listen: false)
                                    .generatePassword(
                                        true, true, true, true, 12);
                          })
                : Container(),
            IconButton(
              tooltip: 'Copy to clipboard',
              icon: Icon(Icons.content_copy,
                  color: Theme.of(context).colorScheme.secondary),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: widget.controller.text));
                Timer(Duration(seconds: passwords.clipboardTimeout),
                    () => Clipboard.setData(ClipboardData(text: '   ')));
                ScaffoldMessenger.of(context)
                  ..removeCurrentSnackBar()
                  ..showSnackBar(SnackBar(
                      duration: Duration(seconds: 2),
                      content: Text('Password copied to clipboard')));
              },
            ),
            IconButton(
              tooltip: 'Reveal password',
              icon: Icon(_obscureText ? Icons.visibility : Icons.visibility_off,
                  color: Theme.of(context).colorScheme.secondary),
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
