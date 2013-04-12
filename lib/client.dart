// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library route.client;

import 'dart:async';
import 'dart:html';
import 'package:logging/logging.dart';
import 'url_pattern.dart';

final _logger = new Logger('route');

typedef Handler(String path);

typedef void EventHandler(Event e);

/**
 * Basic routable interface that web-components can implement to implement
 * custom routing behavior.
 */
abstract class Routable {
  void setRouter(Router router);
  String getPath(String childPath);
}

class RouteEvent {
  String path;
  RouteEvent(this.path);
}

/**
 * Stores a set of [UrlPattern] to [Handler] associations and provides methods
 * for calling a handler for a URL path, listening to [Window] history events,
 * and creating HTML event handlers that navigate to a URL.
 */
class Router {
  final List<Router> _childRouters;
  final Router _parentRouter;
  final bool useFragment;
  final Routable host;
  final StreamController<RouteEvent> _onRouteController;
  final StreamController<RouteEvent> _onLeaveController;
  // TODO: these should be final!
  Stream<RouteEvent> onRoute;
  Stream<RouteEvent> onLeave;
  bool _hostRouterSet = false;
  dynamic win;

  /**
   * [useFragment] determines whether this Router uses pure paths with
   * [History.pushState] or paths + fragments and [Location.assign]. The default
   * value is null which then determines the behavior based on
   * [History.supportsState].
   */
  Router({Router parentRouter, Routable host, bool useFragment, dynamic win})
      : _childRouters = <Router>[],
        _parentRouter = parentRouter,
        host = (host == null) ? new PropagatingRoutable() : host,
        useFragment = (useFragment == null)
            ? !History.supportsState
            : useFragment,
        _onRouteController = new StreamController<RouteEvent>.broadcast(),
        _onLeaveController = new StreamController<RouteEvent>.broadcast(),
        this.win = win == null ? window : win {
    onRoute = _onRouteController.stream;
    onLeave = _onLeaveController.stream;
  }

  void addRoutable(Routable routable) {
    Router childRouter = new Router(parentRouter: this, host: routable,
        useFragment: useFragment, win: win);
    _childRouters.add(childRouter);
  }

  /**
   * Finds a matching [UrlPattern] added with [addHandler], parses the path
   * and invokes the associated callback.
   *
   * This method does not perform any navigation, [go] should be used for that.
   * This method is used to invoke a handler after some other code navigates the
   * window, such as [listen].
   *
   * If the UrlPattern contains a fragment (#), the handler is always called
   * with the path version of the URL by convertins the # to a /.
   */
  void route(String path) {
    _logger.finest('route $path');
    if (!_hostRouterSet && host != null) {
      host.setRouter(this);
      _hostRouterSet = true;
    }
    _onRouteController.add(new RouteEvent(path));
  }
  
  /**
   * Propagates the given path to all child routables.
   */
  void propagate(String path) {
    _logger.finest('propagate $path');
    _childRouters.forEach((r) {
      r.route(path);
    });
  }

  void go(String newToken, {bool replace: false}) {
    var p = _parentRouter;
    var url = newToken;
    while(p != null) {
      url = p.host.getPath(url);
      p = p._parentRouter;
    }
    _go(url, replace: replace);
  }

  void _go(String path, {String title, bool replace: false}) {
    title = (title == null) ? '' : title;
    if (useFragment) {
      if (replace) {
        win.location.replace('#' + path);
      } else {
        win.location.assign('#' + path);
      }
      (win.document as HtmlDocument).title = title;
    } else {
      if (replace) {
        win.history.replaceState(null, title, path);
      } else {
        win.history.pushState(null, title, path);
      }
    }
  }
}

/**
 * Simple routable implementation that propagates routes to its children.
 */
class PropagatingRoutable implements Routable {
  void setRouter(Router router) {
    router.onRoute.listen((RouteEvent e) {
      router.propagate(e.path);
    }); 
  }

  String getPath(String childPath) {
    return childPath;
  }
}

class TemplateRoutable implements Routable {
  final Element element;
  
  TemplateRoutable(Element this.element) {
  }
  
  void setRouter(Router router) {
    _compile(router, [element]);
  }

  String getPath(String childPath) {
    return childPath;
  }
  
  void _compile(Router router, List<Element> children) {
    for (var child in children) {
      if (_isRoutable(child)) {
        router.addRoutable(_getRoutable(child));
      } else {
        _compile(router, child.children);
      }
    }
  }
  
  Routable _getRoutable(Element element) {
    if (element.xtag != null && element.xtag is Routable) {
      return element.xtag;
    }
    return new TemplateRoutable(element);
  }
  
  bool _isRoutable(Element element) {
    return element.xtag != null && element.xtag is Routable || 
        element.attributes.containsKey('routable');
  }
}

class RouterUtils {
  List<Routable> _routables;
  final bool useFragment;
  
  /**
   * [useFragment] determines whether this Router uses pure paths with
   * [History.pushState] or paths + fragments and [Location.assign]. The default
   * value is null which then determines the behavior based on
   * [History.supportsState].
   */
  RouterUtils({bool useFragment})
      : _routables = <Routable>[],
        useFragment = (useFragment == null)
            ? !History.supportsState
            : useFragment;

  
  /**
   * Listens for window history events and invokes the router. On older
   * browsers the hashChange event is used instead.
   */
  void listen({bool ignoreClick: false}) {
    if (useFragment) {
      window.onHashChange.listen((_) =>
          handle('${window.location.pathname}#${window.location.hash}'));
    } else {
      window.onPopState.listen((_) => handle(window.location.pathname));
    }
    if (!ignoreClick) {
      window.onClick.listen((e) {
        if (e.target is AnchorElement) {
          AnchorElement anchor = e.target;
          if (anchor.host == window.location.host) {
            var fragment = (anchor.hash == '') ? '' : '#${anchor.hash}'; 
            gotoPath("${anchor.pathname}$fragment", anchor.title);
            e.preventDefault();
          }
        }
      });
    }
  }
  
  /**
   * Returns an [Event] handler suitable for use as a click handler on [:<a>;]
   * elements. The handler reverses [ur] with [args] and uses [window.pushState]
   * with [title] to change the user visible URL without navigating to it.
   * [Event.preventDefault] is called to stop the default behavior. Then the
   * handler associated with [url] is invoked with [args].
   */
  EventHandler clickHandler(UrlPattern url, List args, String title) =>
      (Event e) {
        e.preventDefault();
        gotoUrl(url, args, title);
      };
}
