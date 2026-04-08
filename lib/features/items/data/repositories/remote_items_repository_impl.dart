import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/saved_item.dart';
import '../../domain/repositories/items_repository.dart';
import '../models/shared_item_dto.dart';

/// Repositório de itens de coleções compartilhadas via Supabase Realtime.
class RemoteItemsRepositoryImpl implements ItemsRepository {
  final SupabaseClient _client;

  RemoteItemsRepositoryImpl(this._client);

  String? get _userId => _client.auth.currentUser?.id;

  // Resolve UUIDs de added_by/purchased_by para display_name via profiles.
  Future<Map<String, String>> _resolveNames(List<String> userIds) async {
    if (userIds.isEmpty) return {};
    final rows = await _client
        .from('profiles')
        .select('id, display_name')
        .inFilter('id', userIds);
    return {for (final r in rows as List) r['id'] as String: r['display_name'] as String};
  }

  Future<List<SavedItem>> _mapRows(List rows) async {
    final ids = <String>{};
    for (final r in rows) {
      if (r['added_by'] != null) ids.add(r['added_by'] as String);
      if (r['purchased_by'] != null) ids.add(r['purchased_by'] as String);
    }
    final names = await _resolveNames(ids.toList());
    return rows
        .map((r) => SharedItemDto.fromJson(
              r,
              addedByName: r['added_by'] != null ? names[r['added_by']] : null,
              purchasedByName:
                  r['purchased_by'] != null ? names[r['purchased_by']] : null,
            ))
        .toList();
  }

  @override
  Future<List<SavedItem>> getByCollection(String collectionId) async {
    final rows = await _client
        .from('shared_items')
        .select()
        .eq('collection_id', collectionId)
        .order('created_at');
    return _mapRows(rows as List);
  }

  @override
  Future<SavedItem?> getById(String id) async {
    final row = await _client
        .from('shared_items')
        .select()
        .eq('id', id)
        .maybeSingle();
    if (row == null) return null;
    final names = await _resolveNames([
      if (row['added_by'] != null) row['added_by'] as String,
      if (row['purchased_by'] != null) row['purchased_by'] as String,
    ]);
    return SharedItemDto.fromJson(
      row,
      addedByName: row['added_by'] != null ? names[row['added_by']] : null,
      purchasedByName:
          row['purchased_by'] != null ? names[row['purchased_by']] : null,
    );
  }

  @override
  Future<void> save(SavedItem item) async {
    final userId = _userId;
    if (userId == null) return;

    // Se o item já existe → update; senão → insert
    final existing = await _client
        .from('shared_items')
        .select('id')
        .eq('id', item.id)
        .maybeSingle();

    if (existing == null) {
      await _client.from('shared_items').insert(
            SharedItemDto.toInsertJson(item: item, addedByUserId: userId),
          );
    } else {
      final purchasedBy =
          item.status == ItemStatus.purchased ? userId : null;
      await _client.from('shared_items').update(
            SharedItemDto.toUpdateJson(item: item, purchasedByUserId: purchasedBy),
          ).eq('id', item.id);
    }
  }

  @override
  Future<void> delete(String id) async {
    await _client.from('shared_items').delete().eq('id', id);
  }

  @override
  Stream<List<SavedItem>> watchByCollection(String collectionId) {
    // Supabase .stream() abre um canal Realtime. Se o JWT expirar enquanto o
    // canal estiver aberto, o Supabase lança RealtimeSubscribeException com
    // channelError/InvalidJWTToken. Relançamos a subscription automaticamente
    // após refreshar o token, sem propagar o erro para a UI.
    late StreamController<List<SavedItem>> controller;
    StreamSubscription? sub;

    void subscribe() {
      sub?.cancel();
      sub = _client
          .from('shared_items')
          .stream(primaryKey: ['id'])
          .eq('collection_id', collectionId)
          .order('created_at')
          .asyncMap((rows) => _mapRows(rows))
          .listen(
            (data) => controller.add(data),
            onError: (Object e) async {
              if (e is RealtimeSubscribeException) {
                await Future<void>.delayed(const Duration(seconds: 5));
                try {
                  await _client.auth.refreshSession();
                } catch (_) {}
                subscribe();
              } else {
                controller.addError(e);
              }
            },
          );
    }

    controller = StreamController<List<SavedItem>>(
      onListen: subscribe,
      onCancel: () => sub?.cancel(),
    );

    return controller.stream;
  }

  @override
  Future<List<SavedItem>> searchByName(String query) async {
    final rows = await _client
        .from('shared_items')
        .select()
        .ilike('name', '%$query%')
        .order('created_at');
    return _mapRows(rows as List);
  }
}
