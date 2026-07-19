import 'package:hive/hive.dart';

class PortfolioHistoryModel {
  final DateTime date;
  final double totalValue;

  PortfolioHistoryModel({
    required this.date,
    required this.totalValue,
  });
}

class PortfolioHistoryModelAdapter extends TypeAdapter<PortfolioHistoryModel> {
  @override
  final int typeId = 3;

  @override
  PortfolioHistoryModel read(BinaryReader reader) {
    return PortfolioHistoryModel(
      date: DateTime.parse(reader.readString()),
      totalValue: reader.readDouble(),
    );
  }

  @override
  void write(BinaryWriter writer, PortfolioHistoryModel obj) {
    writer.writeString(obj.date.toIso8601String());
    writer.writeDouble(obj.totalValue);
  }
}
