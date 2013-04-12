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
  final Map<UrlPattern, Handler> _handlers;
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
        _handlers = new Map<UrlPattern, Handler>(),
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

  void addHandler(UrlPattern pattern, Handler handler) {
    _handlers[pattern] = handler;
  }
  
  UrlPattern _getUrl(path) => _handlers.keys.firstWhere((url) => 
      url.matches(path), orElse: () => null);
        
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
  void _handle(String path) {
    var url = _getUrl(path);
    if (url != null) {
      // always give handlers a non-fragment path
      var fixedPath = url.reverse(url.parse(path));
      _handlers[url](fixedPath);
    }
  }
      
  void route(String path) {
    _logger.finest('route $path');
    _handle(path);
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
  
  /**
   * Listens for window history events and invokes the router. On older
   * browsers the hashChange event is used instead.
   */
  void listen({bool ignoreClick: false}) {
    _logger.finest('listen $ignoreClick');
    if (_parentRouter != null) {
      throw new StateError('Can only listen on root router.');
    }
    if (useFragment) {
      window.onHashChange.listen((_) =>
          route('${window.location.pathname}#${window.location.hash}'));;
    } else {
      window.onPopState.listen((_) => route(window.location.pathname));
    }
    if (!ignoreClick) {
      window.onClick.listen((e) {
        if (e.target is AnchorElement) {
          AnchorElement anchor = e.target;
          if (anchor.host == window.location.host) {
            var fragment = (anchor.hash == '') ? '' : '#${anchor.hash}'; 
            e.preventDefault();
            _go("${anchor.pathname}$fragment", title: anchor.title);
            route("${anchor.pathname}$fragment");
          }
        }
      });
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
