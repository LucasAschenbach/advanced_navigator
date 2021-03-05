import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

part 'route_information_provider.dart';

/// A function for building a page stack from route information
typedef PathFactory = RouterConfiguration Function(RouteInformation);

/// A function for building a page from route settings
typedef PageFactory = Page Function(RouteSettings);

/// A widget that manages a set of child widgets with a stack discipline.
/// 
/// This widget wraps a [Router] and [Navigator] object for maintaining a full 
/// 
/// ```dart
/// AdvancedNavigator(
///   pages: {
///     'projects': (_) => MaterialPage(child: ViewHome()),
///     'settings': (_) => MaterialPage(child: ViewSettings()),
///     'editor': (args) => MaterialPage(child: ViewProject(args['projectId'])),
///   },
///   paths: {
///     '/': (_) => [
///       MaterialPage(child: ViewHome()),
///     ],
///     '/projects': (_) => [
///       MaterialPage(child: ViewHome()),
///     ],
///     '/projects/{projecId}': (args) => [
///       MaterialPage(child: ViewHome()),
///       MaterialPage(child: ViewProject(args['projectId'])),
///     ],
///     '/settings': (_) => [
///       MaterialPage(child: ViewHome()),
///       MaterialPage(child: ViewSettings()),
///     ],
///   },
///   onGeneratePath: (configuration) {
///     // fallback for paths
///   },
///   onUnknownPath: (configuration) {
///     // fallback for onGeneratePath
///   },
/// );
/// ```
class AdvancedNavigator extends StatefulWidget {
  AdvancedNavigator({
    Key key,
    this.parent,
    this.initialLocation,
    this.paths = const {},
    this.onGeneratePath,
    this.onUnknownPath,
    this.pages = const {},
    this.onGeneratePage,
    this.onUnknownPage,
    this.onPopPage,
    this.routes,
    this.onGenerateRoute,
    this.onUnknownRoute,
    this.backButtonDispatcher,
    this.transitionDelegate = const DefaultTransitionDelegate<dynamic>(),
    this.reportsRouteUpdateToEngine = false,
    this.observers = const <NavigatorObserver>[],
    this.restorationScopeId,
  }) : assert(pages != null),
       assert(paths != null),
       assert(transitionDelegate != null),
       assert(observers != null),
       assert(reportsRouteUpdateToEngine != null),
       super(key: key);

  /// The navigator instance to which all navigation events from this navigator
  /// will be reported.
  /// 
  /// If specified, this navigator will work as an extension of the given
  /// navigator. It will notify the parent navigator of any changes to its
  /// current path. The respective path name will be appended to the parent's
  /// `currentConfiguration` for external use, most commonly for dispalying the 
  /// browser url.
  /// On the flip side, navigation events which cannot be fully handled by the
  /// `parent` but where the first `n` segments match a path group with this
  /// navigator in it, will be forwarded to this navigator.
  /// As a result, this navigator effectively manages a subtree appended to the
  /// navigation route which contains this navigator.
  /// 
  /// This allows for hierarchical organization of pages which is particularly
  /// useful for working with Providers like in the BLoC pattern. Providers can
  /// be injected into the widget tree inbetween the two navigators and can
  /// therefore depend on route information such as an `id` in the path name.
  /// 
  /// Example: 
  /// 
  /// ```dart
  /// '/'
  /// '/products'
  /// '/products/{productId}'
  /// '/products/{productId}/edit' // <-- nested navigator appends '/edit'
  /// ```
  /// 
  /// Another use case is when part of the UI should persist between routes.
  /// This is sometimes desired for bottom navigation bars or side drawers, just
  /// to give an example.
  /// 
  /// In most cases, `parent` should be the nearest instance of
  /// [AdvancedNavigator], i.e. 
  /// 
  /// ```dart
  /// AdvancedNavigator(
  ///   parent: AdvancedNavigator.of(context),
  ///   ...
  /// );
  /// ```
  final AdvancedNavigatorState parent;
  // Page API
  final String initialLocation;
  final Map<String, List<Page> Function(Map<String, dynamic>)> paths;
  final PathFactory onGeneratePath;
  final PathFactory onUnknownPath;
  final Map<String, Page Function(Map<String, dynamic>)> pages;
  final PageFactory onGeneratePage;
  final PageFactory onUnknownPage;
  final PopPageCallback onPopPage;
  // Route API
  final Map<String, Route> routes;
  final RouteFactory onGenerateRoute;
  final RouteFactory onUnknownRoute;
  // Utils
  final BackButtonDispatcher backButtonDispatcher;
  final TransitionDelegate transitionDelegate;
  final bool reportsRouteUpdateToEngine;
  final List<NavigatorObserver> observers;
  final String restorationScopeId;

