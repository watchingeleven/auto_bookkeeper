import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/transaction.dart' as model;
import '../main.dart' show firebaseInitialized;
import 'database_service.dart';

/// Firebase 云端同步服务
class SyncService {
  final DatabaseService _dbService;

  SyncService(this._dbService);

  /// 匿名登录
  Future<bool> ensureAuthenticated() async {
    if (!firebaseInitialized) return false;
    try {
      final auth = FirebaseAuth.instance;
      if (auth.currentUser != null) return true;
      await auth.signInAnonymously();
      return true;
    } catch (e) {
      debugPrint('Firebase 认证失败: $e');
      return false;
    }
  }

  CollectionReference<Map<String, dynamic>>? _getUserCollection() {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return null;
      return FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('transactions');
    } catch (_) {
      return null;
    }
  }

  /// 将未同步的本地记录上传到云端
  Future<int> syncToCloud() async {
    if (!await ensureAuthenticated()) return 0;
    final collection = _getUserCollection();
    if (collection == null) return 0;

    final unsyncedList = await _dbService.getUnsyncedTransactions();
    if (unsyncedList.isEmpty) return 0;

    try {
      final batch = FirebaseFirestore.instance.batch();
      int syncedCount = 0;

      for (final transaction in unsyncedList) {
        batch.set(collection.doc(transaction.id), transaction.toFirestore());
        syncedCount++;
      }

      await batch.commit();
      for (final transaction in unsyncedList) {
        await _dbService.markAsSynced(transaction.id);
      }
      return syncedCount;
    } catch (e) {
      debugPrint('同步到云端失败: $e');
      return 0;
    }
  }

  /// 从云端拉取数据到本地
  Future<int> syncFromCloud() async {
    if (!await ensureAuthenticated()) return 0;
    final collection = _getUserCollection();
    if (collection == null) return 0;

    try {
      final snapshot =
          await collection.orderBy('createdAt', descending: true).get();
      int importedCount = 0;

      for (final doc in snapshot.docs) {
        final transaction = model.Transaction.fromFirestore(doc.data());
        await _dbService.insertTransaction(transaction);
        importedCount++;
      }
      return importedCount;
    } catch (e) {
      debugPrint('从云端恢复失败: $e');
      return 0;
    }
  }

  /// 删除云端记录
  Future<void> deleteFromCloud(String transactionId) async {
    if (!firebaseInitialized) return;
    try {
      final collection = _getUserCollection();
      await collection?.doc(transactionId).delete();
    } catch (_) {}
  }
}
