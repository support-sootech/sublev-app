import 'package:dio/dio.dart';
import 'package:ootech/config/custom_exception.dart';
import 'package:ootech/models/relatorio_recebimento_item.dart';
import 'package:ootech/services/dio_custom.dart';

class RelatorioRecebimentoRepository {
  final DioCustom service = DioCustom();

  Future<List<RelatorioRecebimentoItem>> carregar({
    required DateTime dtIni,
    required DateTime dtFim,
    String status = '',
  }) async {
    try {
      final resp = await service.dio.get(
        '/app-relatorio-materiais-recebimento',
        queryParameters: {
          'dt_ini': _fmtDate(dtIni),
          'dt_fim': _fmtDate(dtFim),
          if (status.isNotEmpty) 'status': status,
        },
      );
      if (resp.statusCode == 200 && resp.data is Map) {
        final Map data = resp.data;
        if (data.containsKey('success') && data['success'] != true) {
          throw CustomException(
              message: (data['msg'] ?? 'Erro ao carregar relatório').toString());
        }
        final payload = data['data'];
        if (payload is List) {
          return payload
              .whereType<Map>()
              .map((e) => RelatorioRecebimentoItem.fromJson(
                  Map<String, dynamic>.from(e)))
              .toList();
        }
      }
    } on DioException catch (e) {
      throw CustomException(message: e.message ?? 'Falha de rede');
    }
    return <RelatorioRecebimentoItem>[];
  }

  String _fmtDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
}
