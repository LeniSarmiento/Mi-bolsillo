import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mi_bolsillo/core/formatting/cop_formatter.dart';
import 'package:mi_bolsillo/core/routing/app_routes.dart';
import 'package:mi_bolsillo/core/theme/app_colors.dart';
import 'package:mi_bolsillo/core/theme/app_spacing.dart';

import '../../../core/formatting/exports.dart';

import 'package:mi_bolsillo/core/widgets/state_feedback_views.dart';
import 'package:mi_bolsillo/features/analysis/application/analysis_provider.dart';

/// Screen 7: Análisis y reportes con dona de gastos por categoría y diagnóstico.
class AnalysisScreen extends ConsumerStatefulWidget {
  const AnalysisScreen({super.key});

  @override
  ConsumerState<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends ConsumerState<AnalysisScreen> {
  AnalysisPeriod _period = AnalysisPeriod.monthly;

  static const List<Color> _chartPalette = [
    AppColors.primary,
    AppColors.secondary,
    AppColors.warning,
    Color(0xFF0EA5E9),
    Color(0xFFEF4444),
    Color(0xFF8B5CF6),
    Color(0xFF14B8A6),
    Color(0xFF64748B),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = context.semanticColors;
    final report = ref.watch(analysisReportProvider(_period));

    return Scaffold(
      appBar: AppBar(title: const Text('Análisis y Reportes')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.pagePadding(context),
            AppSpacing.sm,
            AppSpacing.pagePadding(context),
            96,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: AppSpacing.maxContentWidth(context),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SegmentedButton<AnalysisPeriod>(
                    showSelectedIcon: false,
                    segments: AnalysisPeriod.values
                        .map(
                          (p) => ButtonSegment<AnalysisPeriod>(
                            value: p,
                            label: Text(p.label),
                          ),
                        )
                        .toList(),
                    selected: {_period},
                    onSelectionChanged: (selection) {
                      setState(() => _period = selection.first);
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (report.categories.isEmpty)
                    EmptyStateView(
                      icon: Icons.pie_chart_outline_rounded,
                      title: 'Sin gastos para analizar',
                      description: 'Registra al menos un gasto para ver el reparto por categorías y tu diagnóstico financiero.',
                      actionLabel: 'Registrar gasto',
                      onAction: () => context.push(AppRoutes.registerExpense),
                    )
                  else ...[
                    Card(
                      color: semantic.incomeContainer.withValues(alpha: 0.65),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.lightbulb_outline_rounded,
                              color: semantic.income,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Diagnóstico Amigable',
                                    style: theme.textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    report.topCategory != null
                                        ? 'Tu mayor categoría es ${report.topCategory!.category} (${report.topCategory!.percentage}% del gasto). Conservas ${report.freePercent}% libre de tus ingresos.'
                                        : 'Tu balance del período está al día.',
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Flujo de Dinero (${_period.label})',
                                    style: theme.textTheme.titleMedium,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Chip(
                                  label: Text('${report.freePercent}% libre'),
                                  backgroundColor: semantic.incomeContainer,
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            _FlowRow(
                              label: 'Ingresos totales',
                              value: CopFormatter.format(report.totalIncomeCop),
                              color: semantic.income,
                            ),
                            const SizedBox(height: 6),
                            _FlowRow(
                              label: 'Gastos totales',
                              value: CopFormatter.formatSigned(
                                report.totalExpensesCop,
                                isPositive: false,
                              ),
                              color: semantic.expense,
                            ),
                            const Divider(height: 20),
                            _FlowRow(
                              label: report.savedCop >= 0
                                  ? 'Saldo libre'
                                  : 'Déficit del período',
                              value: CopFormatter.format(report.savedCop),
                              color: report.savedCop >= 0
                                  ? semantic.income
                                  : semantic.expense,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Gastos por Categoría',
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Center(
                              child: SizedBox(
                                width: 170,
                                height: 170,
                                child: CustomPaint(
                                  painter: _DonutChartPainter(
                                    slices: report.categories,
                                    palette: _chartPalette,
                                    centerColor: theme.cardColor,
                                  ),
                                  child: Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Total gastos',
                                          style: theme.textTheme.labelSmall,
                                        ),
                                        Text(
                                          CopFormatter.format(
                                            report.totalExpensesCop,
                                            includeCurrency: false,
                                          ),
                                          style: theme.textTheme.titleSmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            ...List.generate(report.categories.length, (i) {
                              final item = report.categories[i];
                              final color =
                                  _chartPalette[i % _chartPalette.length];
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 14,
                                      height: 14,
                                      decoration: BoxDecoration(
                                        color: color,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Expanded(
                                      child: Text(
                                        item.category,
                                        style: theme.textTheme.bodyLarge,
                                      ),
                                    ),
                                    Text(
                                      '${item.percentage}% · ${CopFormatter.format(item.amountCop, includeCurrency: false)}',
                                      style: theme.textTheme.titleSmall,
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Card(
                      color: semantic.warningContainer.withValues(alpha: 0.7),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Row(
                          children: [
                            Icon(
                              Icons.track_changes_rounded,
                              color: semantic.warning,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Foco de Atención',
                                    style: theme.textTheme.titleSmall,
                                  ),
                                  Text(
                                    'Promedio de gasto diario: ${CopFormatter.format(report.dailyAverageCop)} / día.',
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    OutlinedButton.icon(
                      onPressed: () =>
                          exportReport(context, report, _period.label),
                      icon: const Icon(Icons.picture_as_pdf_outlined),
                      label: const Text('Exportar resumen a PDF'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FlowRow extends StatelessWidget {
  const _FlowRow({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(color: color),
        ),
      ],
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  _DonutChartPainter({
    required this.slices,
    required this.palette,
    required this.centerColor,
  });

  final List<CategoryBreakdown> slices;
  final List<Color> palette;
  final Color centerColor;

  @override
  void paint(Canvas canvas, Size size) {
    final total = slices.fold<int>(0, (sum, s) => sum + s.amountCop);
    if (total <= 0) return;

    final rect = Offset.zero & size;
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 26
      ..strokeCap = StrokeCap.butt;

    final insetRect = rect.deflate(14);
    var startAngle = -math.pi / 2;

    for (var i = 0; i < slices.length; i++) {
      final sweep = (slices[i].amountCop / total) * (math.pi * 2);
      strokePaint.color = palette[i % palette.length];
      canvas.drawArc(insetRect, startAngle, sweep - 0.03, false, strokePaint);
      startAngle += sweep;
    }

    final innerPaint = Paint()..color = centerColor;
    canvas.drawCircle(size.center(Offset.zero), size.width * 0.28, innerPaint);
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) =>
      oldDelegate.slices != slices || oldDelegate.centerColor != centerColor;
}
