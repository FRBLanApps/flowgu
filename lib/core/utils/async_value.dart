sealed class AsyncValue<T> {
  const AsyncValue();

  bool get isLoading => this is AsyncLoading<T>;
  T? get data => switch (this) {
        AsyncData<T>(value: final value) => value,
        _ => null,
      };
}

class AsyncInitial<T> extends AsyncValue<T> {
  const AsyncInitial();
}

class AsyncLoading<T> extends AsyncValue<T> {
  const AsyncLoading();
}

class AsyncData<T> extends AsyncValue<T> {
  const AsyncData(this.value);

  final T value;
}

class AsyncError<T> extends AsyncValue<T> {
  const AsyncError(this.message);

  final String message;
}
