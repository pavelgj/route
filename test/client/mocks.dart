// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test_mocks;

import 'dart:html';

class MockWindow {
  MockDocument document = new MockDocument();
  MockHistory history = new MockHistory();
  MockLocation location = new MockLocation();
}

class MockDocument implements HtmlDocument {
  List titleSetCalls = [];
  List titleGetCalls = [];
  String _title;
  String set title(title) {
    _title = title;
    titleSetCalls.add(title);
  }
  String get title {
    titleGetCalls.add(title);
    return _title;
  }
}

class MockHistory {
  List replaceStateCalls = [];
  List pushStateCalls = [];
  void replaceState(Object data, String title, String url) {
    replaceStateCalls.add([data, title, url]);
  }
  void pushState(Object data, String title, String url) {
    pushStateCalls.add([data, title, url]);
  }
}

class MockLocation {
  List replaceCalls = [];
  List assignCalls = [];
  void replace(String url) {
    replaceCalls.add(url);
  }
  void assign(String url) {
    assignCalls.add(url);
  }
}
