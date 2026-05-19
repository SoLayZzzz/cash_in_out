import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../data/models/cash_entry.dart';
import 'home_controller.dart';

const _cashInColor = Color(0xFF16A34A);
const _cashOutColor = Color(0xFFDC2626);

class HomePage extends GetView<HomeController> {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMMM yyyy');
    final usdFormat = NumberFormat.currency(symbol: r'$', decimalDigits: 2);
    final khrFormat = NumberFormat.currency(symbol: '៛', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              'assets/logo/cash_logo.PNG',
              fit: BoxFit.cover,
            ),
          ),
        ),
        title: const Text('Cash In/Out'),
        actions: [
          IconButton(
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text('Clear all data?'),
                    content: const Text('This will delete all saved cash in/out records.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Clear'),
                      ),
                    ],
                  );
                },
              );

              if (ok == true) {
                await controller.clearAll();
              }
            },
            tooltip: 'Clear all',
            icon: const Icon(Icons.delete_sweep_outlined),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
      body: Obx(() {
        final month = controller.selectedMonth.value;
        final entries = controller.entriesForSelectedMonth;

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        dateFormat.format(month),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: () async {
                        final picked = await showModalBottomSheet<DateTime>(
                          context: context,
                          showDragHandle: true,
                          builder: (context) {
                            return SafeArea(
                              child: ListView(
                                children: controller.availableMonths.map((m) {
                                  final selected = m.year == month.year && m.month == month.month;
                                  return ListTile(
                                    title: Text(dateFormat.format(m)),
                                    trailing: selected ? const Icon(Icons.check) : null,
                                    onTap: () => Navigator.of(context).pop(m),
                                  );
                                }).toList(),
                              ),
                            );
                          },
                        );
                        if (picked != null) controller.setMonth(picked);
                      },
                      icon: const Icon(Icons.calendar_month_outlined),
                      label: const Text('Month'),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _SummaryCards(
                  cashInUsd: controller.cashInTotalUsd,
                  cashOutUsd: controller.cashOutTotalUsd,
                  netUsd: controller.netTotalUsd,
                  cashInKhr: controller.cashInTotalKhr,
                  cashOutKhr: controller.cashOutTotalKhr,
                  netKhr: controller.netTotalKhr,
                  usdFormat: usdFormat,
                  khrFormat: khrFormat,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'Transactions',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
            if (entries.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 120),
                  child: Text(
                    'No transactions for this month. Tap Add to start tracking.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                sliver: SliverList.separated(
                  itemCount: entries.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final e = entries[index];
                    final isIn = e.type == CashEntryType.cashIn;
                    final amountColor = isIn ? _cashInColor : _cashOutColor;

                    final usdText = e.amountUsd == 0 ? null : usdFormat.format(e.amountUsd);
                    final khrText = e.amountKhr == 0 ? null : khrFormat.format(e.amountKhr);

                    return Card(
                      elevation: 0,
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: amountColor.withValues(alpha: 0.12),
                          foregroundColor: amountColor,
                          child: Icon(isIn ? Icons.south_west : Icons.north_east),
                        ),
                        title: Text(
                          isIn ? 'Cash In' : 'Cash Out',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(color: amountColor),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (usdText != null)
                              Text(
                                usdText,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(color: amountColor, fontWeight: FontWeight.w700),
                              ),
                            if (khrText != null)
                              Text(
                                khrText,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(color: amountColor, fontWeight: FontWeight.w700),
                              ),
                            if (usdText == null && khrText == null)
                              Text(
                                usdFormat.format(0),
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(color: amountColor, fontWeight: FontWeight.w700),
                              ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(DateFormat('dd MMM, HH:mm').format(e.createdAt)),
                            if (!isIn && e.note.trim().isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text('Note: ${e.note}'),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      }),
    );
  }

  Future<void> _openAddSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return const _AddEntrySheet();
      },
    );
  }
}

class _AddEntrySheet extends StatefulWidget {
  const _AddEntrySheet();

  @override
  State<_AddEntrySheet> createState() => _AddEntrySheetState();
}

