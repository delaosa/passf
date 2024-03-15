import 'package:flutter/material.dart';


Future<bool> confirmDialog(BuildContext context, [String text = "Do you want to cancel?"]) async {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false, // user must tap button for close dialog!
    builder: (BuildContext context) {
      return AlertDialog(
        //title: Text('$operation?'),
        content: SelectableText(text),
        actions: <Widget>[
          TextButton(
            child: const Text('No'),
            onPressed: () {
              Navigator.of(context).pop(false);
            },
          ),
          TextButton(
            child: const Text('Yes'),
            onPressed: () {
              Navigator.of(context).pop(true);
            },
          )
        ],
      );
    },
  );
}

Future<String> askPassphraseDialog(BuildContext context) async {
  TextEditingController _textFieldController = TextEditingController();

  return showDialog<String>(
    context: context,
    barrierDismissible: false, // user must tap button for close dialog!
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Passphrase'),
        content:  TextField(
          obscureText: true,
          obscuringCharacter: "*",
          autofocus: true,
          autocorrect: false,
          enableSuggestions: false,
          controller: _textFieldController,
          textInputAction: TextInputAction.send,
          onEditingComplete: () => Navigator.of(context).pop(_textFieldController.text),
          //decoration: InputDecoration(labelText: "GPG Passphrase"),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('SUBMIT'),
            onPressed: () {
              Navigator.of(context).pop(_textFieldController.text);
            },
          )
        ],
      );
    },
  );
}


class WaitDialog {
  static Future<void> showLoadingDialog(
      BuildContext context, GlobalKey key) async {
    return showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return new WillPopScope(
              onWillPop: () async => false,
              child: SimpleDialog(
                  key: key,
                  backgroundColor: Theme.of(context).cardColor,
                  children: <Widget>[
                    Center(
                      child: Column(children: [
                        CircularProgressIndicator(backgroundColor: Theme.of(context).colorScheme.secondary),
                        SizedBox(height: 10,),
                        Text("Please Wait....",style: TextStyle(color: Theme.of(context).colorScheme.secondary),)
                      ]),
                    )
                  ]));
        });
  }
}
