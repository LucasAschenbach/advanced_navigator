part of 'advanced_navigator.dart';

/// Object which notifies previously registered [CurrentPageKeyObservers] upon
/// changes to the `observedPageKey` member by calling `didChangePageKey` on
/// them with the update [Key] object.
/// 
/// An instance of this class is a member of [AdvancedNavigatorState] for
/// communicating to descending navigators whether the route they are contained
/// in is currently on top of the page stack or not.
class CurrentPageKeyObservable {
  List<CurrentPageKeyObserver> _observers = [];

  Key _value;
  Key get value => _value;
  set value(Key value) {
    print('${this.hashCode} set value: $value');
    if (_value == value) {
      return;
    }
    _value = value;
    notifyObservers();
  }

  void notifyObservers() {
    for (var observer in _observers) {
      observer.didChangePageKey(_value);
    }
  }

  void addObserver(CurrentPageKeyObserver observer) {
    _observers.add(observer);
  }

  void removeObserver(CurrentPageKeyObserver observer) {
    _observers.remove(observer);
  }
}

abstract class CurrentPageKeyObserver {
  void didChangePageKey(Key pageKey);
}

class NestedBackButtonDispatcher extends ChildBackButtonDispatcher 
    with CurrentPageKeyObserver {
  NestedBackButtonDispatcher(BackButtonDispatcher parent) : super(parent);

  factory NestedBackButtonDispatcher.fromChildBackButtonDispatcher(
    ChildBackButtonDispatcher childBackButtonDispatcher
  ) => NestedBackButtonDispatcher(childBackButtonDispatcher.parent);

  CurrentPageKeyObservable ancestorNavigator;
  Key ancestorPageKey;
  
  bool _allowPop = true;

  void _updateAllowPop(Key ancestorNavigatorCurrentPageKey) {
    print('_updateAllowPop: $ancestorNavigatorCurrentPageKey');
    _allowPop = ancestorNavigatorCurrentPageKey == ancestorPageKey;
  }

  @override
  Future<bool> invokeCallback(Future<bool> defaultValue) {
    print('invokeCallback()');
    if (_allowPop) {
      return super.invokeCallback(defaultValue);
    } else {
      print('SHOULD NOT POP');
      return super.invokeCallback(SynchronousFuture(false));
      //return super.invokeCallback(defaultValue);
    }
  }

  @override
  void addCallback(ValueGetter<Future<bool>> callback) {
    if (!hasCallbacks)
      ancestorNavigator.addObserver(this);
    super.addCallback(callback);
  }

  @override
  void removeCallback(ValueGetter<Future<bool>> callback) {
    super.removeCallback(callback);
    if (!hasCallbacks)
      ancestorNavigator.removeObserver(this);
  }

  @override
  void didChangePageKey(Key pageKey) {
    print('didChangePageKey: $pageKey');
    _updateAllowPop(pageKey);
  }
}