  static const String defaultPathName = '/';

  /// Pattern for detecting parameters in a path name.
  /// 
  /// The pattern is matched against every path segment separately and **must
  /// contain at least one group** for extracting the argument name.
  /// 
  /// The default argument pattern will match any path segment wrapped in
  /// paretheses `{...}` and use their content as parameter name.
  /// 
  /// Example: 
  /// 
  /// ```dart
  /// '/projects/{projectId}/settings' => args: {1: 'projectId'}
  /// ```
  static RegExp argPattern = RegExp(r'^{([^/]*)}$');

  /// Pattern for detecting whether a path name can have nested path names
  /// appended to it.
  /// 
  /// This pattern is matched against the entire path name.
  /// 
  /// The default nest pattern will match any path name ending with: `'/...'`.
  static RegExp nestPattern = RegExp(r'/...$');

  /// Function for parsing a string path to a [PathGroup] object.
  /// 
  /// This function is called by the [didUpdateWidget] function from the
  /// [AdvanceNavigatorState] when generating the [DefaultRouteDelegate] which
  /// uses the created [PathGroup] objects for matching any incoming path names
  /// (e.g. browser url) to a predefined path type from the paths map.
  /// 
  /// By default, this function will filter out segments enclosed in parentheses
  /// `{...}` as arguments. For example, for `/users/{userId}/profile` it would
  /// return a PathGroup which matches `/users/DqHKNnIeZo7NtLfNjn6l/profile` or
  /// `/users/jACSWZyufIEbMFVYUOaN/profile` but not `users/profile`.
  /// 
  /// This method can be changed externally by setting:
  /// 
  /// ```dart
  /// AdvancedNavigator.parsePath = (path) {
  ///   //custom implementation
  /// };
  /// ```
  /// However, in most cases it will make more sense to either adjust the
  /// [argPattern] variable or to define a custom [onGeneratePath] function as
  /// a fallback.
  static PathGroup parsePath(String path) {
    var args = <int, String>{};
    var uri = Uri.parse(path);
    var pathSegments = List<String>.from(uri.pathSegments);
    var isNested = nestPattern.firstMatch(uri.path) != null;
    if (isNested) pathSegments.removeLast();
    var strPattern = '';
    pathSegments.asMap().forEach((index, pathSegment) {
      // check if segment is argument
      var argName = argPattern.firstMatch(pathSegment)?.group(1);
      if (argName == null) {
        strPattern += RegExp.escape('/$pathSegment');
      } else {
        args[index] = argName;
        strPattern += '/[^/]*';
      }
    });
    if (strPattern.isEmpty) strPattern = '/';
    strPattern = '^' + strPattern;
    if (!isNested) strPattern += r'$';
    var pattern = RegExp(strPattern);
    return PathGroup(pattern, length: pathSegments.length, args: args);
  }

  /// The router delegate from the closest instance of this class that encloses
  /// the given context.
  ///
  /// Typical usage is as follows:
  ///
  /// ```dart
  /// AdvancedNavigator.of(context)
  ///   ..pop()
  ///   ..pop()
  ///   ..pushNamed('/settings');
  /// ```
  /// 
  /// The `skip` argument denominates the number of instances to be skipped when
  /// searching up the widget tree for an instance of [AdvancedNavigator]. 
  /// 
  /// If `rootNavigator` is set to true, `skip` is ignored and the state from
  /// the furthest instance of this class is given instead. Useful for pushing
  /// contents above all subsequent instances of [AdvancedNavigator].
  ///
  /// If there is no [AdvancedNavigator] in the give `context`, this function
  /// will throw a [FlutterError] in debug mode, and an exception in release
  /// mode.
  static AdvancedNavigatorState of(
    BuildContext context, {
    bool rootNavigator = false,
    int skip = 0,
  }) {
    var navigator = AdvancedNavigator.maybeOf(
      context,
      rootNavigator: rootNavigator,
      skip: skip,
    );
    assert(() {
      if (navigator == null) {
        throw FlutterError(
          'AdvancedNavigator operation requested with a context that does not include an AdvancedNavigator.\n'
          'The context used to push or pop routes from the AdvancedNavigator must be that of a '
          'widget that is a descendant of a Navigator widget.'
        );
      }
      return true;
    }());
    return navigator;
  }

