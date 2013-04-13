library basic_routable;

import 'dart:html';
import 'package:route/client.dart';
import 'package:logging/logging.dart';

final _logger = new Logger('');

class RoutableOne implements Routable {
  String lastToken;
  
  void setRouter(Router router) {
    router.addRoutable(new RoutableTwo());
    router.onRoute.listen((RouteEvent e) {
      var tokens = e.path.split('/');
      lastToken = tokens.length > 1 ? tokens[1] : null;
      
      _routeHelper(lastToken, tokens.sublist(1), router, e, 'a');
    });
  }
  
  String getPath(String childPath) {
    return "/$lastToken/$childPath";
  }
}

class RoutableTwo implements Routable {
  String lastToken;
  Router router;
  
  RoutableTwo() {
    query('#go-b2').onClick.listen((_){
      router.go('b2');
    });
  }

  void setRouter(Router router) {
    this.router = router;
    router.addRoutable(new RoutableThree());
    router.onRoute.listen((RouteEvent e) {
      var tokens = e.path.split('/');
      lastToken = tokens.length > 0 ? tokens[0] : null;
      
      _routeHelper(lastToken, tokens, router, e, 'b1');
      _routeHelper(lastToken, tokens, router, e, 'b2');
    });
  }
  
  String getPath(String childPath) {
    return "$lastToken/$childPath";
  }
}

class RoutableThree implements Routable {
  String lastToken;
  
  void setRouter(Router router) {
    router.onRoute.listen((RouteEvent e) {
      var tokens = e.path.split('/');
      lastToken = tokens.length > 0 ? tokens[0] : null;
      
      _routeHelper(lastToken, tokens, router, e, 'c1');
      _routeHelper(lastToken, tokens, router, e, 'c2');
      _routeHelper(lastToken, tokens, router, e, 'c3');
      _routeHelper(lastToken, tokens, router, e, 'c4');
    });
  }
  
  String getPath(String childPath) {
    return "$lastToken/$childPath";
  }
}

/**
 * A helper method that changes visiblity for [match] depending on the token
 * value. It also propagates the "tail" the token to child routables.
 */
void _routeHelper(String token, List<String> tokens, Router router,
                  RouteEvent e, String match) {
  query('#section-' + match).style.display = (token == match) ? "block" : "none";
  if (tokens.length > 0) {
    router.propagate(tokens.sublist(1).join('/'));
  } else {
    router.propagate('');
  }
}

main() {
  _logger.level = Level.FINEST;
  _logger.onRecord.listen((LogRecord lr) {
    print('[' + lr.level.name + '] ' +  lr.message);
  });
  
  Router router = new Router(useFragment: false)
    ..addRoutable(new RoutableOne())
    ..listen();
}