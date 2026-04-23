import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_manager/features/wish_list/model/wish_item.dart';

class WishListViewModel extends Notifier<AsyncValue<List<WishItem>>> {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  @override
  AsyncValue<List<WishItem>> build() {
    _subscribe();
    return const AsyncValue.loading();
  }

  void _subscribe() {
    final uid = _uid;
    if (uid == null) {
      state = const AsyncValue.data([]);
      return;
    }
    _db
        .collection('users')
        .doc(uid)
        .collection('wishlist')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
      (snapshot) {
        state = AsyncValue.data(
          snapshot.docs.map(WishItem.fromFirestore).toList(),
        );
      },
      onError: (e) => state = AsyncValue.error(e, StackTrace.current),
    );
  }

  Future<void> addItem({
    required String name,
    required int price,
    String shopUrl = '',
    String imageUrl = '',
  }) async {
    final uid = _uid;
    if (uid == null) return;
    final item = WishItem(
      id: '',
      name: name,
      price: price,
      shopUrl: shopUrl,
      imageUrl: imageUrl,
      createdAt: DateTime.now(),
    );
    await _db
        .collection('users')
        .doc(uid)
        .collection('wishlist')
        .add(item.toFirestore());
  }

  Future<void> togglePurchased(WishItem item) async {
    final uid = _uid;
    if (uid == null) return;
    await _db
        .collection('users')
        .doc(uid)
        .collection('wishlist')
        .doc(item.id)
        .update({'isPurchased': !item.isPurchased});
  }

  Future<void> deleteItem(String itemId) async {
    final uid = _uid;
    if (uid == null) return;
    await _db
        .collection('users')
        .doc(uid)
        .collection('wishlist')
        .doc(itemId)
        .delete();
  }
}

final wishListProvider =
    NotifierProvider<WishListViewModel, AsyncValue<List<WishItem>>>(
  WishListViewModel.new,
);
