# Advanced Navigator

This package aims at making the new [Navigator 2.0](https://docs.google.com/document/d/1Q0jx0l4-xymph9O6zLaOY4d_f7YFpNWX_eGbzYxr9wY/edit#) easy to implement without any boilerplate code while offering a wide array of advanced functionalities and customizations for difficult navigation logic.

## Usage

This package is build to handle both, simple navigations without unnecessary code overhead as well as very complex navigations which require web-URL synching across nested navigators. At its core is the `AdvancedNavigator` widget. It looks similar to the standard navigator but provides easy access to the declarative API and adds other features without requiring custom router delegates or route information providers.

### Basic Navigation

Every navigation operation which can be applied to `AdvancedNavigatior` falls into one of three categories:

1. **Path Navigation:** Replaces entire page stack with new list of pages
2. **Page Navigation:** Adds or removes page to or from top of page stack
3. **Pageless Navigation:** Attaches route to top-most page in page stack

> A page is a blueprint for building a route. For more information, please go to the Navigator 2.0 introduction [here](https://docs.google.com/document/d/1Q0jx0l4-xymph9O6zLaOY4d_f7YFpNWX_eGbzYxr9wY/edit#).

#### Paths

Paths are in most cases declared through the `paths` argument which provides a simple and clear interface for fully customizable page stack manipulations. It maps a set of URIs to path builder functions which will be invoked whenever `AdvancedNavigator.openNamed(context, <uri>)` with the associated URI is called. The returned path (list of pages) then replaces the navigators current page stack.

> `AdvancedNavigator` expects each requested path name to be in the standard [URI](https://tools.ietf.org/html/rfc2396) format and will parse it as such. Therefore, to take full advantage of this widget it is recommended to design path names with that format in mind.

There is built in argument parsing for extracting arguments such as id's directly from the provided URI. In the path name, arguments are marked with enclosing parentheses `.../{argName}/...` and can be read from the args argument in the path builder function to be used for building the page stack.

Query parameters as in `/search?q=unicorn&res=50` will be extracted and passed on as well. However, path name arguments will take precidence in the event of a name collision.

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

It is worth noting that most use-cases will only need the `paths` argument for *Path Navigation*. However, there is the option to specify an `onGeneratePath` and  `onUnknownPath` function for full customizability. These functions can work in tandem with `paths` and are used by the navigator as a fallback for requests `paths` is unable to handle.

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

*Page Navigation* is more generative and can be implemented using the `pages` argument. Instead of replacing the entire page stack, pages are incrementally added to or removed from the top of the page stack. This allows for very long and flexible page histories but is also less predictable and might lead to undesired navigation flows.

`paths` defines a map of pages uniquely identified by a string (page name). Also, the string identifier is not required to comply with any format and can be chosen arbitrarily. Arguments are not contained in the name but are passed along as a separate parameter in the `pushNamed()` function. Calling `pushNamed()` will invoke the page builder function of the associated page name with the given arguments and add the returned page to the top of the page stack.

Example:

```dart
AdvancedNavigator(
  pages: {
    'post': (args) => CupertinoPage(key: ValueKey('post${args['postId']}'), child: ViewPost(args['postId'])),
    'profile': (args) => CupertinoPage(key: ValueKey('profile${args['userId']}'), child: ViewProfile(args['userId'])),
  }
);
```

> **Important:** Always be sure to **assign a restorable key to every page** before adding it to the page stack. Otherwise, there will be issues with *path navigation* operations as the navigator won't be able to tell whether a page has already been in the page stack before the request was made or not.

#### Routes

Routes work nearly identical to pages, however with the difference that they are added to the navigator as a pageless route. Since they have not been inflated from a page, there is no page to be added to the page stack. Instead, they are attached to the current top-most page. Consequently, whenever that page is moved around the page stack or removed, so will this route.

Often it makes more sense to use pages instead as it leaves the app with more fine grained control over the navigator's route stack. However, routes with strict links to the last page such as **dialogs and drop-down menus do benefit from being pageless**.

Routes can be generated using the `onGenerateRoute` function and are added using `attach()` or `attachNamed()`.

```dart
AdvancedNavigator(
  onGenerateRoute: (RouteSettings configuration) {
    // code here
  },
  onUnknownRoute: (RouteSettings configuration) {
    // fallback code here
  },
),
```

#### API Overview

The advanced navigator implements an imperative API for remotely manipulating the page stack from anywhere in the widget tree. This new API exposes the following endpoints:
| Endpoint | Description |
| --- | --- |
| **open** | Replaces current page stack with provided page stack |
| **openNamed** | Checks if provided path name has reference in `paths` argument, otherwise generates path with `onGeneratePath` and replaces current page stack. |
| **push** | Adds provided page to top of page stack. |
| **pushNamed** | Checks if provided page name has reference in `pages` argument and adds page to top of page stack. |
| **attach** | Attaches provided pageless route to top-most paged route *(= Navigator.push)*. |
| **attachNamed** | Generates route with onGenerateRoute and attaches it to top-most paged route *(= Navigator.pushNamed)*. |
| **pop** | Pops top-most route from navigator, regardless of whether route is pageless or not. If the navigator only has one route in its stack, the pop request is automatically forwarded to the nearest ancestor. |

> Since `AdvancedNavigator` also builds a standard `Navigator` as its child, all navigation operations from the old imperative API such as `Navigator.popAndPushNamed(context, ...)` will continue to work with `AdvancedNavigator`.

In practice, these functions can be invoked by calling them on an instance of `AdvancedNavigatorState` which can be obtained using `AdvancedNavigator.of(context)`, assuming `context` contains an instance of `AdvancedNavigator`.

```dart
TextButton(
  child: ...,
  onPressed: () => AdvancedNavigator.of(context).openNamed('items/$itemId'),
),
```

Equally valid is this, more concise syntax where the context is passed directly to the navigation function:

```dart
TextButton(
  child: ...,
  onPressed: () => AdvancedNavigator.openNamed(context, 'items/$itemId'),
),
```

The `of()` function also provides the option to specify a `skip` parameter which allows you to access navigators which are further up in the widget tree above other navigators without having to pass down the build context.

### Nesting

`AdvancedNavigator` is built to be nested. It configures itself automatically based on whether there is an instance of `AdvancedNavigator` above itself in the widget tree and also maintains an active channel of communication with its parent navigator throughout its lifetime. This allows `AdvancedNavigator` to support global URI navigation, even across nested navigators.

To implement nested navigation, path names building nested navigators must be marked as nested by appending `/...` to the path name. That way, they are matched as a prefix against incoming path name requests and only need to match the first `n` segments and not the entire path name to the last segment. When then a navigator is unable to fully handle a navigation request, i.e. the requested path name matched a nested path name as longest name, it handles the request with the nested path and stores the remaining unused path segments. Now, other navigators (usually descendants) can set that navigator as their `parent` and listen to changes on that path remainder and open that path. Vice verca, when a navigation operation occurs in a navigatior which has a parent, that navigator updates the parent's *nested path* so it can then update its parent or the system navigator of the navigation.

Here is what that means in practice:

```dart
AdvancedNavigator(
  paths: {
    '/': (_) => [
      CupertinoPage(key: ValueKey('home'), child: ViewHome()),
    ],
    '/myArticles': (_) => [
      CupertinoPage(key: ValueKey('home'), child: ViewHome()),
      CupertinoPage(key: ValueKey('myArticles'), child: ViewMyArticles()),
    ],
    '/myArticles/{articleId}/...': (args) => [
      CupertinoPage(key: ValueKey('home'), child: ViewHome()),
      CupertinoPage(key: ValueKey('myArticles'), child: ViewMyArticles()),
      CupertinoPage(key: ValueKey('article${args['articleId']}'), child: AppTextEditor(args['articleId'])),
    ],
  },
),


// inside AppTextEditor

AdvancedNavigator(
  parent: AdvancedNavigator.of(context),
  paths: {
    '/': (_) => [
      CupertinoPage(key: ValueKey('editor'), child: ViewTextEditor()),
    ],
    '/stats': (_) => [
      CupertinoPage(key: ValueKey('editor'), child: ViewTextEditor()),
      CupertinoPage(key: ValueKey('stats'), child: ViewTextEditorSettings()),
    ],
    '/settings': (_) => [
      CupertinoPage(key: ValueKey('editor'), child: ViewTextEditor()),
      CupertinoPage(key: ValueKey('settings'), child: ViewTextEditorSettings()),
    ],
  },
),
```

With this setup the app will support the following navigation requests, both from inside the app through `openNamed()` or from an external source such as the web broswer url:

* `'/'`
* `'/myArticles'`
* `'/myArticles/9420ad99c0ec'`
* `'/myArticles/9420ad99c0ec/stats'`
* `'/myArticles/9420ad99c0ec/settings'`

At the same time, navigation requests directed at the child navigator such as `openNamed('/stats')` will update the global URI as well, in this case to `'/myArticles/9420ad99c0ec/stats'`.

Nesting is extremely useful, not just for dealing with presistent UI components but also for capsulating components of an app. Given the example above, `AppTextEditor` can now be entirely separate from the rest of the app. The text editor pages are in a separate hirarchical layer which means all the presentation logic (e.g. BLoCs) can now behave as if there was only one article.

## Examples

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

## About

Initially, I only created this package to easily port all of my Flutter projects to the new *Navigator 2.0* without having to rewrite the same code over and over again and spontaneously decided to make it open scource. Consequently, there may be a few use cases which this library is not yet properly optimized for. In that case, feel free to create an issue with a feature request.

**Issues and PRs are welcome.**