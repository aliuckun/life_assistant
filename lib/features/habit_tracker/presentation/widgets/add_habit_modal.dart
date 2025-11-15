//lib/habit_tracker/presentation/widgets/add_habit_modal.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:life_assistant/features/habit_tracker/domain/entities/habit.dart';

class AddHabitModal extends StatefulWidget {
  final Function(Habit) onSave;

  const AddHabitModal({super.key, required this.onSave});

  @override
  State<AddHabitModal> createState() => _AddHabitModalState();
}

class _AddHabitModalState extends State<AddHabitModal> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _targetCountController = TextEditingController(
    text: '1',
  );
  HabitType _habitType = HabitType.gain;
  bool _enableNotification = true;
  TimeOfDay _notificationTime = TimeOfDay.now();

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

    // 🔥 HIVE için Habit.create() kullanıyoruz
    final newHabit = Habit.create(
      id: '', // Repository tarafından oluşturulacak
      name: name, // ✅ _nameController.text yerine 'name' değişkeni
      type: _habitType, // ✅ _habitType kullanıyoruz
      targetCount: targetCount, // ✅ targetCount değişkeni
      enableNotification: _enableNotification, // ✅ _enableNotification
      notificationTime: _enableNotification
          ? _notificationTime
          : null, // ✅ _notificationTime
      progress: {}, // Boş progress ile başla
    );

    widget.onSave(newHabit);
    context.pop();
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
            Text(
              'Yeni Alışkanlık Ekle',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: Colors.white),
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
                    : 'Günlük Hedef (Sadece 0 kabul edilir)',
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
              style: const TextStyle(color: Colors.white),
              enabled: _habitType == HabitType.gain,
            ),
            const SizedBox(height: 15),
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
                backgroundColor: Theme.of(context).primaryColor,
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
