library example;

import 'dart:html';
import 'package:route/url_pattern.dart';
import 'package:route/client.dart';
import 'package:logging/logging.dart';

final _logger = new Logger('');

final one = new UrlPattern('/one');
final two = new UrlPattern('/two');

main() {
  _logger.level = Level.FINEST;
  _logger.onRecord.listen((LogRecord lr) {
    print('[' + lr.level.name + '] ' +  lr.message);
  });

  query('#warning').remove();
  query('#one').classes.add('selected');
  
  var router = new Router()
    ..addHandler(one, showOne)
    ..addHandler(two, showTwo)
    ..listen();
}

void showOne(String path) {
  print("showOne");
  query('#one').classes.add('selected');
  query('#two').classes.remove('selected');
}

void showTwo(String path) {
  print("showTwo");
  query('#one').classes.remove('selected');
  query('#two').classes.add('selected');
}
