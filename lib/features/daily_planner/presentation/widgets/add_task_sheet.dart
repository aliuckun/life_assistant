import 'package:flutter/material.dart';
import '../../domain/plan_models.dart';
import '../utils/planner_constants.dart';

class AddTaskSheet extends StatefulWidget {
  final DateTime selectedDate;
  final Function(PlanItem) onSaved;

  const AddTaskSheet({
    super.key,
    required this.selectedDate,
    required this.onSaved,
  });

  @override
  State<AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<AddTaskSheet> {
  final titleController = TextEditingController();
  final descController = TextEditingController();

  @override
  void dispose() {
    titleController.dispose();
    descController.dispose();
    super.dispose();
  }

  TimeOfDay selectedStart = TimeOfDay.now();
  TimeOfDay selectedEnd = TimeOfDay.now().replacing(
    // 24'e bölümünden kalanı alarak 23'ten sonra 0'a dönmesini sağlıyoruz
    hour: (TimeOfDay.now().hour + 1) % 24,
  );
  PlanCategory selectedCategory = PlannerConstants.categories[0];
  PlanPriority selectedPriority = PlanPriority.medium;

  @override
  Widget build(BuildContext context) {
    // Klavye açılınca ekran boyutu değişse bile sayfanın toplam yüksekliğini sabitliyoruz.
    // Bu sayede klavye animasyonu sırasında tüm sayfa titremez.
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.85,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            // Tutamaç ve Header
            _SheetHeader(date: widget.selectedDate),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24),
                // Klavye açılınca listenin zıplamasını önlemek için:
                physics: const ClampingScrollPhysics(),
                children: [
                  // --- OPTİMİZASYON 1: Kategori Seçici Ayrıldı ---
                  _CategorySelector(
                    selectedCategory: selectedCategory,
                    onCategoryChanged: (cat) {
                      setState(() => selectedCategory = cat);
                    },
                  ),
                  const SizedBox(height: 24),

                  // Text Fields
                  _buildTextFields(),
                  const SizedBox(height: 24),

                  // Zaman Seçici
                  _TimeSection(
                    start: selectedStart,
                    end: selectedEnd,
                    onStartChanged: (val) =>
                        setState(() => selectedStart = val),
                    onEndChanged: (val) => setState(() => selectedEnd = val),
                  ),
                  const SizedBox(height: 24),

                  // --- OPTİMİZASYON 2: Öncelik Seçici Ayrıldı ---
                  _PrioritySelector(
                    selectedPriority: selectedPriority,
                    onPriorityChanged: (p) {
                      setState(() => selectedPriority = p);
                    },
                  ),

                  // Klavye açılınca en altta boşluk kalsın
                  SizedBox(
                    height: MediaQuery.of(context).viewInsets.bottom + 100,
                  ),
                ],
              ),
            ),

            // Kaydet Butonu (Sabit Alt Kısım)
            _SaveButton(
              onPressed: () {
                if (titleController.text.isNotEmpty) {
                  final newItem = PlanItem(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    title: titleController.text,
                    description: descController.text,
                    date: widget.selectedDate,
                    startTimeInMinutes:
                        selectedStart.hour * 60 + selectedStart.minute,
                    endTimeInMinutes:
                        selectedEnd.hour * 60 + selectedEnd.minute,
                    categoryName: selectedCategory.name,
                    priorityIndex: selectedPriority.index,
                  );
                  widget.onSaved(newItem);
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextFields() {
    // Ortak stil tanımları (Kod tekrarını önlemek ve tutarlılık için)
    final inputDecorationTheme = InputDecoration(
      filled: true,
      // Daha belirgin bir arka plan rengi (Açık Gri)
      fillColor: const Color(0xFFF3F4F6),

      // Yazı yazılmıyorken görünen kenarlık (Hafif gri çizgi)
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
      ),

      // Yazı yazılırken (tıklanınca) görünen kenarlık (Siyah ve belirgin)
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.black87, width: 1.5),
      ),

      // Hata durumunda
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1),
      ),

      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),

      // Label (Etiket) stili
      labelStyle: TextStyle(
        color: Colors.grey.shade600,
        fontWeight: FontWeight.w500,
      ),

      // İkon rengi
      prefixIconColor: Colors.grey.shade700,
    );

    // Yazılan metnin stili
    const textStyle = TextStyle(
      color: Colors.black87, // Koyu siyah
      fontSize: 16,
      fontWeight: FontWeight.w600, // Biraz kalın, okunabilir
    );

    return Column(
      children: [
        // BAŞLIK ALANI
        TextField(
          controller: titleController,
          textInputAction: TextInputAction.next,
          style: textStyle, // Yazı rengini uygula
          cursorColor: Colors.black, // İmleç rengi
          decoration: inputDecorationTheme.copyWith(
            labelText: 'Plan Başlığı',
            hintText: 'Örn: Raporu Hazırla',
            hintStyle: TextStyle(color: Colors.grey.shade400),
            prefixIcon: const Icon(Icons.title_rounded),
          ),
        ),

        const SizedBox(height: 16),

        // NOTLAR ALANI
        TextField(
          controller: descController,
          maxLines: 3,
          textInputAction: TextInputAction.done,
          style: textStyle, // Yazı rengini uygula
          cursorColor: Colors.black,
          decoration: inputDecorationTheme.copyWith(
            labelText: 'Notlar',
            hintText: 'Detayları buraya ekle...',
            hintStyle: TextStyle(color: Colors.grey.shade400),
            prefixIcon: const Icon(Icons.notes_rounded),
            alignLabelWithHint: true, // İkonu yukarı hizalar
          ),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// AŞAĞIDAKİ WIDGET'LAR AYRIŞTIRILARAK PERFORMANS ARTIRILDI
// Flutter bunları "const" gibi işleyerek gereksiz render'ı önler.
// -----------------------------------------------------------------------------

class _CategorySelector extends StatelessWidget {
  final PlanCategory selectedCategory;
  final ValueChanged<PlanCategory> onCategoryChanged;

  const _CategorySelector({
    required this.selectedCategory,
    required this.onCategoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Kategori',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 90,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: PlannerConstants.categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final cat = PlannerConstants.categories[index];
              final isSelected = selectedCategory.name == cat.name;
              return GestureDetector(
                onTap: () => onCategoryChanged(cat),
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected ? cat.color : Colors.grey[100],
                        shape: BoxShape.circle,
                        // Gölgeyi sadece seçiliyse çiz, performansı koru
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: cat.color.withOpacity(0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                      child: Icon(
                        cat.icon,
                        color: isSelected ? Colors.white : Colors.grey[500],
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      cat.name,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isSelected ? Colors.black87 : Colors.grey,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PrioritySelector extends StatelessWidget {
  final PlanPriority selectedPriority;
  final ValueChanged<PlanPriority> onPriorityChanged;

  const _PrioritySelector({
    required this.selectedPriority,
    required this.onPriorityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Öncelik',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: PlanPriority.values.map((priority) {
              final isSelected = selectedPriority == priority;
              Color activeColor;
              String label;
              switch (priority) {
                case PlanPriority.low:
                  activeColor = Colors.blueGrey;
                  label = 'Düşük';
                  break;
                case PlanPriority.medium:
                  activeColor = Colors.orange;
                  label = 'Orta';
                  break;
                case PlanPriority.high:
                  activeColor = Colors.red;
                  label = 'Yüksek';
                  break;
              }
              return Expanded(
                child: GestureDetector(
                  onTap: () => onPriorityChanged(priority),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4,
                              ),
                            ]
                          : [],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isSelected) ...[
                          Icon(Icons.circle, size: 8, color: activeColor),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          label,
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w500,
                            color: isSelected
                                ? Colors.black87
                                : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _TimeSection extends StatelessWidget {
  final TimeOfDay start;
  final TimeOfDay end;
  final ValueChanged<TimeOfDay> onStartChanged;
  final ValueChanged<TimeOfDay> onEndChanged;

  const _TimeSection({
    required this.start,
    required this.end,
    required this.onStartChanged,
    required this.onEndChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Zaman Aralığı',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildTimeSelector(
                context,
                'Başlangıç',
                start,
                onStartChanged,
              ),
            ),
            const SizedBox(width: 16),
            const Icon(Icons.arrow_forward, color: Colors.grey),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTimeSelector(context, 'Bitiş', end, onEndChanged),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTimeSelector(
    BuildContext context,
    String label,
    TimeOfDay time,
    Function(TimeOfDay) onSelected,
  ) {
    return GestureDetector(
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: time,
        );
        if (picked != null) onSelected(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              time.format(context),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  final DateTime date;
  const _SheetHeader({required this.date});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Center(
          child: Container(
            margin: const EdgeInsets.only(top: 12, bottom: 20),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              const Text(
                'Yeni Plan',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${date.day}.${date.month}.${date.year}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SaveButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _SaveButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black87,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: const Text(
            'Planı Kaydet',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
