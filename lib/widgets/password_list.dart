import 'dart:async';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../routes/editpass_route.dart';
import '../routes/viewpass_route.dart';
import '../providers/passf_provider.dart';
import '../constants.dart';
import '../widgets/dialogs.dart';

class PasswordList extends StatefulWidget {
  PasswordList({
    Key key
  }) : super(key: key);
  @override
  PasswordListState createState() => PasswordListState();
}

class PasswordListState extends State<PasswordList> {
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = new GlobalKey<RefreshIndicatorState>();
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final passwords = Provider.of<Passwords>(context);
    //final searchFilter = passwords.searchFilter ?? '';

    return (passwords.reloading)
//  return ( passwords.items.length >= 0  || passwords.searchFilter.isNotEmpty || passwords.path != passwords.gitPath )
        ? Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            key: _refreshIndicatorKey,
            child: ListView.builder(
                padding: EdgeInsets.only(left: 8, right: 8),
                itemCount: passwords.items.length,
                itemBuilder: (context, index) {
                  return Column(children: <Widget>[
                    (passwords.items[index].type == 'File' ||
                            passwords.items[index].meta == '0')
                        ? Dismissible(
                            key: UniqueKey(),
                            confirmDismiss: (DismissDirection direction) async {
                              if (direction == DismissDirection.endToStart) {
                                // dismissed to the left
                                return await _deletePassword(context, index);
                              } else {
                                if (direction == DismissDirection.startToEnd) {
                                  // dismissed to the right
                                  _editPassword(context, index);
                                  return false;
                                }
                              }
                              return false;
                            },
                            background: Container(
                                alignment: AlignmentDirectional.centerStart,
                                color: Theme.of(context).colorScheme.secondary,
                                child: Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(20, 0, 0, 0),
                                  child: Icon(Icons.edit,
                                      color: Theme.of(context).cardColor),
                                )),
                            child: PasswordTile(index: index),
                            secondaryBackground: Container(
                                alignment: AlignmentDirectional.centerEnd,
                                color: Colors.red,
                                child: Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(0, 0, 20, 0),
                                  child:
                                      Icon(Icons.delete, color: Colors.white),
                                )),
                          )
                        : PasswordTile(index: index),
                    const Divider(
                      height: 0,
                      thickness: 0,
                      indent: 10,
                      endIndent: 10,
                    ),
                  ]);
                }),
            onRefresh: _syncRemote,
          );
  }

  Future<void> callRefresh() async {
    _refreshIndicatorKey.currentState.show();
  }

  Future<void> _syncRemote() async {
    final response=await Provider.of<Passwords>(context, listen: false).syncPasswords();
    final message = response ? 'Successfully synced' : 'Sync failed';
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
    setState(() {});
    //return response;
  }
}

class PasswordTile extends StatelessWidget {
  const PasswordTile({
    Key key,
    @required this.index,
  }) : super(key: key);
  final int index;

  @override
  Widget build(BuildContext context) {
    final passwords = Provider.of<Passwords>(context, listen: false);

    return ListTile(
      title: Text(passwords.items[index].name),
      subtitle: (passwords.recursive &&
              File(passwords.items[index].path).parent.path !=
                  passwords.gitPath)
          ? Text(File(passwords.items[index].path)
              .parent
              .path
              .substring(passwords.gitPath.length + 1))
          : null,
      leading: passwords.items[index].type == 'File'
          ? Icon(Icons.lock_outline, color: Theme.of(context).colorScheme.secondary)
          : Icon(Icons.folder_open, color: Theme.of(context).colorScheme.secondary),
      trailing: passwords.items[index].type == 'File'
          ? IconButton(
              icon: Icon(Icons.content_copy,
                  color: Theme.of(context).colorScheme.secondary),
              onPressed: () async {
                _copyPassword(context, index);
              },
            )
          //: Chip(avatar: CircleAvatar(child: Text('2') ),label: Text('2'),),
          : CircleAvatar(
              backgroundColor: Theme.of(context).canvasColor,
              child: Text(passwords.items[index].meta)),
      onTap: () async {
        if (passwords.items[index].type == 'File') {
          _viewPassword(context, index);
        } else {
          //Directory
          passwords.path = passwords.items[index].path;
          passwords.reloadPasswords();
          //Navigator.pushNamed(context, ListRoute.routeName, arguments: index);
        }
      },
      onLongPress: () {
        if (passwords.items[index].type == 'File') {
          Clipboard.setData(
              new ClipboardData(text: passwords.items[index].name));
         ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Name copied to clipboard')));
        }
      },
    );
  }
}

