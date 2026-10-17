import 'package:flutter_test/flutter_test.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sangaso/src/models/service_model.dart';
import 'package:sangaso/src/services/service_service.dart';

import 'package:sangaso/src/features/search/presentation/search_screen.dart';

/// Test double for ServiceService — streams of local data, no Firebase.
class FakeServiceService extends ServiceService {
  FakeServiceService(this.data);

  final List<ServiceModel> data;

  List<ServiceModel> filter({required bool activeOnly, String? category}) =>
      data.where((s) =>
              (!activeOnly || s.isActive) &&
              (category == null || s.category == category))
          .toList();

  Stream<List<ServiceModel>> emit(List<ServiceModel> services) =>
      Stream.value(services);

  @override
  Stream<List<ServiceModel>> getAllServices() =>
      emit(filter(activeOnly: true));

  @override
  Stream<List<ServiceModel>> getServicesByCategory(String category) =>
      emit(filter(activeOnly: true, category: category));
}

ServiceModel service({
  required String id,
  required String name,
  required String description,
  required String category,
  double price = 100,
}) =>
    ServiceModel(
      id: id,
      providerId: 'p1',
      name: name,
      description: description,
      category: category,
      price: price,
      isActive: true,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

Widget searchHarness(ServiceService serviceService, {String? initialCategory}) =>
    MultiProvider(
      providers: [Provider<ServiceService>.value(value: serviceService)],
      child: MaterialApp(
          home: SearchScreen(initialCategory: initialCategory)),
    );

void main() {
  late FakeServiceService serviceService;

  setUp(() {
    serviceService = FakeServiceService([
      service(
          id: '1',
          name: 'Deep apartment clean',
          description: 'Full clean with supplies',
          category: 'Cleaning',
          price: 250),
      service(
          id: '2',
          name: 'Bathroom plumbing repair',
          description: 'Fix leaking taps',
          category: 'Plumbing',
          price: 180),
      service(
          id: '3',
          name: 'Ceiling fan install',
          description: 'Electrical small job',
          category: 'Electrical',
          price: 150),
    ]);
  });

  testWidgets('shows all services initially', (tester) async {
    await tester.pumpWidget(searchHarness(serviceService));
    await tester.pumpAndSettle();

    expect(find.text('Deep apartment clean'), findsOneWidget);
    expect(find.text('Bathroom plumbing repair'), findsOneWidget);
    expect(find.text('Ceiling fan install'), findsOneWidget);
  });

  testWidgets('search text filters results', (tester) async {
    await tester.pumpWidget(searchHarness(serviceService));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'plumbing');
    await tester.pumpAndSettle();

    expect(find.text('Bathroom plumbing repair'), findsOneWidget);
    expect(find.text('Deep apartment clean'), findsNothing);
  });

  testWidgets('category chip switches the stream source', (tester) async {
    await tester.pumpWidget(searchHarness(serviceService));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Plumbing').first, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.text('Bathroom plumbing repair'), findsOneWidget);
    expect(find.text('Deep apartment clean'), findsNothing);
    expect(find.text('Ceiling fan install'), findsNothing);

    await tester.tap(find.text('Cleaning').first, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.text('Deep apartment clean'), findsOneWidget);
  });

  testWidgets('combined search query and selected category filter state',
      (tester) async {
    serviceService.data.add(service(
        id: '4',
        name: 'Plumbing consultation',
        description: 'Estimate only',
        category: 'Cleaning',
        price: 90));
    await tester.pumpWidget(searchHarness(serviceService));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cleaning').first, warnIfMissed: false);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'plumbing');
    await tester.pumpAndSettle();

    // Category Cleaning + text "plumbing": only the cross match shows.
    expect(find.text('Plumbing consultation'), findsOneWidget);
    expect(find.text('Bathroom plumbing repair'), findsNothing);
  });

  testWidgets('invalid initial category falls back to All', (tester) async {
    await tester.pumpWidget(searchHarness(serviceService, initialCategory: 'Car Wash'));
    await tester.pumpAndSettle();

    expect(find.text('Deep apartment clean'), findsOneWidget);
    expect(find.text('Bathroom plumbing repair'), findsOneWidget);
  });

  testWidgets('valid initial category activates that filter', (tester) async {
    await tester.pumpWidget(searchHarness(serviceService, initialCategory: 'Electrical'));
    await tester.pumpAndSettle();

    expect(find.text('Ceiling fan install'), findsOneWidget);
    expect(find.text('Deep apartment clean'), findsNothing);
  });

  testWidgets('empty state message for no matches', (tester) async {
    await tester.pumpWidget(searchHarness(serviceService));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'zzzz');
    await tester.pumpAndSettle();

    expect(find.text('No results for "zzzz"'), findsOneWidget);
    expect(find.text('Try a different search or category'), findsOneWidget);
  });
}
