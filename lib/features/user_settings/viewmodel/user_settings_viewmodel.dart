import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_manager/features/user_settings/model/user_settings.dart';

class UserSettingsState {
  const UserSettingsState({
    this.settings = const UserSettings(),
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
  });

  final UserSettings settings;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;

  UserSettingsState copyWith({
    UserSettings? settings,
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
  }) {
    return UserSettingsState(
      settings: settings ?? this.settings,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage,
    );
  }
}

class UserSettingsViewModel extends Notifier<UserSettingsState> {
  final _db = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;
  final _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  @override
  UserSettingsState build() {
    _load();
    return const UserSettingsState(isLoading: true);
  }

  Future<void> _load() async {
    final uid = _uid;
    if (uid == null) {
      state = state.copyWith(isLoading: false);
      return;
    }
    try {
      final doc = await _db.collection('users').doc(uid).get();
      state = state.copyWith(
        settings: UserSettings.fromFirestore(doc),
        isLoading: false,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  void update(UserSettings settings) {
    state = state.copyWith(settings: settings);
  }

  Future<String?> uploadAvatar(File file) async {
    final uid = _uid;
    if (uid == null) return null;
    final ref = _storage.ref('avatars/$uid.jpg');
    await ref.putFile(file);
    return ref.getDownloadURL();
  }

  Future<bool> adjustBalance(int delta) async {
    update(state.settings.copyWith(totalEarned: state.settings.totalEarned + delta));
    return save();
  }

  Future<bool> save() async {
    final uid = _uid;
    if (uid == null) return false;
    state = state.copyWith(isSaving: true);
    try {
      await _db
          .collection('users')
          .doc(uid)
          .set(state.settings.toFirestore(), SetOptions(merge: true))
          .timeout(const Duration(seconds: 15));
      state = state.copyWith(isSaving: false);
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, errorMessage: '保存に失敗しました: $e');
      return false;
    }
  }
}

final userSettingsProvider =
    NotifierProvider<UserSettingsViewModel, UserSettingsState>(
  UserSettingsViewModel.new,
);