  /// The navigator state from the closest instance of this class that encloses
  /// the given context, if any.
  ///
  /// Typical usage is as follows:
  ///
  /// ```dart
  /// AdvancedNavigatorState? navigator = AdvancedNavigator.maybeOf(context);
  /// if (navigator != null) {
  ///   navigator
  ///     ..pop()
  ///     ..pop()
  ///     ..pushNamed('/settings');
  /// }
  /// ```
  /// 
  /// The `skip` argument denominates the number of instances to be skipped when
  /// searching up the widget tree for an instance of [AdvancedNavigator]. 
  /// 
  /// If `rootNavigator` is set to true, `skip` is ignored and the state from
  /// the furthest instance of this class is given instead. Useful for pushing
  /// contents above all subsequent instances of [AdvancedNavigator].
  ///
  /// Will return null if there is no ancestor [AdvancedNavigator] in the
  /// `context`.
  static AdvancedNavigatorState maybeOf(
    BuildContext context, {
    bool rootNavigator = false,
    int skip = 0,
  }) {
    assert(rootNavigator != null);
    assert(rootNavigator || skip != null);
    AdvancedNavigatorState navigator;
    // Handles the case where the input context is a navigator element.
    if (context is StatefulElement && context.state is AdvancedNavigatorState) {
      navigator = context.state as AdvancedNavigatorState ?? navigator;
    }
    if (rootNavigator) {
      navigator = context.findRootAncestorStateOfType<AdvancedNavigatorState>() ?? navigator;
    } else {
      context.visitAncestorElements((element) {
        if (element is StatefulElement && element.state is AdvancedNavigatorState) {
          if (skip <= 0) {
            navigator = element.state as AdvancedNavigatorState;
            return false;
          }
          skip--;
        }
        return true;
      });
    }
    return navigator;
  }

  static void open(BuildContext context, List<Page> pages, [Object state]) {
    AdvancedNavigator.of(context).open(pages, state);
  }

  static Future<void> openNamed(BuildContext context, String location, [Object state]) async {
    await AdvancedNavigator.of(context).openNamed(location, state);
  }

  @optionalTypeArgs
  static Future<void> push<T extends Object>(BuildContext context, Page<T> page) async {
    return AdvancedNavigator.of(context).push(page);
  }

  @optionalTypeArgs
  static Future<T> pushNamed<T extends Object>(BuildContext context, String name, { Map<String, dynamic> arguments }) async {
    return AdvancedNavigator.of(context).pushNamed(name, arguments: arguments);
  }

  /// Pop the top-most route off the navigator that most tightly encloses the
  /// given context.
  ///
  /// {@template flutter.widgets.navigator.pop}
  /// The current route's [Route.didPop] method is called first. If that method
  /// returns false, then the route remains in the [Navigator]'s history (the
  /// route is expected to have popped some internal state; see e.g.
  /// [LocalHistoryRoute]). Otherwise, the rest of this description applies.
  ///
  /// If non-null, `result` will be used as the result of the route that is
  /// popped; the future that had been returned from pushing the popped route
  /// will complete with `result`. Routes such as dialogs or popup menus
  /// typically use this mechanism to return the value selected by the user to
  /// the widget that created their route. The type of `result`, if provided,
  /// must match the type argument of the class of the popped route (`T`).
  ///
  /// The popped route and the route below it are notified (see [Route.didPop],
  /// [Route.didComplete], and [Route.didPopNext]). If the [Navigator] has any
  /// [Navigator.observers], they will be notified as well (see
  /// [NavigatorObserver.didPop]).
  ///
  /// The `T` type argument is the type of the return value of the popped route.
  ///
  /// The type of `result`, if provided, must match the type argument of the
  /// class of the popped route (`T`).
  /// {@endtemplate}
  ///
  /// {@tool snippet}
  ///
  /// Typical usage for closing a route is as follows:
  ///
  /// ```dart
  /// void _close() {
  ///   AdvancedNavigator.pop(context);
  /// }
  /// ```
  /// {@end-tool}
  ///
  /// A dialog box might be closed with a result:
  ///
  /// ```dart
  /// void _accept() {
  ///   AdvancedNavigator.pop(context, true); // dialog returns true
  /// }
  /// ```
  @optionalTypeArgs
  static void pop<T extends Object>(BuildContext context, [ T result ]) {
    AdvancedNavigator.of(context).pop<T>(result);
  }

