class ProdutoModel {
  final String descricao;
  final String codigoBarras;
  final int? diasVencimento;
  final int? diasVencimentoAberto;
  final double? peso;
  final int? idUnidadesMedidas;
  final int? idModoConservacao;
  final int? idPessoasFabricante;
  final int? idMateriaisMarcas;
  final int? idMateriaisCategorias;

  ProdutoModel({
    required this.descricao,
    required this.codigoBarras,
    this.diasVencimento,
    this.diasVencimentoAberto,
    this.peso,
    this.idUnidadesMedidas,
    this.idModoConservacao,
    this.idPessoasFabricante,
    this.idMateriaisMarcas,
    this.idMateriaisCategorias,
  });

  factory ProdutoModel.fromJson(Map<String, dynamic> json) {
    double? parseDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString().replaceAll(',', '.'));
    }

    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      return int.tryParse(value.toString());
    }

    return ProdutoModel(
      descricao: (json['descricao'] ?? json['nome'] ?? '').toString(),
      codigoBarras: (json['codigo_barras'] ?? json['cod_barras'] ?? '').toString(),
      diasVencimento: parseInt(json['dias_vencimento']),
      diasVencimentoAberto: parseInt(json['dias_vencimento_aberto']),
      peso: parseDouble(json['peso']),
      idUnidadesMedidas: parseInt(json['id_unidades_medidas']),
      idModoConservacao: parseInt(json['id_modo_conservacao']),
      idPessoasFabricante: parseInt(json['id_pessoas_fabricante']),
      idMateriaisMarcas: parseInt(json['id_materiais_marcas']),
      idMateriaisCategorias: parseInt(json['id_materiais_categorias']),
    );
  }
}
