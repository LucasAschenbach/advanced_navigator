part of 'advanced_navigator.dart';

class NestedBackButtonDispatcher extends ChildBackButtonDispatcher {
  NestedBackButtonDispatcher(
    BackButtonDispatcher parent, {
    @required Route route,
  }) : _route = route,
       super(parent);

  final Route _route;

  void dispose() {
    parent.forget(this);
  }

  @override
  Future<bool> invokeCallback(Future<bool> defaultValue) {
    // only pop if navigator is contained in top-most route
    if (_route.isCurrent) {
      return super.invokeCallback(defaultValue);
    } else {
      parent.forget(this);
      var value = parent.invokeCallback(defaultValue);
      parent.deferTo(this);
      return value;
    }
  }
}