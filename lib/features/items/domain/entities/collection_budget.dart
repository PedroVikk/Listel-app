import 'saved_item.dart';

class CollectionBudget {
  final double totalPending;
  final double totalPurchased;
  final double totalAll;
  final int itemsWithoutPrice;

  const CollectionBudget({
    required this.totalPending,
    required this.totalPurchased,
    required this.totalAll,
    required this.itemsWithoutPrice,
  });

  bool get hasAnyData => totalAll > 0 || itemsWithoutPrice > 0;

  factory CollectionBudget.fromItems(List<SavedItem> items) {
    double pending = 0;
    double purchased = 0;
    int withoutPrice = 0;

    for (final item in items) {
      if (item.price == null) {
        withoutPrice++;
      } else if (item.isPurchased) {
        purchased += item.price!;
      } else {
        pending += item.price!;
      }
    }

    return CollectionBudget(
      totalPending: pending,
      totalPurchased: purchased,
      totalAll: pending + purchased,
      itemsWithoutPrice: withoutPrice,
    );
  }
}
