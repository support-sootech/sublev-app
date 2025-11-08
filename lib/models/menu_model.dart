import 'package:flutter/material.dart';

class MenuModel {
  int? id;
  String? title;
  Widget? page;
  IconData? icon;

  MenuModel({this.id, this.title, this.page, this.icon});

  MenuModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    title = json['title'];
    page = json['widget'];
    icon = json['icon'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['title'] = title;
    data['page'] = page;
    data['icon'] = icon;
    return data;
  }
}
