import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../portfolio/domain/fund_model.dart';
import '../domain/portfolio_history_model.dart';
import '../../../core/widgets/gradient_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Box<FundModel> fundBox;
  late Box<PortfolioHistoryModel> historyBox;

  @override
  void initState() {
    super.initState();
    fundBox = Hive.box<FundModel>('walletBox');
    historyBox = Hive.box<PortfolioHistoryModel>('portfolioHistoryBox');
    _recordDailyValue();
  }

  void _recordDailyValue() {
    final today = DateTime.now();
    final todayStr = "${today.year}-${today.month}-${today.day}";
    
    double totalValue = 0;
    for (var f in fundBox.values) {
      totalValue += f.totalValue;
    }
    
    // Aynı güne ait kayıt varsa güncelle, yoksa yeni ekle
    int existingIndex = -1;
    for (int i = 0; i < historyBox.length; i++) {
      final record = historyBox.getAt(i);
      if (record != null) {
        final recordStr = "${record.date.year}-${record.date.month}-${record.date.day}";
        if (recordStr == todayStr) {
          existingIndex = i;
          break;
        }
      }
    }

    if (existingIndex != -1) {
      historyBox.putAt(existingIndex, PortfolioHistoryModel(date: today, totalValue: totalValue));
    } else {
      historyBox.add(PortfolioHistoryModel(date: today, totalValue: totalValue));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.auto_graph, color: Colors.greenAccent),
            SizedBox(width: 8),
            Text('Özet', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      body: ValueListenableBuilder(
        valueListenable: fundBox.listenable(),
        builder: (context, Box<FundModel> box, _) {
          double totalValue = 0;
          double totalCost = 0;
          for (var f in box.values) {
            totalValue += f.totalValue;
            totalCost += f.totalCost;
          }
          final profitLoss = totalValue - totalCost;
          final isProfit = profitLoss >= 0;
          final percent = totalCost > 0 ? (profitLoss / totalCost) * 100 : 0.0;

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GradientCard(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Toplam Varlık', style: TextStyle(color: Color(0xFFA1A1AA), fontSize: 16)),
                        const SizedBox(height: 8),
                        Text(
                          '₺${totalValue.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -1),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: (isProfit ? Colors.greenAccent : Colors.redAccent).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: (isProfit ? Colors.greenAccent : Colors.redAccent).withValues(alpha: 0.2),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(isProfit ? Icons.arrow_upward : Icons.arrow_downward, 
                                       color: isProfit ? Colors.greenAccent : Colors.redAccent, size: 18),
                                  const SizedBox(width: 6),
                                  Text(
                                    '₺${profitLoss.abs().toStringAsFixed(2)} (${percent.toStringAsFixed(2)}%)',
                                    style: TextStyle(
                                      color: isProfit ? Colors.greenAccent : Colors.redAccent,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text('Tüm Zamanlar', style: TextStyle(color: Color(0xFF71717A))), // Zinc 500
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text('Geçmiş Portföy Performansı', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
                  ),
                  const SizedBox(height: 16),
                  GradientCard(
                    padding: const EdgeInsets.only(top: 24, bottom: 16, left: 8, right: 24),
                    child: ValueListenableBuilder(
                      valueListenable: historyBox.listenable(),
                      builder: (context, Box<PortfolioHistoryModel> hBox, _) {
                        return _buildLineChart(hBox.values.toList(), totalValue);
                      },
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

  Widget _buildLineChart(List<PortfolioHistoryModel> historyList, double currentVal) {
    if (historyList.isEmpty && currentVal == 0) {
      return const Center(child: Text('Veri yok'));
    }
    
    historyList.sort((a, b) => a.date.compareTo(b.date));
    
    // Eğer sadece tek günlük veri varsa veya geçmiş yoksa grafiği düz çizgi yapmak için bugünü çoğaltalım
    if (historyList.length < 2) {
      final now = DateTime.now();
      historyList = [
        PortfolioHistoryModel(date: now.subtract(const Duration(days: 1)), totalValue: currentVal),
        PortfolioHistoryModel(date: now, totalValue: currentVal),
      ];
    }
    
    // Sadece son 30 kaydı göster
    if (historyList.length > 30) {
      historyList = historyList.sublist(historyList.length - 30);
    }

    final spots = <FlSpot>[];
    double minVal = historyList.first.totalValue;
    double maxVal = historyList.first.totalValue;
    
    for (int i = 0; i < historyList.length; i++) {
      final val = historyList[i].totalValue;
      spots.add(FlSpot(i.toDouble(), val));
      if (val < minVal) minVal = val;
      if (val > maxVal) maxVal = val;
    }

    if (minVal == maxVal) {
      minVal = minVal * 0.9;
      maxVal = maxVal * 1.1;
    } else {
      final diff = maxVal - minVal;
      minVal -= diff * 0.1;
      maxVal += diff * 0.1;
    }

    final gradientColors = [
      Theme.of(context).primaryColor.withValues(alpha: 0.5),
      Theme.of(context).primaryColor.withValues(alpha: 0.0),
    ];

    return AspectRatio(
      aspectRatio: 1.70,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          minY: minVal,
          maxY: maxVal,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Theme.of(context).primaryColor,
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: gradientColors,
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
