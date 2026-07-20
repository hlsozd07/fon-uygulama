import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'fund_detail_screen.dart';
import '../../portfolio/domain/fund_model.dart';
import '../../history/domain/sell_history_model.dart';
import '../../tefas/data/tefas_service.dart';
import '../../../core/widgets/gradient_card.dart';

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

enum SortOption { none, profitHighest, profitLowest, weightHighest }

class _PortfolioScreenState extends State<PortfolioScreen> {
  late Box<FundModel> fundBox;
  bool _isUpdatingPrices = false;
  SortOption _currentSort = SortOption.none;

  @override
  void initState() {
    super.initState();
    fundBox = Hive.box<FundModel>('walletBox');
    _updatePrices();
  }

  void _updatePrices() async {
    setState(() => _isUpdatingPrices = true);
    for (int i = 0; i < fundBox.length; i++) {
      final fund = fundBox.getAt(i);
      if (fund != null) {
        final tefasData = await TefasService().getFundDetails(fund.name);
        if (tefasData != null && tefasData.price > 0) {
           final updatedFund = FundModel(
             name: fund.name,
             quantity: fund.quantity,
             averageCost: fund.averageCost,
             currentPrice: tefasData.price,
             assetType: fund.assetType,
           );
           await fundBox.putAt(i, updatedFund);
        }
      }
    }
    if (mounted) setState(() => _isUpdatingPrices = false);
  }

