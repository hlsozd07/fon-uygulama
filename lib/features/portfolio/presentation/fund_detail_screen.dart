import 'package:flutter/material.dart';
import '../../tefas/data/tefas_service.dart';
import '../../tefas/domain/tefas_fund_model.dart';
import '../domain/fund_model.dart';

class FundDetailScreen extends StatefulWidget {
  final FundModel fund;
  const FundDetailScreen({super.key, required this.fund});

  @override
  State<FundDetailScreen> createState() => _FundDetailScreenState();
}

class _FundDetailScreenState extends State<FundDetailScreen> {
  TefasFundModel? tefasData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  void _fetchDetails() async {
    final data = await TefasService().getFundDetails(widget.fund.name);
    if (mounted) {
      setState(() {
        tefasData = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isProfit = widget.fund.profitLoss >= 0;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.fund.name} Detayı', style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text('Sizin Portföyünüz', style: TextStyle(color: Colors.white54)),
                    const SizedBox(height: 8),
                    Text(
                      '₺${widget.fund.totalValue.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStat('Adet', widget.fund.quantity.toStringAsFixed(0)),
                        _buildStat('Maliyet', '₺${widget.fund.averageCost.toStringAsFixed(3)}'),
                        _buildStat(
                          'Kâr/Zarar',
                          '${isProfit ? "+" : ""}₺${widget.fund.profitLoss.abs().toStringAsFixed(2)}',
                          color: isProfit ? Colors.greenAccent : Colors.redAccent,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            const Text('TEFAS Verileri', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (tefasData == null)
              const Center(child: Text('Bu fon TEFAS simülasyonunda bulunamadı.'))
            else
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(tefasData!.name, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      const Divider(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStat('Güncel Fiyat', '₺${tefasData!.price.toStringAsFixed(4)}'),
                          _buildStat(
                            'Günlük Getiri',
                            '${tefasData!.dailyReturn >= 0 ? "+" : ""}%${tefasData!.dailyReturn.toStringAsFixed(2)}',
                            color: tefasData!.dailyReturn >= 0 ? Colors.greenAccent : Colors.redAccent,
                          ),
                          _buildStat('Valör', 'T+${tefasData!.valor}'),
                        ],
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

  Widget _buildStat(String label, String value, {Color? color}) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color ?? Colors.white)),
      ],
    );
  }
}
