import 'package:flutter/cupertino.dart';
import 'package:advanced_navigator/advanced_navigator.dart';
import 'package:flutter/material.dart';

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