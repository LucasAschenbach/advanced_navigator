# Advanced Navigator

This package contains a fully fetched implementation of the new [Navigator 2.0](https://docs.google.com/document/d/1Q0jx0l4-xymph9O6zLaOY4d_f7YFpNWX_eGbzYxr9wY/edit#) as one easy-to-use widget: AdvancedNavigator. In contrast to the standard Navigator, it enables fully customizable page history manipulations from anywhere in the widget tree, automatically synchronizes the browser URL to navigation events, and communicates with other navigator widgets for intelligent nesting behaviours. At the same time, all endpoints of the old navigator API (i.e. push, pushNamed, popAndPushNamed, etc.) will continue to work when using AdvancedNavigator.

**Table of Contents**
* [Overview](https://github.com/LucasAschenbach/advanced_navigator#overview)
  * [Paths](https://github.com/LucasAschenbach/advanced_navigator#paths)
  * [Navigation API](https://github.com/LucasAschenbach/advanced_navigator#navigation-api)
  * [Nesting](https://github.com/LucasAschenbach/advanced_navigator#nesting)
* [Use Cases](https://github.com/LucasAschenbach/advanced_navigator#use-cases)
  * [1. Persistent Side Drawer](https://github.com/LucasAschenbach/advanced_navigator#1-persistent-side-drawer)
  * [2. Encapsulated Navigation](https://github.com/LucasAschenbach/advanced_navigator#2-encapsulated-navigation)
  * [3. URL synching](https://github.com/LucasAschenbach/advanced_navigator#3-url-synching)

---

## Overview

The advanced navigator widget is a wrapper for a router and navigator and makes extensive use of the newly added declarative navigator API. 

### Paths
A significant accomplishment of the new declarative API is that it allows for unrestricted page stack manipulation. The `AdvancedNavigator` widget provides a simple interface for controlling such page stack manipulations through the `paths` argument.
This is similar to the `routes` argument used by the old navigator widget in that it specifies a map of string URIs pointing towards a path builder function which is executed upon reception of a navigation request with the associated URI. The returned page list will then replace the current page stack of the navigator.

Advanced navigator has built in argument parsing for extracting arguments such as id's directly from the provided URI. In the path name, arguments are marked with enclosing parentheses `.../{argName}/...` and can be read from the args argument in the path builder function to be used for building the page stack:

```dart
AdvancedNavigator(
  paths: {
    '/': (_) => [
      CupertinoPage(key: ValueKey('home'), child: ViewHome()),
    ]
    '/items': (_) => [
      CupertinoPage(key: ValueKey('home'), child: ViewHome()),
    ],
    '/items/{itemId}': (args) => [
      CupertinoPage(key: ValueKey('home'), child: ViewHome()),
      CupertinoPage(key: ValueKey('item${args['itemId']}'), child: ViewItem(args['itemId']),
    ],
  }
);
```
Query parameters as in `home/details?sort=desc` will be extracted and passed on as well. However, path name arguments will take precidence in the event of a name collision.

Most use-cases will only need the `paths` argument. However, there is the option to specify an `onGeneratePath` and  `onUnknownPath` function for full customizability. These functions can work in tandem with `paths` and are used by the navigator as a fallback for requests `paths` is unable to handle.

```dart
AdvancedNavigator(
  onGeneratePath: (RouteInformation configuration) {
    // code here
  },
  onUnknownPath: (RouteInformation configuration) {
    // fallback code here
  }
),
```

### Navigation API

The advanced navigator implements an imperative API for remotely manipulating the page stack from anywhere in the widget tree. This new API exposes the following endpoints:
| Endpoint | Description |
| --- | --- |
| **open** | Replaces current page stack with provided page stack |
| **openNamed** | Checks if provided path name has reference in `paths` argument, otherwise generates path with `onGeneratePath` and replaces current page stack. |
| **push** | Adds provided page to top of page stack. |
| **pushNamed** | Checks if provided page name has reference in `pages` argument and adds page to top of page stack. |
| **attach** | Attaches provided pageless route to top-most paged route *(= Navigator.push)*. |
| **attachNamed** | Generates route with onGenerateRoute and attaches it to top-most paged route *(= Navigator.pushNamed)*. |
| **pop** | Pops top-most route from navigator, regardless of whether route is pageless or not. If the navigator only has one route in its stack, the pop request is forwarded to the nearest ancestor. |

In practice, these functions can be invoked by calling them on an instance of `AdvancedNavigatorState` which can be obtained using `AdvancedNavigator.of(context)`, assuming `context` contains an instance of `AdvancedNavigator`.
```dart
ListTile(
  ...
  onTap: () => AdvancedNavigator.of(context).openNamed('items/$itemId');
),
```

*Note: Since `AdvancedNavigator` also builds a standard `Navigator` as its child, all navigation operations from the old imperative API such as `Navigator.popAndPushNamed(context, ...)` will continue to work with `AdvancedNavigator`.*

### Nesting

Advanced Navigator supports global URI navigation, even across nested navigators. This works by maintaining an active channel of communication between navigator to update each other on new navigation events.

Since Flutter creates its element tree recursively, a navigator can only know about its ancestors but not about its descendants during build. Accordingly, upon build a navigator will take a parent navigator as an argument (usually `AdvancedNavigator.of(context)`) and attach a listener to its `currentNestedPath` variable. Advanced navigator checks whether there is another navigator above itself in the widget tree and configures itself accordingly.

```dart
AdvancedNavigator(
  paths: {
    '/': (_) => ...,
    '/projects/{projectId}': (args) => [
      ...,
      EditorApp(
        ...
        // Provider for projectId:

            AdvancedNavigator(
              parent: AdvancedNavigator.of(context),
              paths: {
                '/': (_) => [Editor()],
                '/settings': (_) => [
                  Editor(),
                  Settings(),
                ],
              },
            ),

        ...
      ),
    ],
  },
),
```

## Use Cases

### 1. Persistent Side Drawer

### 2. Encapsulated Navigation

### 3. URL synching

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