  @override
  State<StatefulWidget> createState() => AdvancedNavigatorState();
}

class AdvancedNavigatorState extends State<AdvancedNavigator>
    with RouteInformationObservable {

  GlobalKey _routerKey;

  DefaultRouterDelegate _routerDelegate;
  RouteInformationProvider _informationProvider;

  Set<AdvancedNavigatorState> _children;
  
  RouteInformation get currentNestedPath => _routerDelegate._currentNestedPath;

  @override
  void initState() { 
    super.initState();
    _routerKey = GlobalKey(debugLabel: 'Router');
    _children = {};
    // establish relationship to parent, if specified
    widget.parent?.addChild(this);
  }

  void addChild(AdvancedNavigatorState navigator) {
    _children.add(navigator);
  }

  void removeChild(AdvancedNavigatorState navigator) {
    _children.remove(navigator);
    if (_children.isEmpty) {
      updatedSubtree(null);
    }
  }
  
  /// Update `_currentNestedPath` from router delegate with new route
  /// information from nested navigators and notify route information provider 
  void updatedSubtree(RouteInformation subtreeConfiguration) {
    _routerDelegate._currentNestedPath = subtreeConfiguration;
    var configuration = _routerDelegate.currentConfiguration;
    _informationProvider.routerReportsNewRouteInformation(configuration);
  }

  @override
  void dispose() {
    widget.parent?.removeChild(this);
    super.dispose();
  }

  // NAVIGATION API

  /// Opens given path with its entire history stack.
  void open(List<Page> pages, [Object state]) {
    _routerDelegate?.open(pages, state);
  }

  /// Opens path from given location reference with its entire history stack.
  Future<void> openNamed(String location, [Object state]) async {
    return _routerDelegate?.openNamed(location, state);
  }

  /// Pushes given page to top of navigator page stack and inflates it.
  @optionalTypeArgs
  Future<T> push<T extends Object>(Page<T> page) async {
    return _routerDelegate?.push<T>(page);
  }

  /// Pushes page with given name to top of navigator page stack and inflates it.
  @optionalTypeArgs
  Future<T> pushNamed<T extends Object>(String name, { Map<String, dynamic> arguments }) async {
    return _routerDelegate?.pushNamed<T>(name, arguments: arguments);
  }

  /// Adds pageless route to top of navigator route stack.
  @optionalTypeArgs
  Future<T> attach<T extends Object>(Route<T> route) {
    return _routerDelegate?.attach<T>(route);
  }

  /// Adds pageless route with given name to top of navigator route stack.
  @optionalTypeArgs
  Future<T> attachNamed<T extends Object>(String routeName, { Object arguments }) {
    return _routerDelegate?.attachNamed<T>(routeName, arguments: arguments);
  }

  /// Pops topmost route and its corresponding page, if any.
  @optionalTypeArgs
  void pop<T extends Object>([ T result ]) {
    _routerDelegate?.pop<T>(result);
  }

  @override
  Widget build(BuildContext context) {
    // persist state on rebuild: ??=
    _routerDelegate ??= DefaultRouterDelegate(
      context: context,
      onNestedPathUpdate: (configuration) {
        observedRouteInformation = configuration;
      },
      paths: widget.paths.map(
        (key, value) => MapEntry(AdvancedNavigator.parsePath(key), value),
      ),
      onGeneratePath: widget.onGeneratePath,
      onUnknownPath: widget.onUnknownPath,
      pages: widget.pages,
      onGeneratePage: widget.onGeneratePage,
      onUnknownPage: widget.onUnknownPage,
      onPopPage: widget.onPopPage,
      onGenerateRoute: widget.onGenerateRoute,
      onUnknownRoute: widget.onUnknownRoute,
      transitionDelegate: widget.transitionDelegate,
      reportsRouteUpdateToEngine: widget.reportsRouteUpdateToEngine,
      observers: widget.observers,
      restorationScopeId: widget.restorationScopeId,
    );

    // persist state on rebuild: == null
    if (_informationProvider == null) {
      var ancestor = context.findAncestorStateOfType<AdvancedNavigatorState>();
      var initialLocation = widget.initialLocation
          ?? AdvancedNavigator.defaultPathName;
      var initialRouteInformation = RouteInformation(
        location: initialLocation,
      );
      if (widget.parent != null) {
        // navigator is nested with parent
        _informationProvider = NestedRouteInformationProvider(
          widget.parent,
          initialRouteInformation: initialRouteInformation,
        );
      } else if (ancestor != null) {
        // navigator is nested without parent
        _informationProvider = EmptyRouteInformationProvider(
          initialRouteInformation: initialRouteInformation,
        );
      } else {
        // navigator is at root
        initialLocation = WidgetsBinding.instance.window.defaultRouteName != AdvancedNavigator.defaultPathName
            ? WidgetsBinding.instance.window.defaultRouteName
            : initialLocation;
        initialRouteInformation = RouteInformation(
          location: initialLocation,
        );
        _informationProvider = PlatformRouteInformationProvider(
          initialRouteInformation: initialRouteInformation,
        );
      }
    }

    return Router(
      key: _routerKey,
      routerDelegate: _routerDelegate,
      routeInformationProvider: _informationProvider,
      routeInformationParser: DefaultRouteInformationParser(),
      backButtonDispatcher: widget.backButtonDispatcher ?? RootBackButtonDispatcher(),
    );
  }
}

