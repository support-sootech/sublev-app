import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ootech/controller/entrada_materiais_controller.dart';
import 'package:ootech/models/modo_conservacao_model.dart';
import 'package:ootech/models/option_model.dart';
import 'package:ootech/models/unidade_medida_model.dart';
import 'package:ootech/repositories/combos_repository.dart';
import 'package:ootech/repositories/modo_conservacao_repository.dart';
import 'package:ootech/repositories/unidades_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    Get.reset();
  });

  test('loadCombos populates dropdown options without hitting network', () async {
    final controller = EntradaMateriaisController(
      combosRepository: _StubCombosRepository(),
      unidadesRepository: _StubUnidadesRepository(),
      modoConservacaoRepository: _StubModosRepository(),
    );

    await controller.loadCombos();

    expect(controller.categorias, hasLength(1));
    expect(controller.fornecedores, isNotEmpty);
    expect(controller.fabricantes, isNotEmpty);
    expect(controller.marcas, isNotEmpty);
    expect(controller.condicoesEmbalagem, isNotEmpty);
    expect(controller.unidades, isNotEmpty);
    expect(controller.modosConservacao, isNotEmpty);
  });
}

class _StubCombosRepository extends CombosRepository {
  final OptionModel _option =
      const OptionModel(id: 10, descricao: 'stub option');

  @override
  Future<List<OptionModel>> listarCategorias({String status = 'A'}) async {
    return [_option];
  }

  @override
  Future<List<OptionModel>> listarFornecedores({String status = 'A'}) async {
    return [_option];
  }

  @override
  Future<List<OptionModel>> listarFabricantes({String status = 'A'}) async {
    return [_option];
  }

  @override
  Future<List<OptionModel>> listarMarcas({String status = 'A'}) async {
    return [_option];
  }

  @override
  Future<List<OptionModel>> listarCondicoesEmbalagem({String status = 'A'}) async {
    return [_option];
  }
}

class _StubUnidadesRepository extends UnidadesRepository {
  @override
  Future<List<UnidadeMedidaModel>> listar({String status = 'A'}) async {
    return [
      UnidadeMedidaModel(id: 1, descricao: 'KG', sigla: 'kg'),
    ];
  }

  @override
  Future<List<OptionModel>> listarAsOptionModel({String status = 'A'}) async {
    return [
      const OptionModel(id: 1, descricao: 'Kg'),
    ];
  }
}

class _StubModosRepository extends ModoConservacaoRepository {
  @override
  Future<List<ModoConservacaoModel>> listar({String status = 'A'}) async {
    return [
      ModoConservacaoModel(id: 1, descricao: 'Refrigerado'),
    ];
  }
}
