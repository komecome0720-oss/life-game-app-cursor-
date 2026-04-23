import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_manager/features/wish_list/viewmodel/wish_list_viewmodel.dart';

class AddWishItemSheet extends ConsumerStatefulWidget {
  const AddWishItemSheet({super.key});

  @override
  ConsumerState<AddWishItemSheet> createState() => _AddWishItemSheetState();
}

class _AddWishItemSheetState extends ConsumerState<AddWishItemSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _shopUrlCtrl = TextEditingController();
  final _imageUrlCtrl = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _shopUrlCtrl.dispose();
    _imageUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    await ref.read(wishListProvider.notifier).addItem(
          name: _nameCtrl.text.trim(),
          price: int.parse(_priceCtrl.text),
          shopUrl: _shopUrlCtrl.text.trim(),
          imageUrl: _imageUrlCtrl.text.trim(),
        );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16, right: 16, top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('欲しいものを追加', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: '商品名 *', border: OutlineInputBorder()),
              validator: (v) => (v == null || v.trim().isEmpty) ? '商品名を入力してください' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _priceCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(labelText: '価格 *', suffixText: '円', border: OutlineInputBorder()),
              validator: (v) {
                final n = int.tryParse(v ?? '');
                if (n == null || n <= 0) return '価格を入力してください';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _shopUrlCtrl,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(labelText: 'ショップURL（任意）', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _imageUrlCtrl,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(labelText: '画像URL（任意）', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _isSaving ? null : _submit,
              child: _isSaving
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('追加'),
            ),
          ],
        ),
      ),
    );
  }
}
