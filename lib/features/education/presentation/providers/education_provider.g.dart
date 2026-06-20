// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'education_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(educationProgress)
const educationProgressProvider = EducationProgressProvider._();

final class EducationProgressProvider extends $FunctionalProvider<
        AsyncValue<EducationProgressEntity?>,
        EducationProgressEntity?,
        Stream<EducationProgressEntity?>>
    with
        $FutureModifier<EducationProgressEntity?>,
        $StreamProvider<EducationProgressEntity?> {
  const EducationProgressProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'educationProgressProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$educationProgressHash();

  @$internal
  @override
  $StreamProviderElement<EducationProgressEntity?> $createElement(
          $ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<EducationProgressEntity?> create(Ref ref) {
    return educationProgress(ref);
  }
}

String _$educationProgressHash() => r'001a2ab867a12ff85607dd49dedb4942e807beb0';

@ProviderFor(availableLessons)
const availableLessonsProvider = AvailableLessonsProvider._();

final class AvailableLessonsProvider extends $FunctionalProvider<
        AsyncValue<List<LessonEntity>>,
        List<LessonEntity>,
        FutureOr<List<LessonEntity>>>
    with
        $FutureModifier<List<LessonEntity>>,
        $FutureProvider<List<LessonEntity>> {
  const AvailableLessonsProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'availableLessonsProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$availableLessonsHash();

  @$internal
  @override
  $FutureProviderElement<List<LessonEntity>> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<LessonEntity>> create(Ref ref) {
    return availableLessons(ref);
  }
}

String _$availableLessonsHash() => r'6dc6ebe6ce632b7571c84a03bf0de55e184c488a';

@ProviderFor(weeklyLesson)
const weeklyLessonProvider = WeeklyLessonProvider._();

final class WeeklyLessonProvider extends $FunctionalProvider<
        AsyncValue<LessonEntity?>, LessonEntity?, FutureOr<LessonEntity?>>
    with $FutureModifier<LessonEntity?>, $FutureProvider<LessonEntity?> {
  const WeeklyLessonProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'weeklyLessonProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$weeklyLessonHash();

  @$internal
  @override
  $FutureProviderElement<LessonEntity?> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<LessonEntity?> create(Ref ref) {
    return weeklyLesson(ref);
  }
}

String _$weeklyLessonHash() => r'c3add66e3a954eea375c08e645c8d6f8a5c17526';

@ProviderFor(EducationNotifier)
const educationProvider = EducationNotifierProvider._();

final class EducationNotifierProvider
    extends $NotifierProvider<EducationNotifier, AsyncValue<void>> {
  const EducationNotifierProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'educationProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$educationNotifierHash();

  @$internal
  @override
  EducationNotifier create() => EducationNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<void> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<void>>(value),
    );
  }
}

String _$educationNotifierHash() => r'23a9fab59bd2632ffa8ccfc32daf962492283a8c';

abstract class _$EducationNotifier extends $Notifier<AsyncValue<void>> {
  AsyncValue<void> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AsyncValue<void>, AsyncValue<void>>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<void>, AsyncValue<void>>,
        AsyncValue<void>,
        Object?,
        Object?>;
    element.handleValue(ref, created);
  }
}