@immutable
class PathGroup {
  const PathGroup(this.pattern, {
    @required this.length,
    this.args = const {},
  }) : assert(pattern != null),
       assert(length != null),
       assert(args != null);

  final RegExp pattern;
  final int length;
  final Map<int, String> args;
}

@immutable
class RouterConfiguration {
  const RouterConfiguration({
    @required this.pages,
    this.internalPath,
    this.nestedPath,
  }) : assert(pages != null);

  final List<Page> pages;
  final RouteInformation internalPath;
  final RouteInformation nestedPath;
}

class DefaultRouteInformationParser
    extends RouteInformationParser<RouteInformation> {
  const DefaultRouteInformationParser();
  
  @override
  SynchronousFuture<RouteInformation> parseRouteInformation(
      RouteInformation routeInformation) => SynchronousFuture(routeInformation);

  @override
  RouteInformation restoreRouteInformation(
      RouteInformation routeInformation) => routeInformation;
}

class DefaultRouterDelegate extends RouterDelegate<RouteInformation>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin {
  DefaultRouterDelegate({
    @required this.context,
    @required this.onNestedPathUpdate,
    @required this.paths,
    @required this.onGeneratePath,
    @required this.onUnknownPath,
    @required this.pages,
    @required this.onGeneratePage,
    @required this.onUnknownPage,
    @required this.onPopPage,
    @required this.onGenerateRoute,
    @required this.onUnknownRoute,
    @required this.transitionDelegate,
    @required this.reportsRouteUpdateToEngine,
    @required this.observers,
    @required this.restorationScopeId,
  }) : assert(context != null),
       assert(pages != null),
       assert(paths != null),
       assert(paths.isNotEmpty
           || onGeneratePath != null
           || onUnknownPath != null),
       assert(transitionDelegate != null),
       assert(reportsRouteUpdateToEngine != null),
       assert(observers != null);
       
  final BuildContext context;
  final void Function(RouteInformation) onNestedPathUpdate;
  final Map<PathGroup, List<Page> Function(Map<String, dynamic>)> paths;
  final PathFactory onGeneratePath;
  final PathFactory onUnknownPath;
  final Map<String, Page Function(Map<String, dynamic>)> pages;
  final PageFactory onGeneratePage;
  final PageFactory onUnknownPage;
  final PopPageCallback onPopPage;
  final RouteFactory onGenerateRoute;
  final RouteFactory onUnknownRoute;
  final TransitionDelegate transitionDelegate;
  final bool reportsRouteUpdateToEngine;
  final List<NavigatorObserver> observers;
  final String restorationScopeId;

  RouteInformation _currentInternalPath;
  RouteInformation _currentNestedPath;
  List<Page> _pages;

  /// Opens given path with its entire history stack.
  void open(List<Page> pages, [Object state]) {
    _pages = pages;
    notifyListeners();
  }

  /// Opens path from given location reference with its entire history stack.
  Future<void> openNamed(String location, [Object state]) async {
    var configuration = RouteInformation(location: location, state: state);
    await setNewRoutePath(configuration);
  }

