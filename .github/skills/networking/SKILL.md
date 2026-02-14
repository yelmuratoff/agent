---
name: networking
description: When implementing API calls, background parsing, error mapping, and repository/client tests.
---

# Networking (Clients, Parsing, Testing)

## When to use

- Adding a new endpoint for a feature.
- Parsing large JSON responses.
- Introducing retries/timeouts or improving reliability.
- Writing unit tests around repositories and clients.

## Steps

### 1) Keep HTTP in the data layer

Typical flow:

- BLoC calls repository interface (domain)
- repository implementation calls datasource/client (data)
- datasource owns request/response details

Example datasource:

```dart
abstract interface class IOrdersRemoteDataSource {
  Future<List<Map<String, Object?>>> fetchOrders();
}
```

### 2) Map failures into explicit exceptions

Define explicit exception types and convert low-level errors at the boundary:

```dart
final class NetworkException implements Exception {
  const NetworkException(this.message, {this.cause});
  final String message;
  final Object? cause;
}

final class ParseException implements Exception {
  const ParseException(this.message, {this.cause});
  final String message;
  final Object? cause;
}
```

Repository boundary example:

```dart
final class OrdersRepository implements IOrdersRepository {
  OrdersRepository({required this.remote});
  final IOrdersRemoteDataSource remote;

  @override
  Future<List<OrderDto>> getOrders() async {
    try {
      final maps = await remote.fetchOrders();
      return maps.map(OrderDto.fromMap).toList();
    } on FormatException catch (e) {
      throw ParseException('Invalid orders payload', cause: e);
    } catch (e) {
      throw NetworkException('Failed to fetch orders', cause: e);
    }
  }
}
```

### 3) Parse large payloads off the UI thread

Use background parsing for large JSON:

```dart
import 'package:flutter/foundation.dart';

List<OrderDto> parseOrders(List<Map<String, Object?>> maps) =>
    maps.map(OrderDto.fromMap).toList();

Future<List<OrderDto>> parseOrdersInBackground(List<Map<String, Object?>> maps) =>
    compute(parseOrders, maps);
```

For heavier work, prefer `Isolate.run` (Dart 3) where available.

### 4) Unit test repositories with mocked datasources

Prefer mocking the datasource/client (not making real HTTP calls):

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _RemoteMock extends Mock implements IOrdersRemoteDataSource {}

void main() {
  test('getOrders returns parsed DTOs', () async {
    final remote = _RemoteMock();
    when(() => remote.fetchOrders()).thenAnswer(
      (_) async => [
        {'id': '1', 'createdAt': '2026-01-01T00:00:00.000Z', 'timeout': 1000},
      ],
    );

    final repo = OrdersRepository(remote: remote);
    final result = await repo.getOrders();

    expect(result.length, 1);
    expect(result.first.id, '1');
  });
}
```
