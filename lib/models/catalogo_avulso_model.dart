class CatalogoAvulsoModel {
  int? id;
  String descricao;
  int qtdeDiasVencimento;
  double peso;
  int idUnidadesMedidas;
  int idModoConservacao;
  bool favorito;
  String? dsUnidadeMedida;
  String? dsModoConservacao;
  DateTime? dtAtualizacao;

  CatalogoAvulsoModel({
    this.id,
    required this.descricao,
    required this.qtdeDiasVencimento,
    this.peso = 0.0,
    required this.idUnidadesMedidas,
    required this.idModoConservacao,
    this.favorito = true,
    this.dsUnidadeMedida,
    this.dsModoConservacao,
    this.dtAtualizacao,
  });

  factory CatalogoAvulsoModel.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      return int.tryParse(v.toString()) ?? 0;
    }
    double parseDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is double) return v;
      if (v is int) return v.toDouble();
      String s = v.toString().replaceAll(',', '.');
      return double.tryParse(s) ?? 0.0;
    }
    bool parseBool(dynamic v) {
      if (v == null) return false;
      if (v is bool) return v;
      if (v is int) return v == 1;
      return v.toString() == '1' || v.toString().toLowerCase() == 'true';
    }

    return CatalogoAvulsoModel(
      id: parseInt(json['id']),
      descricao: json['descricao'] ?? '',
      qtdeDiasVencimento: parseInt(json['qtde_dias_vencimento']),
      peso: parseDouble(json['peso']),
      idUnidadesMedidas: parseInt(json['id_unidades_medidas']),
      idModoConservacao: parseInt(json['id_modo_conservacao']),
      favorito: parseBool(json['favorito']),
      dsUnidadeMedida: json['ds_unidade_medida'],
      dsModoConservacao: json['ds_modo_conservacao'],
      dtAtualizacao: json['dt_atualizacao'] != null 
          ? DateTime.tryParse(json['dt_atualizacao'].toString()) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'descricao': descricao,
      'qtde_dias_vencimento': qtdeDiasVencimento,
      'peso': peso,
      'id_unidades_medidas': idUnidadesMedidas,
      'id_modo_conservacao': idModoConservacao,
      'favorito': favorito,
    };
  }
}
