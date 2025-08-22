import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sqflite/sqflite.dart';
import 'package:tasknest/services/local_db_service.dart';

class SyncService {
  static Future<void> syncTasks() async {
    final db = await LocalDbService.getDb();
    final localTasks = await db.query('tasks');
    final firestore = FirebaseFirestore.instance;

    for (final local in localTasks) {
      final remoteDoc =
          await firestore.collection('tasks').doc(local['id'] as String).get();
      final localUpdatedAt = local['updatedAt'] as String? ?? '';
      final remoteUpdatedAt = remoteDoc.data()?['updatedAt'] ?? '';

      if (!remoteDoc.exists || localUpdatedAt.compareTo(remoteUpdatedAt) > 0) {
        // Local is newer, push to Firestore
        await firestore
            .collection('tasks')
            .doc(local['id'] as String)
            .set(local);
      } else if (remoteUpdatedAt.compareTo(localUpdatedAt) > 0) {
        // Remote is newer, update local
        await db.insert(
          'tasks',
          remoteDoc.data()!,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    }
  }
}
