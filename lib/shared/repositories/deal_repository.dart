import 'package:uuid/uuid.dart';
import '../models/deal_model.dart';
import '../services/database_service.dart';

class DealRepository {
  final DatabaseService _db = DatabaseService();
  final _uuid = const Uuid();

  Future<List<DealModel>> getAllDeals() async {
    final db = await _db.database;
    final now = DateTime.now();
    
    final results = await db.query(
      'deals',
      where: 'expires_at > ?',
      whereArgs: [now.toIso8601String()],
      orderBy: 'is_featured DESC, expires_at ASC',
    );
    return results.map((map) => DealModel.fromMap(map)).toList();
  }

  Future<List<DealModel>> getFeaturedDeals() async {
    final db = await _db.database;
    final now = DateTime.now();
    
    final results = await db.query(
      'deals',
      where: 'is_featured = 1 AND expires_at > ?',
      whereArgs: [now.toIso8601String()],
      orderBy: 'expires_at ASC',
    );
    return results.map((map) => DealModel.fromMap(map)).toList();
  }

  Future<List<DealModel>> getDealsByCategory(String category) async {
    final db = await _db.database;
    final now = DateTime.now();
    
    final results = await db.query(
      'deals',
      where: 'category = ? AND expires_at > ?',
      whereArgs: [category, now.toIso8601String()],
      orderBy: 'expires_at ASC',
    );
    return results.map((map) => DealModel.fromMap(map)).toList();
  }

  Future<DealModel?> getDealById(String id) async {
    final db = await _db.database;
    final results = await db.query(
      'deals',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return DealModel.fromMap(results.first);
  }

  Future<String> insertDeal(DealModel deal) async {
    final db = await _db.database;
    final id = deal.id.isEmpty ? _uuid.v4() : deal.id;
    
    final newDeal = DealModel(
      id: id,
      title: deal.title,
      description: deal.description,
      store: deal.store,
      discount: deal.discount,
      category: deal.category,
      imageUrl: deal.imageUrl,
      link: deal.link,
      startsAt: deal.startsAt,
      expiresAt: deal.expiresAt,
      isFeatured: deal.isFeatured,
    );
    
    await db.insert('deals', newDeal.toMap());
    return id;
  }

  Future<void> updateDeal(DealModel deal) async {
    final db = await _db.database;
    await db.update(
      'deals',
      deal.toMap(),
      where: 'id = ?',
      whereArgs: [deal.id],
    );
  }

  Future<void> deleteDeal(String dealId) async {
    final db = await _db.database;
    await db.delete(
      'deals',
      where: 'id = ?',
      whereArgs: [dealId],
    );
  }

  Future<List<DealModel>> getSavedDeals(String userId) async {
    final db = await _db.database;
    final results = await db.rawQuery('''
      SELECT d.* FROM deals d
      INNER JOIN saved_deals sd ON d.id = sd.deal_id
      WHERE sd.user_id = ?
      ORDER BY sd.saved_at DESC
    ''', [userId]);
    return results.map((map) => DealModel.fromMap(map)).toList();
  }

  Future<void> saveDeal(String userId, String dealId) async {
    final db = await _db.database;
    await db.insert('saved_deals', {
      'id': _uuid.v4(),
      'user_id': userId,
      'deal_id': dealId,
      'saved_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> unsaveDeal(String userId, String dealId) async {
    final db = await _db.database;
    await db.delete(
      'saved_deals',
      where: 'user_id = ? AND deal_id = ?',
      whereArgs: [userId, dealId],
    );
  }

  Future<bool> isDealSaved(String userId, String dealId) async {
    final db = await _db.database;
    final results = await db.query(
      'saved_deals',
      where: 'user_id = ? AND deal_id = ?',
      whereArgs: [userId, dealId],
      limit: 1,
    );
    return results.isNotEmpty;
  }

  Future<void> seedSampleDeals() async {
    final db = await _db.database;
    final existing = await db.query('deals', limit: 1);
    if (existing.isNotEmpty) return;

    final sampleDeals = [
      DealModel(
        id: _uuid.v4(),
        title: 'Save 30% on Dairy Products',
        description: 'Get 30% off on all dairy products including milk, yogurt, and cheese.',
        store: 'Whole Foods',
        discount: '30%',
        category: 'Food',
        expiresAt: DateTime.now().add(const Duration(days: 7)),
        isFeatured: true,
      ),
      DealModel(
        id: _uuid.v4(),
        title: 'Organic Milk Bundle',
        description: 'Buy 2 get 1 free on organic milk.',
        store: 'Whole Foods',
        discount: '25%',
        category: 'Food',
        expiresAt: DateTime.now().add(const Duration(days: 5)),
      ),
      DealModel(
        id: _uuid.v4(),
        title: 'Greek Yogurt 4-Pack',
        description: 'Premium Greek yogurt at discounted price.',
        store: "Trader Joe's",
        discount: '20%',
        category: 'Food',
        expiresAt: DateTime.now().add(const Duration(days: 10)),
      ),
      DealModel(
        id: _uuid.v4(),
        title: 'Multi-Vitamin Pack',
        description: 'Complete daily vitamins for the whole family.',
        store: 'CVS Pharmacy',
        discount: '30%',
        category: 'Medicine',
        expiresAt: DateTime.now().add(const Duration(days: 14)),
      ),
      DealModel(
        id: _uuid.v4(),
        title: 'Skincare Essentials',
        description: 'Premium skincare products bundle.',
        store: 'Sephora',
        discount: '15%',
        category: 'Cosmetics',
        expiresAt: DateTime.now().add(const Duration(days: 21)),
      ),
      DealModel(
        id: _uuid.v4(),
        title: 'Pantry Staples Bundle',
        description: 'Rice, pasta, and canned goods at bulk prices.',
        store: 'Costco',
        discount: '35%',
        category: 'Grocery',
        expiresAt: DateTime.now().add(const Duration(days: 3)),
      ),
    ];

    for (final deal in sampleDeals) {
      await db.insert('deals', deal.toMap());
    }
  }
}
