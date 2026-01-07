import 'package:shared_models/spin_entry_model.dart';
import 'package:shared_models/spin_model.dart';
import 'package:shared_supabase/repos/spins_repo.dart';

class SpinsRepo {
  final SpinsRepoSB _sb = SpinsRepoSB();

  Future<List<SpinModel>> listForCity(String city) =>
      _sb.listSpinsForCity(city: city);

  Future<List<SpinEntryModel>> participants(String spinId, {int limit = 50}) =>
      _sb.listParticipants(spinId: spinId, limit: limit);

  Future<int> participantsCount(String spinId) =>
      _sb.participantsCount(spinId);

  Future<SpinModel?> getSpinById(String spinId) =>
      _sb.getSpinById(spinId);
}
