import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ListViewMode { galeria, shopping, vitrine }

extension ListViewModeExt on ListViewMode {
  String get label => switch (this) {
        ListViewMode.galeria => 'Galeria',
        ListViewMode.shopping => 'Shopping',
        ListViewMode.vitrine => 'Vitrine',
      };

  String get emoji => switch (this) {
        ListViewMode.galeria => '🗂️',
        ListViewMode.shopping => '🛍️',
        ListViewMode.vitrine => '✨',
      };

  ListViewMode get next =>
      ListViewMode.values[(index + 1) % ListViewMode.values.length];
}

final listViewModeProvider =
    StateProvider<ListViewMode>((ref) => ListViewMode.galeria);
