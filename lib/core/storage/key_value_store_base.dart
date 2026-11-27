abstract interface class KeyValueStore {
  String? read(String key);
  void write(String key, String value);
}
