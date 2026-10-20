/// Thrown when a sale or restock cannot be completed because a product no
/// longer has enough stock.
class InsufficientStockException implements Exception {
  InsufficientStockException({
    required this.productName,
    required this.requested,
    required this.available,
  });

  final String productName;
  final int requested;
  final int available;

  @override
  String toString() {
    return 'Not enough stock for "$productName": '
        'requested $requested, available $available.';
  }
}

/// Thrown when a repository operation is invalid.
class RepositoryException implements Exception {
  RepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}
