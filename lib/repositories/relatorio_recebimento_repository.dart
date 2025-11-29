import 'dart:io';

import 'package:dio/dio.dart';
import 'package:ootech/config/custom_exception.dart';
import 'package:ootech/models/relatorio_recebimento_item.dart';
import 'package:ootech/services/dio_custom.dart';
import 'package:path_provider/path_provider.dart';

class RelatorioRecebimentoRepository {
  final DioCustom service = DioCustom();

  Future<List<RelatorioRecebimentoItem>> carregar({
    required DateTime dtIni,
    required DateTime dtFim,
    String busca = '',
  }) async {
    try {
      final params = {
        'dt_ini': _fmtDate(dtIni),
        'dt_fim': _fmtDate(dtFim),
      };
      final filtro = busca.trim();
      if (filtro.isNotEmpty) params['busca'] = filtro;
      final resp = await service.dio.get(
        '/app-relatorio-materiais-recebimento',
        queryParameters: params,
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

  Future<File> exportarPdf({
    required DateTime dtIni,
    required DateTime dtFim,
    String busca = '',
  }) async {
    try {
      final params = {
        'dt_ini': _fmtDate(dtIni),
        'dt_fim': _fmtDate(dtFim),
        'tipo': 'pdf',
      };
      final filtro = busca.trim();
      if (filtro.isNotEmpty) params['busca'] = filtro;
      final resp = await service.dio.get(
        '/app-relatorio-materiais-recebimento',
        queryParameters: params,
        options: Options(responseType: ResponseType.bytes),
      );
      if (resp.statusCode == 200 && resp.data is List<int>) {
        final dir = await getTemporaryDirectory();
        final file = File(
          '${dir.path}/relatorio_recebimento_${DateTime.now().millisecondsSinceEpoch}.pdf',
        );
        await file.writeAsBytes(List<int>.from(resp.data));
        return file;
      }
      throw CustomException(message: 'Não foi possível gerar o PDF');
    } on DioException catch (e) {
      throw CustomException(message: e.message ?? 'Falha ao exportar PDF');
    }
  }

  String _fmtDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
}
