import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'firebase_providers.g.dart';

// ── Firebase Singletons ───────────────────────────────────────────

@riverpod
FirebaseAuth firebaseAuth(Ref ref) => FirebaseAuth.instance;

@riverpod
FirebaseFirestore firebaseFirestore(Ref ref) {
  final db = FirebaseFirestore.instance;
  // Configurar caché offline para soporte sin conexión
  db.settings = const Settings(persistenceEnabled: true, cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED);
  return db;
}

@riverpod
FirebaseStorage firebaseStorage(Ref ref) => FirebaseStorage.instance;

// ── Auth State Stream ─────────────────────────────────────────────

@riverpod
Stream<User?> authState(Ref ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
}

/// Proveedor del UID del usuario autenticado.
/// Lanza [StateError] si no hay usuario — no debería ocurrir
/// dentro de rutas protegidas.
@riverpod
String currentUserId(Ref ref) {
  final user = ref.watch(authStateProvider).asData?.value;
  if (user == null) throw StateError('No hay usuario autenticado');
  return user.uid;
}

// ── Firestore Document References ────────────────────────────────

@riverpod
DocumentReference<Map<String, dynamic>> userDocRef(Ref ref) {
  final uid = ref.watch(currentUserIdProvider);
  return ref.watch(firebaseFirestoreProvider).collection('users').doc(uid);
}

@riverpod
CollectionReference<Map<String, dynamic>> debtsCollectionRef(Ref ref) {
  return ref.watch(userDocRefProvider).collection('debts');
}

@riverpod
CollectionReference<Map<String, dynamic>> goalsCollectionRef(Ref ref) {
  return ref.watch(userDocRefProvider).collection('savingsGoals');
}

@riverpod
CollectionReference<Map<String, dynamic>> automationsCollectionRef(Ref ref) {
  return ref.watch(userDocRefProvider).collection('automations');
}

@riverpod
CollectionReference<Map<String, dynamic>> monthlySnapshotsRef(Ref ref) {
  return ref.watch(userDocRefProvider).collection('monthlySnapshots');
}
