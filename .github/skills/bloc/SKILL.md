---
name: bloc
description: When implementing feature state using BLoC (default), Cubit (small UI state), or Provider (lightweight UI controllers).
---

# State Management (BLoC Default)

## When to use

- BLoC: default for feature flows, async orchestration, and business-facing UI state.
- Cubit: small UI-only state (toggles, selected tab) where events/transformers are unnecessary.
- Provider: a lightweight UI controller (e.g., filters) when it stays UI-scoped and does not contain business logic.

## Steps

### 1) Choose the right tool

Quick rule:

- If it coordinates async work and talks to repositories: BLoC.
- If it only holds ephemeral UI state: Cubit.
- If it’s a tiny widget-scoped controller and BLoC would be noise: Provider.

### 2) Define events (sealed, manual)

```dart
part of 'orders_bloc.dart';

sealed class OrdersEvent {
  const OrdersEvent();
}

final class OrdersStartedEvent extends OrdersEvent {
  const OrdersStartedEvent();
}

final class OrdersRefreshEvent extends OrdersEvent {
  const OrdersRefreshEvent();
}
```

### 3) Define states (sealed, minimal, Equatable only when needed)

```dart
part of 'orders_bloc.dart';

sealed class OrdersState {
  const OrdersState();
}

final class OrdersInitialState extends OrdersState {
  const OrdersInitialState();
}

final class OrdersLoadingState extends OrdersState {
  const OrdersLoadingState();
}

final class OrdersLoadedState extends OrdersState with EquatableMixin {
  const OrdersLoadedState({required this.orders});

  final List<OrderDto> orders;

  @override
  List<Object?> get props => [orders];
}

final class OrdersErrorState extends OrdersState with EquatableMixin {
  const OrdersErrorState({
    required this.message,
    this.error,
    this.stackTrace,
  });

  final String? message;
  final Object? error;
  final StackTrace? stackTrace;

  @override
  List<Object?> get props => [message, error, stackTrace];
}
```

### 4) Implement the BLoC with explicit concurrency

Pick the transformer intentionally:

- `droppable()` for “tap spam should not queue”
- `restartable()` for “latest wins” (search, refresh)
- `sequential()` for strict ordering

Example with `restartable()`:

```dart
import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';

part 'orders_event.dart';
part 'orders_state.dart';

final class OrdersBloc extends Bloc<OrdersEvent, OrdersState> {
  OrdersBloc({required this.repository}) : super(const OrdersInitialState()) {
    on<OrdersEvent>(
      (event, emit) => switch (event) {
        OrdersStartedEvent() => _load(emit),
        OrdersRefreshEvent() => _load(emit),
      },
      transformer: restartable(),
    );
  }

  final IOrdersRepository repository;

  Future<void> _load(Emitter<OrdersState> emit) async {
    emit(const OrdersLoadingState());
    try {
      final orders = await repository.getOrders();
      emit(OrdersLoadedState(orders: orders));
    } catch (e, st) {
      handleException(
        exception: e,
        stackTrace: st,
        onError: (message, _, _, _) => emit(
          OrdersErrorState(message: message, error: e, stackTrace: st),
        ),
      );
    }
  }
}
```

### 5) Keep business logic out of widgets

BLoC orchestrates UI state; business rules live in repositories/services (or in small injected helpers).

If the BLoC grows because of data formatting:

- move formatting to DTO extensions
- move procedural logic to an injected service

### 6) Test BLoCs at the boundary

Use `bloc_test` and mock repositories. Cover:

- success path
- expected failures (network/timeout/cache)
- concurrency behavior (e.g., restartable cancels previous)

Example:

```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _OrdersRepositoryMock extends Mock implements IOrdersRepository {}

void main() {
  late IOrdersRepository repo;

  setUp(() => repo = _OrdersRepositoryMock());

  blocTest<OrdersBloc, OrdersState>(
    'emits [Loading, Loaded] on success',
    build: () {
      when(() => repo.getOrders()).thenAnswer((_) async => const []);
      return OrdersBloc(repository: repo);
    },
    act: (bloc) => bloc.add(const OrdersStartedEvent()),
    expect: () => [
      const OrdersLoadingState(),
      const OrdersLoadedState(orders: []),
    ],
  );
}
```
