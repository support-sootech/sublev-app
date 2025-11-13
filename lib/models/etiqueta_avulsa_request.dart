class EtiquetaAvulsaRequest {
  final String descricao;
  final DateTime? validade;
  final double? peso;
  final int? idUnidadesMedidas;
  final int? idModoConservacao;
  final int quantidade;

  EtiquetaAvulsaRequest({
    required this.descricao,
    required this.quantidade,
    this.validade,
    this.peso,
    this.idUnidadesMedidas,
    this.idModoConservacao,
  });

  Map<String, dynamic> toJson() {
    return {
      'descricao': descricao,
      'quantidade': quantidade,
      if (validade != null) 'validade': '${validade!.toIso8601String().substring(0,10)}',
      if (peso != null) 'peso': peso,
      if (idUnidadesMedidas != null) 'idUnidadesMedidas': idUnidadesMedidas,
      if (idModoConservacao != null) 'idModoConservacao': idModoConservacao,
    };
  }
}
