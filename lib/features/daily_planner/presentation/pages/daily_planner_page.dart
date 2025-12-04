import 'package:flutter/material.dart';
import '../../domain/plan_models.dart';
import '../../data/services/planner_service.dart';
import '../utils/planner_constants.dart';
import '../widgets/date_timeline.dart';
import '../widgets/planner_header.dart';
import '../widgets/plan_task_card.dart';
import '../widgets/add_task_sheet.dart';

class DailyPlannerPage extends StatefulWidget {
  const DailyPlannerPage({super.key});

  @override
  State<DailyPlannerPage> createState() => _DailyPlannerPageState();
}

class _DailyPlannerPageState extends State<DailyPlannerPage> {
  final PlannerService _service = PlannerService();
  DateTime _selectedDate = DateTime.now();
  List<PlanItem> _currentPlans = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initService();
  }

  // Hive servisini başlat ve verileri çek
  Future<void> _initService() async {
    await _service.init();
    _loadPlans();
  }

  // --- OPTİMİZE EDİLMİŞ VERİ YÜKLEME ---
  // Sıralama işlemini setState dışına taşıdık.
  void _loadPlans() {
    // 1. Veriyi çek
    final plans = _service.getPlansByDate(_selectedDate);

    // 2. Sıralamayı UI thread'ini kilitlemeden yap
    plans.sort((a, b) => a.startTimeInMinutes.compareTo(b.startTimeInMinutes));

    // 3. Sadece atama işlemi için setState kullan
    if (mounted) {
      setState(() {
        _currentPlans = plans;
        _isLoading = false;
      });
    }
  }

  double get _progress {
    if (_currentPlans.isEmpty) return 0.0;
    int completed = _currentPlans.where((p) => p.isCompleted).length;
    return completed / _currentPlans.length;
  }

  // --- CRUD İşlemleri ---

  void _addNewTask(PlanItem newItem) async {
    await _service.addPlan(newItem);
    _loadPlans();
  }

  void _toggleTask(PlanItem plan) async {
    plan.isCompleted = !plan.isCompleted;
    await _service.updatePlan(plan);
    _loadPlans();
  }

  void _deleteTask(String id) async {
    await _service.deletePlan(id);
    _loadPlans();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      // --- FPS DÜŞÜŞÜNÜ ENGELLEYEN KRİTİK AYAR ---
      // Klavye açıldığında sayfanın yeniden boyutlanıp sıkışmasını engeller.
      resizeToAvoidBottomInset: false,

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
              setState(() {
                _selectedDate = DateTime.now();
                _loadPlans();
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Tarih Seçici
          DateTimeline(
            selectedDate: _selectedDate,
            onDateSelected: (date) {
              setState(() {
                _selectedDate = date;
                _loadPlans();
              });
            },
          ),

          // 2. İlerleme Kartı
          PlannerHeader(
            progress: _progress,
            isToday: PlannerConstants.isSameDay(_selectedDate, DateTime.now()),
          ),

          // 3. Liste (Optimize Edildi)
          Expanded(
            child: _currentPlans.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                    // cacheExtent: Ekran dışında kalan öğeleri önceden yükleyerek
                    // kaydırma (scroll) sırasında takılmaları azaltır.
                    cacheExtent: 500,
                    itemCount: _currentPlans.length,
                    itemBuilder: (context, index) {
                      final plan = _currentPlans[index];
                      return PlanTaskCard(
                        // Key kullanımı Flutter'ın hangi widget'ın değiştiğini
                        // anlamasını kolaylaştırır ve gereksiz çizimi önler.
                        key: ValueKey(plan.id),
                        plan: plan,
                        onToggle: () => _toggleTask(plan),
                        onDelete: () => _deleteTask(plan.id),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            // Klavye padding'ini bottom sheet içinde yönetmek daha sağlıklıdır
            builder: (context) => Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: AddTaskSheet(
                selectedDate: _selectedDate,
                onSaved: _addNewTask,
              ),
            ),
          );
        },
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

  Widget _buildEmptyState() {
    bool isToday = PlannerConstants.isSameDay(_selectedDate, DateTime.now());
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
}
