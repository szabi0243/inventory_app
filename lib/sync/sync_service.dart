import 'dart:convert';
import '../db/app_db.dart';
import '../api/api_service.dart';

Future<void> syncData(AppDB db) async {
  final queue = await db.select(db.syncQueue).get();

  for (var item in queue) {
    if (item.done) continue;

    final data = jsonDecode(item.payload);

    bool success = false;

    if (item.action == "ADD") {
      success = await ApiService.send("products", data);
    }

    if (success) {
      await (db.update(db.syncQueue)
        ..where((t) => t.id.equals(item.id)))
          .write(SyncQueueCompanion(done: Value(true)));
    }
  }
}