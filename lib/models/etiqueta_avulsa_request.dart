class EtiquetaAvulsaRequest {
  final String descricao;
  final DateTime? validade;
  final double peso;
  final int idUnidadesMedidas;
  final int idModoConservacao;
  final int quantidade;
  final bool salvarCatalogo;

  EtiquetaAvulsaRequest({
    required this.descricao,
    required this.validade,
    required this.peso,
    required this.idUnidadesMedidas,
    required this.idModoConservacao,
    required this.quantidade,
    this.salvarCatalogo = false,
  });

  Map<String, dynamic> toJson() {
    String? validadeIso;
    if (validade != null) {
      validadeIso =
          '${validade!.year.toString().padLeft(4, '0')}-'
          '${validade!.month.toString().padLeft(2, '0')}-'
          '${validade!.day.toString().padLeft(2, '0')}';
    }

    return {
      'descricao': descricao,
      'validade': validadeIso,
      'peso': peso,
      'id_unidades_medidas': idUnidadesMedidas,
      'id_modo_conservacao': idModoConservacao,
      'quantidade': quantidade,
      'salvar_catalogo': salvarCatalogo,
    };
  }
}
