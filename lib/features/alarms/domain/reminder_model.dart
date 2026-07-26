import 'package:hive/hive.dart';

class ReminderModel extends HiveObject {
  final int id;
  final int dayOfMonth;
  final String assetName;
  final double amount;
  bool isActive;

  ReminderModel({
    required this.id,
    required this.dayOfMonth,
    required this.assetName,
    required this.amount,
    this.isActive = true,
  });
}

class ReminderModelAdapter extends TypeAdapter<ReminderModel> {
  @override
  final int typeId = 6;

  @override
  ReminderModel read(BinaryReader reader) {
    return ReminderModel(
      id: reader.readInt(),
      dayOfMonth: reader.readInt(),
      assetName: reader.readString(),
      amount: reader.readDouble(),
      isActive: reader.readBool(),
    );
  }

  @override
  void write(BinaryWriter writer, ReminderModel obj) {
    writer.writeInt(obj.id);
    writer.writeInt(obj.dayOfMonth);
    writer.writeString(obj.assetName);
    writer.writeDouble(obj.amount);
    writer.writeBool(obj.isActive);
  }
}
