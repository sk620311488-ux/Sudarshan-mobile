import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/app_models.dart';

class SocialService {
  static const _publicProfilesCollection = 'public_profiles';
  static const _friendsCollection = 'user_friends';

  Future<void> upsertPublicProfile(PublicStudentProfile profile) async {
    if (Firebase.apps.isEmpty || profile.uid.trim().isEmpty) {
      return;
    }

    await FirebaseFirestore.instance
        .collection(_publicProfilesCollection)
        .doc(profile.uid)
        .set(
      {
        ...profile.toJson(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<PublicStudentProfile?> getPublicProfile(String uid) async {
    if (Firebase.apps.isEmpty || uid.trim().isEmpty) {
      return null;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(_publicProfilesCollection)
          .doc(uid)
          .get();
      final data = snapshot.data();
      if (data == null) {
        return null;
      }
      return PublicStudentProfile.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  Future<PublicStudentProfile?> findProfileByStudentId(String studentId) async {
    if (Firebase.apps.isEmpty || studentId.trim().isEmpty) {
      return null;
    }

    try {
      final query = await FirebaseFirestore.instance
          .collection(_publicProfilesCollection)
          .where('customStudentId', isEqualTo: studentId.trim().toUpperCase())
          .limit(1)
          .get();
      if (query.docs.isEmpty) {
        return null;
      }
      return PublicStudentProfile.fromJson(query.docs.first.data());
    } catch (_) {
      return null;
    }
  }

  Future<List<PublicStudentProfile>> getFriendProfiles(String uid) async {
    if (Firebase.apps.isEmpty || uid.trim().isEmpty) {
      return const [];
    }

    final links = await _friendLinksRef(uid).get();
    if (links.docs.isEmpty) {
      return const [];
    }

    final friendIds = links.docs.map((doc) => doc.id).toList();
    final profiles = <PublicStudentProfile>[];
    for (final friendId in friendIds) {
      final profile = await getPublicProfile(friendId);
      if (profile != null) {
        profiles.add(profile);
      }
    }
    profiles.sort(
      (a, b) => a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()),
    );
    return profiles;
  }

  Future<void> addFriend({
    required AppSession owner,
    required PublicStudentProfile friend,
  }) async {
    if (Firebase.apps.isEmpty || owner.uid.trim().isEmpty) {
      return;
    }

    await _friendLinksRef(owner.uid).doc(friend.uid).set(
      {
        'uid': friend.uid,
        'name': friend.displayName,
        'customStudentId': friend.customStudentId,
        'rankTitle': friend.rankTitle,
        'level': friend.level,
        'addedAt': FieldValue.serverTimestamp(),
        'addedAtIso': DateTime.now().toIso8601String(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> removeFriend({
    required String ownerUid,
    required String friendUid,
  }) async {
    if (Firebase.apps.isEmpty ||
        ownerUid.trim().isEmpty ||
        friendUid.trim().isEmpty) {
      return;
    }

    await _friendLinksRef(ownerUid).doc(friendUid).delete();
  }

  Stream<List<PublicStudentProfile>> watchFriendProfiles(String uid) {
    if (Firebase.apps.isEmpty || uid.trim().isEmpty) {
      return const Stream<List<PublicStudentProfile>>.empty();
    }

    return _friendLinksRef(uid).snapshots().asyncMap((snapshot) async {
      if (snapshot.docs.isEmpty) {
        return const <PublicStudentProfile>[];
      }

      final profiles = <PublicStudentProfile>[];
      for (final doc in snapshot.docs) {
        final profile = await getPublicProfile(doc.id);
        if (profile != null) {
          profiles.add(profile);
        }
      }

      profiles.sort(
        (a, b) => a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()),
      );
      return profiles;
    });
  }

  CollectionReference<Map<String, dynamic>> _friendLinksRef(String uid) {
    return FirebaseFirestore.instance
        .collection(_friendsCollection)
        .doc(uid)
        .collection('links');
  }

  // Friend Requests logic
  static const _requestsCollection = 'friend_requests';

  Future<void> sendFriendRequest({
    required String fromUid,
    required String fromName,
    required String toUid,
    String message = '',
  }) async {
    final docId = '${fromUid}_$toUid';
    await FirebaseFirestore.instance.collection(_requestsCollection).doc(docId).set({
      'id': docId,
      'fromUid': fromUid,
      'fromName': fromName,
      'toUid': toUid,
      'status': FriendRequestStatus.pending.name,
      'message': message,
      'createdAtIso': DateTime.now().toIso8601String(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> respondToFriendRequest({
    required FriendRequest request,
    required FriendRequestStatus status,
    required AppSession currentSession,
  }) async {
    if (status == FriendRequestStatus.accepted) {
      // 1. Get profiles
      final fromProfile = await getPublicProfile(request.fromUid);
      final toProfile = await getPublicProfile(request.toUid);

      if (fromProfile != null && toProfile != null) {
        // 2. Add mutual links
        await addFriend(owner: currentSession, friend: fromProfile);

        // We also need the other person to have the link
        // This is a bit tricky since we don't have the other person's AppSession here
        // But we can construct a dummy session or just use the UID logic
        await _friendLinksRef(request.fromUid).doc(toProfile.uid).set({
          'uid': toProfile.uid,
          'name': toProfile.displayName,
          'customStudentId': toProfile.customStudentId,
          'rankTitle': toProfile.rankTitle,
          'level': toProfile.level,
          'addedAt': FieldValue.serverTimestamp(),
          'addedAtIso': DateTime.now().toIso8601String(),
        });
      }
    }

    // Update or delete request
    if (status == FriendRequestStatus.declined) {
      await FirebaseFirestore.instance.collection(_requestsCollection).doc(request.id).delete();
    } else {
      await FirebaseFirestore.instance.collection(_requestsCollection).doc(request.id).update({
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Stream<List<FriendRequest>> watchIncomingRequests(String uid) {
    return FirebaseFirestore.instance
        .collection(_requestsCollection)
        .where('toUid', isEqualTo: uid)
        .where('status', isEqualTo: FriendRequestStatus.pending.name)
        .snapshots()
        .map((snap) => snap.docs.map((d) => FriendRequest.fromJson(d.data())).toList());
  }

  Future<List<PublicStudentProfile>> getMutualFriends(String uid1, String uid2) async {
    final f1 = await getFriendProfiles(uid1);
    final f2 = await getFriendProfiles(uid2);

    final ids1 = f1.map((e) => e.uid).toSet();
    return f2.where((e) => ids1.contains(e.uid)).toList();
  }
}
