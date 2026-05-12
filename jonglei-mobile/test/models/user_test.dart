import 'package:flutter_test/flutter_test.dart';
import 'package:jonglei_fish_hub/models/user.dart';

void main() {
  group('User.fromJson', () {
    final Map<String, dynamic> fullJson = {
      'id': 'abc-123',
      'phone_number': '+211912345678',
      'username': 'testtrader',
      'role': 'TRADER',
      'role_display': 'Fish Trader',
      'location': 'Bor',
      'is_verified': true,
      'rating': '4.5',
      'total_transactions': 12,
      'preferred_language': 'EN',
    };

    test('parses all fields correctly', () {
      final user = User.fromJson(fullJson);
      expect(user.id, 'abc-123');
      expect(user.phoneNumber, '+211912345678');
      expect(user.username, 'testtrader');
      expect(user.role, 'TRADER');
      expect(user.roleDisplay, 'Fish Trader');
      expect(user.location, 'Bor');
      expect(user.isVerified, true);
      expect(user.rating, 4.5);
      expect(user.totalTransactions, 12);
      expect(user.preferredLanguage, 'EN');
    });

    test('rating parses from string', () {
      final user = User.fromJson({...fullJson, 'rating': '3.75'});
      expect(user.rating, 3.75);
    });

    test('rating parses from num', () {
      final user = User.fromJson({...fullJson, 'rating': 2});
      expect(user.rating, 2.0);
    });

    test('rating defaults to 0 when null', () {
      final json = Map<String, dynamic>.from(fullJson)..remove('rating');
      final user = User.fromJson(json);
      expect(user.rating, 0.0);
    });

    test('optional fields default gracefully', () {
      final minimal = {
        'id': 'x',
        'phone_number': '+211900000000',
        'username': null,
        'role': 'BUYER',
      };
      final user = User.fromJson(minimal);
      expect(user.username, '');
      expect(user.roleDisplay, '');
      expect(user.location, '');
      expect(user.isVerified, false);
      expect(user.totalTransactions, 0);
      expect(user.preferredLanguage, 'EN');
    });

    test('toJson round-trips correctly', () {
      final user = User.fromJson(fullJson);
      final json = user.toJson();
      final restored = User.fromJson(json);
      expect(restored.id, user.id);
      expect(restored.phoneNumber, user.phoneNumber);
      expect(restored.username, user.username);
      expect(restored.role, user.role);
      expect(restored.rating, user.rating);
      expect(restored.totalTransactions, user.totalTransactions);
    });
  });
}
