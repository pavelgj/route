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
  Element defaultRoute;
  String _lastToken = '';
  
  TemplateRoutable(Element this.element);
  
  void setRouter(Router router) {
    _compile(router, [element], skipRoutable: true);
    router.onRoute.listen((RouteEvent e) {
      var tokens = e.path.split('/');
      var token = tokens[0];
      // TODO(pavelgj): do something smarter here.
      routes.keys.forEach((key){
        routes[key].style.display = 'none';
      });
      if (routes.containsKey(token)) {
        routes[token].style.display = '';
      } else if (defaultRoute != null) {
        defaultRoute.style.display = '';
      }
      if (tokens.length > 0) {
        router.propagate(tokens.sublist(1).join('/'));
      } else {
        router.propagate('');
      }
      _lastToken = token;
    });
  }
  
  String getPath(String childPath) {
    return '$_lastToken/$childPath';
  }
  
  void _compile(Router router, List<Element> children, {bool skipRoutable: false}) {
    for (var child in children) {
      if (!skipRoutable && _isRoutable(child)) {
        router.addRoutable(_getRoutable(child));
        continue;
      }
      if (_isRoute(child)) {
        _logger.finest('found route ${child.attributes['route']}');
        routes[child.attributes['route']] = child;
        child.style.display = 'none';
      }
      if (_isDefaultRoute(child)) {
        defaultRoute = child;
        if (child.attributes['default-route'] != '') {
          routes[child.attributes['default-route']] = child;
        }
        child.style.display = 'none';
      }
      _compile(router, child.children);
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
  
  bool _isDefaultRoute(Element element) {
    return element.attributes.containsKey('default-route');
  }
}
