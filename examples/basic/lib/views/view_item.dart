import 'package:advanced_navigator/advanced_navigator.dart';
import 'package:flutter/material.dart';

class ViewItem extends StatelessWidget {
  const ViewItem(this.item, {Key key}) : super(key: key);

  final int item;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () => AdvancedNavigator.openNamed(context, '/'),
        ),
        title: Text('Item Details'),
      ),
      body: Center(
        child: Text(
          'Viewing item #$item',
          style: Theme.of(context).textTheme.headline4,
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: Icon(Icons.arrow_right),
        label: Text('Next Item'),
        tooltip: 'Next Item',
        onPressed: () => AdvancedNavigator.openNamed(context, '/items/${item + 1}'),
      ),
    );
  }
}