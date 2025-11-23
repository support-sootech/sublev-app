class AvulsaResponse {
  final bool success;
  final List<int> ids;
  final List<EtiquetaAvulsaItem> data;

  AvulsaResponse({
    required this.success,
    required this.ids,
    required this.data,
  });

  factory AvulsaResponse.fromJson(Map<String, dynamic> json) {
    bool parseBool(dynamic value) {
      if (value is bool) return value;
      if (value is String) return value.toLowerCase() == 'true';
      return value == 1;
    }

    final idsRaw = json['ids'];
    final dataRaw = json['data'];

    return AvulsaResponse(
      success: parseBool(json['success'] ?? json['ok'] ?? false),
      ids: (idsRaw is List)
          ? idsRaw
              .map((e) => int.tryParse(e.toString()) ?? 0)
              .where((e) => e > 0)
              .toList()
          : <int>[],
      data: (dataRaw is List)
          ? dataRaw
              .whereType<Map>()
            .map((e) => EtiquetaAvulsaItem.fromJson(
              Map<String, dynamic>.from(e)))
              .toList()
          : <EtiquetaAvulsaItem>[],
    );
  }
}

class EtiquetaAvulsaItem {
  final int? idEtiquetas;
  final String? descricao;
  final int? idMateriaisFracionados;
  final int? idMateriais;
  final String? status;
  final int? idUsuarios;
  final String? dsMaterial;
  final String? dsUnidadesMedidas;
  final String? dsModoConservacao;
  final String? qtdFracionada;
  final String? dtFracionamento;
  final String? dtFracionamentoReduzido;
  final String? dtVencimento;
  final String? dtVencimentoReduzido;
  final String? nmPessoa;
  final String? nmPessoaAbreviado;
  final String? nmSetor;
  final int? numEtiqueta;

  EtiquetaAvulsaItem({
    this.idEtiquetas,
    this.descricao,
    this.idMateriaisFracionados,
    this.idMateriais,
    this.status,
    this.idUsuarios,
    this.dsMaterial,
    this.dsUnidadesMedidas,
    this.dsModoConservacao,
    this.qtdFracionada,
    this.dtFracionamento,
    this.dtFracionamentoReduzido,
    this.dtVencimento,
    this.dtVencimentoReduzido,
    this.nmPessoa,
    this.nmPessoaAbreviado,
    this.nmSetor,
    this.numEtiqueta,
  });

  factory EtiquetaAvulsaItem.fromJson(Map<String, dynamic> json) {
    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      return int.tryParse(value.toString());
    }

    return EtiquetaAvulsaItem(
      idEtiquetas: parseInt(json['id_etiquetas']),
      descricao: json['descricao']?.toString(),
      idMateriaisFracionados: parseInt(json['id_materiais_fracionados']),
      idMateriais: parseInt(json['id_materiais']),
      status: json['status']?.toString(),
      idUsuarios: parseInt(json['id_usuarios']),
      dsMaterial: json['ds_material']?.toString(),
      dsUnidadesMedidas: json['ds_unidades_medidas']?.toString(),
      dsModoConservacao: json['ds_modo_conservacao']?.toString(),
      qtdFracionada: json['qtd_fracionada']?.toString(),
      dtFracionamento: json['dt_fracionamento']?.toString(),
      dtFracionamentoReduzido:
          json['dt_fracionamento_reduzido']?.toString(),
      dtVencimento: json['dt_vencimento']?.toString(),
      dtVencimentoReduzido: json['dt_vencimento_reduzido']?.toString(),
      nmPessoa: json['nm_pessoa']?.toString(),
      nmPessoaAbreviado: json['nm_pessoa_abreviado']?.toString(),
      nmSetor: json['nm_setor']?.toString(),
      numEtiqueta: parseInt(json['num_etiqueta']),
    );
  }

  String get qtdFracionadaDisplay {
    final raw = qtdFracionada?.trim();
    if (raw == null || raw.isEmpty) return '';
    // Normaliza qualquer separador para ponto para parse.
    final normalize = raw.replaceAll(',', '.');
    final value = double.tryParse(normalize);
    if (value == null) return raw; // não parseou, devolve original
    // Inteiro: remove casas decimais.
    if (value % 1 == 0) return value.toInt().toString();
    // Formata removendo zeros desnecessários e usando vírgula como separador.
    String s = value.toString(); // ex: 6.5 ou 6.125
    if (s.contains('.')) {
      s = s.replaceAll(RegExp(r'0+$'), ''); // remove zeros à direita
      s = s.replaceAll(RegExp(r'\.$'), ''); // remove ponto final se restou
    }
    s = s.replaceAll('.', ',');
    return s;
  }
}
