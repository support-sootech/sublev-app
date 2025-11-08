import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class CardInfoWidget extends StatelessWidget {
  final Color cardColor;
  final IconData icon;
  final Widget qtd;
  final String descricao;
  final Function()? onTap;
  const CardInfoWidget({
    super.key,
    required this.cardColor,
    required this.icon,
    required this.qtd,
    required this.descricao,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: () {
          if (onTap != null) {
            onTap!();
          }
        },
        child: Card(
          color: cardColor,
          elevation: 8,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                FaIcon(icon, size: 28, color: Colors.white),
                qtd,
                Text(
                  descricao,
                  style: TextStyle(fontSize: 14, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
