import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  /// Every user's data lives under users/{uid}/...
  static DocumentReference get _userDoc => _db.collection('users').doc(_uid);

  // ---------- Wallet (bank balance + budget limit) ----------

  static Stream<DocumentSnapshot> get walletStream => _userDoc.snapshots();

  static Future<void> setBankBalance(double value) async {
    await _userDoc.set({'bankBalance': value}, SetOptions(merge: true));
  }

  static Future<void> setBudgetLimit(double value) async {
    await _userDoc.set({'budgetLimit': value}, SetOptions(merge: true));
  }

  // ---------- Portfolio all-time-high tracker ----------

  static Future<double> getPortfolioAth() async {
    final snap = await _userDoc.get();
    final data = snap.data() as Map<String, dynamic>?;
    return (data?['portfolioAthRecord'] as num?)?.toDouble() ?? 5000.0;
  }

  static Future<void> setPortfolioAth(double value) async {
    await _userDoc.set({'portfolioAthRecord': value}, SetOptions(merge: true));
  }

  static Future<void> ensureWalletDefaults() async {
    final snap = await _userDoc.get();
    if (!snap.exists || (snap.data() as Map?)?['bankBalance'] == null) {
      await _userDoc.set({
        'bankBalance': 500000.0,
        'budgetLimit': 25000.0,
      }, SetOptions(merge: true));
    }
  }

  // ---------- Expenses ----------

  static CollectionReference get _expensesCol =>
      _userDoc.collection('expenses');

  static Stream<QuerySnapshot> get expensesStream =>
      _expensesCol.orderBy('date', descending: true).snapshots();

  static Future<void> addExpense(Map<String, dynamic> expense) async {
    await _expensesCol.add(expense);
  }

  static Future<void> deleteExpense(String docId) async {
    await _expensesCol.doc(docId).delete();
  }

  static Future<void> seedDefaultExpenses() async {
    final existing = await _expensesCol.limit(1).get();
    if (existing.docs.isNotEmpty) return;

    final defaults = [
      {'title': 'Dinner out', 'category': 'Food', 'amount': 1200.0, 'date': '2026-06-18'},
      {'title': 'Monthly Rent', 'category': 'Housing', 'amount': 12000.0, 'date': '2026-06-01'},
      {'title': 'Coffee run', 'category': 'Food', 'amount': 300.0, 'date': '2026-06-19'},
    ];
    for (final e in defaults) {
      await _expensesCol.add(e);
    }
  }

  // ---------- Portfolio ----------

  static CollectionReference get _portfolioCol =>
      _userDoc.collection('portfolio');

  static Stream<QuerySnapshot> get portfolioStream => _portfolioCol.snapshots();

  static Future<void> addAsset(Map<String, dynamic> asset) async {
    await _portfolioCol.add(asset);
  }

  static Future<void> updateAsset(String docId, Map<String, dynamic> data) async {
    await _portfolioCol.doc(docId).update(data);
  }

  static Future<void> deleteAsset(String docId) async {
    await _portfolioCol.doc(docId).delete();
  }

  static Future<void> seedDefaultPortfolio() async {
    final existing = await _portfolioCol.limit(1).get();
    if (existing.docs.isNotEmpty) return;

    final defaults = [
      {'name': 'RELIANCE', 'shares': 10, 'buy_price': 2400.0, 'current_price': 2850.0, 'type': 'Stock'},
      {'name': 'BTC', 'shares': 0.05, 'buy_price': 4200000.0, 'current_price': 5400000.0, 'type': 'Crypto'},
    ];
    for (final a in defaults) {
      await _portfolioCol.add(a);
    }
  }
}