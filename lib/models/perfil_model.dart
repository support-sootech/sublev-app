class PerfilModel {
  int? idPerfil;
  String? dsPerfil;

  PerfilModel({this.idPerfil, this.dsPerfil});

  PerfilModel.fromJson(Map<String, dynamic> json) {
    idPerfil = json['id_perfil'];
    dsPerfil = json['ds_perfil'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id_perfil'] = idPerfil;
    data['ds_perfil'] = dsPerfil;
    return data;
  }
}
