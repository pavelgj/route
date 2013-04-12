// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library route.client_test;

import 'package:unittest/unittest.dart';
import 'package:route/client.dart';
import 'package:route/url_pattern.dart';
import 'mocks.dart';

class RoutableOne implements Routable {
  Router _router;
  RoutableTwo two = new RoutableTwo();
  List<RouteEvent> routeEvents = <RouteEvent>[];
  List<Router> setRouterCalls = <Router>[];
  String lastPath;
  
  void setRouter(Router router) {
    setRouterCalls.add(router);
    _router = router;
    router.addRoutable(two);
    router.onRoute.listen((RouteEvent e) {
      routeEvents.add(e);
      lastPath = e.path;
      router.propagate(e.path.split('/').sublist(1).join('/'));
    });
  }
  
  String getPath(String childPath) {
    return "$lastPath/$childPath";
  }
}

class RoutableTwo implements Routable {
  Router _router;
  List<RouteEvent> routeEvents = <RouteEvent>[];
  List<Router> setRouterCalls = <Router>[];
  String lastPath;
  
  void setRouter(Router router) {
    setRouterCalls.add(router);
    _router = router;
    router.onRoute.listen((RouteEvent e) {
      routeEvents.add(e);
      lastPath = e.path;
    });
  }
  
  String getPath(String childPath) {
    return "$lastPath/$childPath";
  }
}

main() {
  test('handle', () {
    var router = new Router();
    var url1 = new UrlPattern(r'/');
    var url2 = new UrlPattern(r'/foo/(\d+)');
    var testPath = '/foo/123';

    router.addHandler(url1, (String path) {
      fail('should not have been called');
    });

    router.addHandler(url2, (String path) {
      expect(path, testPath);
    });

    router.route(testPath);
  });

  test('fragment', () {
    var router = new Router(useFragment: true);
    var url2 = new UrlPattern(r'/foo#(\d+)');

    var testPath = '/foo/123';
    var testPathFragment = '/foo#123';

    router.addHandler(url2, (String path) {
      // always expect the non-fragment path
      expect(path, testPath);
    });

    router.route(testPath);
    router.route(testPathFragment);
  });

  test('route event occurs', () {
    var one = new RoutableOne();
    Router router = new Router()
      ..addRoutable(one);
    router.route('foo');
    expect(one.routeEvents.length, equals(1));
    expect(one.routeEvents[0].path, equals('foo'));
    router.route('bar');
    expect(one.routeEvents.length, equals(2));
    expect(one.routeEvents[1].path, equals('bar'));
  });
  
  test('router set only once', () {
    var one = new RoutableOne();
    Router router = new Router()
      ..addRoutable(one);
    expect(one.setRouterCalls.length, equals(0));
    router.route('foo');
    expect(one.setRouterCalls.length, equals(1));
    router.route('bar');
    expect(one.setRouterCalls.length, equals(1));
  });

  test('useFragment:true go does location.assign/replace', () {
    var mockWindow = new MockWindow();
    var one = new RoutableOne();
    Router router = new Router(useFragment: true, win: mockWindow)
      ..addRoutable(one);
    router.route('foo');
    
    one._router.go('bar');
    expect(mockWindow.location.assignCalls.length, equals(1));
    expect(mockWindow.location.assignCalls[0], '#bar');
    expect(mockWindow.location.replaceCalls.length, equals(0));
    
    one._router.go('bar', replace: true);
    expect(mockWindow.location.replaceCalls.length, equals(1));
    expect(mockWindow.location.replaceCalls[0], '#bar');
    expect(mockWindow.location.assignCalls.length, equals(1));
  });

  test('useFragment:false go does history.pushState/replaceState', () {
    var mockWindow = new MockWindow();
    var one = new RoutableOne();
    Router router = new Router(win: mockWindow)
      ..addRoutable(one);
    router.route('foo');
    
    one._router.go('bar');
    expect(mockWindow.history.pushStateCalls.length, equals(1));
    expect(mockWindow.history.pushStateCalls[0], [null, '', 'bar']);
    expect(mockWindow.history.replaceStateCalls.length, equals(0));
    
    one._router.go('aux', replace: true);
    expect(mockWindow.history.replaceStateCalls.length, equals(1));
    expect(mockWindow.history.replaceStateCalls[0], [null, '', 'aux']);
    expect(mockWindow.history.pushStateCalls.length, equals(1));
  });

  test('one should propagate route', () {
    var mockWindow = new MockWindow();
    var one = new RoutableOne();
    Router router = new Router(win: mockWindow)
      ..addRoutable(one);
    
    router.route('foo/bar');
    expect(one.lastPath, equals('foo/bar'));
    expect(one.two.lastPath, equals('bar'));
    
    router.route('foo');
    expect(one.lastPath, equals('foo'));
    expect(one.two.lastPath, equals(''));
    
    router.route('foo/bar/aux');
    expect(one.lastPath, equals('foo/bar/aux'));
    expect(one.two.lastPath, equals('bar/aux'));
  });
}
