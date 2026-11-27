import 'key_value_store_base.dart';

KeyValueStore createKeyValueStore() => MemoryKeyValueStore();

class MemoryKeyValueStore implements KeyValueStore {
  final Map<String, String> _values = {};
  @override
  String? read(String key) => _values[key];
  @override
  void write(String key, String value) => _values[key] = value;
}
