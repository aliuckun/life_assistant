// lib/features/habit_tracker/presentation/widgets/edit_habit_modal.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:life_assistant/features/habit_tracker/domain/entities/habit.dart';

class EditHabitModal extends StatefulWidget {
  final Habit habit;
  final Function(Habit) onUpdate;
  final Function(String) onDelete;

  const EditHabitModal({
    super.key,
    required this.habit,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  State<EditHabitModal> createState() => _EditHabitModalState();
}

class _EditHabitModalState extends State<EditHabitModal> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _targetCountController = TextEditingController();

  late HabitType _habitType;
  late bool _enableNotification;
  late TimeOfDay _notificationTime;

  @override
  void initState() {
    super.initState();
    // Mevcut habit verilerini yükle
    _nameController.text = widget.habit.name;
    _targetCountController.text = widget.habit.targetCount.toString();
    _habitType = widget.habit.type;
    _enableNotification = widget.habit.enableNotification;
    _notificationTime = widget.habit.notificationTime ?? TimeOfDay.now();
  }

  void _selectTime() async {
    final TimeOfDay? newTime = await showTimePicker(
      context: context,
      initialTime: _notificationTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: Theme.of(context).primaryColor,
              onPrimary: Colors.white,
              surface: Colors.grey[800]!,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (newTime != null) {
      setState(() {
        _notificationTime = newTime;
      });
    }
  }

  void _saveHabit() {
    final name = _nameController.text.trim();
    final targetCount = int.tryParse(_targetCountController.text) ?? 1;

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen alışkanlık adını giriniz.')),
      );
      return;
    }

    final updatedHabit = widget.habit.copyWith(
      name: name,
      type: _habitType,
      targetCount: _habitType == HabitType.quit ? 1 : targetCount,
      enableNotification: _enableNotification,
      notificationTime: _enableNotification ? _notificationTime : null,
      // Progress'i koru:
      progress: widget.habit.progress,
    );

    widget.onUpdate(updatedHabit);
    context.pop();
  }

  void _deleteHabit() async {
    final confirmed = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Silme Onayı'),
        content: Text(
          '${widget.habit.name} alışkanlığını silmek istediğinizden emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      widget.onDelete(widget.habit.id);
      context.pop();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetCountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Alışkanlığı Düzenle',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(color: Colors.white),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_forever,
                    color: Colors.redAccent,
                  ),
                  onPressed: _deleteHabit,
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Alışkanlık Adı',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 15),
            // ... (RadioListTile'lar aynı kalır)
            Row(
              children: [
                Expanded(
                  child: RadioListTile<HabitType>(
                    title: const Text(
                      'Kazanmak',
                      style: TextStyle(color: Colors.white),
                    ),
                    value: HabitType.gain,
                    groupValue: _habitType,
                    onChanged: (HabitType? value) {
                      setState(() {
                        _habitType = value!;
                      });
                    },
                    activeColor: Colors.green,
                  ),
                ),
                Expanded(
                  child: RadioListTile<HabitType>(
                    title: const Text(
                      'Bırakmak',
                      style: TextStyle(color: Colors.white),
                    ),
                    value: HabitType.quit,
                    groupValue: _habitType,
                    onChanged: (HabitType? value) {
                      setState(() {
                        _habitType = value!;
                      });
                    },
                    activeColor: Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _targetCountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: _habitType == HabitType.gain
                    ? 'Günlük Hedef (Kaç Defa)'
                    : 'Bırakılacak Alışkanlık',
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
              style: const TextStyle(color: Colors.white),
              enabled: _habitType == HabitType.gain,
            ),
            const SizedBox(height: 15),
            // ... (Bildirim ayarları aynı kalır)
            CheckboxListTile(
              title: const Text(
                'Bildirim İstiyorum',
                style: TextStyle(color: Colors.white),
              ),
              value: _enableNotification,
              onChanged: (bool? value) {
                setState(() {
                  _enableNotification = value!;
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: Colors.blueAccent,
            ),
            if (_enableNotification)
              ListTile(
                title: const Text(
                  'Bildirim Saati Seç',
                  style: TextStyle(color: Colors.white70),
                ),
                trailing: Text(
                  _notificationTime.format(context),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                  ),
                ),
                onTap: _selectTime,
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveHabit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orangeAccent,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Kaydet',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
