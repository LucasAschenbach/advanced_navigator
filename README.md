# Advanced Navigator

This package contains a fully fetched implementation of the new [Navigator 2.0](https://docs.google.com/document/d/1Q0jx0l4-xymph9O6zLaOY4d_f7YFpNWX_eGbzYxr9wY/edit#) as one easy-to-use widget: AdvancedNavigator. In contrast to the standard Navigator, it enables fully customizable page history manipulations from anywhere in the widget tree, automatically synchronizes the browser URL to navigation events, and communicates with other navigator widgets for intelligent nesting behaviours. At the same time, all endpoints of the old navigator API (i.e. push, pushNamed, popAndPushNamed, etc.) will continue to work when using AdvancedNavigator.

**Table of Contents**
* [Overview](https://github.com/LucasAschenbach/advanced_navigator#overview)
  * [Paths, Pages & Routes](https://github.com/LucasAschenbach/advanced_navigator#paths)
  * [Navigation API](https://github.com/LucasAschenbach/advanced_navigator#navigation-api)
  * [Nesting](https://github.com/LucasAschenbach/advanced_navigator#nesting)
* [Use Cases](https://github.com/LucasAschenbach/advanced_navigator#use-cases)
  * [1. Persistent Side Drawer](https://github.com/LucasAschenbach/advanced_navigator#1-persistent-side-drawer)
  * [2. Encapsulated Navigation](https://github.com/LucasAschenbach/advanced_navigator#2-encapsulated-navigation)
  * [3. URL synching](https://github.com/LucasAschenbach/advanced_navigator#3-url-synching)

---

## Overview

The advanced navigator widget is a wrapper for a router and navigator and makes extensive use of the newly added declarative navigator API. 

### Paths, Pages & Routes

#### Paths

A significant accomplishment of the new declarative API is that it allows for unrestricted page stack manipulation. The `AdvancedNavigator` widget provides a simple interface for controlling such page stack manipulations through the `paths` argument. It takes a map of unique string identifiers each associated with a path builder function whose return value will replace the current page history whenever `openNamed()` is called with the associated path name. 

AdvancedNavigator expects each requested path name to be in the standard [URI](https://tools.ietf.org/html/rfc2396) format and will parse it as such. Therefore, to take full advantage of this widget it is recommended to define path names using that format.

Example:

| ✔️ Do | ❌ Don't |
| --- | --- |
| `'/'` | `''` |
| `'/movies'` | `'/movies/'` |
| `'/settings/general'` | `'settings-general'` |
| `'/recommendations?res=50'` | `'/recommendations/?res=50'` |

AdvancedNavigator also has built in argument parsing for extracting arguments such as id's directly from the provided URI. In the path name, arguments are marked with enclosing parentheses `.../{argName}/...` and can be read from the args argument in the path builder function to be used for building the page stack.

Example:

| ✔️ Do | ❌ Don't |
| --- | --- |
| `'/items/{itemId}'` | `'/items/0x{itemId}'` |
|  | `'items-{itemId}'` |

Query parameters as in `/search?q=unicorn&res=50` will be extracted and passed on as well. However, path name arguments will take precidence in the event of a name collision.

Example:

```dart
AdvancedNavigator(
  paths: {
    '/': (_) => [
      CupertinoPage(key: ValueKey('home'), child: ViewHome()),
    ]
    '/items': (_) => [
      CupertinoPage(key: ValueKey('home'), child: ViewHome()),
    ],
    // example: '/items/ac9f0e80'
    '/items/{itemId}': (args) => [
      CupertinoPage(key: ValueKey('home'), child: ViewHome()),
      CupertinoPage(key: ValueKey('item${args['itemId']}'), child: ViewItem(args['itemId']),
    ],
    // example: '/search?q=unicorn&res=50'
    '/search': (args) => [
      CupertinoPage(key: ValueKey('home'), child: ViewHome()),
      CupertinoPage(key: ValueKey('search'), child: ViewSearch(args['q'], res: int.parse(args['res']))),
    ],
  }
);
```

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

#### Pages

For generative navigation, `AdvancedNavigator` also offers the `pages` argument. Instead of replacing the entire page stack, in this approach pages are incrementally added to or removed from the top of the page stack. This allows for very long and flexible page histories but is also less predictable and might lead to undesired navigation flows.

As in the `paths` argument, `pages` maps a unique string identifier to a builder function, however here for building a page instead of a path. Also, the string identifier is not required to comply with any format and can be chosen arbitrarily. Arguments are not contained in the name but are passed along as a separate parameter in the `pushNamed()` function. Calling `pushNamed()` will invoke the page builder function of the associated page name with the given arguments and add the returned page to the top of the page stack.

Example:

```dart
AdvancedNavigator(
  pages: {
    'post': (args) => CupertinoPage(key: ValueKey('post${args['postId']}'), child: ViewPost(args['postId'])),
    'profile': (args) => CupertinoPage(key: ValueKey('profile${args['userId']}'), child: ViewProfile(args['userId'])),
  }
);
```

> **Important:** For the navigator to be able to recognize whether a widget changed or not, it is curcial to assign a restorable key to your pages. Otherwise, the navigator will rebuild the entire page stack with new widgets for every navigation operation.

#### Routes

Routes work nearly identical to pages, however with the difference that the are added to the navigator as a pageless route. Since they have not been inflated from a page, there is no page to be added to the page stack. Instead, they are attached to the current top-most page. Consequently, whenever that page is moved around the page stack or removed, so will this route.

Often it makes more sense to use pages instead as it leaves the app with more fine grained control over the navigator's route stack. However, routes with strict links to the last page such as dialogs and drop-down menus do benefit from being pageless.

Routes can be generated using the `onGenerateRoute` function and are added using `attach()` or `attachNamed()`.

```dart
AdvancedNavigator(
  onGenerateRoute: (RouteSettings configuration) {
    // code here
  },
  onUnknownRoute: (RouteSettings configuration) {
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
TextButton(
  child: ...,
  onPressed: () => AdvancedNavigator.of(context).openNamed('items/$itemId');
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

// TODO

### 2. Encapsulated Navigation

// TODO

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