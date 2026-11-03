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
          purpose: 'Esta sección estará disponible en una próxima versión.',
          nextHint: 'Mientras tanto, use Vista Previa o Historial.',
        ),
        GuidanceBanner(
          kind: GuidanceKind.info,
          title: 'Próximamente',
          message: 'Para ver totales por categoría use Vista Previa; para ver lo enviado a QuickBooks use Historial.',
          actionLabel: 'Ir a Vista Previa',
          onAction: () => context.go(Routes.vistaPrevia),
          secondaryLabel: 'Ir a Historial',
          onSecondary: () => context.go(Routes.historial),
        ),
      ]);
}
