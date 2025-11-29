import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:ootech/models/produto_model.dart';
import 'package:ootech/services/dio_custom.dart';
import 'package:ootech/services/network_access.dart';

class ProdutoRepository {
  final DioCustom service = DioCustom();
  final NetworkAccess networkAccess = NetworkAccess();

  Future<List<ProdutoModel>> autocompleteProdutos(String termo) async {
    if (termo.trim().length < 2) return <ProdutoModel>[];
    final connected = await networkAccess.checkNetworkAcess();
    if (!connected) return <ProdutoModel>[];

    try {
      final resp = await service.dio.post(
        '/prod-autocomplete-json',
        data: {
          'flagListaCampo': 'L',
          'campo': termo.trim(),
        },
      );
      final data = resp.data is Map ? resp.data['data'] : resp.data;
      if (data is List) {
        return data
            .whereType<Map>()
            .map((e) => ProdutoModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    } on DioException catch (e) {
      if (kDebugMode) debugPrint('autocompleteProdutos erro: ${e.message}');
    }
    return <ProdutoModel>[];
  }

  Future<ProdutoModel?> buscarPorCodigoBarras(String codigo) async {
    if (codigo.trim().isEmpty) return null;
    final connected = await networkAccess.checkNetworkAcess();
    if (!connected) return null;

    try {
      final resp = await service.dio.post(
        '/prod-autocomplete-json',
        data: {
          'flagListaCampo': 'C',
          'campo': codigo.trim(),
        },
      );
      final payload = resp.data is Map ? resp.data['data'] : resp.data;
      if (payload is List && payload.isNotEmpty) {
        final first = payload.first;
        if (first is Map) {
          return ProdutoModel.fromJson(Map<String, dynamic>.from(first));
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('buscarPorCodigoBarras erro: $e');
    }
    return null;
  }
}
