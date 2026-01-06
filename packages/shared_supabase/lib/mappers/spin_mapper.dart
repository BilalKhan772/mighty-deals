import 'package:shared_models/spin_model.dart';
import 'package:shared_models/spin_entry_model.dart';

class SpinMapper {
  static SpinModel toSpin(Map<String, dynamic> row) => SpinModel.fromMap(row);
  static SpinEntryModel toEntry(Map<String, dynamic> row) => SpinEntryModel.fromMap(row);
}
