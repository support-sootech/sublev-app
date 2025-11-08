class MaterialModel {
  int? idMateriais;
  String? descricao;
  String? peso;
  String? lote;
  String? codBarras;
  String? marca;
  String? dsUnidadeMedida;
  String? colorDtVencimento;
  int? quantidade;
  String? dtFabricacao;
  String? dtVencimento;

  MaterialModel({
    this.idMateriais,
    this.descricao,
    this.peso,
    this.lote,
    this.codBarras,
    this.marca,
    this.dsUnidadeMedida,
    this.colorDtVencimento,
    this.quantidade,
    this.dtFabricacao,
    this.dtVencimento,
  });

  MaterialModel.fromJson(Map<String, dynamic> json) {
    idMateriais = json['id_materiais'];
    descricao = json['descricao'];
    peso = json['peso'];
    lote = json['lote'];
    codBarras = json['cod_barras'];
    marca = json['marca'];
    dsUnidadeMedida = json['ds_unidade_medida'];
    colorDtVencimento = json['color_dt_vencimento'];
    quantidade = json['quantidade'];
    dtFabricacao = json['dt_fabricacao'];
    dtVencimento = json['dt_vencimento'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id_materiais'] = this.idMateriais;
    data['descricao'] = this.descricao;
    data['peso'] = this.peso;
    data['lote'] = this.lote;
    data['cod_barras'] = this.codBarras;
    data['marca'] = this.marca;
    data['ds_unidade_medida'] = this.dsUnidadeMedida;
    data['color_dt_vencimento'] = this.colorDtVencimento;
    data['quantidade'] = this.quantidade;
    data['dt_fabricacao'] = this.dtFabricacao;
    data['dt_vencimento'] = this.dtVencimento;
    return data;
  }
}
