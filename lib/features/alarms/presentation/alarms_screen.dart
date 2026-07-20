import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../domain/alarm_model.dart';
import '../../../core/widgets/gradient_card.dart';

class AlarmsScreen extends StatefulWidget {
  const AlarmsScreen({super.key});

  @override
  State<AlarmsScreen> createState() => _AlarmsScreenState();
}

class _AlarmsScreenState extends State<AlarmsScreen> {
  late Box<AlarmModel> alarmBox;

  @override
  void initState() {
    super.initState();
    alarmBox = Hive.box<AlarmModel>('alarmBox');
  }

  void _addAlarmDialog() {
    final codeController = TextEditingController();
    final priceController = TextEditingController();
    bool isGreaterThan = true;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Yeni Alarm Kur'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: codeController,
                    decoration: const InputDecoration(labelText: 'Fon Kodu (Örn: AFT)'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: priceController,
                    decoration: const InputDecoration(labelText: 'Hedef Fiyat (₺)'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: Text(isGreaterThan ? 'Fiyat Üstüne Çıkarsa' : 'Fiyat Altına İnerse'),
                    value: isGreaterThan,
                    onChanged: (val) => setState(() => isGreaterThan = val),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
                ElevatedButton(
                  onPressed: () {
                    final newAlarm = AlarmModel(
                      fundCode: codeController.text.toUpperCase(),
                      targetPrice: double.tryParse(priceController.text.replaceAll(',', '.')) ?? 0,
                      isGreaterThan: isGreaterThan,
                    );
                    alarmBox.add(newAlarm);
                    Navigator.pop(context);
                  },
                  child: const Text('Kur'),
                ),
              ],
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fiyat Alarmları', style: TextStyle(fontWeight: FontWeight.bold))),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addAlarmDialog,
        icon: const Icon(Icons.add_alert),
        label: const Text('Alarm Kur', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: const Color(0xFF09090B),
        elevation: 0,
      ),
      body: ValueListenableBuilder(
        valueListenable: alarmBox.listenable(),
        builder: (context, Box<AlarmModel> box, _) {
          if (box.isEmpty) {
            return const Center(child: Text('Kurulu bir kâr/zarar alarmınız bulunmuyor.', textAlign: TextAlign.center));
          }
          return ListView.builder(
            itemCount: box.length,
            itemBuilder: (context, index) {
              final alarm = box.getAt(index);
              if (alarm == null) return const SizedBox.shrink();

              return GestureDetector(
                onLongPress: () {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Alarmı Sil'),
                      content: const Text('Bu alarmı silmek istiyor musunuz?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
                        TextButton(
                          onPressed: () {
                            alarmBox.deleteAt(index);
                            Navigator.pop(context);
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
                        color: (alarm.isGreaterThan ? Colors.greenAccent : Colors.redAccent).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        alarm.isGreaterThan ? Icons.trending_up : Icons.trending_down,
                        color: alarm.isGreaterThan ? Colors.greenAccent : Colors.redAccent,
                      ),
                    ),
                    title: Text(alarm.fundCode, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    subtitle: Text('Hedef: ₺${alarm.targetPrice.toStringAsFixed(3)}', style: const TextStyle(color: Color(0xFFA1A1AA))),
                    trailing: Switch(
                      value: alarm.isActive,
                      activeThumbColor: Theme.of(context).primaryColor,
                      onChanged: (val) {
                        setState(() {
                          alarm.isActive = val;
                          alarm.save();
                        });
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
