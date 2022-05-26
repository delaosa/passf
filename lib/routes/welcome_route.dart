/// Flutter code sample for Stepper

import 'package:flutter/material.dart';
import 'setgit_router.dart';
import 'setgpg_route.dart';
import '../constants.dart' show appName;

/// This is the stateful widget that the main application instantiates.
class WelcomeRoute extends StatefulWidget {
  const WelcomeRoute({Key key}) : super(key: key);
  static const String routeName = "/welcome";

  @override
  State<WelcomeRoute> createState() => _WelcomeRouteState();
}

/// This is the private State class that goes with WelcomeRoute.
class _WelcomeRouteState extends State<WelcomeRoute> {
  int _index = 0;
  static const String _title = 'Welcome to $appName';

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context);
        return Future.value(true);
      },
      child: Scaffold(
        appBar:
            AppBar(automaticallyImplyLeading: false, title: const Text(_title)),
        body: Center(
            child: Stepper(
          currentStep: _index,
          onStepCancel: () {
/*              if (_index > 0) {
                setState(() {
                  _index -= 1;
                });
              }*/
            if (_index == 2) {
              Navigator.pop(context);
              //Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>ListRoute()));
            }
            if (_index <= 1) {
              setState(() {
                _index += 1;
              });
            }
          },
          onStepContinue: () {
            if (_index == 0) {
              Navigator.pushNamed(context, SetGitRoute.routeName);
            }

            if (_index == 1) {
              Navigator.pushNamed(context, SetGpgRoute.routeName);
            }

            if (_index == 2) {
              Navigator.pop(context);
            }
            if (_index <= 1) {
              setState(() {
                _index += 1;
              });
            }
          },
          onStepTapped: (int index) {
            setState(() {
              _index = index;
            });
          },
          steps: <Step>[
            Step(
              title: const Text('Step 1 Git'),
              content: Container(
                  alignment: Alignment.centerLeft,
                  child: const Text('Set up Git details')),
            ),
            const Step(
              title: Text('Step 2 PGP'),
              content: Text('Set up PGP keys'),
            ),
            const Step(
              title: Text('Step 3 Done'),
              content: Text('Setup is done'),
            ),
          ],
        )),
      ),
    );
  }
}