  /// TODO: Return T from page route
  /// 
  /// Pushes given page to top of navigator page stack and inflates it.
  @optionalTypeArgs
  Future<T> push<T extends Object>(Page<T> page) async {
    _pages.add(page);
    notifyListeners();
    return null;
  }

  /// TODO: Return T from page route
  /// 
  /// Pushes page with given name to top of navigator page stack and inflates it.
  @optionalTypeArgs
  Future<T> pushNamed<T extends Object>(String name, { Map<String, dynamic> arguments = const <String, dynamic>{} }) async {
    Page page;
    if (pages.containsKey(name)) {
      page = pages[name](arguments);
    } else {
      // generate page with callback
      assert(() {
        if (onGeneratePage == null) {
          throw FlutterError.fromParts(<DiagnosticsNode>[
            ErrorSummary('AdvancedNavigator.onGeneratePage was null but the referenced page had no corresponding page in the app.'),
            ErrorDescription(
              'The referenced page was: "$name" '
              'To use the AdvancedNavigator API with named pages (pushNamed), '
              'the AdvancedNavigator must be provided with either a matching reference '
              'in the pages map or an onGeneratePage handler.\n'
            ),
            DiagnosticsProperty<RouterDelegate>('The RouterDelegate was', this, style: DiagnosticsTreeStyle.errorProperty),
          ]);
        }
        return true;
      }());
      var routeSettings = RouteSettings(name: name, arguments: arguments);
      page = onGeneratePage(routeSettings);
      if (page == null) {
        assert(() {
          if (onUnknownPage == null) {
            throw FlutterError.fromParts(<DiagnosticsNode>[
              ErrorSummary('AdvancedNavigator.onGeneratePage returned null when requested to build page "$name".'),
              ErrorDescription(
                'The onGeneratePage callback must never return null, unless an onUnknownPage '
                'callback is provided as well.'
              ),
              DiagnosticsProperty<RouterDelegate>('The RouterDelegate was', this, style: DiagnosticsTreeStyle.errorProperty),
            ]);
          }
          return true;
        }());
        page = onUnknownPage(routeSettings);
        assert(() {
          if (page == null) {
            throw FlutterError.fromParts(<DiagnosticsNode>[
              ErrorSummary('Navigator.onUnknownPage returned null when requested to build page "$name".'),
              ErrorDescription('The onUnknownPage callback must never return null.'),
              DiagnosticsProperty<RouterDelegate>('The RouterDelegate was', this, style: DiagnosticsTreeStyle.errorProperty),
            ]);
          }
          return true;
        }());
      }
    }
    assert(page != null);
    _pages.add(page);
    notifyListeners();
    return null;
  }

  /// Adds pageless route to top of navigator route stack.
  @optionalTypeArgs
  Future<T> attach<T extends Object>(Route<T> route) {
    var navigator = navigatorKey.currentState;
    return navigator.push<T>(route);
  }

  /// Adds pageless route with given name to top of navigator route stack.
  @optionalTypeArgs
  Future<T> attachNamed<T extends Object>(String routeName, { Object arguments }) {
    var navigator = navigatorKey.currentState;
    return navigator.pushNamed<T>(routeName, arguments: arguments);
  }

  /// Pops topmost route and its corresponding page, if any.
  @optionalTypeArgs
  void pop<T extends Object>([ T result ]) {
    var navigator = navigatorKey.currentState;
    if (navigator.canPop()) {
      navigator.pop<T>(result);
    } else {
      var advancedNavigator = context
          .findAncestorStateOfType<AdvancedNavigatorState>();
      if (advancedNavigator != null) {
        advancedNavigator.pop<T>(result);
      }
    }
  }

  @override
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  String _cleanPath(String location) {
    if (location == '/') {
      return location;
    }
    location.trim();
    location.replaceAll('//', '/');
    if (location.endsWith('/')) {
      return location.substring(0, location.length-1);
    }
    return location;
  }

  @override
  RouteInformation get currentConfiguration {
    var rawPath = _currentInternalPath.location +
        (_currentNestedPath?.location ?? '');
    return RouteInformation(
      location: _cleanPath(rawPath),
      state: _currentInternalPath.state,
    );
  }

