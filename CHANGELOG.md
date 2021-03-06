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