  void _addFundDialog() {
    final nameController = TextEditingController();
    final quantityController = TextEditingController();
    final costController = TextEditingController();
    final priceController = TextEditingController();
    String selectedAssetType = 'Fon';
    bool isFetchingPrice = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Yeni Varlık Ekle'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: selectedAssetType,
                      decoration: const InputDecoration(labelText: 'Varlık Tipi'),
                      items: const [
                        DropdownMenuItem(value: 'Fon', child: Text('Yatırım Fonu')),
                        DropdownMenuItem(value: 'Hisse', child: Text('Hisse Senedi (BIST)')),
                        DropdownMenuItem(value: 'Döviz', child: Text('Döviz')),
                        DropdownMenuItem(value: 'Altın', child: Text('Altın')),
                      ],
                      onChanged: (val) {
                        if (val != null) setStateDialog(() => selectedAssetType = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameController, 
                      decoration: InputDecoration(
                        labelText: selectedAssetType == 'Döviz' ? 'Döviz Kodu (Örn: USD)' : 
                                   selectedAssetType == 'Hisse' ? 'Hisse Kodu (Örn: THYAO)' : 
                                   selectedAssetType == 'Altın' ? 'Altın Kodu (Örn: GLD)' : 'Fon Kodu (Örn: AFT)',
                        suffixIcon: isFetchingPrice 
                            ? const Padding(
                                padding: EdgeInsets.all(12.0),
                                child: SizedBox(
                                  width: 20, 
                                  height: 20, 
                                  child: CircularProgressIndicator(strokeWidth: 2)
                                ),
                              )
                            : IconButton(
                                icon: const Icon(Icons.search, color: Colors.blueAccent),
                                onPressed: () async {
                                  if (nameController.text.trim().isEmpty) return;
                                  setStateDialog(() => isFetchingPrice = true);
                                  final details = await TefasService().getFundDetails(nameController.text.trim());
                                  if (details != null && details.price > 0) {
                                    priceController.text = details.price.toString();
                                  } else {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Fiyat bulunamadı, varlık kodunu kontrol edin.'))
                                      );
                                    }
                                  }
                                  setStateDialog(() => isFetchingPrice = false);
                                },
                              ),
                      )
                    ),
                    const SizedBox(height: 12),
                    TextField(controller: quantityController, decoration: const InputDecoration(labelText: 'Adet'), keyboardType: TextInputType.number),
                    const SizedBox(height: 12),
                    TextField(controller: costController, decoration: const InputDecoration(labelText: 'Ortalama Maliyet'), keyboardType: TextInputType.number),
                    const SizedBox(height: 12),
                    TextField(controller: priceController, decoration: const InputDecoration(labelText: 'Güncel Fiyat'), keyboardType: TextInputType.number),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
                ElevatedButton(
                  onPressed: () {
                    final newFund = FundModel(
                      name: nameController.text.trim().toUpperCase(),
                      quantity: double.tryParse(quantityController.text.replaceAll(',', '.')) ?? 0,
                      averageCost: double.tryParse(costController.text.replaceAll(',', '.')) ?? 0,
                      currentPrice: double.tryParse(priceController.text.replaceAll(',', '.')) ?? 0,
                      assetType: selectedAssetType,
                    );
                    fundBox.add(newFund);
                    Navigator.pop(context);
                  },
                  child: const Text('Ekle'),
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
      appBar: AppBar(
        title: const Text('Cüzdanım', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          PopupMenuButton<SortOption>(
            onSelected: (val) => setState(() => _currentSort = val),
            icon: const Icon(Icons.sort),
            itemBuilder: (context) => const [
              PopupMenuItem(value: SortOption.none, child: Text('Ekleme Sırası')),
              PopupMenuItem(value: SortOption.profitHighest, child: Text('En Çok Kazandıranlar')),
              PopupMenuItem(value: SortOption.profitLowest, child: Text('En Çok Kaybettirenler')),
              PopupMenuItem(value: SortOption.weightHighest, child: Text('En Yüksek Bakiye')),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addFundDialog,
        icon: const Icon(Icons.add),
        label: const Text('Varlık Ekle', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: const Color(0xFF09090B),
        elevation: 0,
      ),
      body: ValueListenableBuilder(
        valueListenable: fundBox.listenable(),
        builder: (context, Box<FundModel> box, _) {
          if (box.isEmpty) {
            return const Center(child: Text('Henüz portföyünüze fon eklemediniz.\nSağ alt köşeden yeni fon ekleyebilirsiniz.', textAlign: TextAlign.center));
          }

          double totalPortfolioValue = 0;
          double totalProfitLoss = 0;
          for (var fund in box.values) {
            totalPortfolioValue += fund.totalValue;
            totalProfitLoss += fund.profitLoss;
          }

          return Column(
            children: [
              _buildSummaryCard(totalPortfolioValue, totalProfitLoss),
              if (_isUpdatingPrices)
                 const Padding(
                   padding: EdgeInsets.symmetric(vertical: 8.0),
                   child: Row(
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: [
                       SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                       SizedBox(width: 8),
                       Text('TEFAS\'tan canlı fiyatlar güncelleniyor...'),
                     ],
                   ),
                 ),
              _buildPieChart(box),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: _buildGroupedList(box),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(double totalValue, double profitLoss) {
    final theme = Theme.of(context);
    final isProfit = profitLoss >= 0;
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GradientCard(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          children: [
            Text('Toplam Varlık', style: TextStyle(color: const Color(0xFFA1A1AA), fontSize: 16)),
            const SizedBox(height: 8),
            Text(
              '₺${totalValue.toStringAsFixed(2)}',
              style: theme.textTheme.displayMedium?.copyWith(color: Colors.white, fontSize: 36, letterSpacing: -1),
            ),
            const SizedBox(height: 16),
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
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(isProfit ? Icons.trending_up : Icons.trending_down, 
                       color: isProfit ? Colors.greenAccent : Colors.redAccent, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '${isProfit ? "+" : ""}₺${profitLoss.toStringAsFixed(2)}',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: isProfit ? Colors.greenAccent : Colors.redAccent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildPieChart(Box<FundModel> box) {
    if (box.isEmpty) return const SizedBox.shrink();
    
    double totalPortfolioValue = 0;
    for (var fund in box.values) {
      totalPortfolioValue += fund.totalValue;
    }
    
    if (totalPortfolioValue == 0) return const SizedBox.shrink();

    final sections = box.values.toList().asMap().entries.map((entry) {
      final index = entry.key;
      final fund = entry.value;
      final percentage = (fund.totalValue / totalPortfolioValue) * 100;
      
      final colors = [
        Colors.blueAccent,
        Colors.greenAccent,
        Colors.orangeAccent,
        Colors.purpleAccent,
        Colors.redAccent,
        Colors.tealAccent,
      ];
      final color = colors[index % colors.length];

      return PieChartSectionData(
        color: color,
        value: percentage,
        title: '${fund.name}\n%${percentage.toStringAsFixed(1)}',
        radius: 60,
        titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      child: PieChart(
        PieChartData(
          sectionsSpace: 2,
          centerSpaceRadius: 40,
          sections: sections,
        ),
      ),
    );
  }

  List<FundModel> _getSortedFunds(Iterable<FundModel> funds) {
    final list = funds.toList();
    switch (_currentSort) {
      case SortOption.profitHighest:
        list.sort((a, b) => b.profitLossPercentage.compareTo(a.profitLossPercentage));
        break;
      case SortOption.profitLowest:
        list.sort((a, b) => a.profitLossPercentage.compareTo(b.profitLossPercentage));
        break;
      case SortOption.weightHighest:
        list.sort((a, b) => b.totalValue.compareTo(a.totalValue));
        break;
      case SortOption.none:
        break;
    }
    return list;
  }

  List<Widget> _buildGroupedList(Box<FundModel> box) {
    if (box.isEmpty) return const [Center(child: Text('Cüzdanınızda henüz bir varlık yok.'))];
    
    final sortedList = _getSortedFunds(box.values);
    final grouped = <String, List<FundModel>>{};
    for (var fund in sortedList) {
      grouped.putIfAbsent(fund.assetType, () => []).add(fund);
    }

    final widgets = <Widget>[];
    
    final typeNames = {
      'Fon': 'Yatırım Fonları',
      'Hisse': 'Hisse Senetleri (BIST)',
      'Döviz': 'Döviz',
      'Altın': 'Kıymetli Madenler',
    };

    for (var entry in grouped.entries) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
          child: Text(
            typeNames[entry.key] ?? entry.key,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white70),
          ),
        ),
      );
      for (var fund in entry.value) {
        widgets.add(_buildFundCard(fund, box));
      }
      widgets.add(const SizedBox(height: 16));
    }
    return widgets;
  }

  Widget _buildFundCard(FundModel fund, Box<FundModel> box) {
    final isProfit = fund.profitLoss >= 0;
    
    return GestureDetector(
      onLongPress: () {
        showModalBottomSheet(
          context: context,
          builder: (context) => SafeArea(
            child: Wrap(
              children: [
                ListTile(
                  leading: const Icon(Icons.sell, color: Colors.greenAccent),
                  title: const Text('Satış Yap'),
                  onTap: () {
                    Navigator.pop(context);
                    _showSellDialog(fund, box);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.redAccent),
                  title: const Text('Varlığı Sil'),
                  onTap: () {
                    Navigator.pop(context);
                    _showDeleteDialog(fund, box);
                  },
                ),
              ],
            ),
          ),
        );
      },
      child: GradientCard(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => FundDetailScreen(fund: fund)));
        },
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                fund.name.length > 3 ? fund.name.substring(0, 3) : fund.name,
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(fund.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text('Maliyet: ₺${fund.averageCost} | Fiyat: ₺${fund.currentPrice}', 
                       style: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 13)),
                  Text('Adet: ${fund.quantity}', 
                       style: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 13)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₺${fund.totalValue.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (isProfit ? Colors.greenAccent : Colors.redAccent).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${isProfit ? "+" : ""}%${fund.profitLossPercentage.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: isProfit ? Colors.greenAccent : Colors.redAccent,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(FundModel fund, Box<FundModel> box) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Varlığı Sil'),
        content: const Text('Bu varlığı portföyünüzden tamamen silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
          TextButton(
            onPressed: () {
              final realIndex = box.values.toList().indexOf(fund);
              if (realIndex != -1) {
                fundBox.deleteAt(realIndex);
              }
              Navigator.pop(context);
            },
            child: const Text('Sil', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _showSellDialog(FundModel fund, Box<FundModel> box) {
    final quantityController = TextEditingController(text: fund.quantity.toString());
    final priceController = TextEditingController(text: fund.currentPrice.toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('${fund.name} Satışı'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: quantityController,
                decoration: const InputDecoration(labelText: 'Satılacak Adet'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(labelText: 'Satış Fiyatı'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
            ElevatedButton(
              onPressed: () async {
                final sellQuantity = double.tryParse(quantityController.text.replaceAll(',', '.')) ?? 0;
                final sellPrice = double.tryParse(priceController.text.replaceAll(',', '.')) ?? 0;
                
                if (sellQuantity <= 0 || sellPrice <= 0) return;
                
                final realIndex = box.values.toList().indexOf(fund);
                if (realIndex == -1) return;

                final actualSellQty = sellQuantity > fund.quantity ? fund.quantity : sellQuantity;
                final profit = (sellPrice - fund.averageCost) * actualSellQty;

                // Geçmişe ekle
                final sellBox = await Hive.openBox<SellHistoryModel>('sellHistoryBox');
                sellBox.add(SellHistoryModel(
                  fundName: fund.name,
                  sellQuantity: actualSellQty,
                  buyPrice: fund.averageCost,
                  sellPrice: sellPrice,
                  profit: profit,
                  sellDate: DateTime.now(),
                ));

                // Portföyü güncelle
                if (actualSellQty >= fund.quantity) {
                  fundBox.deleteAt(realIndex); // Tamamını sattıysa sil
                } else {
                  final updatedFund = FundModel(
                    name: fund.name,
                    quantity: fund.quantity - actualSellQty,
                    averageCost: fund.averageCost,
                    currentPrice: fund.currentPrice,
                    assetType: fund.assetType,
                  );
                  fundBox.putAt(realIndex, updatedFund);
                }

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Satış işlemi kaydedildi.'))
                  );
                }
              },
              child: const Text('Satışı Onayla'),
            ),
          ],
        );
      },
    );
  }
}
