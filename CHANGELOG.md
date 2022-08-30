# 1.0.1
* Fix: pages list not updated on pop
* Fix: Navigator not rebuilding on `push()`, `pushNamed()`

# 1.0.0
* **BREAKING**: Navigation operations can now take arbitrary objects as arguments in addition to path arguments
  * Path arguments are now accessed from `PathArguments.path`
* Fix: nested paths not interpolated using initial location when empty (particularly caused problems when initial location of nested navigators was set to '/')
* Improved error messages
* Formatting

# 0.2.1+3
* Fix static analysis

# 0.2.1+2
* Fix analyzer warnings

# 0.2.1+1
* Port for Flutter v3.0.0

# 0.2.1
* Add `tag` argument to `of()` and `maybeOf()` for reliably accessing navigators with a particular tag

# 0.2.0+1
* Port for Flutter v2.8.0

# 0.2.0
* Port to Null-Safety

# 0.1.2+1
* Fix: back button event not automatically deferred to child back button dispatchers

# 0.1.2
* Add `NestedBackButtonDispatcher` class
* Automatically configure `backButtonDispatcher` based on widget tree (no manual configuration required anymore!)
* Update example

# 0.1.1+3
* Add static `attach()` and `attachNamed()` functions to `AdvancedNavigator` class

# 0.1.1+2
* Fix: named path '/' not forwarding requests to nested navigators

# 0.1.1+1
* Update example with BackButtonDispatcher
* Fix: query parameters not forwarded to nested navigators

# 0.1.1
* Update README.md
* Add page generator functions
* Fix path generator functions

# 0.1.0+1
* Update README.md
* Fixes from pedantic analyzer

# 0.1.0
* Nested navigator communication:
  * Navigation request forwarding to nested child navigators
  * Notify parent navigator of navigation activity
* Fix: URL not syncing without WidgetsApp

# 0.0.1
* Compact declaration syntax with predefined paths and pages
* Automatic parameter parsing from URI
* Declaratively set navigator page stack with `open()` and `openNamed()`
* Sync current path with platform (e.g. browser URL)
* Push pages to top of page stack
* Attach pageless routes to top page
