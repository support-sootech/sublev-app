import 'package:ootech/models/modo_conservacao_model.dart';
import 'package:ootech/services/dio_custom.dart';
import 'package:ootech/services/network_access.dart';

class ModoConservacaoRepository {
  final DioCustom service = DioCustom();
  final NetworkAccess networkAccess = NetworkAccess();

  Future<List<ModoConservacaoModel>> listar({String status = 'A'}) async {
    final t0 = DateTime.now();
    print('[MODOS-REPO] listar status="$status" iniciando');
    final connected = await networkAccess.checkNetworkAcess();
    if (!connected) return <ModoConservacaoModel>[];

    try {
      final resp = await service.dio.get(
        '/app-modo-conservacao',
        queryParameters: {'status': status},
      );
      if (resp.statusCode == 200) {
        final data = resp.data;
        final payload = data is Map ? (data['data'] ?? data['modos']) : data;
        if (payload is List) {
          return payload
              .whereType<Map>()
            .map((e) => ModoConservacaoModel.fromJson(
              Map<String, dynamic>.from(e)))
              .toList();
        }
        if (payload is Map) {
          return payload.values
              .whereType<Map>()
            .map((e) => ModoConservacaoModel.fromJson(
              Map<String, dynamic>.from(e)))
              .toList();
        }
      }
    } catch (_) {}
    print('[MODOS-REPO] listar vazio/erro dur=${DateTime.now().difference(t0).inMilliseconds}ms');
    return <ModoConservacaoModel>[];
  }
}
