import 'package:flutter/material.dart';

// --- YARDIMCI FONKSİYONLAR ---
bool isSameDay(DateTime? a, DateTime? b) {
  if (a == null || b == null) return false;
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

String getTurkishDayName(int weekday) {
  switch (weekday) {
    case 1:
      return 'Pzt';
    case 2:
      return 'Sal';
    case 3:
      return 'Çar';
    case 4:
      return 'Per';
    case 5:
      return 'Cum';
    case 6:
      return 'Cmt';
    case 7:
      return 'Paz';
    default:
      return '';
  }
}

// --- MODELLER ---

enum PlanPriority { low, medium, high }

class PlanCategory {
  final String name;
  final IconData icon;
  final Color color;

  const PlanCategory(this.name, this.icon, this.color);
}

class PlanItem {
  String id;
  String title;
  String? description;
  DateTime date; // 🚨 YENİ ALAN: Tarih bilgisi
  TimeOfDay startTime;
  TimeOfDay endTime;
  bool isCompleted;
  PlanCategory category;
  PlanPriority priority;

  PlanItem({
    required this.id,
    required this.title,
    this.description,
    required this.date, // Zorunlu alan
    required this.startTime,
    required this.endTime,
    this.isCompleted = false,
    required this.category,
    this.priority = PlanPriority.medium,
  });
}

// --- SABİT VERİLER ---

const List<PlanCategory> kCategories = [
  PlanCategory('İş', Icons.work_outline, Colors.blue),
  PlanCategory('Spor', Icons.fitness_center, Colors.orange),
  PlanCategory('Kişisel', Icons.person_outline, Colors.purple),
  PlanCategory('Eğitim', Icons.school_outlined, Colors.green),
  PlanCategory('Sosyal', Icons.people_outline, Colors.pink),
  PlanCategory('Ev', Icons.home_outlined, Colors.brown),
];

// --- SAYFA ---

class DailyPlannerPage extends StatefulWidget {
  const DailyPlannerPage({super.key});

  @override
  State<DailyPlannerPage> createState() => _DailyPlannerPageState();
}

class _DailyPlannerPageState extends State<DailyPlannerPage> {
  DateTime _selectedDate = DateTime.now(); // Seçili gün

  // Son 7 günü oluştur
  final List<DateTime> _weekDates = List.generate(7, (index) {
    return DateTime.now().subtract(Duration(days: 6 - index));
  });

  // Örnek Veriler (Tarihli)
  late List<PlanItem> _allPlans;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));

    _allPlans = [
      // BUGÜNÜN PLANLARI
      PlanItem(
        id: '1',
        title: 'Sabah Koşusu',
        description: 'Sahilde 5km hafif tempo.',
        date: today,
        startTime: const TimeOfDay(hour: 07, minute: 00),
        endTime: const TimeOfDay(hour: 07, minute: 45),
        category: kCategories[1], // Spor
        priority: PlanPriority.high,
        isCompleted: true,
      ),
      PlanItem(
        id: '2',
        title: 'Flutter Proje Toplantısı',
        date: today,
        startTime: const TimeOfDay(hour: 09, minute: 30),
        endTime: const TimeOfDay(hour: 10, minute: 30),
        category: kCategories[0], // İş
        priority: PlanPriority.medium,
      ),

      // DÜNÜN PLANLARI (Geçmiş kontrolü için)
      PlanItem(
        id: '3',
        title: 'Kitap Okuma',
        description: 'Otomatik Portakal - 30 sayfa',
        date: yesterday,
        startTime: const TimeOfDay(hour: 21, minute: 00),
        endTime: const TimeOfDay(hour: 22, minute: 00),
        category: kCategories[2], // Kişisel
        isCompleted: false, // Yapılmamış
        priority: PlanPriority.low,
      ),
      PlanItem(
        id: '4',
        title: 'Market Alışverişi',
        date: yesterday,
        startTime: const TimeOfDay(hour: 18, minute: 00),
        endTime: const TimeOfDay(hour: 19, minute: 00),
        category: kCategories[5], // Ev
        isCompleted: true, // Yapılmış
        priority: PlanPriority.medium,
      ),
    ];
  }

  // Seçili güne ait planları filtrele
  List<PlanItem> get _currentPlans {
    return _allPlans.where((p) => isSameDay(p.date, _selectedDate)).toList();
  }

  double get _progress {
    final plans = _currentPlans;
    if (plans.isEmpty) return 0.0;
    int completed = plans.where((p) => p.isCompleted).length;
    return completed / plans.length;
  }

  void _addNewTask(PlanItem newItem) {
    setState(() {
      _allPlans.add(newItem);
      // (Sıralama sadece görüntüleme anında yapılabilir veya burada tüm listeyi sıralayabiliriz)
    });
  }

  void _deleteTask(String id) {
    setState(() {
      _allPlans.removeWhere((item) => item.id == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final filteredPlans = _currentPlans;

    // Saat sıralaması
    filteredPlans.sort((a, b) {
      final aMin = a.startTime.hour * 60 + a.startTime.minute;
      final bMin = b.startTime.hour * 60 + b.startTime.minute;
      return aMin.compareTo(bMin);
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Column(
          children: [
            Text(
              'Günlük Akış',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: Colors.black87,
              ),
            ),
            Text(
              'Geçmişini ve Gününü Yönet',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.calendar_today_outlined,
              color: Colors.black87,
            ),
            onPressed: () {
              // Bugün'e hızlı dönüş
              setState(() {
                _selectedDate = DateTime.now();
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. TARİH SEÇİCİ (YENİ)
          _buildDateSelector(),

          // 2. İLERLEME KARTI
          _buildHeaderSection(primaryColor),

          // 3. GÖREV LİSTESİ
          Expanded(
            child: filteredPlans.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                    itemCount: filteredPlans.length,
                    itemBuilder: (context, index) =>
                        _buildPlanCard(filteredPlans[index]),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showEnhancedAddTaskDialog(context),
        backgroundColor: Colors.black87,
        elevation: 4,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Yeni Plan',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // --- WIDGETS ---

  Widget _buildDateSelector() {
    return Container(
      height: 85,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        scrollDirection: Axis.horizontal,
        itemCount: _weekDates.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final date = _weekDates[index];
          final isSelected = isSameDay(date, _selectedDate);
          final isToday = isSameDay(date, DateTime.now());

          return GestureDetector(
            onTap: () => setState(() => _selectedDate = date),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 55,
              decoration: BoxDecoration(
                color: isSelected ? Colors.black87 : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: isToday && !isSelected
                    ? Border.all(color: Colors.black87, width: 1.5)
                    : Border.all(color: Colors.transparent),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 4,
                        ),
                      ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    getTurkishDayName(date.weekday),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.white70 : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${date.day}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                  ),
                  if (isToday && !isSelected)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: Colors.black87,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderSection(Color primaryColor) {
    final currentProgress = _progress;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20), // Biraz küçülttüm
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.black87, Colors.grey[800]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isSameDay(_selectedDate, DateTime.now())
                      ? 'Bugünün Durumu'
                      : 'Geçmiş Özeti',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  '%${(currentProgress * 100).toInt()}',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: currentProgress,
                    minHeight: 6,
                    backgroundColor: Colors.white.withOpacity(0.1),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.greenAccent,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Container(
            height: 50,
            width: 50,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              currentProgress == 1
                  ? Icons.check_circle
                  : Icons.pie_chart_outline,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(PlanItem plan) {
    bool isDone = plan.isCompleted;
    Color priorityColor;
    switch (plan.priority) {
      case PlanPriority.high:
        priorityColor = Colors.redAccent;
        break;
      case PlanPriority.medium:
        priorityColor = Colors.orangeAccent;
        break;
      case PlanPriority.low:
        priorityColor = Colors.blueGrey;
        break;
    }

    return Dismissible(
      key: Key(plan.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(
          Icons.delete_sweep_outlined,
          color: Colors.red[400],
          size: 30,
        ),
      ),
      onDismissed: (_) => _deleteTask(plan.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              setState(() => plan.isCompleted = !plan.isCompleted);
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sol: Saat
                  Column(
                    children: [
                      Text(
                        plan.startTime.format(context),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: isDone ? Colors.grey[400] : Colors.black87,
                        ),
                      ),
                      Container(
                        width: 2,
                        height: 24,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: isDone
                              ? Colors.grey[200]
                              : plan.category.color.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Text(
                        plan.endTime.format(context),
                        style: TextStyle(fontSize: 10, color: Colors.grey[400]),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),

                  // Orta: İçerik
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: plan.category.color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    plan.category.icon,
                                    size: 10,
                                    color: plan.category.color,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    plan.category.name,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: plan.category.color,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            if (plan.priority == PlanPriority.high && !isDone)
                              Icon(
                                Icons.priority_high_rounded,
                                size: 14,
                                color: priorityColor,
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          plan.title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            decoration: isDone
                                ? TextDecoration.lineThrough
                                : null,
                            color: isDone ? Colors.grey[400] : Colors.black87,
                          ),
                        ),
                        if (plan.description != null &&
                            plan.description!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            plan.description!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: isDone
                                  ? Colors.grey[300]
                                  : Colors.grey[500],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Sağ: Checkbox
                  const SizedBox(width: 8),
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDone ? Colors.green : Colors.transparent,
                      border: Border.all(
                        color: isDone ? Colors.green : Colors.grey[300]!,
                        width: 2,
                      ),
                    ),
                    child: isDone
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    bool isToday = isSameDay(_selectedDate, DateTime.now());
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isToday ? Icons.event_note_rounded : Icons.history_toggle_off,
            size: 64,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            isToday ? 'Bugün Henüz Plan Yok' : 'Bu Tarihte Kayıt Yok',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          if (isToday)
            Text(
              'Günü planlamak için hemen başla.',
              style: TextStyle(fontSize: 14, color: Colors.grey[400]),
            ),
        ],
      ),
    );
  }

  // --- MODAL ---
  void _showEnhancedAddTaskDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descController = TextEditingController();

    TimeOfDay selectedStart = TimeOfDay.now();
    TimeOfDay selectedEnd = TimeOfDay.now().replacing(
      hour: TimeOfDay.now().hour + 1,
    );
    PlanCategory selectedCategory = kCategories[0];
    PlanPriority selectedPriority = PlanPriority.medium;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Column(
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
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        // Eklenecek tarihi göster
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
                                '${_selectedDate.day}.${_selectedDate.month}.${_selectedDate.year}',
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

                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        const Text(
                          'Kategori',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 90,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: kCategories.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 12),
                            itemBuilder: (context, index) {
                              final cat = kCategories[index];
                              final isSelected = selectedCategory == cat;
                              return GestureDetector(
                                onTap: () =>
                                    setModalState(() => selectedCategory = cat),
                                child: Column(
                                  children: [
                                    AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? cat.color
                                            : Colors.grey[100],
                                        shape: BoxShape.circle,
                                        boxShadow: isSelected
                                            ? [
                                                BoxShadow(
                                                  color: cat.color.withOpacity(
                                                    0.4,
                                                  ),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 4),
                                                ),
                                              ]
                                            : [],
                                      ),
                                      child: Icon(
                                        cat.icon,
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.grey[500],
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
                                        color: isSelected
                                            ? Colors.black87
                                            : Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 24),

                        TextField(
                          controller: titleController,
                          decoration: InputDecoration(
                            labelText: 'Plan Başlığı',
                            hintText: 'Örn: Raporu Hazırla',
                            filled: true,
                            fillColor: Colors.grey[50],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            prefixIcon: const Icon(Icons.title),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: descController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: 'Notlar',
                            filled: true,
                            fillColor: Colors.grey[50],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            prefixIcon: const Icon(Icons.notes),
                            alignLabelWithHint: true,
                          ),
                        ),

                        const SizedBox(height: 24),

                        const Text(
                          'Zaman Aralığı',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTimeSelector(
                                context,
                                'Başlangıç',
                                selectedStart,
                                (val) =>
                                    setModalState(() => selectedStart = val),
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Icon(Icons.arrow_forward, color: Colors.grey),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildTimeSelector(
                                context,
                                'Bitiş',
                                selectedEnd,
                                (val) => setModalState(() => selectedEnd = val),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        const Text(
                          'Öncelik',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
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
                                  onTap: () => setModalState(
                                    () => selectedPriority = priority,
                                  ),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    alignment: Alignment.center,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: isSelected
                                          ? [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(
                                                  0.05,
                                                ),
                                                blurRadius: 4,
                                              ),
                                            ]
                                          : [],
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        if (isSelected) ...[
                                          Icon(
                                            Icons.circle,
                                            size: 8,
                                            color: activeColor,
                                          ),
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
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),

                  Container(
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
                        onPressed: () {
                          if (titleController.text.isNotEmpty) {
                            final newItem = PlanItem(
                              id: DateTime.now().toString(),
                              title: titleController.text,
                              description: descController.text,
                              date: _selectedDate, // 🚨 SEÇİLİ GÜNE EKLE
                              startTime: selectedStart,
                              endTime: selectedEnd,
                              category: selectedCategory,
                              priority: selectedPriority,
                            );
                            _addNewTask(newItem);
                            Navigator.pop(context);
                          }
                        },
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
                  ),
                ],
              ),
            );
          },
        );
      },
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
