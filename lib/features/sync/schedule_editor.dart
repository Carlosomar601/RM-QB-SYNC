import 'package:flutter/material.dart';

import '../../core/dates.dart';
import '../../core/schedule.dart';
import '../../data/db/repositories.dart';
import '../../ui/guided/guided.dart';

/// Mutable schedule draft shared by the step widgets.
class ScheduleDraft extends ChangeNotifier {
  ScheduleDraft({ScheduleModel? from}) {
    if (from != null) {
      enabled = from.enabled;
      frequency = from.frequency;
      time = from.timeOfDay;
      dayOfWeek = from.dayOfWeek ?? 1;
      dayOfMonth = from.dayOfMonth ?? 1;
    }
  }

  bool enabled = true;
  ScheduleFrequency frequency = ScheduleFrequency.daily;
  TimeOfDayHm time = const TimeOfDayHm(23, 0);
  int dayOfWeek = 1;
  int dayOfMonth = 1;

  void update(void Function(ScheduleDraft d) f) {
    f(this);
    notifyListeners();
  }

  ScheduleModel toModel() => ScheduleModel(
        enabled: enabled,
        frequency: frequency,
        timeOfDay: time,
        dayOfWeek: frequency == ScheduleFrequency.weekly ? dayOfWeek : null,
        dayOfMonth: frequency == ScheduleFrequency.monthly ? dayOfMonth : null,
      );

  Map<String, Object?> toJson() => {
        'enabled': enabled,
        'frequency': frequency.name,
        'time': time.toString(),
        'dayOfWeek': dayOfWeek,
        'dayOfMonth': dayOfMonth,
      };

  void applyJson(Map<String, Object?> j) {
    enabled = j['enabled'] as bool? ?? enabled;
    frequency = ScheduleFrequency.parse('${j['frequency'] ?? frequency.name}');
    time = TimeOfDayHm.parse('${j['time'] ?? time}');
    dayOfWeek = (j['dayOfWeek'] as num?)?.toInt() ?? dayOfWeek;
    dayOfMonth = (j['dayOfMonth'] as num?)?.toInt() ?? dayOfMonth;
    notifyListeners();
  }
}

class FrequencyPicker extends StatelessWidget {
  const FrequencyPicker({super.key, required this.draft, this.enabled = true});
  final ScheduleDraft draft;
  final bool enabled;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: draft,
        builder: (context, _) => RadioGroup<ScheduleFrequency>(
          groupValue: draft.frequency,
          onChanged: (v) => enabled && v != null ? draft.update((d) => d.frequency = v) : null,
          child: Column(children: [
            for (final (f, desc) in [
              (ScheduleFrequency.daily, 'Envía las ventas del mismo día, todos los días a la hora indicada.'),
              (ScheduleFrequency.weekly, 'Envía los últimos 7 días (hoy y los 6 anteriores) una vez por semana.'),
              (ScheduleFrequency.monthly, 'Envía el mes anterior completo una vez al mes.'),
            ])
              RadioListTile<ScheduleFrequency>(
                value: f,
                enabled: enabled,
                title: Text(f.label + (f == ScheduleFrequency.daily ? ' (recomendada)' : '')),
                subtitle: Text(desc),
              ),
          ]),
        ),
      );
}

class TimeDayPicker extends StatelessWidget {
  const TimeDayPicker({super.key, required this.draft, this.enabled = true});
  final ScheduleDraft draft;
  final bool enabled;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: draft,
        builder: (context, _) => Wrap(spacing: 16, runSpacing: 16, crossAxisAlignment: WrapCrossAlignment.center, children: [
          OutlinedButton.icon(
            onPressed: !enabled
                ? null
                : () async {
                    final t = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay(hour: draft.time.hour, minute: draft.time.minute),
                      helpText: 'Hora de envío',
                    );
                    if (t != null) draft.update((d) => d.time = TimeOfDayHm(t.hour, t.minute));
                  },
            icon: const Icon(Icons.access_time),
            label: Text('Hora: ${draft.time}'),
          ),
          const HelpTip('Recomendado: después del cierre de la tienda (por ejemplo 23:00) para incluir todas las ventas del día.'),
          if (draft.frequency == ScheduleFrequency.weekly)
            SizedBox(
              width: 220,
              child: DropdownButtonFormField<int>(
                isExpanded: true,
                initialValue: draft.dayOfWeek,
                decoration: const InputDecoration(labelText: 'Día de la semana *'),
                items: [for (final e in weekdayNames.entries) DropdownMenuItem(value: e.key, child: Text(e.value))],
                onChanged: enabled ? (v) => draft.update((d) => d.dayOfWeek = v ?? 1) : null,
              ),
            ),
          if (draft.frequency == ScheduleFrequency.monthly)
            SizedBox(
              width: 220,
              child: DropdownButtonFormField<int>(
                isExpanded: true,
                initialValue: draft.dayOfMonth,
                decoration: const InputDecoration(labelText: 'Día del mes *', helperText: '1 a 28'),
                items: [for (var i = 1; i <= 28; i++) DropdownMenuItem(value: i, child: Text('$i'))],
                onChanged: enabled ? (v) => draft.update((d) => d.dayOfMonth = v ?? 1) : null,
              ),
            ),
        ]),
      );
}

class ScheduleSummaryView extends StatelessWidget {
  const ScheduleSummaryView({super.key, required this.draft, required this.now, this.enabled = true});
  final ScheduleDraft draft;
  final DateTime now;
  final bool enabled;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: draft,
        builder: (context, _) {
          final m = draft.toModel();
          final next = m.computeNext(now);
          final range = ScheduleCalculator.rangeFor(m.frequency, next);
          return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: draft.enabled,
              onChanged: enabled ? (v) => draft.update((d) => d.enabled = v) : null,
              title: const Text('Programación activa'),
              subtitle: Text(draft.enabled ? 'Se enviará automáticamente.' : 'Guardada pero sin ejecutarse.'),
            ),
            GuidanceBanner(
              kind: GuidanceKind.info,
              title: m.description,
              message: draft.enabled
                  ? 'Próxima ejecución: ${Dates.dmyHm(next)}\nEnviará: ${Dates.dmy(range.from)} al ${Dates.dmy(range.to)}\n'
                      'Si ese momento la aplicación está cerrada, se enviará al volver a abrirla. '
                      'Nunca envía fechas que ya se enviaron con éxito.'
                  : 'La programación está desactivada.',
            ),
          ]);
        },
      );
}
