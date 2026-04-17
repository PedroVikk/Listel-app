import '../entities/saved_item.dart';

abstract interface class ItemsRepository {
  Future<List<SavedItem>> getByCollection(String collectionId);
  Future<SavedItem?> getById(String id);
  Future<void> save(SavedItem item);
  Future<void> delete(String id);
  Future<void> reorder(List<String> orderedIds);
  Stream<List<SavedItem>> watchByCollection(String collectionId);
  Future<List<SavedItem>> searchByName(String query);
}
