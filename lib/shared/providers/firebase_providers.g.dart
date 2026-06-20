// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'firebase_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(firebaseAuth)
const firebaseAuthProvider = FirebaseAuthProvider._();

final class FirebaseAuthProvider
    extends $FunctionalProvider<FirebaseAuth, FirebaseAuth, FirebaseAuth>
    with $Provider<FirebaseAuth> {
  const FirebaseAuthProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'firebaseAuthProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$firebaseAuthHash();

  @$internal
  @override
  $ProviderElement<FirebaseAuth> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  FirebaseAuth create(Ref ref) {
    return firebaseAuth(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FirebaseAuth value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FirebaseAuth>(value),
    );
  }
}

String _$firebaseAuthHash() => r'8f84097cccd00af817397c1715c5f537399ba780';

@ProviderFor(firebaseFirestore)
const firebaseFirestoreProvider = FirebaseFirestoreProvider._();

final class FirebaseFirestoreProvider extends $FunctionalProvider<
    FirebaseFirestore,
    FirebaseFirestore,
    FirebaseFirestore> with $Provider<FirebaseFirestore> {
  const FirebaseFirestoreProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'firebaseFirestoreProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$firebaseFirestoreHash();

  @$internal
  @override
  $ProviderElement<FirebaseFirestore> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  FirebaseFirestore create(Ref ref) {
    return firebaseFirestore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FirebaseFirestore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FirebaseFirestore>(value),
    );
  }
}

String _$firebaseFirestoreHash() => r'80203fceee83af1896f97200f9bffba436404f99';

@ProviderFor(firebaseStorage)
const firebaseStorageProvider = FirebaseStorageProvider._();

final class FirebaseStorageProvider extends $FunctionalProvider<FirebaseStorage,
    FirebaseStorage, FirebaseStorage> with $Provider<FirebaseStorage> {
  const FirebaseStorageProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'firebaseStorageProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$firebaseStorageHash();

  @$internal
  @override
  $ProviderElement<FirebaseStorage> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  FirebaseStorage create(Ref ref) {
    return firebaseStorage(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FirebaseStorage value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FirebaseStorage>(value),
    );
  }
}

String _$firebaseStorageHash() => r'47903c48019f7dfa1ba82fa0a905885442d69f6b';

@ProviderFor(authState)
const authStateProvider = AuthStateProvider._();

final class AuthStateProvider
    extends $FunctionalProvider<AsyncValue<User?>, User?, Stream<User?>>
    with $FutureModifier<User?>, $StreamProvider<User?> {
  const AuthStateProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'authStateProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$authStateHash();

  @$internal
  @override
  $StreamProviderElement<User?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<User?> create(Ref ref) {
    return authState(ref);
  }
}

String _$authStateHash() => r'afdf515e14d0bb725ca181867cf6d626a5d85246';

/// Proveedor del UID del usuario autenticado.
/// Lanza [StateError] si no hay usuario — no debería ocurrir
/// dentro de rutas protegidas.

@ProviderFor(currentUserId)
const currentUserIdProvider = CurrentUserIdProvider._();

/// Proveedor del UID del usuario autenticado.
/// Lanza [StateError] si no hay usuario — no debería ocurrir
/// dentro de rutas protegidas.

