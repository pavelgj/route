// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library route.client.template;

import 'dart:html';
import 'package:logging/logging.dart';
import 'client.dart';

final _logger = new Logger('route.template');

class TemplateRoutable implements Routable {
  final Element element;
  final Map<String, Element> routes = {};
  final Map<String, List<Routable>> routeRouters = {};
  String defaultToken;
  String _lastToken = '';
  
  TemplateRoutable(Element this.element);
  
  void setRouter(Router router) {
    _compile(router, [element], element, skipRoutable: true);
    router.onRoute.listen((RouteEvent e) {
      routes.keys.forEach((key){
        routes[key].style.display = 'none';
      });
      if (e.path == null) {
        router.propagate(null);
        return;
      }
      var tokens = e.path.split('/');
      var token = tokens[0];
      if (!routes.containsKey(token) && defaultToken != null) {
        token = defaultToken;
      }
      if (routes.containsKey(token)) {
        routes[token].style.display = '';
        var tail = tokens.length > 0 ? tokens.sublist(1).join('/') : '';
        var routables = routeRouters.containsKey(token) ? 
            routeRouters[token] : null;
        if (routables != null) {
          router.propagate(tail, routables: routables);
          if (routables != null) {
            List<Routable> toNull = [];
            routeRouters.keys.forEach((key) {
              if (key != token) {
                toNull.addAll(routeRouters[key]);
              }
            });
            if (toNull.length > 0) {
              router.propagate(null, routables: toNull);
            }
          }
        } else {
          router.propagate(null);
        }
      }
      _lastToken = token;
    });
  }
  
  String getPath(String childPath) {
    return '$_lastToken/$childPath';
  }
  
  void _compile(Router router, List<Element> children, Element root, {bool skipRoutable: false}) {
    for (var child in children) {
      if (!skipRoutable && _isRoutable(child)) {
        var routable = _getRoutable(child);
        router.addRoutable(routable);
        // now we walk up the tree and determine if we're in a route.
        var p = child.parent;
        var route;
        while (p!= null && p != root) {
          if (_isRoute(p) || _isDefaultRoute(child)) {
            if (!routeRouters.containsKey(_getRoute(p))) {
              routeRouters[_getRoute(p)] = [];
            }
            routeRouters[_getRoute(p)].add(routable);
          }
          p = p.parent;
        }
        continue; // we're done with this branch.
      }
      if (_isRoute(child) || _isDefaultRoute(child)) {
        _logger.finest('found route ${_getRoute(child)}');
        routes[_getRoute(child)] = child;
        child.style.display = 'none';
      }
      if (_isDefaultRoute(child)) {
        defaultToken = child.attributes['default-route'];
      }
      _compile(router, child.children, root);
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
  
  bool _isRoute(Element element) {
    return element.attributes.containsKey('route');
  }
  
  String _getRoute(Element element) {
    if (_isRoute(element)) {
      return element.attributes['route'];
    }
    if (_isDefaultRoute(element)) {
      return element.attributes['default-route'];
    }
    return null;
  }
  
  bool _isDefaultRoute(Element element) {
    return element.attributes.containsKey('default-route');
  }
}
