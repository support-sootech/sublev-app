import 'package:ootech/models/perfil_model.dart';

class UserModel {
  int? idUsuarios;
  String? senha;
  String? status;
  int? idPessoas;
  int? idSetor;
  String? hash;
  String? nmPessoa;
  String? email;
  String? dtNascimento;
  String? tpJuridico;
  String? cpfCnpj;
  String? genero;
  int? cep;
  String? logradouro;
  String? numero;
  String? complemento;
  String? bairro;
  String? cidade;
  String? estado;
  int? codIbge;
  int? telefone;
  int? idEmpresas;
  String? nmEmpresa;
  int? idTiposPessoas;
  String? dsTiposPessoas;
  String? hashLogin;
  String? nmSetor;
  List<PerfilModel>? perfil;

  UserModel({
    this.idUsuarios,
    this.senha,
    this.status,
    this.idPessoas,
    this.idSetor,
    this.hash,
    this.nmPessoa,
    this.email,
    this.dtNascimento,
    this.tpJuridico,
    this.cpfCnpj,
    this.genero,
    this.cep,
    this.logradouro,
    this.numero,
    this.complemento,
    this.bairro,
    this.cidade,
    this.estado,
    this.codIbge,
    this.telefone,
    this.idEmpresas,
    this.nmEmpresa,
    this.idTiposPessoas,
    this.dsTiposPessoas,
    this.hashLogin,
    this.nmSetor,
    this.perfil,
  });

  UserModel.fromJson(Map<String, dynamic> json) {
    idUsuarios = json['id_usuarios'];
    senha = json['senha'];
    status = json['status'];
    idPessoas = json['id_pessoas'];
    idSetor = json['id_setor'];
    hash = json['hash'];
    nmPessoa = json['nm_pessoa'];
    email = json['email'];
    dtNascimento = json['dt_nascimento'];
    tpJuridico = json['tp_juridico'];
    cpfCnpj = json['cpf_cnpj'];
    genero = json['genero'];
    cep = json['cep'];
    logradouro = json['logradouro'];
    numero = json['numero'];
    complemento = json['complemento'];
    bairro = json['bairro'];
    cidade = json['cidade'];
    estado = json['estado'];
    codIbge = json['cod_ibge'];
    telefone = json['telefone'];
    idEmpresas = json['id_empresas'];
    nmEmpresa = json['nm_empresa'];
    idTiposPessoas = json['id_tipos_pessoas'];
    dsTiposPessoas = json['ds_tipos_pessoas'];
    hashLogin = json['hash_login'];
    nmSetor = json['nm_setor'];
    if (json['perfil'] != null) {
      perfil = <PerfilModel>[];
      json['perfil'].forEach((v) {
        perfil!.add(PerfilModel.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id_usuarios'] = idUsuarios;
    data['senha'] = senha;
    data['status'] = status;
    data['id_pessoas'] = idPessoas;
    data['id_setor'] = idSetor;
    data['hash'] = hash;
    data['nm_pessoa'] = nmPessoa;
    data['email'] = email;
    data['dt_nascimento'] = dtNascimento;
    data['tp_juridico'] = tpJuridico;
    data['cpf_cnpj'] = cpfCnpj;
    data['genero'] = genero;
    data['cep'] = cep;
    data['logradouro'] = logradouro;
    data['numero'] = numero;
    data['complemento'] = complemento;
    data['bairro'] = bairro;
    data['cidade'] = cidade;
    data['estado'] = estado;
    data['cod_ibge'] = codIbge;
    data['telefone'] = telefone;
    data['id_empresas'] = idEmpresas;
    data['nm_empresa'] = nmEmpresa;
    data['id_tipos_pessoas'] = idTiposPessoas;
    data['ds_tipos_pessoas'] = dsTiposPessoas;
    data['hash_login'] = hashLogin;
    data['nm_setor'] = nmSetor;
    if (perfil != null) {
      data['perfil'] = perfil!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}
