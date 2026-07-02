import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart' show Share, XFile;
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../widgets/fafoutt_logo.dart';

enum ReportPeriod { today, week, month, custom }

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final DatabaseService _db = DatabaseService();
  ReportPeriod _period = ReportPeriod.today;
  DateTime _customStart = DateTime.now().subtract(const Duration(days: 7));
  DateTime _customEnd = DateTime.now();

  Map<String, double> _summary = {
    'transactionCount': 0,
    'revenue': 0,
    'profit': 0,
    'averageBasket': 0,
  };
  List<Map<String, dynamic>> _topProducts = [];
  List<Map<String, dynamic>> _byPaymentMethod = [];
  bool _loading = true;

  final _currencyFormat =
      NumberFormat.currency(locale: 'fr', symbol: 'HTG ', decimalDigits: 0);
  final _dateFormat = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    _load();
  }

  (DateTime, DateTime) get _range {
    final now = DateTime.now();
    switch (_period) {
      case ReportPeriod.today:
        final start = DateTime(now.year, now.month, now.day);
        return (start, now);
      case ReportPeriod.week:
        final start = now.subtract(const Duration(days: 7));
        return (start, now);
      case ReportPeriod.month:
        final start = DateTime(now.year, now.month, 1);
        return (start, now);
      case ReportPeriod.custom:
        return (_customStart, _customEnd);
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final (start, end) = _range;
    final summary = await _db.getSalesSummary(start, end);
    final topProducts = await _db.getTopProducts(start, end);
    final byPayment = await _db.getSalesByPaymentMethod(start, end);
    setState(() {
      _summary = summary;
      _topProducts = topProducts;
      _byPaymentMethod = byPayment;
      _loading = false;
    });
  }

  String _paymentLabel(String method) {
    switch (method) {
      case 'cash':
        return 'Cash';
      case 'card':
        return 'Carte';
      case 'mobileMoney':
        return 'Mobile Money';
      default:
        return method;
    }
  }

  Future<void> _pickCustomRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _customStart, end: _customEnd),
    );
    if (picked != null) {
      setState(() {
        _customStart = picked.start;
        _customEnd = picked.end;
        _period = ReportPeriod.custom;
      });
      _load();
    }
  }

  Future<void> _exportPdf() async {
    final (start, end) = _range;
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Fafoutt Store — Rapport de ventes',
                style:
                    pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
            pw.Text(
                'Période : ${_dateFormat.format(start)} au ${_dateFormat.format(end)}'),
            pw.SizedBox(height: 16),
            pw.Text('Chiffre d\'affaires : ${_currencyFormat.format(_summary['revenue'])}'),
            pw.Text('Bénéfice estimé : ${_currencyFormat.format(_summary['profit'])}'),
            pw.Text('Nombre de ventes : ${_summary['transactionCount']!.toInt()}'),
            pw.Text('Panier moyen : ${_currencyFormat.format(_summary['averageBasket'])}'),
            pw.SizedBox(height: 16),
            pw.Text('Produits les plus vendus',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
            pw.SizedBox(height: 6),
            ..._topProducts.map((p) => pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('${p['name']} x${p['quantity']}'),
                    pw.Text(_currencyFormat.format(p['revenue'])),
                  ],
                )),
          ],
        ),
      ),
    );
    await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: 'rapport_fafoutt_${DateTime.now().millisecondsSinceEpoch}.pdf');
  }

  Future<void> _exportCsv() async {
    final (start, end) = _range;
    final sales = await _db.getSalesReport(start, end);
    final buffer = StringBuffer();
    buffer.writeln('Date,Mode de paiement,Total (HTG)');
    for (final sale in sales) {
      final date = DateTime.parse(sale['date']);
      buffer.writeln(
          '${DateFormat('dd/MM/yyyy HH:mm').format(date)},${_paymentLabel(sale['paymentMethod'])},${sale['total']}');
    }
    final dir = await getTemporaryDirectory();
    final file = File(
        '${dir.path}/rapport_fafoutt_${DateTime.now().millisecondsSinceEpoch}.csv');
    await file.writeAsString(buffer.toString());
    await Share.shareXFiles([XFile(file.path)],
        text: 'Rapport de ventes Fafoutt Store');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const FafouttHeader(subtitle: 'Rapports de ventes'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.ios_share_rounded),
            tooltip: 'Exporter',
            onSelected: (value) {
              if (value == 'pdf') _exportPdf();
              if (value == 'csv') _exportCsv();
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'pdf',
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf_outlined, size: 18),
                    SizedBox(width: 10),
                    Text('Exporter en PDF'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'csv',
                child: Row(
                  children: [
                    Icon(Icons.table_chart_outlined, size: 18),
                    SizedBox(width: 10),
                    Text('Exporter en Excel (CSV)'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _PeriodChip(
                    label: 'Aujourd\'hui',
                    selected: _period == ReportPeriod.today,
                    onTap: () {
                      setState(() => _period = ReportPeriod.today);
                      _load();
                    },
                  ),
                  const SizedBox(width: 8),
                  _PeriodChip(
                    label: '7 derniers jours',
                    selected: _period == ReportPeriod.week,
                    onTap: () {
                      setState(() => _period = ReportPeriod.week);
                      _load();
                    },
                  ),
                  const SizedBox(width: 8),
                  _PeriodChip(
                    label: 'Ce mois',
                    selected: _period == ReportPeriod.month,
                    onTap: () {
                      setState(() => _period = ReportPeriod.month);
                      _load();
                    },
                  ),
                  const SizedBox(width: 8),
                  _PeriodChip(
                    label: _period == ReportPeriod.custom
                        ? '${_dateFormat.format(_customStart)} - ${_dateFormat.format(_customEnd)}'
                        : 'Personnalisé',
                    selected: _period == ReportPeriod.custom,
                    icon: Icons.calendar_today_rounded,
                    onTap: _pickCustomRange,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (_loading)
              const Padding(
                padding: EdgeInsets.only(top: 60),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.5,
                children: [
                  _StatCard(
                    icon: Icons.payments_rounded,
                    label: 'Chiffre d\'affaires',
                    value: _currencyFormat.format(_summary['revenue']),
                    color: AppColors.navy,
                  ),
                  _StatCard(
                    icon: Icons.trending_up_rounded,
                    label: 'Bénéfice estimé',
                    value: _currencyFormat.format(_summary['profit']),
                    color: AppColors.success,
                  ),
                  _StatCard(
                    icon: Icons.receipt_long_rounded,
                    label: 'Nombre de ventes',
                    value: '${_summary['transactionCount']!.toInt()}',
                    color: AppColors.blue,
                  ),
                  _StatCard(
                    icon: Icons.shopping_basket_rounded,
                    label: 'Panier moyen',
                    value: _currencyFormat.format(_summary['averageBasket']),
                    color: AppColors.gold,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text('Produits les plus vendus',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              if (_topProducts.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text('Aucune vente sur cette période',
                        style: TextStyle(color: AppColors.textSecondary)),
                  ),
                )
              else
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: _topProducts.map((p) {
                        final maxQty = _topProducts
                            .map((e) => e['quantity'] as int)
                            .reduce((a, b) => a > b ? a : b);
                        final ratio = (p['quantity'] as int) / maxQty;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${p['name']}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13),
                                    ),
                                  ),
                                  Text(
                                    '${p['quantity']} vendus',
                                    style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: ratio,
                                  minHeight: 6,
                                  backgroundColor: const Color(0xFFEBEDF2),
                                  valueColor:
                                      const AlwaysStoppedAnimation(AppColors.gold),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              Text('Ventes par mode de paiement',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              if (_byPaymentMethod.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text('Aucune donnée',
                        style: TextStyle(color: AppColors.textSecondary)),
                  ),
                )
              else
                Card(
                  child: Column(
                    children: _byPaymentMethod.map((row) {
                      return ListTile(
                        leading: const Icon(Icons.payment_rounded,
                            color: AppColors.navy, size: 20),
                        title: Text(_paymentLabel(row['paymentMethod'])),
                        subtitle: Text('${row['cnt']} vente(s)'),
                        trailing: Text(
                          _currencyFormat.format(row['revenue']),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              const SizedBox(height: 20),
            ],
          ],
        ),
      ),
    );
  }
}

class _PeriodChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  const _PeriodChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: selected ? Colors.white : AppColors.navy),
            const SizedBox(width: 4),
          ],
          Text(label),
        ],
      ),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.navy,
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        color: selected ? Colors.white : AppColors.textPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: selected ? AppColors.navy : const Color(0xFFE3E6EC),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(9),
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: color, size: 16),
            ),
            const Spacer(),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: AppColors.textPrimary),
            ),
            Text(
              label,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