class _AddEntrySheetState extends State<_AddEntrySheet> {
  final _type = CashEntryType.cashIn.obs;
  final _amountUsdController = TextEditingController();
  final _amountKhrController = TextEditingController();
  final _noteController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _selectedDate = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  ).obs;

  void _showSavedSnack({
    required CashEntryType type,
    required double amountUsd,
    required double amountKhr,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final usdFormat = NumberFormat.currency(symbol: r'$', decimalDigits: 2);
    final khrFormat = NumberFormat.currency(symbol: '៛', decimalDigits: 0);
    final isIn = type == CashEntryType.cashIn;
    final accent = isIn ? _cashInColor : _cashOutColor;

    final parts = <String>[];
    if (amountUsd != 0) parts.add(usdFormat.format(amountUsd));
    if (amountKhr != 0) parts.add(khrFormat.format(amountKhr));
    if (parts.isEmpty) parts.add(usdFormat.format(0));

    Get.snackbar(
      'Saved',
      '${isIn ? 'Cash In' : 'Cash Out'}  ${parts.join('  |  ')}',
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(12),
      backgroundColor: scheme.surfaceContainerHighest,
      colorText: scheme.onSurface,
      borderRadius: 14,
      icon: Icon(isIn ? Icons.south_west : Icons.north_east, color: accent),
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void dispose() {
    _amountUsdController.dispose();
    _amountKhrController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final dateLabel = DateFormat('EEE, dd MMM yyyy');
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final sectionDecoration = BoxDecoration(
      color: scheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: scheme.outlineVariant),
    );

    InputDecoration fieldDecoration({
      required String label,
      required IconData icon,
      String? hint,
      String? prefixText,
    }) {
      return InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        prefixText: prefixText,
        filled: true,
        fillColor: scheme.surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      );
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottomPadding),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.swap_vert_rounded,
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add transaction',
                          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 2),
                        Obx(() {
                          final isOut = _type.value == CashEntryType.cashOut;
                          return Text(
                            isOut ? 'Cash Out (note required)' : 'Cash In',
                            style: textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  IconButton.filledTonal(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                decoration: sectionDecoration,
                padding: const EdgeInsets.all(10),
                child: Obx(() {
                  final isIn = _type.value == CashEntryType.cashIn;
                  final selectedColor = isIn ? _cashInColor : _cashOutColor;
                  return SegmentedButton<CashEntryType>(
                    segments: const [
                      ButtonSegment(
                        value: CashEntryType.cashIn,
                        label: Text('Cash In'),
                        icon: Icon(Icons.south_west),
                      ),
                      ButtonSegment(
                        value: CashEntryType.cashOut,
                        label: Text('Cash Out'),
                        icon: Icon(Icons.north_east),
                      ),
                    ],
                    selected: {_type.value},
                    onSelectionChanged: (s) => _type.value = s.first,
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.selected)) {
                          return selectedColor.withValues(alpha: 0.14);
                        }
                        return scheme.surfaceContainerLow;
                      }),
                      foregroundColor: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.selected)) {
                          return selectedColor;
                        }
                        return scheme.onSurfaceVariant;
                      }),
                      overlayColor: WidgetStateProperty.all(
                        selectedColor.withValues(alpha: 0.08),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: sectionDecoration,
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _amountUsdController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        textInputAction: TextInputAction.next,
                        style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                        decoration: fieldDecoration(
                          label: 'USD',
                          hint: '0',
                          icon: Icons.attach_money,
                          prefixText: r'$ ',
                        ),
                        validator: (v) {
                          final raw = (v ?? '').trim();
                          if (raw.isEmpty) return null;
                          final amount = double.tryParse(raw);
                          if (amount == null || amount < 0) return 'Invalid';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _amountKhrController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: false),
                        textInputAction: TextInputAction.next,
                        style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                        decoration: fieldDecoration(
                          label: 'Riel',
                          hint: '0',
                          icon: Icons.payments_outlined,
                          prefixText: '៛ ',
                        ),
                        validator: (v) {
                          final raw = (v ?? '').trim();
                          if (raw.isEmpty) return null;
                          final amount = double.tryParse(raw);
                          if (amount == null || amount < 0) return 'Invalid';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Obx(() {
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () async {
                      final current = _selectedDate.value;
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: current,
                        firstDate: DateTime(DateTime.now().year - 5, 1, 1),
                        lastDate: DateTime(DateTime.now().year + 5, 12, 31),
                      );
                      if (picked == null) return;
                      _selectedDate.value = DateTime(picked.year, picked.month, picked.day);
                    },
                    child: Container(
                      decoration: sectionDecoration,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      child: ListTile(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        leading: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.event_outlined),
                        ),
                        title: const Text('Date'),
                        subtitle: Text(dateLabel.format(_selectedDate.value)),
                        trailing: const Icon(Icons.chevron_right),
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 12),
              Obx(() {
                final isOut = _type.value == CashEntryType.cashOut;
                return Container(
                  decoration: sectionDecoration,
                  padding: const EdgeInsets.all(12),
                  child: TextFormField(
                    controller: _noteController,
                    decoration: fieldDecoration(
                      label: 'Note${isOut ? ' (required)' : ' (optional)'}',
                      hint: isOut ? 'What did you pay for?' : 'Optional details',
                      icon: Icons.sticky_note_2_outlined,
                    ),
                    validator: (v) {
                      if (!isOut) return null;
                      if ((v ?? '').trim().isEmpty) return 'Please add a note for Cash Out';
                      return null;
                    },
                    maxLines: 2,
                    textInputAction: TextInputAction.done,
                  ),
                );
              }),
              const SizedBox(height: 14),
              Container(
                decoration: sectionDecoration,
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          shape: const StadiumBorder(),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () async {
                          final ok = _formKey.currentState?.validate() ?? false;
                          if (!ok) return;

                          final usdRaw = _amountUsdController.text.trim();
                          final khrRaw = _amountKhrController.text.trim();
                          final amountUsd = usdRaw.isEmpty ? 0.0 : (double.tryParse(usdRaw) ?? double.nan);
                          final amountKhr = khrRaw.isEmpty ? 0.0 : (double.tryParse(khrRaw) ?? double.nan);

                          if (amountUsd.isNaN || amountKhr.isNaN) {
                            Get.snackbar(
                              'Invalid amount',
                              'Please enter a valid number for USD or Riel.',
                              snackPosition: SnackPosition.BOTTOM,
                              margin: const EdgeInsets.all(12),
                            );
                            return;
                          }

                          if (amountUsd <= 0 && amountKhr <= 0) {
                            Get.snackbar(
                              'Amount required',
                              'Enter USD or Riel amount.',
                              snackPosition: SnackPosition.BOTTOM,
                              margin: const EdgeInsets.all(12),
                            );
                            return;
                          }

                          final note = _noteController.text.trim();
                          final type = _type.value;
                          final now = DateTime.now();
                          final d = _selectedDate.value;
                          final createdAt = DateTime(
                            d.year,
                            d.month,
                            d.day,
                            now.hour,
                            now.minute,
                            now.second,
                            now.millisecond,
                            now.microsecond,
                          );

                          await Get.find<HomeController>().addEntry(
                            type: type,
                            amountUsd: amountUsd,
                            amountKhr: amountKhr,
                            note: note,
                            createdAt: createdAt,
                          );

                          Get.back();
                          _showSavedSnack(
                            type: type,
                            amountUsd: amountUsd,
                            amountKhr: amountKhr,
                          );
                        },
                        icon: const Icon(Icons.save_outlined),
                        label: const Text('Save'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryCards extends StatelessWidget {
  const _SummaryCards({
    required this.cashInUsd,
    required this.cashOutUsd,
    required this.netUsd,
    required this.cashInKhr,
    required this.cashOutKhr,
    required this.netKhr,
    required this.usdFormat,
    required this.khrFormat,
  });

  final double cashInUsd;
  final double cashOutUsd;
  final double netUsd;
  final double cashInKhr;
  final double cashOutKhr;
  final double netKhr;
  final NumberFormat usdFormat;
  final NumberFormat khrFormat;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                title: 'Cash In',
                value: khrFormat.format(cashInKhr),
                secondaryValue: usdFormat.format(cashInUsd),
                icon: Icons.south_west,
                color: _cashInColor,
                valueColor: _cashInColor,
                secondaryValueColor: _cashInColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                title: 'Cash Out',
                value: khrFormat.format(cashOutKhr),
                secondaryValue: usdFormat.format(cashOutUsd),
                icon: Icons.north_east,
                color: _cashOutColor,
                valueColor: _cashOutColor,
                secondaryValueColor: _cashOutColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _MetricCard(
          title: 'Net',
          value: khrFormat.format(netKhr),
          secondaryValue: usdFormat.format(netUsd),
          icon: Icons.account_balance_wallet_outlined,
          color: (netUsd < 0 || netKhr < 0) ? _cashOutColor : _cashInColor,
          valueColor: netKhr < 0 ? _cashOutColor : _cashInColor,
          secondaryValueColor: netUsd < 0 ? _cashOutColor : _cashInColor,
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    this.secondaryValue,
    required this.icon,
    required this.color,
    this.valueColor,
    this.secondaryValueColor,
  });

  final String title;
  final String value;
  final String? secondaryValue;
  final IconData icon;
  final Color color;
  final Color? valueColor;
  final Color? secondaryValueColor;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.12),
              foregroundColor: color,
              child: Icon(icon),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: valueColor,
                        ),
                  ),
                  if (secondaryValue != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      secondaryValue!,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: secondaryValueColor ?? valueColor,
                          ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