Future<bool> _deletePassword(BuildContext context, int index) async {
  final passwords = Provider.of<Passwords>(context, listen: false);
  final _name = passwords.items[index].name;

  SharedPreferences prefs = await SharedPreferences.getInstance();
  final _askDialogs = prefs.getBool('advanced_askdialogs') ?? true;

  if (!_askDialogs || await confirmDialog(context, 'Delete $_name?')) {
    if (passwords.items[index].type == "File") {
      //await passwords.createSnapshot(index);
      final result = await passwords.removePassword(index);
      if (result) {
       ScaffoldMessenger.of(context)
          ..removeCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content: Text("$_name deleted"),
            duration: Duration(seconds: 5),
            action: SnackBarAction(
                label: "Undo",
                //textColor: Theme.of(context).indicatorColor,
                textColor: Theme.of(context).colorScheme.primary,
                onPressed: () {
                  passwords.undoLast();
                  //passwords.restoreSnapshot();
                }),
          ));
        return true;
      } else {
       ScaffoldMessenger.of(context)
          ..removeCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content: Text("Failed to delete $_name"),
            duration: Duration(seconds: 2),
          ));
        return false;
      }
    } else {
      final result = await passwords.removeDirectory(index);
      if (result) {
       ScaffoldMessenger.of(context)
          ..removeCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content: Text("Folder $_name deleted"),
            duration: Duration(seconds: 2),
          ));
        return true;
      } else {
       ScaffoldMessenger.of(context)
          ..removeCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content: Text("Failed to delete folder $_name"),
            duration: Duration(seconds: 2),
          ));
        return false;
      }
    }
  } else {
    return false;
  }
}

// Check we're able to decode
Future<bool> _prePassword(BuildContext context, int index) async {
  final passwords = Provider.of<Passwords>(context, listen: false);
  String _pass;

  _pass = await passwords.readPassword(index);

  //In case passphrase is wrong ask for it once
  if (_pass == "###WK###") {
    ScaffoldMessenger.of(context)
      ..removeCurrentSnackBar();
    passwords.gpgPassphrase = await askPassphraseDialog(context) ?? '';
    _pass = await passwords.readPassword(index);
  }

  if (_pass == null || _pass == "###WK###" ) {
   ScaffoldMessenger.of(context)
      ..removeCurrentSnackBar()
      ..showSnackBar(SnackBar(
          duration: Duration(seconds: 2),
          content: Text('Error decrypting password file')));
    return false;
  }

  return true;
}

Future<void> _editPassword(BuildContext context, int index) async {
  //if (await _prePassword(context, index)) {
    final result = await Navigator.pushNamed(context, EditPassRoute.routeName,
        arguments: index);

    if (verboseSnack)
     ScaffoldMessenger.of(context)
        ..removeCurrentSnackBar()
        ..showSnackBar(SnackBar(
            duration: Duration(seconds: 2), content: Text("$result")));
  //}
}

Future<void> _viewPassword(BuildContext context, int index) async {
  //if (await _prePassword(context, index)) {
    final result = await Navigator.pushNamed(context, ViewPassRoute.routeName,
        arguments: index);

    if (result == 'edit') {
      final result = await Navigator.pushNamed(context, EditPassRoute.routeName,
          arguments: index);

      if (verboseSnack)
       ScaffoldMessenger.of(context)
          ..removeCurrentSnackBar()
          ..showSnackBar(SnackBar(
              duration: Duration(seconds: 2), content: Text("$result")));
    }
  //}
}

Future<void> _copyPassword(BuildContext context, int index) async {
  final passwords = Provider.of<Passwords>(context, listen: false);
  String _pass;

  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      duration: Duration(seconds: 2),
      content: Text('Password copied to clipboard')));

  if (await _prePassword(context, index)) {
    _pass = await passwords.readPassword(index);

    if (_pass == null) {
     ScaffoldMessenger.of(context)
        ..removeCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('Error decrypting')));
    } else {
      _pass = _pass.split('\n')[0];
      Clipboard.setData(new ClipboardData(text: '$_pass'));
      Timer(Duration(seconds: passwords.clipboardTimeout),
          () => Clipboard.setData(ClipboardData(text: '   ')));
    }
  }
}
