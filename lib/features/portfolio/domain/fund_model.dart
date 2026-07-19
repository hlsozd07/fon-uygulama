import 'package:hive/hive.dart';

class FundModel {
  final String name;
  final double quantity;
  final double averageCost;
  final double currentPrice;
  final String assetType; // 'Fon', 'Hisse', 'Döviz', 'Altın'

  FundModel({
    required this.name,
    required this.quantity,
    required this.averageCost,
    required this.currentPrice,
    this.assetType = 'Fon',
  });

  double get totalValue => quantity * currentPrice;
  double get totalCost => quantity * averageCost;
  double get profitLoss => totalValue - totalCost;
  double get profitLossPercentage => totalCost > 0 ? (profitLoss / totalCost) * 100 : 0;
}

class FundModelAdapter extends TypeAdapter<FundModel> {
  @override
  final int typeId = 0;

  @override
  FundModel read(BinaryReader reader) {
    return FundModel(
      name: reader.readString(),
      quantity: reader.readDouble(),
      averageCost: reader.readDouble(),
      currentPrice: reader.readDouble(),
      assetType: reader.readString(),
    );
  }

  @override
  void write(BinaryWriter writer, FundModel obj) {
    writer.writeString(obj.name);
    writer.writeDouble(obj.quantity);
    writer.writeDouble(obj.averageCost);
    writer.writeDouble(obj.currentPrice);
    writer.writeString(obj.assetType);
  }
}
