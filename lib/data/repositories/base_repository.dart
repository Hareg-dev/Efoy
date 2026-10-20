/// Common CRUD contract implemented by all Isar-backed repositories.
abstract class BaseRepository<T> {
  Future<T?> getById(int id);

  Future<List<T>> getAll();

  Future<T> create(T entity);

  Future<T> update(T entity);

  Future<void> delete(int id);
}
