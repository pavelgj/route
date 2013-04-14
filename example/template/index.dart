library template_example;

import 'dart:html';
import 'package:route/client.dart';
import 'package:logging/logging.dart';

final _logger = new Logger('');

main() {
  _logger.level = Level.FINEST;
  _logger.onRecord.listen((LogRecord lr) {
    print('[' + lr.level.name + '] ' +  lr.message);
  });
  
  Router router = new Router(useFragment: true)
    ..addRoutable(new TemplateRoutable(query('#root')))
    ..listen();
}

