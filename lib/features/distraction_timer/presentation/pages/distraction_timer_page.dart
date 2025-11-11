// lib/features/distraction_timer/presentation/pages/distraction_timer_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/distraction_timer_notifier.dart';

class DistractionTimerPage extends ConsumerStatefulWidget {
  const DistractionTimerPage({super.key});

  @override
  ConsumerState<DistractionTimerPage> createState() =>
      _DistractionTimerPageState();
}

class _DistractionTimerPageState extends ConsumerState<DistractionTimerPage>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // 🚫 UYGULAMA İÇİ MODAL DİNLEYİCİSİNİ KALDIRDIK
    // Artık sadece sistem bildirimi kullanılıyor
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Uygulama Yaşam Döngüsünü Yakalama
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final notifier = ref.read(distractionTimerProvider.notifier);

    switch (state) {
      case AppLifecycleState.paused:
        // Uygulama arka plana atıldı
        notifier.setBackground();
        print('📱 Uygulama arka plana gitti - Timer başladı');
        break;
      case AppLifecycleState.resumed:
        // Uygulama ön plana geri geldi
        notifier.setForeground();
        print('📱 Uygulama ön plana geldi - Timer durumu güncellendi');
        break;
      default:
        break;
    }
  }

  // Süre seçimi için modal
  void _showLimitSelectionModal() {
    int currentMinutes = ref
        .read(distractionTimerProvider)
        .settings
        .limit
        .inMinutes;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Dikkat Dağılma Limitini Ayarla',
          style: TextStyle(color: Colors.white),
        ),
        content: DropdownButtonFormField<int>(
          value: currentMinutes,
          dropdownColor: Colors.grey[800],
          decoration: const InputDecoration(
            labelText: 'Dakika',
            labelStyle: TextStyle(color: Colors.grey),
          ),
          items: [1, 2, 3, 5, 10, 15, 20]
              .map(
                (min) => DropdownMenuItem(
                  value: min,
                  child: Text(
                    '$min Dakika',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              )
              .toList(),
          onChanged: (min) {
            if (min != null) {
              currentMinutes = min;
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              ref
                  .read(distractionTimerProvider.notifier)
                  .setLimit(Duration(minutes: currentMinutes));
              Navigator.pop(ctx);
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(distractionTimerProvider);
    final notifier = ref.read(distractionTimerProvider.notifier);

    if (!state.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    final String minutes = (state.elapsedDuration.inMinutes % 60)
        .toString()
        .padLeft(2, '0');
    final String seconds = (state.elapsedDuration.inSeconds % 60)
        .toString()
        .padLeft(2, '0');

    final bool isExceeded = state.status == TimerStatus.exceeded;
    final bool isRunning = state.status == TimerStatus.running;
    final bool isPaused = state.isAppInBackground && isRunning;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // AÇ/KAPA DÜĞMESİ
            SwitchListTile(
              title: const Text(
                'Odaklanma Koruması Aktif',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                state.isGloballyActive
                    ? '🔔 Arka plana geçtiğinizde sayım başlar ve bildirim gelecek.'
                    : 'Koruma Pasif. Sayım yapılmayacaktır.',
                style: TextStyle(
                  color: state.isGloballyActive
                      ? Colors.greenAccent
                      : Colors.redAccent,
                ),
              ),
              value: state.isGloballyActive,
              onChanged: (newValue) {
                notifier.setGlobalActive(newValue);
              },
              activeColor: Colors.green,
            ),

            const SizedBox(height: 30),

            // LİMİT AYARI
            ListTile(
              leading: const Icon(Icons.timer, color: Colors.blueAccent),
              title: Text(
                'Süre Limiti: ${state.settings.limit.inMinutes} dakika',
                style: const TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                '⚠️ Bu süreden sonra sistem bildirimi alacaksınız.',
                style: TextStyle(color: Colors.grey),
              ),
              trailing: const Icon(Icons.edit, color: Colors.grey),
              onTap: _showLimitSelectionModal,
            ),

            const SizedBox(height: 60),

            // DURUM GÖSTERGE KARTI
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isExceeded
                    ? Colors.red.withOpacity(0.2)
                    : isRunning
                    ? Colors.orange.withOpacity(0.2)
                    : Colors.grey.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isExceeded
                      ? Colors.red
                      : isRunning
                      ? Colors.orange
                      : Colors.grey,
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  // DURUM METNİ
                  if (isExceeded)
                    const Column(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.red,
                          size: 48,
                        ),
                        SizedBox(height: 10),
                        Text(
                          '⚠️ LİMİT AŞILDI',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Telefonunuza sistem bildirimi gönderildi.\nOdağınıza geri dönün!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    )
                  else if (isRunning)
                    Column(
                      children: [
                        Icon(
                          isPaused ? Icons.pause_circle : Icons.play_circle,
                          color: isPaused ? Colors.orange : Colors.green,
                          size: 48,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          isPaused
                              ? '⏸️ ARKA PLANDA SAYILIYOR'
                              : '▶️ TIMER AKTİF',
                          style: TextStyle(
                            color: isPaused ? Colors.orange : Colors.green,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        // SÜRE GÖSTERİMİ
                        Text(
                          '$minutes:$seconds',
                          style: const TextStyle(
                            fontSize: 72,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 4,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Limit: ${state.settings.limit.inMinutes} dakika',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    )
                  else
                    const Column(
                      children: [
                        Icon(Icons.shield, color: Colors.grey, size: 48),
                        SizedBox(height: 10),
                        Text(
                          '⏹️ HAZIR',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Koruma aktif edildiğinde,\narka plana geçtiğinizde sayım başlar.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ],
                    ),

                  // SIFIRLA BUTONU
                  if (isRunning || isExceeded) ...[
                    const SizedBox(height: 30),
                    ElevatedButton.icon(
                      onPressed: notifier.stopTimer,
                      icon: const Icon(Icons.refresh),
                      label: const Text('SIFIRLA'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 30),

            // BİLGİLENDİRME
            const Card(
              color: Colors.blue,
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.white),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Limit dolduğunda telefonunuza sistem bildirimi gelecektir.',
                        style: TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
