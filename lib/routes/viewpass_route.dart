import 'package:flutter/material.dart';
import '../widgets/password_form.dart';


class ViewPassRoute extends StatelessWidget {
  static const String routeName = "/viewentry";
  static const String title = "View entry";

  @override
  Widget build(BuildContext context) {
    final int index = ModalRoute.of(context).settings.arguments;
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(Icons.close),
              onPressed: () async {Navigator.pop(context);},
              tooltip: MaterialLocalizations.of(context).cancelButtonLabel,
            );
          },
        ),
        actions: <Widget>[
          new IconButton(icon: const Icon(Icons.edit), onPressed: ()  {
             //Navigator.pushReplacementNamed(context, EditPassRoute.routeName, arguments: index);
            Navigator.pop(context, 'edit');
          })
        ],
      ),

      body: new PasswordForm(index: index, readOnly: true),
    );
  }
}