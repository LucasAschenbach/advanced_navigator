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