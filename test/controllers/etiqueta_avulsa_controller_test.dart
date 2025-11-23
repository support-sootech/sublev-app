import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ootech/controller/etiqueta_avulsa_controller.dart';
import 'package:ootech/models/etiqueta_avulsa_models.dart';
import 'package:ootech/models/etiqueta_avulsa_request.dart';
import 'package:ootech/models/modo_conservacao_model.dart';
import 'package:ootech/models/unidade_medida_model.dart';
import 'package:ootech/repositories/etiqueta_repository.dart';
import 'package:ootech/repositories/modo_conservacao_repository.dart';
import 'package:ootech/repositories/unidades_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    Get.reset();
  });

  test('loadCombos fills unidades e modos without network', () async {
    final controller = EtiquetaAvulsaController(
      unidadesRepository: _StubUnidadesRepository(),
      modosRepository: _StubModoRepository(),
    );

    await controller.loadCombos();

    expect(controller.unidades, isNotEmpty);
    expect(controller.modos, isNotEmpty);
  });

  test('criar forwards request to repository and returns response', () async {
    final expectedResponse = AvulsaResponse(
      success: true,
      ids: [1],
      data: [
        EtiquetaAvulsaItem(idEtiquetas: 1, descricao: 'Teste'),
      ],
    );
    final controller = EtiquetaAvulsaController(
      repository: _StubEtiquetaRepository(expectedResponse),
    );

    final request = EtiquetaAvulsaRequest(
      descricao: 'teste',
      validade: DateTime(2025, 1, 1),
      peso: 1.0,
      idUnidadesMedidas: 1,
      idModoConservacao: 1,
      quantidade: 1,
    );

    final response = await controller.criar(request);
    expect(response.success, isTrue);
    expect(response.data.first.idEtiquetas, equals(1));
  });
}

class _StubEtiquetaRepository extends EtiquetaRepository {
  final AvulsaResponse response;

  _StubEtiquetaRepository(this.response);

  @override
  Future<AvulsaResponse> criarEtiquetaAvulsaComFracionamento(
      EtiquetaAvulsaRequest request) async {
    return response;
  }

  @override
  Future<AvulsaResponse> criarEtiquetaAvulsa(
      EtiquetaAvulsaRequest request) async {
    return response;
  }
}

class _StubUnidadesRepository extends UnidadesRepository {
  @override
  Future<List<UnidadeMedidaModel>> listar({String status = 'A'}) async {
    return [
      UnidadeMedidaModel(id: 1, descricao: 'Kg', sigla: 'kg'),
    ];
  }
}

class _StubModoRepository extends ModoConservacaoRepository {
  @override
  Future<List<ModoConservacaoModel>> listar({String status = 'A'}) async {
    return [
      ModoConservacaoModel(id: 1, descricao: 'Refrigerado'),
    ];
  }
}