  @override
  SynchronousFuture<void> setNewRoutePath(RouteInformation configuration) {
    if (configuration == _currentInternalPath) {
      return SynchronousFuture(null);
    }
    List<Page> changedPages;
    RouteInformation currentInternalPath;
    RouteInformation currentNestedPath;
    // check for match in paths map
    if (paths.isNotEmpty) {
      // find matching reference
      var uri = Uri.parse(configuration.location);
      PathGroup pathGroup;
      String internalPath;
      String nestedPath;
      paths.keys.forEach((iterationPathGroup) {
        var match = iterationPathGroup.pattern.firstMatch(uri.path);
        if (match != null) {
          // longest matched path takes precidence
          if (iterationPathGroup.length > (pathGroup?.length ?? -1)) {
            var iterationNestedPath = match.input.substring(match.end);
            // pattern must match entire string or be followed by '/'
            if (iterationNestedPath.isEmpty || iterationNestedPath[0] == '/') {
              pathGroup = iterationPathGroup;
              internalPath = match.group(0);
              nestedPath = iterationNestedPath.isEmpty 
                  ? null
                  : iterationNestedPath;
            }
          }
        }
      });
      // parse args
      if (pathGroup != null) {
        var args = <String, String>{};
        args.addAll(uri.queryParameters);
        args.addAll(pathGroup.args.map((pos, argName) => MapEntry(
          argName, uri.pathSegments[pos]
        )));
        changedPages = paths[pathGroup](args);
        currentInternalPath = RouteInformation(
          location: internalPath,
          state: configuration.state,
        );
        currentNestedPath = nestedPath == null
            ? null
            : RouteInformation(location: nestedPath);
      }
    }
    // generate path with callback
    if (changedPages == null) {
      assert(() {
        if (onGeneratePath == null) {
          throw FlutterError.fromParts(<DiagnosticsNode>[
            ErrorSummary('AdvancedNavigator.onGeneratePath was null but the referenced path had no corresponding path in the app.'),
            ErrorDescription(
              'The referenced path was: "${configuration.location}" '
              'To use the AdvancedNavigator API with named paths (openNamed), '
              'the AdvancedNavigator must be provided with either a matching reference '
              'in the paths map or an onGeneratePath handler.\n'
            ),
            DiagnosticsProperty<RouterDelegate>('The RouterDelegate was', this, style: DiagnosticsTreeStyle.errorProperty),
          ]);
        }
        return true;
      }());
      var routerConfiguration = onGeneratePath(configuration);
      changedPages = routerConfiguration.pages;
      currentInternalPath = routerConfiguration.internalPath;
      currentNestedPath = routerConfiguration.nestedPath;
      if (changedPages == null) {
        assert(() {
          if (onUnknownPath == null) {
            throw FlutterError.fromParts(<DiagnosticsNode>[
              ErrorSummary('AdvancedNavigator.onGeneratePath returned null when requested to build path "${configuration.location}".'),
              ErrorDescription(
                'The onGeneratePath callback must never return null, unless an onUnknownPath '
                'callback is provided as well.'
              ),
              DiagnosticsProperty<RouterDelegate>('The RouterDelegate was', this, style: DiagnosticsTreeStyle.errorProperty),
            ]);
          }
          return true;
        }());
        routerConfiguration = onUnknownPath(configuration);
        changedPages = routerConfiguration.pages;
        currentInternalPath = routerConfiguration.internalPath;
        currentNestedPath = routerConfiguration.nestedPath;
        assert(() {
          if (changedPages == null) {
            throw FlutterError.fromParts(<DiagnosticsNode>[
              ErrorSummary('Navigator.onUnknownPath returned null when requested to build path "${configuration.location}".'),
              ErrorDescription('The onUnknownPath callback must never return null.'),
              DiagnosticsProperty<RouterDelegate>('The RouterDelegate was', this, style: DiagnosticsTreeStyle.errorProperty),
            ]);
          }
          return true;
        }());
      }
    }
    assert(changedPages != null);
    _currentNestedPath = currentNestedPath;
    _currentInternalPath = currentInternalPath ?? configuration;
    _pages = changedPages;
    onNestedPathUpdate(_currentNestedPath);
    notifyListeners();
    return SynchronousFuture(null);
  }

  bool _onPopPage(Route<dynamic> route, dynamic result) {
    if (!route.didPop(result)) {
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      pages: _pages,
      onPopPage: onPopPage ?? _onPopPage,
      onGenerateRoute: onGenerateRoute,
      onUnknownRoute: onUnknownRoute,
      transitionDelegate: transitionDelegate,
      reportsRouteUpdateToEngine: reportsRouteUpdateToEngine,
      observers: observers,
      restorationScopeId: restorationScopeId,
    );
  }
}