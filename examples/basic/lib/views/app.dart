import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:advanced_navigator/advanced_navigator.dart';

import 'view_home.dart';
import 'view_item.dart';

class App extends StatelessWidget {
  const App({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQueryData.fromWindow(WidgetsBinding.instance.window),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Localizations(
          locale: WidgetsBinding.instance.window.locale,
          delegates: [DefaultWidgetsLocalizations.delegate, DefaultMaterialLocalizations.delegate],
          child: Material(
            child: AdvancedNavigator(
              paths: {
                '/': (_) => [
                  CupertinoPage(key: ValueKey('home'), child: ViewHome()),
                ],
                '/items': (_) => [
                  CupertinoPage(key: ValueKey('home'), child: ViewHome()),
                ],
                '/items/{itemId}': (args) => [
                  CupertinoPage(key: ValueKey('home'), child: ViewHome()),
                  CupertinoPage(key: ValueKey('item${args['itemId']}'), child: ViewItem(int.parse(args['itemId']))),
                ],
              },
            ),
          ),
        ),
      ),
    );
  }
}