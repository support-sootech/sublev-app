class EtiquetaModel {
  int? idEtiquetas;
  String? descricao;
  String? codigo;
  int? idMateriaisFracionados;
  int? idMateriais;
  String? status;
  int? idUsuarios;
  String? dsMaterial;
  String? lote;
  String? dtFabricacao;
  String? dtFabricacaoReduzido;
  String? codBarras;
  String? dsUnidadesMedidas;
  String? dsModoConservacao;
  String? qtdFracionada;
  String? dtFracionamento;
  String? dtFracionamentoReduzido;
  String? dtVencimento;
  String? dtVencimentoReduzido;
  String? nmPessoa;
  String? nmPessoaAbreviado;
  String? nmSetor;
  int? numEtiqueta;

  EtiquetaModel({
    this.idEtiquetas,
    this.descricao,
    this.codigo,
    this.idMateriaisFracionados,
    this.idMateriais,
    this.status,
    this.idUsuarios,
    this.dsMaterial,
    this.lote,
    this.dtFabricacao,
    this.dtFabricacaoReduzido,
    this.codBarras,
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

  EtiquetaModel.fromJson(Map<String, dynamic> json) {
    idEtiquetas = json['id_etiquetas'];
    descricao = json['descricao'];
    codigo = json['codigo'];
    idMateriaisFracionados = json['id_materiais_fracionados'];
    idMateriais = json['id_materiais'];
    status = json['status'];
    idUsuarios = json['id_usuarios'];
    dsMaterial = json['ds_material'];
    lote = json['lote'];
    dtFabricacao = json['dt_fabricacao'];
    dtFabricacaoReduzido = json['dt_fabricacao_reduzido'];
    codBarras = json['cod_barras'];
    dsUnidadesMedidas = json['ds_unidades_medidas'];
    dsModoConservacao = json['ds_modo_conservacao'];
    qtdFracionada = json['qtd_fracionada'];
    dtFracionamento = json['dt_fracionamento'];
    dtFracionamentoReduzido = json['dt_fracionamento_reduzido'];
    dtVencimento = json['dt_vencimento'];
    dtVencimentoReduzido = json['dt_vencimento_reduzido'];
    nmPessoa = json['nm_pessoa'];
    nmPessoaAbreviado = json['nm_pessoa_abreviado'];
    nmSetor = json['nm_setor'];
    numEtiqueta = json['num_etiqueta'];
  }

  // Formata qtd_fracionada para exibição limpa:
  // "6,00" -> "6" ; "6,50" permanece "6,50" ; valores sem vírgula retornam como estão.
  String get qtdFracionadaDisplay {
    final raw = qtdFracionada?.trim();
    if (raw == null || raw.isEmpty) return '';
    final normalize = raw.replaceAll(',', '.');
    final value = double.tryParse(normalize);
    if (value == null) return raw; // devolve original se não parseia
    if (value % 1 == 0) return value.toInt().toString(); // inteiro puro
    String s = value.toString();
    if (s.contains('.')) {
      s = s.replaceAll(RegExp(r'0+$'), '');
      s = s.replaceAll(RegExp(r'\.$'), '');
    }
    s = s.replaceAll('.', ',');
    return s;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id_etiquetas'] = idEtiquetas;
    data['descricao'] = descricao;
    data['codigo'] = codigo;
    data['id_materiais_fracionados'] = idMateriaisFracionados;
    data['id_materiais'] = idMateriais;
    data['status'] = status;
    data['id_usuarios'] = idUsuarios;
    data['ds_material'] = dsMaterial;
    data['lote'] = lote;
    data['dt_fabricacao'] = dtFabricacao;
    data['dt_fabricacao_reduzido'] = dtFabricacaoReduzido;
    data['cod_barras'] = codBarras;
    data['ds_unidades_medidas'] = dsUnidadesMedidas;
    data['ds_modo_conservacao'] = dsModoConservacao;
    data['qtd_fracionada'] = qtdFracionada;
    data['dt_fracionamento'] = dtFracionamento;
    data['dt_fracionamento_reduzido'] = dtFracionamentoReduzido;
    data['dt_vencimento'] = dtVencimento;
    data['dt_vencimento_reduzido'] = dtVencimentoReduzido;
    data['nm_pessoa'] = nmPessoa;
    data['nm_pessoa_abreviado'] = nmPessoaAbreviado;
    data['nm_setor'] = nmSetor;
    data['num_etiqueta'] = numEtiqueta;
    return data;
  }
}
