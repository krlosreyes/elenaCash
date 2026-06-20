import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn? _googleSignInOverride;
  GoogleSignIn? _googleSignInInstance;

  AuthRepositoryImpl({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
    GoogleSignIn? googleSignIn,
  })  : _auth = auth,
        _firestore = firestore,
        _googleSignInOverride = googleSignIn;

  // Lazy: se crea solo cuando se llama a signInWithGoogle(), no al arrancar la app.
  // En web requiere clientId configurado; en móvil funciona sin él.
  GoogleSignIn get _googleSignIn {
    if (_googleSignInOverride != null) return _googleSignInOverride;
    return _googleSignInInstance ??= kIsWeb
        ? GoogleSignIn(
            clientId: const String.fromEnvironment('GOOGLE_CLIENT_ID'),
          )
        : GoogleSignIn();
  }

  @override
  Stream<UserEntity?> get authStateChanges {
    return _auth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) return null;
      final provider = firebaseUser.providerData
          .map((p) => p.providerId)
          .firstWhere((id) => id != 'firebase', orElse: () => 'password');
      try {
        final doc = await _firestore.collection('users').doc(firebaseUser.uid).get();
        if (!doc.exists) {
          // Race condition: el doc de Firestore aún no se ha creado
          // (ocurre justo después de registerWithEmail). Construimos el
          // UserModel desde Firebase Auth para no interrumpir el flujo.
          return UserModel(
            uid: firebaseUser.uid,
            email: firebaseUser.email ?? '',
            displayName: firebaseUser.displayName ?? '',
            photoUrl: firebaseUser.photoURL,
            createdAt: firebaseUser.metadata.creationTime ?? DateTime.now(),
            signInProvider: provider,
          );
        }
        return UserModel.fromFirestore(doc, signInProvider: provider);
      } catch (_) {
        return null;
      }
    });
  }

  @override
  Future<Either<Failure, UserEntity>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final doc = await _firestore.collection('users').doc(credential.user!.uid).get();
      return Right(UserModel.fromFirestore(doc));
    } on FirebaseAuthException catch (e) {
      return Left(_mapFirebaseAuthException(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await credential.user!.updateDisplayName(displayName);

      // Crear documento inicial en Firestore
      final userModel = UserModel(
        uid: credential.user!.uid,
        email: email,
        displayName: displayName,
        currency: 'COP',
        country: 'CO',
        payFrequency: 'biweekly',
        monthlyNetIncome: 0,
        isPremium: false,
        richLifeDescription: '',
        onboardingCompleted: false,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(credential.user!.uid)
          .set(userModel.toInitialFirestore());

      return Right(userModel);
    } on FirebaseAuthException catch (e) {
      return Left(_mapFirebaseAuthException(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> signInWithGoogle() async {
    try {
      final googleAccount = await _googleSignIn.signIn();
      if (googleAccount == null) {
        return const Left(AuthFailure(message: 'Inicio de sesión cancelado.'));
      }

      final googleAuth = await googleAccount.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final uid = userCredential.user!.uid;

      final docRef = _firestore.collection('users').doc(uid);
      final doc = await docRef.get();

      if (!doc.exists) {
        // Primer inicio con Google — crear perfil
        final userModel = UserModel(
          uid: uid,
          email: userCredential.user!.email ?? '',
          displayName: userCredential.user!.displayName ?? '',
          photoUrl: userCredential.user!.photoURL,
          currency: 'COP',
          country: 'CO',
          payFrequency: 'biweekly',
          monthlyNetIncome: 0,
          isPremium: false,
          richLifeDescription: '',
          onboardingCompleted: false,
          createdAt: DateTime.now(),
        );
        await docRef.set(userModel.toInitialFirestore());
        return Right(userModel);
      }

      return Right(UserModel.fromFirestore(doc));
    } on FirebaseAuthException catch (e) {
      return Left(_mapFirebaseAuthException(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return const Right(null);
    } on FirebaseAuthException catch (e) {
      return Left(_mapFirebaseAuthException(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> getCurrentUser() async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return const Left(AuthFailure(message: 'No hay sesión activa.'));
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) return const Left(UserNotFoundFailure());
      return Right(UserModel.fromFirestore(doc));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> updateUserProfile({
    String? displayName,
    String? photoUrl,
    String? currency,
    String? country,
    String? richLifeDescription,
    double? monthlyNetIncome,
    String? payFrequency,
    bool? onboardingCompleted,
  }) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return const Left(AuthFailure(message: 'No hay sesión activa.'));

      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
        if (displayName != null) 'displayName': displayName,
        if (photoUrl != null) 'photoUrl': photoUrl,
        if (currency != null) 'currency': currency,
        if (country != null) 'country': country,
        if (richLifeDescription != null) 'richLifeDescription': richLifeDescription,
        if (monthlyNetIncome != null) 'monthlyNetIncome': monthlyNetIncome,
        if (payFrequency != null) 'payFrequency': payFrequency,
        if (onboardingCompleted != null) 'onboardingCompleted': onboardingCompleted,
      };

      await _firestore.collection('users').doc(uid).set(updates, SetOptions(merge: true));
      return getCurrentUser();
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return const Left(AuthFailure(message: 'No hay sesión activa.'));
      final uid = user.uid;

      // 1. Borrar todas las subcolecciones de Firestore
      await _deleteUserFirestoreData(uid);

      // 2. Eliminar la cuenta de Firebase Auth
      await user.delete();

      return const Right(null);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        final isGoogle = _auth.currentUser?.providerData
                .any((p) => p.providerId == 'google.com') ??
            false;
        return Left(ReauthRequiredFailure(isGoogleUser: isGoogle));
      }
      return Left(_mapFirebaseAuthException(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Borra todos los datos del usuario en Firestore antes de eliminar la cuenta.
  Future<void> _deleteUserFirestoreData(String uid) async {
    final userDoc = _firestore.collection('users').doc(uid);

    // Subcollecciones con un único documento conocido
    final singleDocCols = [
      'consciousPlan',
      'fastlaneEngine',
      'habitEngine',
      'educationProgress',
    ];

    for (final col in singleDocCols) {
      try {
        await userDoc.collection(col).doc('current').delete();
      } catch (_) {}
    }

    // Subcollecciones con múltiples documentos
    final multiDocCols = ['debts', 'savingsGoals', 'monthlySnapshots'];
    for (final col in multiDocCols) {
      try {
        final snap = await userDoc.collection(col).get();
        final batch = _firestore.batch();
        for (final doc in snap.docs) {
          batch.delete(doc.reference);
        }
        if (snap.docs.isNotEmpty) await batch.commit();
      } catch (_) {}
    }

    // Finalmente el documento raíz del usuario
    try {
      await userDoc.delete();
    } catch (_) {}
  }

  @override
  Future<Either<Failure, void>> reauthenticateWithPassword(
      String password) async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) {
        return const Left(AuthFailure(message: 'No hay sesión activa.'));
      }
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);
      return const Right(null);
    } on FirebaseAuthException catch (e) {
      return Left(_mapFirebaseAuthException(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> reauthenticateWithGoogle() async {
    try {
      final googleAccount = await _googleSignIn.signIn();
      if (googleAccount == null) {
        return const Left(AuthFailure(message: 'Inicio de sesión con Google cancelado.'));
      }
      final googleAuth = await googleAccount.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await _auth.currentUser?.reauthenticateWithCredential(credential);
      return const Right(null);
    } on FirebaseAuthException catch (e) {
      return Left(_mapFirebaseAuthException(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  // ── Mapeo de errores Firebase ─────────────────────────────────
  Failure _mapFirebaseAuthException(FirebaseAuthException e) {
    return switch (e.code) {
      'user-not-found' => const UserNotFoundFailure(),
      'wrong-password' => const WrongPasswordFailure(),
      'email-already-in-use' => const EmailAlreadyInUseFailure(),
      'weak-password' => const WeakPasswordFailure(),
      'invalid-email' => const AuthFailure(message: 'Correo electrónico inválido.'),
      'user-disabled' => const AuthFailure(message: 'Esta cuenta ha sido deshabilitada.'),
      'too-many-requests' => const AuthFailure(message: 'Demasiados intentos. Espera unos minutos.'),
      'network-request-failed' => const NetworkFailure(),
      _ => AuthFailure(message: e.message ?? 'Error de autenticación.', code: e.code),
    };
  }
}
