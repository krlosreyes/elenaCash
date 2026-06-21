import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../shared/providers/firebase_providers.dart';

part 'subscription_provider.g.dart';

// ── CustomerInfo stream ───────────────────────────────────────────
// purchases_flutter v10 no expone un Stream directamente.
// Usamos addCustomerInfoUpdateListener + StreamController.

@riverpod
Stream<CustomerInfo> customerInfoStream(Ref ref) {
  if (kIsWeb) return const Stream.empty();

  final controller = StreamController<CustomerInfo>.broadcast();

  void listener(CustomerInfo info) {
    if (!controller.isClosed) controller.add(info);
  }

  Purchases.addCustomerInfoUpdateListener(listener);

  ref.onDispose(() {
    Purchases.removeCustomerInfoUpdateListener(listener);
    controller.close();
  });

  return controller.stream;
}

// ── Offerings (packages disponibles para compra) ──────────────────

@riverpod
Future<Offerings?> purchaseOfferings(Ref ref) async {
  if (kIsWeb) return null;
  try {
    return await Purchases.getOfferings();
  } catch (_) {
    return null;
  }
}

// ── Notifier — compra y restauración ─────────────────────────────

@riverpod
class SubscriptionNotifier extends _$SubscriptionNotifier {
  @override
  AsyncValue<String?> build() => const AsyncData(null);

  /// Intenta comprar un package de RevenueCat.
  /// Devuelve true si la compra fue exitosa.
  Future<bool> purchase(Package package) async {
    state = const AsyncLoading();
    try {
      // purchasePackage devuelve PurchaseResult, no CustomerInfo
      final result = await Purchases.purchasePackage(package);
      final customerInfo = result.customerInfo;
      final isActive = _isEntitlementActive(customerInfo);
      if (isActive) {
        await _syncPremiumToFirestore(isPremium: true);
      }
      state = const AsyncData(null);
      return isActive;
    } on PlatformException catch (e) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
        // El usuario canceló — no es un error real
        state = const AsyncData(null);
        return false;
      }
      state = AsyncError(e, StackTrace.current);
      return false;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  /// Restaura compras anteriores.
  /// restorePurchases() devuelve CustomerInfo directamente.
  Future<bool> restore() async {
    state = const AsyncLoading();
    try {
      final customerInfo = await Purchases.restorePurchases();
      final isActive = _isEntitlementActive(customerInfo);
      if (isActive) {
        await _syncPremiumToFirestore(isPremium: true);
      }
      state = AsyncData(isActive ? 'restored' : 'not_found');
      return isActive;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  bool _isEntitlementActive(CustomerInfo info) {
    return info.entitlements.active.containsKey('premium');
  }

  Future<void> _syncPremiumToFirestore({required bool isPremium}) async {
    try {
      final userId = ref.read(currentUserIdProvider);
      await ref
          .read(firebaseFirestoreProvider)
          .collection('users')
          .doc(userId)
          .set({'isPremium': isPremium}, SetOptions(merge: true));
    } catch (_) {
      // No bloquear la compra si el sync falla.
      // authStateChanges actualizará isPremium en el próximo refresh.
    }
  }
}
