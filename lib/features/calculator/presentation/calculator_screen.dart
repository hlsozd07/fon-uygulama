import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hive/hive.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'dart:io' show Platform;
import '../../../utils/date_calculator.dart';
import '../../history/domain/history_model.dart';
import '../../notifications/notification_service.dart';
import '../../tefas/data/tefas_service.dart';
import '../../../core/widgets/gradient_card.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  DateTime? _selectedDate;
  int _valorDays = 1;
  DateTime? _calculatedSellDate;
  bool _isFetchingTefas = false;
  final TextEditingController _fundNameController = TextEditingController();

  void _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      locale: const Locale('tr', 'TR'),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _calculatedSellDate = null; // Sonucu sıfırla
      });
    }
  }

  void _calculate() {
    if (_selectedDate == null) return;
    
    final sellDate = DateCalculator.calculateSellDate(_selectedDate!, _valorDays);
    
    setState(() {
      _calculatedSellDate = sellDate;
    });

    final historyBox = Hive.box<HistoryModel>('historyBox');
    final fundName = _fundNameController.text.trim().isEmpty ? 'İsimsiz Fon İşlemi' : _fundNameController.text.trim().toUpperCase();
    
    historyBox.add(HistoryModel(
      fundName: fundName,
      targetDate: _selectedDate!,
      valorDays: _valorDays,
      calculatedSellDate: sellDate,
      createdAt: DateTime.now(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fon Vakti', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Fon Kodu/Adı',
                style: theme.textTheme.displayMedium?.copyWith(fontSize: 24),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _fundNameController,
                      decoration: InputDecoration(
                        labelText: 'Fon Kodu veya Adı',
                        hintText: 'Örn: AFT',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isFetchingTefas ? null : () async {
                      if (_fundNameController.text.trim().isEmpty) return;
                      setState(() => _isFetchingTefas = true);
                      final fund = await TefasService().getFundDetails(_fundNameController.text.trim());
                      
                      if (mounted) {
                        setState(() {
                          _isFetchingTefas = false;
                          if (fund != null) {
                            _valorDays = fund.valor;
                            _fundNameController.text = fund.name;
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text('TEFAS\'tan veri çekildi. Valör: T+${fund.valor}'),
                              backgroundColor: Theme.of(context).colorScheme.primary,
                            ));
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: const Text('Fon TEFAS\'ta bulunamadı.'),
                              backgroundColor: Theme.of(context).colorScheme.error,
                            ));
                          }
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isFetchingTefas 
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Valör Bul'),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              Text(
                'Hedef Tarihiniz',
                style: theme.textTheme.displayMedium?.copyWith(fontSize: 24),
              ),
              const SizedBox(height: 8),
              Text(
                'Paranın elinize geçmesini istediğiniz tarihi seçin.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              
              // Tarih Seçici Kartı
              GradientCard(
                onTap: _pickDate,
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                child: Row(
                  children: [
                    Icon(Icons.calendar_month, color: theme.primaryColor, size: 32),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedDate == null 
                              ? 'Tarih Seçin' 
                              : DateFormat('dd MMMM yyyy, EEEE', 'tr_TR').format(_selectedDate!),
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: _selectedDate == null ? const Color(0xFFA1A1AA) : Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              Text(
                'Fon Valör Süresi',
                style: theme.textTheme.displayMedium?.copyWith(fontSize: 24),
              ),
              const SizedBox(height: 16),
              
              // Valör Seçimi
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 1, label: Text('T+1')),
                  ButtonSegment(value: 2, label: Text('T+2')),
                  ButtonSegment(value: 3, label: Text('T+3')),
                  ButtonSegment(value: 4, label: Text('T+4')),
                ],
                selected: {_valorDays},
                onSelectionChanged: (Set<int> newSelection) {
                  setState(() {
                    _valorDays = newSelection.first;
                    _calculatedSellDate = null;
                  });
                },
              ),
              
              const SizedBox(height: 40),
              
              ElevatedButton(
                onPressed: _selectedDate == null ? null : _calculate,
                child: const Text('Hesapla'),
              ),
              
              const SizedBox(height: 24),
              
              // Sonuç Gösterimi
              if (_calculatedSellDate != null)
                _buildResultCard(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultCard(ThemeData theme) {
    final dateStr = DateFormat('dd MMMM EEEE', 'tr_TR').format(_calculatedSellDate!);
    final timeStr = DateFormat('HH:mm', 'tr_TR').format(_calculatedSellDate!);
    
    return GradientCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 48),
          const SizedBox(height: 16),
          Text(
            'Satış Emri Vermeniz Gereken Zaman:',
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            '$dateStr\nSaat $timeStr\'a kadar',
            style: theme.textTheme.displayMedium?.copyWith(
              color: theme.primaryColor,
              fontSize: 22,
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () async {
              final sellDate = _calculatedSellDate!;
              final alarmTime = sellDate.subtract(const Duration(hours: 1)); // 12:30
              
              // Aynı gün saat 09:00'da bildirim
              final sameDayNotification = DateTime(sellDate.year, sellDate.month, sellDate.day, 9, 0);
              // Bir gün önce saat 09:00'da bildirim
              final prevDayNotification = sameDayNotification.subtract(const Duration(days: 1));
              
              // Bildirimleri kur
              await NotificationService().scheduleAlarm(
                id: sameDayNotification.millisecondsSinceEpoch ~/ 1000,
                title: 'Bugün Fon Satış Günü! ⏰',
                body: 'Unutmayın, hedefiniz için bugün saat 13:30\'a kadar fon satış emri girmelisiniz.',
                scheduledTime: sameDayNotification,
              );

              await NotificationService().scheduleAlarm(
                id: prevDayNotification.millisecondsSinceEpoch ~/ 1000,
                title: 'Yarın Fon Satış Günü!',
                body: 'Hedeflediğiniz nakit için yarın saat 13:30\'a kadar fon satış emri girmeniz gerekecek. Hazırlıklı olun.',
                scheduledTime: prevDayNotification,
              );
              
              if (Platform.isAndroid) {
                final intent = AndroidIntent(
                  action: 'android.intent.action.SET_ALARM',
                  arguments: <String, dynamic>{
                    'android.intent.extra.alarm.HOUR': alarmTime.hour,
                    'android.intent.extra.alarm.MINUTES': alarmTime.minute,
                    'android.intent.extra.alarm.MESSAGE': 'Fon Satış Vakti Yaklaşıyor! ⏰',
                    'android.intent.extra.alarm.SKIP_UI': false,
                  },
                );
                await intent.launch();
              }
            },
            icon: const Icon(Icons.alarm_add),
            label: const Text('Saat Uygulamasına Alarm Kur'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.secondary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
