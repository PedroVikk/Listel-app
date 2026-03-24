import '../entities/collection.dart';

abstract interface class CollectionsRepository {
  Future<List<Collection>> getAll();
  Future<Collection?> getById(String id);
  Future<void> save(Collection collection);
  Future<void> delete(String id);
  Stream<List<Collection>> watchAll();
}
