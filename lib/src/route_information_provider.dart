part of 'advanced_navigator.dart';

/// Object which notifies previously registered [RouteInformationObserver]s upon
/// changes to the `currentRouteInformation` member by calling their
/// `didPushRouteInformation` method with the updated route information.
///
/// This class is mixed into the [AdvancedNavigatorState] for handling
/// communication with nested navigators
///
/// See also:
/// * [RouteInformationObserver]: implements `didPushRouteInformation` for
/// responding to route information changes.
///
class RouteInformationObservable {
  final List<RouteInformationObserver> _observers = [];

  AdvancedRouteInformation? _observedRouteInformation;

  AdvancedRouteInformation? get observedRouteInformation => _observedRouteInformation;

  set observedRouteInformation(AdvancedRouteInformation? value) {
    if (_observedRouteInformation == value) {
      return;
    }
    _observedRouteInformation = value;
    notifyObservers();
  }

  void notifyObservers() {
    for (var observer in _observers) {
      observer.didPushRouteInformation(_observedRouteInformation);
    }
  }

  void addObserver(RouteInformationObserver observer) {
    _observers.add(observer);
  }

  void removeObserver(RouteInformationObserver observer) {
    _observers.remove(observer);
  }

/*@mustCallSuper
  void dispose() {
    _observers = null;
  }*/
}

/// Observer to a [RouteInformationObservable]
///
/// Reacts to changes in observed object with `didPushNewRouteInformation` and
/// is mixed into [NestedRouteInformationProvider] for handling communicatiion
/// with parent navigators.
///
/// See also:
/// * [RouteInformationObservable]: Calls `didPushRouteInformation` upon changes
/// to its `currentRouteInformation`
///
abstract class RouteInformationObserver {
  Future<bool> didPushRouteInformation(RouteInformation? routeInformation) => Future<bool>.value(false);
}

/// Route information provider working supplementary to a single root provider
class NestedRouteInformationProvider extends RouteInformationProvider
    with RouteInformationObserver, ChangeNotifier {
  NestedRouteInformationProvider(
    this._parent, {
    required RouteInformation initialRouteInformation,
  })  : _initialRouteInformation = initialRouteInformation,
        _value = initialRouteInformation = _parent.currentNestedPath ?? initialRouteInformation;

  final AdvancedNavigatorState _parent;

  final RouteInformation _initialRouteInformation;

  AdvancedNavigatorState get parent => _parent;

  @override
  RouteInformation get value => _value;
  RouteInformation _value;

  @override
  void routerReportsNewRouteInformation(covariant AdvancedRouteInformation routeInformation,
      {RouteInformationReportingType type = RouteInformationReportingType.none}) {
    // notify parent of changes in nested navigator
    parent.updatedSubtree(routeInformation);
    _value = routeInformation;
  }

  void _parentReportsNewRouteInformation(RouteInformation? routeInformation) {
    if (_value == routeInformation) return;
    _value = routeInformation ?? _initialRouteInformation;
    notifyListeners();
  }

  @override
  void addListener(VoidCallback listener) {
    if (!hasListeners) parent.addObserver(this);
    super.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    super.removeListener(listener);
    if (!hasListeners) parent.removeObserver(this);
  }

  @override
  void dispose() {
    // In practice, this will rarely be called. We assume that the listeners
    // will be added and removed in a coherent fashion such that when the object
    // is no longer being used, there's no listener, and so it will get garbage
    // collected.
    if (hasListeners) parent.removeObserver(this);
    super.dispose();
  }

  @override
  Future<bool> didPushRouteInformation(RouteInformation? routeInformation) async {
    assert(hasListeners);
    _parentReportsNewRouteInformation(routeInformation);
    return true;
  }
}

/// Route information provider with no communication to external sources
class EmptyRouteInformationProvider extends RouteInformationProvider with ChangeNotifier {
  EmptyRouteInformationProvider({required AdvancedRouteInformation initialRouteInformation})
      : _value = initialRouteInformation;

  @override
  RouteInformation get value => _value;
  RouteInformation _value;

  @override
  void routerReportsNewRouteInformation(covariant AdvancedRouteInformation routeInformation,
      {RouteInformationReportingType type = RouteInformationReportingType.none}) {
    _value = routeInformation;
  }
}
