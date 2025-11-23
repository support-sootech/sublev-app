class MaterialModel {
  final Map<String, dynamic> _raw;
  int? idMateriais;
  int? idPessoasFabricante;
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
  String? nmFabricante;
  String? nmFornecedor;
  String? nmResponsavel;
  String? status;

  MaterialModel({
    Map<String, dynamic>? raw,
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
    this.nmFabricante,
    this.nmFornecedor,
    this.status,
  }) : _raw = Map<String, dynamic>.from(raw ?? {});

  MaterialModel.fromJson(Map<String, dynamic> json)
      : _raw = Map<String, dynamic>.from(json) {
    idMateriais = _parseInt(json['id_materiais']);
    idPessoasFabricante = _parseInt(json['id_pessoas_fabricante']);
    descricao = _parseString(json['descricao']);
    peso = _parseString(json['peso']);
    lote = _parseString(json['lote']);
    codBarras = _parseString(json['cod_barras']);
    marca = _parseString(json['marca']);
    dsUnidadeMedida = _parseString(json['ds_unidade_medida']);
    colorDtVencimento = _parseString(json['color_dt_vencimento']);
    quantidade = json['quantidade'];
    dtFabricacao = _parseString(json['dt_fabricacao']);
    dtVencimento = _parseString(json['dt_vencimento']);
    // nm_fabricante pode vir vazio dependendo do SELECT (usa p1.nome/e1.nome).
    // Alguns endpoints retornam nm_pessoa/nome para fabricante. Fallback:
    final fabricanteRaw = _parseString(json['nm_fabricante']);
    if (fabricanteRaw == null || fabricanteRaw.isEmpty) {
      final alt = _parseString(json['nm_pessoa']) ?? _parseString(json['nome']) ?? _parseString(json['fabricante']);
      nmFabricante = alt;
      if ((alt != null && alt.isNotEmpty)) {
        _raw['nm_fabricante'] = alt; // injeta chave normalizada para listagem
      }
    } else {
      nmFabricante = fabricanteRaw;
    }
    nmFornecedor = _parseString(json['nm_fornecedor']);
    nmResponsavel = _parseString(json['nm_responsavel']);
    status = _parseString(json['status']);
  }

  int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  String? _parseString(dynamic value) {
    if (value == null) return null;
    return value.toString();
  }

  Map<String, dynamic> toJson() => Map<String, dynamic>.from(_raw);
}
