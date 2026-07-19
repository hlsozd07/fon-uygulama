import 'package:hive/hive.dart';

class AlarmModel extends HiveObject {
  final String fundCode;
  final double targetPrice;
  final bool isGreaterThan;
  bool isActive;

  AlarmModel({
    required this.fundCode,
    required this.targetPrice,
    required this.isGreaterThan,
    this.isActive = true,
  });
}

class AlarmModelAdapter extends TypeAdapter<AlarmModel> {
  @override
  final int typeId = 2;

  @override
  AlarmModel read(BinaryReader reader) {
    return AlarmModel(
      fundCode: reader.readString(),
      targetPrice: reader.readDouble(),
      isGreaterThan: reader.readBool(),
      isActive: reader.readBool(),
    );
  }

  @override
  void write(BinaryWriter writer, AlarmModel obj) {
    writer.writeString(obj.fundCode);
    writer.writeDouble(obj.targetPrice);
    writer.writeBool(obj.isGreaterThan);
    writer.writeBool(obj.isActive);
  }
}
