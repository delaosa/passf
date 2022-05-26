import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/password_form.dart';
import '../widgets/dialogs.dart';

final key = new GlobalKey<PasswordFormState>();

class EditPassRoute extends StatelessWidget {
  static const String routeName = "/editentry";
  static const String title = "Edit entry";

  @override
  Widget build(BuildContext context) {

    final int index = ModalRoute.of(context).settings.arguments;
    bool _askDialogs=true;

    SharedPreferences.getInstance().then((SharedPreferences content) {
      final prefs = content;
      _askDialogs = prefs.getBool('advanced_askdialogs');
    });


    return WillPopScope(
      onWillPop: () async {
        //Navigator.pop(context, false);
        if (key.currentState.altered) {
          if ( !_askDialogs || await confirmDialog(context))
            Navigator.pop(context, 'Edit canceled');
        } else {
          Navigator.pop(context, 'Edit canceled');
        }
        return Future.value(true);
      },
      child: Scaffold(
        appBar: AppBar(
          leading: Builder(
            builder: (BuildContext context) {
              return IconButton(
                icon: const Icon(Icons.close),
                onPressed: () async {
                  if (key.currentState.altered) {
                    if ( !_askDialogs || await confirmDialog(context))
                      Navigator.pop(context, 'Edit canceled');
                  } else {
                    Navigator.pop(context, 'Edit canceled');
                  }
                },
                tooltip: MaterialLocalizations.of(context).cancelButtonLabel,
              );
            },
          ),
          title: Text(title),
          actions: <Widget>[
            new IconButton(
                icon: const Icon(Icons.save),
                onPressed: () async {
                  try {
                    await key.currentState.validateAndSaveForm(key.currentState.context);
                    Navigator.pop(context, 'Successfully edited');
                  } catch (ex) {
                    Navigator.pop(context, 'Error');
                  }
                })
          ],
        ),
        body: new PasswordForm(key: key, index: index, readOnly: false),
      ),
    );
  }
}
