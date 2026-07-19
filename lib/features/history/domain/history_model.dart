import 'package:hive/hive.dart';

class HistoryModel {
  final String fundName;
  final DateTime targetDate;
  final int valorDays;
  final DateTime calculatedSellDate;
  final DateTime createdAt;

  HistoryModel({
    required this.fundName,
    required this.targetDate,
    required this.valorDays,
    required this.calculatedSellDate,
    required this.createdAt,
  });
}

class HistoryModelAdapter extends TypeAdapter<HistoryModel> {
  @override
  final int typeId = 1;

  @override
  HistoryModel read(BinaryReader reader) {
    return HistoryModel(
      fundName: reader.readString(),
      targetDate: DateTime.parse(reader.readString()),
      valorDays: reader.readInt(),
      calculatedSellDate: DateTime.parse(reader.readString()),
      createdAt: DateTime.parse(reader.readString()),
    );
  }

  @override
  void write(BinaryWriter writer, HistoryModel obj) {
    writer.writeString(obj.fundName);
    writer.writeString(obj.targetDate.toIso8601String());
    writer.writeInt(obj.valorDays);
    writer.writeString(obj.calculatedSellDate.toIso8601String());
    writer.writeString(obj.createdAt.toIso8601String());
  }
}
