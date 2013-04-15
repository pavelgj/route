// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test_mocks;

import 'dart:html';
import 'package:unittest/mock.dart';

class MockWindow extends Mock implements Window {
  History history = new MockHistory();
  Location location = new MockLocation();
  Document document = new MockDocument();
}

class MockDocument extends Mock implements HtmlDocument {}

class MockHistory extends Mock implements History {}

class MockLocation extends Mock implements Location {}

class MockElement extends Mock implements Element {
  Element parent;
  Map<String, String> attributes = {};
  List<Element> children;
  MockStyle style = new MockStyle();
  MockElement() {
    children = new MockChildren(this);
  }
}

class MockChildren implements List<Element> {
  Element parent;
  List<Element> list = [];
  MockChildren(this.parent);
  void add(Element e) {
    e.parent = parent;
    list.add(e);
  }
  
  void forEach(f) {
    list.forEach(f);
  }
  
  Iterator get iterator {
    return list.iterator;
  }
}

class MockStyle {
  Map<String, String> styles = {};
  dynamic noSuchMethod(InvocationMirror im) {
    if (im.isSetter) {
      var name = im.memberName.substring(0, im.memberName.length - 1);
      styles[name] = im.positionalArguments[0];
    }
    if (im.isGetter) {
      return styles[im.memberName];
    }
  }
}