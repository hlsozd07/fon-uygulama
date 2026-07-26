import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../domain/reminder_model.dart';
import '../../../core/widgets/gradient_card.dart';
import '../../notifications/notification_service.dart';

class RemindersTab extends StatefulWidget {
  const RemindersTab({super.key});

  @override
  State<RemindersTab> createState() => _RemindersTabState();
}

class _RemindersTabState extends State<RemindersTab> {
  late Box<ReminderModel> reminderBox;

  @override
  void initState() {
    super.initState();
    reminderBox = Hive.box<ReminderModel>('reminderBox');
  }

  void _addReminderDialog() {
    final assetController = TextEditingController();
    final amountController = TextEditingController();
    final dayController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Yeni Aylık Hatırlatıcı'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: dayController,
                decoration: const InputDecoration(labelText: 'Ayın Hangi Günü? (1-31)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: assetController,
                decoration: const InputDecoration(labelText: 'Varlık / Fon Adı (Örn: AFT, Altın)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                decoration: const InputDecoration(labelText: 'Tutar (₺)'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
            ElevatedButton(
              onPressed: () async {
                final day = int.tryParse(dayController.text) ?? 1;
                final amount = double.tryParse(amountController.text.replaceAll(',', '.')) ?? 0;
                final assetName = assetController.text;
                
                final id = DateTime.now().millisecondsSinceEpoch.remainder(100000);

                final newReminder = ReminderModel(
                  id: id,
                  dayOfMonth: day.clamp(1, 31),
                  assetName: assetName,
                  amount: amount,
                );
                
                await reminderBox.add(newReminder);
                
                await NotificationService().scheduleMonthlyReminder(
                  id: id,
                  title: 'Yatırım Zamanı: $assetName',
                  body: 'Her ayın ${newReminder.dayOfMonth}. günü! $assetName için ₺${amount.toStringAsFixed(2)} yatırım yapma zamanı geldi.',
                  dayOfMonth: newReminder.dayOfMonth,
                );

                if (mounted) Navigator.pop(context);
              },
              child: const Text('Kur'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addReminderDialog,
        icon: const Icon(Icons.add_task),
        label: const Text('Hatırlatıcı Ekle', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: const Color(0xFF09090B),
        elevation: 0,
      ),
      body: ValueListenableBuilder(
        valueListenable: reminderBox.listenable(),
        builder: (context, Box<ReminderModel> box, _) {
          if (box.isEmpty) {
            return const Center(child: Text('Kurulu bir yatırım hatırlatıcınız bulunmuyor.', textAlign: TextAlign.center));
          }
          return ListView.builder(
            itemCount: box.length,
            itemBuilder: (context, index) {
              final reminder = box.getAt(index);
              if (reminder == null) return const SizedBox.shrink();

              return GestureDetector(
                onLongPress: () {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Hatırlatıcıyı Sil'),
                      content: const Text('Bu hatırlatıcıyı silmek istiyor musunuz?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
                        TextButton(
                          onPressed: () async {
                            await NotificationService().cancelAlarm(reminder.id);
                            await reminderBox.deleteAt(index);
                            if (context.mounted) Navigator.pop(context);
                          },
                          child: const Text('Sil', style: TextStyle(color: Colors.redAccent)),
                        ),
                      ],
                    ),
                  );
                },
                child: GradientCard(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.calendar_month,
                        color: Colors.blueAccent,
                      ),
                    ),
                    title: Text(reminder.assetName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    subtitle: Text('Her ayın ${reminder.dayOfMonth}. günü - ₺${reminder.amount.toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFFA1A1AA))),
                    trailing: Switch(
                      value: reminder.isActive,
                      activeThumbColor: Theme.of(context).primaryColor,
                      onChanged: (val) async {
                        setState(() {
                          reminder.isActive = val;
                          reminder.save();
                        });
                        
                        if (val) {
                          await NotificationService().scheduleMonthlyReminder(
                            id: reminder.id,
                            title: 'Yatırım Zamanı: ${reminder.assetName}',
                            body: 'Her ayın ${reminder.dayOfMonth}. günü! ${reminder.assetName} için ₺${reminder.amount.toStringAsFixed(2)} yatırım yapma zamanı geldi.',
                            dayOfMonth: reminder.dayOfMonth,
                          );
                        } else {
                          await NotificationService().cancelAlarm(reminder.id);
                        }
                      },
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
