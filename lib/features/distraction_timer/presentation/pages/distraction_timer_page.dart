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

// WidgetsBindingObserver ile uygulama yaşam döngüsünü dinleriz
class _DistractionTimerPageState extends ConsumerState<DistractionTimerPage>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Limit aşıldığında modal göstermek için dinleyici
    ref.listenManual(distractionTimerProvider, (previous, next) {
      // Limit aşıldıysa ve ön planda değilsek (yani tam döndüğümüzde) modalı göster
      if (next.status == TimerStatus.exceeded && !next.isAppInBackground) {
        // Build context'in geçerli olduğundan emin olmak için küçük bir gecikme
        Future.microtask(() => _showLimitExceededModal());
      }
    });
  }

  @override
  void dispose() {
    // Dinlemeyi bırak
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Uygulama Yaşam Döngüsünü Yakalama
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final notifier = ref.read(distractionTimerProvider.notifier);

    switch (state) {
      case AppLifecycleState.paused:
        // Uygulama arka plana atıldı (muhtemelen dikkat dağıtıcı uygulamaya geçildi)
        notifier.setBackground();
        break;
      case AppLifecycleState.resumed:
        // Uygulama ön plana geri geldi
        notifier.setForeground();
        break;
      default:
        break;
    }
  }

  // Limit aşıldığında gösterilecek tam ekran modal
  void _showLimitExceededModal() {
    // Sadece sayfa ön plandayken göster
    if (ModalRoute.of(context)?.isCurrent == true) {
      showDialog(
        context: context,
        barrierDismissible: false, // Kullanıcı kapatamaz, eylem yapmalı
        builder: (ctx) => AlertDialog(
          backgroundColor: Colors.red[800],
          title: const Text(
            '!!! ODAKLANMA KORUMASI DEVREDE !!!',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            'Belirlediğin ${ref.read(distractionTimerProvider).settings.limit.inMinutes} dakikalık dikkat dağılma limiti doldu. Lütfen odağına geri dön.',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                // Sayacı durdur ve modalı kapat
                ref.read(distractionTimerProvider.notifier).stopTimer();
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
              child: Text(
                'TAMAM, GERİ DÖNÜYORUM',
                style: TextStyle(color: Colors.red[900]),
              ),
            ),
          ],
        ),
      );
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
        backgroundColor: Colors.grey[900], // Temaya uyum için
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

    // Yükleniyor ekranı (Persistence için)
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
    final bool isPaused =
        state.isAppInBackground && isRunning; // Arka planda sayım yapıyorsa

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // AÇ/KAPA DÜĞMESİ (Toggle Switch)
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
                    ? 'Arka plana geçtiğinizde sayım başlar.'
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
                'Bu süreden sonra uyarı alacaksınız.',
                style: TextStyle(color: Colors.grey),
              ),
              trailing: const Icon(Icons.edit, color: Colors.grey),
              onTap: _showLimitSelectionModal,
            ),

            const SizedBox(height: 60),

            // SÜRE GÖRSELLEŞTİRME (A Özelliği)
            if (isRunning)
              Column(
                children: [
                  Text(
                    isPaused
                        ? 'ARKA PLANDA GEÇEN SÜRE'
                        : 'ODAĞINIZDA GEÇEN SÜRE',
                    style: TextStyle(
                      color: isPaused ? Colors.redAccent : Colors.greenAccent,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '$minutes:$seconds',
                    style: TextStyle(
                      fontSize: 80,
                      fontWeight: FontWeight.bold,
                      color: isExceeded ? Colors.red : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Bu buton, limit aşılsa bile ön plana geldiğinizde sayacı sıfırlar
                  ElevatedButton.icon(
                    onPressed: notifier.stopTimer,
                    icon: const Icon(Icons.stop),
                    label: const Text('SIFIRLA VE KORUMAYI YENİLE'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 15,
                      ),
                    ),
                  ),
                ],
              )
            else
              const Text(
                'Koruma ayarları yapıldı. Lütfen anahtarı aktif edin ve uygulamadan ayrılın.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }
}