final class CurrentUserIdProvider
    extends $FunctionalProvider<String, String, String> with $Provider<String> {
  /// Proveedor del UID del usuario autenticado.
  /// Lanza [StateError] si no hay usuario — no debería ocurrir
  /// dentro de rutas protegidas.
  const CurrentUserIdProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'currentUserIdProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$currentUserIdHash();

  @$internal
  @override
  $ProviderElement<String> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String create(Ref ref) {
    return currentUserId(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$currentUserIdHash() => r'77d7671c4935702e7490915a8fafb72c32facb61';

@ProviderFor(userDocRef)
const userDocRefProvider = UserDocRefProvider._();

final class UserDocRefProvider extends $FunctionalProvider<
        DocumentReference<Map<String, dynamic>>,
        DocumentReference<Map<String, dynamic>>,
        DocumentReference<Map<String, dynamic>>>
    with $Provider<DocumentReference<Map<String, dynamic>>> {
  const UserDocRefProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'userDocRefProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$userDocRefHash();

  @$internal
  @override
  $ProviderElement<DocumentReference<Map<String, dynamic>>> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DocumentReference<Map<String, dynamic>> create(Ref ref) {
    return userDocRef(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DocumentReference<Map<String, dynamic>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<DocumentReference<Map<String, dynamic>>>(value),
    );
  }
}

String _$userDocRefHash() => r'258517519f0c1885e32f91a512b8d96222de28ae';

@ProviderFor(debtsCollectionRef)
const debtsCollectionRefProvider = DebtsCollectionRefProvider._();

final class DebtsCollectionRefProvider extends $FunctionalProvider<
        CollectionReference<Map<String, dynamic>>,
        CollectionReference<Map<String, dynamic>>,
        CollectionReference<Map<String, dynamic>>>
    with $Provider<CollectionReference<Map<String, dynamic>>> {
  const DebtsCollectionRefProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'debtsCollectionRefProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$debtsCollectionRefHash();

  @$internal
  @override
  $ProviderElement<CollectionReference<Map<String, dynamic>>> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CollectionReference<Map<String, dynamic>> create(Ref ref) {
    return debtsCollectionRef(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CollectionReference<Map<String, dynamic>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<CollectionReference<Map<String, dynamic>>>(value),
    );
  }
}

String _$debtsCollectionRefHash() =>
    r'6c7837a64755bc1fd0a265a1cfc04de9b12f5493';

@ProviderFor(goalsCollectionRef)
const goalsCollectionRefProvider = GoalsCollectionRefProvider._();

final class GoalsCollectionRefProvider extends $FunctionalProvider<
        CollectionReference<Map<String, dynamic>>,
        CollectionReference<Map<String, dynamic>>,
        CollectionReference<Map<String, dynamic>>>
    with $Provider<CollectionReference<Map<String, dynamic>>> {
  const GoalsCollectionRefProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'goalsCollectionRefProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$goalsCollectionRefHash();

  @$internal
  @override
  $ProviderElement<CollectionReference<Map<String, dynamic>>> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CollectionReference<Map<String, dynamic>> create(Ref ref) {
    return goalsCollectionRef(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CollectionReference<Map<String, dynamic>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<CollectionReference<Map<String, dynamic>>>(value),
    );
  }
}

String _$goalsCollectionRefHash() =>
    r'c9dd8fb29dfd8fb06cf50b2d6ca2b2655943dbb5';

@ProviderFor(automationsCollectionRef)
const automationsCollectionRefProvider = AutomationsCollectionRefProvider._();

final class AutomationsCollectionRefProvider extends $FunctionalProvider<
        CollectionReference<Map<String, dynamic>>,
        CollectionReference<Map<String, dynamic>>,
        CollectionReference<Map<String, dynamic>>>
    with $Provider<CollectionReference<Map<String, dynamic>>> {
  const AutomationsCollectionRefProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'automationsCollectionRefProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$automationsCollectionRefHash();

  @$internal
  @override
  $ProviderElement<CollectionReference<Map<String, dynamic>>> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CollectionReference<Map<String, dynamic>> create(Ref ref) {
    return automationsCollectionRef(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CollectionReference<Map<String, dynamic>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<CollectionReference<Map<String, dynamic>>>(value),
    );
  }
}

String _$automationsCollectionRefHash() =>
    r'e4c69bda5644477d14d5595359662f08ee19ea4b';

@ProviderFor(monthlySnapshotsRef)
const monthlySnapshotsRefProvider = MonthlySnapshotsRefProvider._();

final class MonthlySnapshotsRefProvider extends $FunctionalProvider<
        CollectionReference<Map<String, dynamic>>,
        CollectionReference<Map<String, dynamic>>,
        CollectionReference<Map<String, dynamic>>>
    with $Provider<CollectionReference<Map<String, dynamic>>> {
  const MonthlySnapshotsRefProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'monthlySnapshotsRefProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$monthlySnapshotsRefHash();

  @$internal
  @override
  $ProviderElement<CollectionReference<Map<String, dynamic>>> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CollectionReference<Map<String, dynamic>> create(Ref ref) {
    return monthlySnapshotsRef(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CollectionReference<Map<String, dynamic>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<CollectionReference<Map<String, dynamic>>>(value),
    );
  }
}

String _$monthlySnapshotsRefHash() =>
    r'755adfef17e7e41aaaba67d64241c8411fcbd220';
