import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../domain/history_model.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Box<HistoryModel> historyBox;

  @override
  void initState() {
    super.initState();
    historyBox = Hive.box<HistoryModel>('historyBox');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('İşlem Geçmişi', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Geçmişi Temizle'),
                  content: const Text('Tüm işlem geçmişi silinecektir. Emin misiniz?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
                    TextButton(
                      onPressed: () {
                        historyBox.clear();
                        Navigator.pop(context);
                      },
                      child: const Text('Sil', style: TextStyle(color: Colors.redAccent)),
                    ),
                  ],
                ),
              );
            },
          )
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: historyBox.listenable(),
        builder: (context, Box<HistoryModel> box, _) {
          if (box.isEmpty) {
            return const Center(child: Text('Henüz kaydedilmiş bir işlem yok.'));
          }

          final records = box.values.toList().reversed.toList();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: records.length,
            itemBuilder: (context, index) {
              final record = records[index];
              final targetDateStr = DateFormat('dd MMM yyyy', 'tr_TR').format(record.targetDate);
              final sellDateStr = DateFormat('dd MMM EEEE, HH:mm', 'tr_TR').format(record.calculatedSellDate);
              
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  title: Text(record.fundName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  subtitle: Text('Hedef: $targetDateStr (Valör: T+${record.valorDays})'),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Satış Zamanı', style: TextStyle(fontSize: 12, color: Colors.white54)),
                      Text(
                        sellDateStr,
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
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
