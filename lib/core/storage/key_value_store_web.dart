// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;

import 'key_value_store_base.dart';

KeyValueStore createKeyValueStore() => BrowserKeyValueStore();

class BrowserKeyValueStore implements KeyValueStore {
  @override
  String? read(String key) => html.window.localStorage[key];
  @override
  void write(String key, String value) => html.window.localStorage[key] = value;
}
