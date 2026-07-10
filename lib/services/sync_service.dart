import 'package:flutter/foundation.dart';
import 'test_service.dart';
import 'local_store_service.dart';
import 'notification_service.dart';
import 'auth_service.dart';

class SyncService {
  final TestService _testService = TestService();
  final LocalStoreService _localStore = LocalStoreService();
  final NotificationService _notifications = NotificationService();
  final AuthService _auth = AuthService();

  Future<void> performEarlyMorningSync() async {
    try {
      debugPrint('SyncService: Starting 4 AM background sync...');
      
      final session = await _auth.loadSession();
      final uid = session?.uid;

      // 1. Fetch latest tests from server
      final latestDaily = await _testService.loadDailyTest();
      final latestPublic = await _testService.loadPublicTests();
      
      if (latestDaily == null && latestPublic.isEmpty) return;

      // 2. Load current cache
      final cachedTests = await _localStore.loadCachedCloudTests(uid);
      final cachedIds = cachedTests.map((t) => t.id).toSet();

      bool foundNew = false;
      String? newTitle;

      if (latestDaily != null && !cachedIds.contains(latestDaily.id)) {
        foundNew = true;
        newTitle = latestDaily.title;
      }

      for (final test in latestPublic) {
        if (!cachedIds.contains(test.id)) {
          foundNew = true;
          newTitle = test.title;
          break;
        }
      }

      // 3. Update cache if something new was found
      if (foundNew) {
        final allNew = [if (latestDaily != null) latestDaily, ...latestPublic];
        await _localStore.saveCachedCloudTests(allNew, uid);
        
        // 4. Trigger local notification
        await _notifications.initialize();
        await _notifications.showSyncNotification(newTitle ?? 'Various Topics');
      }

      debugPrint('SyncService: Sync complete.');
    } catch (e) {
      debugPrint('SyncService: Error during background sync: $e');
    }
  }
}

