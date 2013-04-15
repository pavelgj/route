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
  final List<Tuple<Router, Routable>> _childRouters;
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
      : _childRouters = <Tuple<Router, Routable>>[],
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
    _childRouters.add(new Tuple(childRouter, routable));
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
   * Propagates the given path to child routables.
   */
  void propagate(String path, {List<Routable> routables}) {
    _logger.finest('propagate $path');
    _childRouters.forEach((Tuple<Router, Routable> r) {
      if (routables == null || routables.contains(r.second)) {
        r.first.route(path);
      }
    });
  }

  /**
   * TODO: doc
   */
  void go(String newToken, {bool replace: false}) {
    var p = _parentRouter;
    var url = newToken;
    while(p != null) {
      url = p.host.getPath(url);
      p = p._parentRouter;
    }
    _go(url, replace: replace);
    _rootRouter.route(url);
  }

  Router get _rootRouter {
    var p = _parentRouter;
    while(p != null) {
      if (p._parentRouter == null) {
        return p;
      }
      p = p._parentRouter;
    }
    return null;
  }
  
  void _go(String path, {String title, bool replace: false}) {
    _logger.finest('_go $path');
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
    if (_parentRouter != null) {
      throw new StateError('Can only listen on root router.');
    }
    window.onPopState.listen((_) {
      if (useFragment) {
        var hash = window.location.hash;
        route(hash.startsWith('#') ? hash.substring(1) : hash);
      } else {
        route(window.location.pathname);
      }
    });
    if (!ignoreClick) {
      window.onClick.listen((e) {
        if (e.target is AnchorElement) {
          AnchorElement anchor = e.target;
          if (anchor.host == window.location.host) {
            e.preventDefault();
            var href = anchor.attributes['href'];
            if (useFragment && href.startsWith('#')) {
              href = href.substring(1);
            }
            _go(href, title: anchor.title);
            route(href);
          }
        }
      });
    }
  }
}

class Tuple<T1, T2> {
  final T1 first;
  final T2 second;
  Tuple(this.first, this.second);
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
