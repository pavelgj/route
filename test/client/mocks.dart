// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test_mocks;

import 'dart:html';
import 'package:unittest/mock.dart';

class MockWindow extends Mock implements Window {
  MockWindow() {
    this.when(callsTo('get history')).alwaysReturn(new MockHistory());
    this.when(callsTo('get location')).alwaysReturn(new MockLocation());
    this.when(callsTo('get document')).alwaysReturn(new MockDocument());
  }
}

class MockDocument extends Mock implements HtmlDocument {
}

class MockHistory extends Mock implements History {
}

class MockLocation extends Mock implements Location {
}
