import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';

/// Singleton manager for Google Play / App Store in-app purchases.
///
/// Works gracefully when the store is unavailable (emulators, debug builds).
class BillingManager {
  static final BillingManager _instance = BillingManager._();
  static BillingManager get instance => _instance;
  BillingManager._();

  final InAppPurchase _iap = InAppPurchase.instance;
  bool _available = false;
  List<ProductDetails> _products = [];
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  // ── Product IDs ──────────────────────────────────────────────────────
  static const starterBundleId = 'starter_bundle';
  static const coinsSmallId = 'coins_small'; // 500 coins
  static const coinsMediumId = 'coins_medium'; // 1500 coins
  static const coinsLargeId = 'coins_large'; // 5000 coins

  static const _allProductIds = {
    starterBundleId,
    coinsSmallId,
    coinsMediumId,
    coinsLargeId,
  };

  bool get isAvailable => _available;
  List<ProductDetails> get products => _products;

  ProductDetails? productById(String id) {
    for (final p in _products) {
      if (p.id == id) return p;
    }
    return null;
  }

  // ── Init ─────────────────────────────────────────────────────────────
  Future<void> init() async {
    try {
      _available = await _iap.isAvailable();
    } catch (_) {
      _available = false;
    }
    if (!_available) return;

    final response = await _iap.queryProductDetails(_allProductIds);
    _products = response.productDetails;

    // Listen to purchase updates
    _subscription = _iap.purchaseStream.listen(_handlePurchaseUpdates);
  }

  void dispose() {
    _subscription?.cancel();
  }

  // ── Purchase handling ────────────────────────────────────────────────
  void _handlePurchaseUpdates(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        _deliverProduct(purchase);
        if (purchase.pendingCompletePurchase) {
          _iap.completePurchase(purchase);
        }
      }
      // Error / canceled — nothing to do
    }
  }

  void _deliverProduct(PurchaseDetails purchase) {
    _onPurchaseDelivered?.call(purchase.productID);
  }

  Function(String productId)? _onPurchaseDelivered;

  /// Set a callback that will be invoked when a purchase is successfully
  /// delivered. Wire this to [PlayerProgressNotifier.deliverIAP].
  void setDeliveryCallback(Function(String) callback) {
    _onPurchaseDelivered = callback;
  }

  // ── Buy ──────────────────────────────────────────────────────────────
  Future<bool> buyProduct(ProductDetails product) async {
    if (!_available) return false;
    final purchaseParam = PurchaseParam(productDetails: product);

    // Non-consumables: starter_bundle (the only non-consumable in v1.0).
    if (product.id == starterBundleId) {
      return _iap.buyNonConsumable(purchaseParam: purchaseParam);
    }
    // Consumables: coin packs
    return _iap.buyConsumable(purchaseParam: purchaseParam);
  }

  // ── Restore ──────────────────────────────────────────────────────────
  Future<void> restorePurchases() async {
    if (!_available) return;
    await _iap.restorePurchases();
  }
}
