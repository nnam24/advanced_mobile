import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:final_application/services/subscription_service.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class IAPService {
  // Product IDs
  static const String _proMonthlyId = 'pro_monthly_subscription';
  static const String _proYearlyId = 'pro_yearly_subscription';
  static const String _tokens10Id = 'tokens_10_pack';
  static const String _tokens50Id = 'tokens_50_pack';
  static const String _tokens100Id = 'tokens_100_pack';

  // Set of all product IDs
  static const Set<String> _productIds = {
    _proMonthlyId,
    _proYearlyId,
    _tokens10Id,
    _tokens50Id,
    _tokens100Id,
  };

  // Instance of IAP
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;

  // Stream subscription for purchase updates
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  // Available products
  List<ProductDetails> _products = [];

  // Flag to indicate if IAP is initialized
  bool _isInitialized = false;

  // Singleton pattern with proper initialization
  static IAPService? _instance;
  static IAPService get instance {
    _instance ??= IAPService._internal();
    return _instance!;
  }

  factory IAPService() => instance;

  IAPService._internal();

  // Subscription service
  final SubscriptionService _subscriptionService = SubscriptionService();

  // Products getter
  List<ProductDetails> get products => _products;
  bool get isInitialized => _isInitialized;

  // Initialize the service
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      // Skip IAP initialization in debug mode to avoid issues during development
      if (kDebugMode) {
        print('IAP disabled in debug mode');
        _isInitialized = true;
        return;
      }

      // Check if IAP is available
      final bool available = await _inAppPurchase.isAvailable();
      if (!available) {
        print('In-app purchases not available');
        _isInitialized = true;
        return;
      }

      // Set up the subscription to listen for purchase updates
      _subscription = _inAppPurchase.purchaseStream.listen(
        _handlePurchaseUpdate,
      );

      // Load the products
      await _loadProducts();

      _isInitialized = true;
    } catch (e) {
      print('Error initializing IAP service: $e');
      _isInitialized = false;
    }
  }

  // Load available products
  Future<void> _loadProducts() async {
    try {
      final ProductDetailsResponse response = await _inAppPurchase
          .queryProductDetails(_productIds);

      if (response.notFoundIDs.isNotEmpty) {
        print('Some products not found: ${response.notFoundIDs}');
      }

      _products = response.productDetails;
    } catch (e) {
      print('Error loading products: $e');
    }
  }

  // Handle purchase updates
  void _handlePurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        // Handle pending purchases
      } else if (purchaseDetails.status == PurchaseStatus.purchased ||
          purchaseDetails.status == PurchaseStatus.restored) {
        _deliverProduct(purchaseDetails);
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        print('Error: ${purchaseDetails.error}');
      }

      if (purchaseDetails.pendingCompletePurchase) {
        _inAppPurchase.completePurchase(purchaseDetails);
      }
    }
  }

  // Deliver the purchased product
  void _deliverProduct(PurchaseDetails purchaseDetails) {
    final String productId = purchaseDetails.productID;

    switch (productId) {
      case _proMonthlyId:
        _subscriptionService.upgradeToPro(
          expiryDate: DateTime.now().add(const Duration(days: 30)),
        );
        break;

      case _proYearlyId:
        _subscriptionService.upgradeToPro(
          expiryDate: DateTime.now().add(const Duration(days: 365)),
        );
        break;

      case _tokens10Id:
        _subscriptionService.addTokens(10);
        break;

      case _tokens50Id:
        _subscriptionService.addTokens(50);
        break;

      case _tokens100Id:
        _subscriptionService.addTokens(100);
        break;
    }
  }

  // Purchase a product
  Future<bool> buyProduct(ProductDetails product) async {
    if (!_isInitialized) {
      print('IAP service not initialized');
      return false;
    }

    try {
      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: product,
      );

      if (product.id == _proMonthlyId || product.id == _proYearlyId) {
        return await _inAppPurchase.buyNonConsumable(
          purchaseParam: purchaseParam,
        );
      } else {
        return await _inAppPurchase.buyConsumable(purchaseParam: purchaseParam);
      }
    } catch (e) {
      print('Error purchasing product: $e');
      return false;
    }
  }

  // Restore purchases
  Future<void> restorePurchases() async {
    if (!_isInitialized) {
      print('IAP service not initialized');
      return;
    }

    try {
      await _inAppPurchase.restorePurchases();
    } catch (e) {
      print('Error restoring purchases: $e');
    }
  }

  // Dispose of resources
  void dispose() {
    _subscription?.cancel();
  }
}
