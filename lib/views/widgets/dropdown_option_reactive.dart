import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/option_model.dart';

/// Widget de dropdown com granularidade de rebuild.
/// Rebuild separado para lista (itens) e seleção atual.
class DropdownOptionReactive extends StatelessWidget {
  final String label;
  final RxList<OptionModel> itemsRx;
  final Rx<OptionModel?> selectedRx;
  final void Function(OptionModel?)? onChanged;
  final bool enabled;
  final String? hint;
  final String? errorText;
  final FormFieldValidator<OptionModel?>? validator;
  final VoidCallback? onTapLoad; // chamado antes de abrir se precisar lazy load
  final RxBool? loadingRx; // exibe estado de carregamento se presente

  const DropdownOptionReactive({
    super.key,
    required this.label,
    required this.itemsRx,
    required this.selectedRx,
    this.onChanged,
    this.enabled = true,
    this.hint,
    this.errorText,
    this.validator,
    this.onTapLoad,
    this.loadingRx,
  });

  @override
  Widget build(BuildContext context) {
    // Usamos dois Obx: um para mudanças na lista e outro para seleção.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 4),
        Obx(() {
          // Acesso explícito ao conteúdo reativo para que o Obx
          // detecte dependências (evita erro de "improper use"):
          // - length
          // - geração de uma cópia imutável para o Dropdown.
          final length = itemsRx.length; // dependência direta
          final items = List<OptionModel>.from(itemsRx); // força iteração
          final isLoading = loadingRx?.value == true; // dependência opcional
          assert(() {
            debugPrint('DropdownOptionReactive itens update ($label): length=$length');
            return true;
          }());
          return _SelectionWrapper(
            items: items,
            selectedRx: selectedRx,
            onChanged: onChanged,
            enabled: enabled,
            debugLabel: label,
            hint: hint,
            errorText: errorText,
            validator: validator,
            onTapLoad: onTapLoad,
            isLoading: isLoading,
          );
        }),
      ],
    );
  }
}

class _SelectionWrapper extends StatelessWidget {
  final List<OptionModel> items;
  final Rx<OptionModel?> selectedRx;
  final void Function(OptionModel?)? onChanged;
  final bool enabled;
  final String? debugLabel;
  final String? hint;
  final String? errorText;
  final FormFieldValidator<OptionModel?>? validator;
  final VoidCallback? onTapLoad;
  final bool isLoading;

  const _SelectionWrapper({
    required this.items,
    required this.selectedRx,
    required this.onChanged,
    required this.enabled,
    this.debugLabel,
    this.hint,
    this.errorText,
    this.validator,
    this.onTapLoad,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final selected = selectedRx.value;
      final selectedId = selected?.id;
      assert(() {
        debugPrint('DropdownOptionReactive rebuild${debugLabel != null ? ' ($debugLabel)' : ''}: selId=$selectedId itens=${items.length}');
        return true;
      }());
      return DropdownButtonFormField<int>(
        isExpanded: true,
        value: (selectedId != null && items.any((e) => e.id == selectedId)) ? selectedId : null,
        hint: hint != null ? Text(hint!) : null,
        items: isLoading
            ? [
                const DropdownMenuItem<int>(
                  value: null,
                  child: Row(children: [SizedBox(width:16,height:16,child:CircularProgressIndicator(strokeWidth:2)), SizedBox(width:8), Text('Carregando...')]),
                )
              ]
            : items.map((e) => DropdownMenuItem<int>(
                  value: e.id,
                  child: Text(e.descricao, overflow: TextOverflow.ellipsis),
                ))
                .toList(),
        onChanged: !enabled
            ? null
            : (val) {
                if (val == null) {
                  selectedRx.value = null;
                  onChanged?.call(null);
                  return;
                }
                final match = items.firstWhereOrNull((e) => e.id == val);
                selectedRx.value = match;
                onChanged?.call(match);
              },
        onTap: () {
          if (onTapLoad != null) onTapLoad!();
        },
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          errorText: errorText,
        ),
        validator: validator == null
            ? null
            : (val) {
                final match = items.firstWhereOrNull((e) => e.id == val);
                return validator!(match);
              },
      );
    });
  }
}
