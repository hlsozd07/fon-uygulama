import 'package:hive/hive.dart';

class SellHistoryModel {
  final String fundName;
  final double sellQuantity;
  final double buyPrice;
  final double sellPrice;
  final double profit;
  final DateTime sellDate;

  SellHistoryModel({
    required this.fundName,
    required this.sellQuantity,
    required this.buyPrice,
    required this.sellPrice,
    required this.profit,
    required this.sellDate,
  });
}

class SellHistoryModelAdapter extends TypeAdapter<SellHistoryModel> {
  @override
  final int typeId = 5; // Use 5 as typeId, as walletBox(0), historyBox(1), alarmBox(2), portfolioHistoryBox(4) are likely used.

  @override
  SellHistoryModel read(BinaryReader reader) {
    return SellHistoryModel(
      fundName: reader.readString(),
      sellQuantity: reader.readDouble(),
      buyPrice: reader.readDouble(),
      sellPrice: reader.readDouble(),
      profit: reader.readDouble(),
      sellDate: DateTime.parse(reader.readString()),
    );
  }

  @override
  void write(BinaryWriter writer, SellHistoryModel obj) {
    writer.writeString(obj.fundName);
    writer.writeDouble(obj.sellQuantity);
    writer.writeDouble(obj.buyPrice);
    writer.writeDouble(obj.sellPrice);
    writer.writeDouble(obj.profit);
    writer.writeString(obj.sellDate.toIso8601String());
  }
}
