import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:advanced_navigator/advanced_navigator.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(App());
}

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
                'items/{itemId}': (args) => [
                  CupertinoPage(key: ValueKey('home'), child: ViewHome()),
                  CupertinoPage(key: ValueKey('item${args['itemId']}'), child: AppItem(int.parse(args['itemId']))),
                ],
              },
            ),
          ),
        ),
      ),
    );
  }
}

class ViewHome extends StatelessWidget {
  const ViewHome({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
      ),
      body: ListView.builder(
        itemCount: 25,
        itemBuilder: (context, index) => ListTile(
          leading: Icon(Icons.shopping_bag_sharp),
          title: Text('Item $index'),
          subtitle: Text('This is a sample description for item $index'),
          onTap: () {
            AdvancedNavigator.openNamed(context, '/items/$index');
          },
        ),
      ),
    );
  }
}

class AppItem extends StatelessWidget {
  const AppItem(this.itemNumber, {Key key}) : super(key: key);

  final int itemNumber;

  @override
  Widget build(BuildContext context) {
    return Provider<int>.value(
      value: itemNumber,
      child: AdvancedNavigator(
        parent: AdvancedNavigator.of(context),
        paths: {
          '/': (_) => [
            CupertinoPage(child: ViewItem()),
          ],
          '/edit': (_) => [
            CupertinoPage(child: ViewItem()),
            CupertinoPage(child: ViewEditItem()),
          ],
        },
      ),
    );
  }
}

class ViewItem extends StatelessWidget {
  const ViewItem({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    int itemNumber = Provider.of<int>(context);

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () => AdvancedNavigator.of(context, rootNavigator: true).openNamed('/'),
        ),
        title: Text('Item Details'),
      ),
      body: Center(
        child: Text(
          'Viewing item #$itemNumber',
          style: Theme.of(context).textTheme.headline4,
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: Icon(Icons.edit),
        label: Text('Edit Item'),
        tooltip: 'Edit',
        onPressed: () => AdvancedNavigator.openNamed(context, '/edit'),
      ),
    );
  }
}

class ViewEditItem extends StatelessWidget {
  const ViewEditItem({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    int itemNumber = Provider.of<int>(context);

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () => AdvancedNavigator.openNamed(context, '/'),
        ),
        title: Text('Edit Item'),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.edit, size: 75.0, color: Colors.white),
            ),
            SizedBox(height: 20.0),
            Text(
              'Editing item #$itemNumber',
              style: Theme.of(context).textTheme.headline4,
            ),
          ],
        ),
      ),
    );
  }
}