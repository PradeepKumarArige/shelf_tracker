import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() => _instance;

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'shelf_tracker.db');

    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        email TEXT NOT NULL UNIQUE,
        name TEXT NOT NULL,
        avatar_url TEXT,
        notification_enabled INTEGER DEFAULT 1,
        email_alerts_enabled INTEGER DEFAULT 1,
        deal_notifications_enabled INTEGER DEFAULT 1,
        default_expiry_days INTEGER DEFAULT 7,
        language TEXT DEFAULT 'en',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE items (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        name TEXT NOT NULL,
        category INTEGER NOT NULL,
        purchase_date TEXT NOT NULL,
        expiry_date TEXT NOT NULL,
        quantity INTEGER DEFAULT 1,
        location TEXT,
        notes TEXT,
        barcode TEXT,
        image_url TEXT,
        is_used INTEGER DEFAULT 0,
        used_date TEXT,
        is_deleted INTEGER DEFAULT 0,
        deleted_at TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE item_history (
        id TEXT PRIMARY KEY,
        item_id TEXT NOT NULL,
        user_id TEXT NOT NULL,
        action TEXT NOT NULL,
        previous_values TEXT,
        new_values TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (item_id) REFERENCES items(id) ON DELETE CASCADE,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE notifications (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        item_id TEXT,
        type TEXT NOT NULL,
        title TEXT NOT NULL,
        body TEXT NOT NULL,
        is_read INTEGER DEFAULT 0,
        scheduled_at TEXT,
        sent_at TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
        FOREIGN KEY (item_id) REFERENCES items(id) ON DELETE SET NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE deals (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        store TEXT NOT NULL,
        discount TEXT NOT NULL,
        category TEXT,
        image_url TEXT,
        link TEXT,
        starts_at TEXT,
        expires_at TEXT NOT NULL,
        is_featured INTEGER DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE saved_deals (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        deal_id TEXT NOT NULL,
        saved_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
        FOREIGN KEY (deal_id) REFERENCES deals(id) ON DELETE CASCADE,
        UNIQUE(user_id, deal_id)
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_items_user_id ON items(user_id)
    ''');
    
    await db.execute('''
      CREATE INDEX idx_items_expiry_date ON items(expiry_date)
    ''');
    
    await db.execute('''
      CREATE INDEX idx_items_category ON items(category)
    ''');
    
    await db.execute('''
      CREATE INDEX idx_notifications_user_id ON notifications(user_id)
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE items ADD COLUMN is_deleted INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE items ADD COLUMN deleted_at TEXT');
    }
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }
}
