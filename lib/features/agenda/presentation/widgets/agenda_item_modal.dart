// lib/features/agenda/presentation/widgets/agenda_item_modal.dart
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/agenda_item.dart';

// Modalı kapatıp yeni öğeyi listeye eklemek için callback
typedef AgendaItemCallback = void Function(AgendaItem item);

class AgendaItemModal extends StatefulWidget {
  final AgendaItem? item; // Düzenleme modunda null değil
  final AgendaItemCallback onSubmit;

  const AgendaItemModal({super.key, this.item, required this.onSubmit});

  @override
  State<AgendaItemModal> createState() => _AgendaItemModalState();
}

class _AgendaItemModalState extends State<AgendaItemModal> {
  final _formKey = GlobalKey<FormState>();
  late String _title;
  late String _description;
  late DateTime _dueDate;
  late bool _hasNotification;

  @override
  void initState() {
    super.initState();
    // Eğer düzenleme modu ise mevcut verileri yükle
    _title = widget.item?.title ?? '';
    _description = widget.item?.description ?? '';
    _dueDate =
        widget.item?.dueDate ?? DateTime.now().add(const Duration(days: 1));
    _hasNotification = widget.item?.hasNotification ?? true;
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null && picked != _dueDate) {
      setState(() {
        _dueDate = picked;
      });
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final newItem = AgendaItem(
        id:
            widget.item?.id ??
            const Uuid().v4(), // Yeni ID oluştur veya mevcut ID'yi kullan
        title: _title,
        description: _description,
        dueDate: _dueDate,
        isCompleted: widget.item?.isCompleted ?? false,
        hasNotification: _hasNotification,
      );

      widget.onSubmit(newItem);
      Navigator.pop(context); // Modalı kapat
    }
  }

  @override
  Widget build(BuildContext context) {
    // Klavyenin ekranı kaydırmasını engellemek için Padding
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              blurRadius: 10,
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 5,
            ),
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.item == null ? 'Yeni Görev Ekle' : 'Görevi Düzenle',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  initialValue: _title,
                  decoration: const InputDecoration(
                    labelText: 'Görev Başlığı',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                  ),
                  validator: (value) =>
                      value!.isEmpty ? 'Başlık zorunludur.' : null,
                  onSaved: (value) => _title = value!,
                ),
                const SizedBox(height: 15),
                TextFormField(
                  initialValue: _description,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Açıklama (İsteğe bağlı)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                  ),
                  onSaved: (value) => _description = value!,
                ),
                const SizedBox(height: 20),
                ListTile(
                  title: Text(
                    'Son Tarih: ${_dueDate.day}/${_dueDate.month}/${_dueDate.year}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  trailing: const Icon(Icons.edit_calendar),
                  onTap: () => _selectDate(context),
                ),
                const Divider(),
                SwitchListTile(
                  title: const Text('Hatırlatıcı Ayarla (1 gün önce)'),
                  value: _hasNotification,
                  onChanged: (bool value) {
                    setState(() {
                      _hasNotification = value;
                    });
                  },
                  activeColor: Colors.teal,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey.shade800,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(widget.item == null ? 'Ekle' : 'Kaydet'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
