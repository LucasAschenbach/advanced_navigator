# Advanced Navigator

A Flutter Navigator which combines the capabilities of the [new Declarative](https://docs.google.com/document/d/1Q0jx0l4-xymph9O6zLaOY4d_f7YFpNWX_eGbzYxr9wY/edit#) and the existing Imperative Navigator API into one easy-to-use widget. This widget implements the new Router widget wrapped around a Navigator to allow for full stack manipulation operations, URL synchronization with browsers and better nesting. All endpoints of the Imperative API (i.e. push, pushNamed, popAndPushNamed, etc.) continue to work under this widget.

## Usage

<img src="https://raw.githubusercontent.com/LucasAschenbach/advanced_navigator/main/assets/example_preview.gif" heigh="500em">

The AdvancedNavigator widget takes a `paths` argument for creating a set of predefined paths. Arguments are automatically parsed from the URI.
```dart
AdvancedNavigator(
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
);
```
Paths are opened with the `open()` or `openNamed()` functions and can be accessed just like push and pop from anywhere in the widget tree below the AdvancedNavigator widget.
```dart
ListTile(
  ...
  onPressed: () => AdvancedNavigator.openNamed(context, '/items/$itemId');
),
```
For full customization, AdvancedNavigator can specify an `onGeneratePath` and `onUnknownPath` function for building a path from the raw route information. The generator functions work in tandem with the `paths` and, if specified, assume a fallback role.
```dart
AdvancedNavigator(
  onGeneratePath: (configuration) {
    // code here
  },
  onUnknownPath: (configuration) {
    // fallback code here
  }
),
```
