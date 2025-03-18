class Preferences {
  final List<String> relays;

  Preferences({required this.relays});

  Preferences copyWith({List<String>? relays}) {
    return Preferences(relays: relays ?? this.relays);
  }
}
