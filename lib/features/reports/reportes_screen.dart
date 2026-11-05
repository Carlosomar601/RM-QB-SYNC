import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../ui/guided/guided.dart';
import '../help/help_content.dart';

class ReportesScreen extends StatelessWidget {
  const ReportesScreen({super.key});

  @override
  Widget build(BuildContext context) => PageBody(children: [
        const ScreenHeader(
          icon: Icons.bar_chart,
          title: 'Reportes',
          purpose: 'Reportes de ventas y envíos a QuickBooks.',
          nextHint: 'Mientras tanto, use Vista Previa o Historial.',
        ),
        Card(
          child: EmptyState(
            icon: Icons.bar_chart,
            title: 'Los reportes llegarán en una próxima versión',
            message: 'Mientras tanto: para ver los totales por categoría de cualquier rango use Vista Previa; '
                'para ver qué se envió a QuickBooks y su resultado use Historial.',
            actions: [
              FilledButton.icon(
                onPressed: () => context.go(Routes.vistaPrevia),
                icon: const Icon(Icons.find_in_page_outlined),
                label: const Text('Ir a Vista Previa'),
              ),
              OutlinedButton.icon(
                onPressed: () => context.go(Routes.historial),
                icon: const Icon(Icons.history),
                label: const Text('Ir a Historial'),
              ),
            ],
          ),
        ),
      ]);
}
