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
  Map<String, String> attributes = {};
  List<Element> children = [];
  MockStyle style = new MockStyle();
}

class MockStyle {
  Map<String, String> styles = {};
  dynamic noSuchMethod(InvocationMirror im) {
    if (im.isSetter) {
      styles[im.memberName.substring(0, im.memberName.length - 1)] = im.positionalArguments[0];
    }
    if (im.isGetter) {
      return styles[im.memberName];
    }
  }
}