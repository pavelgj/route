// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library route.template_test;

import 'dart:html';
import 'dart:async';
import 'package:unittest/unittest.dart';
import 'package:unittest/mock.dart';
import 'package:route/client.dart';
import 'package:route/template.dart';
import 'mocks.dart';

Element findElementById(Element root, String id) {
  return findElement(root, (Element e) {
    return e.attributes.containsKey('id') && e.attributes['id'] == id;
  });
}

Element findElement(Element e, Function check) {
  if (check(e)) {
    return e;
  }
  Element found = null;
  e.children.forEach((ee){
    if (found == null) {
      found = findElement(ee, check);
    }
  });
  return found;
}

Element div([Map attributes, List children]) {
  Element e = new MockElement();
  e.attributes = attributes != null ? attributes : {};
  e.children = children != null ? children : [];
  return e;
}

main() {
  test('basic template', () {
    Element root = div({'routable': ''}, [
      div({'route': 'a1', 'id': 'a1'}, [
        div({'routable': ''}, [
          div({'route': 'b1', 'id': 'a1-b1'}),
          div({'route': 'b2', 'id': 'a1-b2'}),
          div({'default-route': 'c', 'id': 'a1-c'}),
        ])
      ]),
      div({'route': 'a2', 'id': 'a2'}, [
        div({'routable': ''}, [
          div({'route': 'b2', 'id': 'a2-b2'}),
          div({'route': 'b3', 'id': 'a2-b3'}),
          div({'route': 'b4', 'id': 'a2-b4'}),
          div({'default-route': 'c', 'id': 'a2-c'}),
        ])
      ])
    ]);
    
    var a1 = findElementById(root, 'a1');
    var a2 = findElementById(root, 'a2');
    var a1b1 = findElementById(root, 'a1-b1');
    var a1b2 = findElementById(root, 'a1-b2');
    var a1c = findElementById(root, 'a1-c');
    var a2b2 = findElementById(root, 'a2-b2');
    var a2b3 = findElementById(root, 'a2-b3');
    var a2b4 = findElementById(root, 'a2-b4');
    var a2c = findElementById(root, 'a2-c');
    
    expect(a1b1.style.display, equals(null));
    expect(a1b2.style.display, equals(null));
    expect(a1c.style.display, equals(null));
    expect(a2b2.style.display, equals(null));
    expect(a2b3.style.display, equals(null));
    expect(a2b4.style.display, equals(null));
    expect(a2c.style.display, equals(null));
    
    Router router = new Router(useFragment: true)
      ..addRoutable(new TemplateRoutable(root));

    router.route('a1/b1');

    expect(a1.style.display, equals(''));
    expect(a2.style.display, equals('none'));
    expect(a1b1.style.display, equals(''));
    expect(a1b2.style.display, equals('none'));
    expect(a1c.style.display, equals('none'));
    expect(a2b2.style.display, equals('none'));
    expect(a2b3.style.display, equals('none'));
    expect(a2b4.style.display, equals('none'));
    expect(a2c.style.display, equals('')); // fix?

    router.route('a1/b2');

    expect(a1.style.display, equals(''));
    expect(a2.style.display, equals('none'));
    expect(a1b1.style.display, equals('none'));
    expect(a1b2.style.display, equals(''));
    expect(a1c.style.display, equals('none'));
    expect(a2b2.style.display, equals('')); // fix?
    expect(a2b3.style.display, equals('none'));
    expect(a2b4.style.display, equals('none'));
    expect(a2c.style.display, equals('none'));

    router.route('a2/b1');

    expect(a1.style.display, equals('none'));
    expect(a2.style.display, equals(''));
    expect(a1b1.style.display, equals('')); // fix?
    expect(a1b2.style.display, equals('none'));
    expect(a1c.style.display, equals('none'));
    expect(a2b2.style.display, equals('none'));
    expect(a2b3.style.display, equals('none'));
    expect(a2b4.style.display, equals('none'));
    expect(a2c.style.display, equals('')); // fix?

    router.route('a2/b4');

    expect(a1.style.display, equals('none'));
    expect(a2.style.display, equals(''));
    expect(a1b1.style.display, equals('none'));
    expect(a1b2.style.display, equals('none'));
    expect(a1c.style.display, equals('')); // fix?
    expect(a2b2.style.display, equals('none'));
    expect(a2b3.style.display, equals('none'));
    expect(a2b4.style.display, equals(''));
    expect(a2c.style.display, equals('none'));

    // The following ones are odd!!!!!!!!!
    router.route('garbage/b4');

    expect(a1.style.display, equals('none'));
    expect(a2.style.display, equals('none'));
    expect(a1b1.style.display, equals('none'));
    expect(a1b2.style.display, equals('none'));
    expect(a1c.style.display, equals('')); // fix?
    expect(a2b2.style.display, equals('none'));
    expect(a2b3.style.display, equals('none'));
    expect(a2b4.style.display, equals(''));
    expect(a2c.style.display, equals('none'));
    
    router.route('a1/b4');

    expect(a1.style.display, equals(''));
    expect(a2.style.display, equals('none'));
    expect(a1b1.style.display, equals('none'));
    expect(a1b2.style.display, equals('none'));
    expect(a1c.style.display, equals('')); // fix?
    expect(a2b2.style.display, equals('none'));
    expect(a2b3.style.display, equals('none'));
    expect(a2b4.style.display, equals(''));
    expect(a2c.style.display, equals('none'));
  });
}
