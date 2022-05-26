import 'package:flutter/material.dart';
import '../constants.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../providers/passf_provider.dart';

class About extends StatefulWidget {
  static const String routeName = "/about";
  About({
    Key key,
  }) : super(key: key);
  @override
  AboutState createState() => AboutState();
}

class AboutState  extends State<About>  {
  bool showLicense = false;
  bool showComponents = false;
  var hiddenCounter = 0;

  @override
  Widget build(BuildContext context) {
    final passwords = Provider.of<Passwords>(context, listen: false);
    return Scaffold(
      appBar: AppBar(
        title: Text('About'),
      ),
      body: Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Column(
            children: <Widget>[
              Icon(Icons.https_rounded, size: 150),
              //Image(image: AssetImage('assets/app_icon.png')),
              GestureDetector(
                onTap: () {
                  setState(() {
                    hiddenCounter++;
                    if (hiddenCounter==5) {
                      hiddenCounter=0;
                      passwords.debugMode=!passwords.debugMode;
                      ScaffoldMessenger.of(context)
                        ..removeCurrentSnackBar()
                        ..showSnackBar(SnackBar(
                            duration: Duration(seconds: 2),
                            content: Text('Debug Mode: ' + passwords.debugMode.toString() )));
                    }
                  });
                },
                // The custom button
                child: Container(
                  child: Text('$appName - $appVersion',
                      textAlign: TextAlign.left,
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              SizedBox(height: 16),
              Text('Developed by $authorName', textAlign: TextAlign.left),
              SizedBox(height: 48),
              ListTile(
                title: Text("Source code"),
                //dense: true,
                //subtitle: Text(_gpgHash ?? "" , maxLines: 1),
                leading: Icon(Icons.code, color: Theme.of(context).colorScheme.secondary),
                onTap: () => _launchURL(githubUrl),
              ),
              ListTile(
                title: Text("Open Source Components"),
                //dense: true,
                //subtitle: Text(_gpgHash ?? "" , maxLines: 1),
                leading: Icon(Icons.settings_input_component, color: Theme.of(context).colorScheme.secondary),
                onTap: () => setState(() {showComponents=!showComponents;}) ,
              ),
              showComponents ? Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    TextButton(
                      child: Text('Flutter Flutter Flutter'),
                      onPressed: () => _launchURL('https://flutter.dev'),
                    ),
                    TextButton(
                      child: Text('pass'),
                      onPressed: () =>
                          _launchURL('https://www.passwordstore.org'),
                    ),
                    TextButton(
                      child: Text('git_bindings'),
                      onPressed: () =>
                          _launchURL('https://pub.dev/packages/git_bindings'),
                    ),
                    TextButton(
                      child: Text('openpgp'),
                      onPressed: () =>
                          _launchURL('https://pub.dev/packages/openpgp'),
                    ),
                    TextButton(
                      child: Text('flutter_secure_storage'),
                      onPressed: () => _launchURL(
                          'https://pub.dev/packages/flutter_secure_storage'),
                    ),
                    TextButton(
                      child: Text('provider'),
                      onPressed: () =>
                          _launchURL('https://pub.dev/packages/provider'),
                    ),
                  ]): Container(),

              ListTile(
                title: Text("License"),
                leading: Icon(Icons.copyright, color: Theme.of(context).colorScheme.secondary),
                onTap: () => setState(() {showLicense=!showLicense;}) ,
              ),
              showLicense ? Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Text(licenseText),
                  ]): Container(),
              ListTile(
                title: Text("Contact"),
                //dense: true,
                //subtitle: Text(_gpgHash ?? "" , maxLines: 1),
                leading: Icon(Icons.email, color: Theme.of(context).colorScheme.secondary),
                onTap: () =>
                    _launchURL('mailto:$authorEMail?subject=$appName&body=Hi!'),
              ),
            ],
          ),
        ),
      ),
    );
  }


  void _launchURL(String url) async =>
      await canLaunch(url) ? await launch(url) : throw 'Could not launch $url';


}
