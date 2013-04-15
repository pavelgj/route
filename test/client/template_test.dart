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
      ]),
      div({'default-route': 'a3', 'id': 'a3'})
    ]);
    
    var a1 = findElementById(root, 'a1');
    var a2 = findElementById(root, 'a2');
    var a3 = findElementById(root, 'a3');
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

    expectVisible(a1);
    expectHidden(a2);
    expectHidden(a3);
    expectVisible(a1b1);
    expectHidden(a1b2);
    expectHidden(a1c);
    expectHidden(a2b2);
    expectHidden(a2b3);
    expectHidden(a2b4);
    expectHidden(a2c);

    router.route('a1/b2');

    expectVisible(a1);
    expectHidden(a2);
    expectHidden(a3);
    expectHidden(a1b1);
    expectVisible(a1b2);
    expectHidden(a1c);
    expectHidden(a2b2);
    expectHidden(a2b3);
    expectHidden(a2b4);
    expectHidden(a2c);

    router.route('a2/b1');

    expectHidden(a1);
    expectVisible(a2);
    expectHidden(a3);
    expectHidden(a1b1);
    expectHidden(a1b2);
    expectHidden(a1c);
    expectHidden(a2b2);
    expectHidden(a2b3);
    expectHidden(a2b4);
    expectVisible(a2c);

    router.route('a2/b4');

    expectHidden(a1);
    expectVisible(a2);
    expectHidden(a3);
    expectHidden(a1b1);
    expectHidden(a1b2);
    expectHidden(a1c);
    expectHidden(a2b2);
    expectHidden(a2b3);
    expectVisible(a2b4);
    expectHidden(a2c);

    router.route('garbage/b4');

    expectHidden(a1);
    expectHidden(a2);
    expectVisible(a3);
    expectHidden(a1b1);
    expectHidden(a1b2);
    expectHidden(a1c);
    expectHidden(a2b2);
    expectHidden(a2b3);
    expectHidden(a2b4);
    expectHidden(a2c);
    
    router.route('a1/b4');

    expectVisible(a1);
    expectHidden(a2);
    expectHidden(a1b1);
    expectHidden(a1b2);
    expectVisible(a1c);
    expectHidden(a2b2);
    expectHidden(a2b3);
    expectHidden(a2b4);
    expectHidden(a2c);
  });
}

void expectVisible(Element e) {
  expect(e.style.display, equals(''));
}

void expectHidden(Element e) {
  expect(e.style.display, equals('none'));
}

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
  if (children != null) {
    children.forEach((c){
      e.children.add(c);
    });
  }
  return e;
}
