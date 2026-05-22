import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:io' show Platform;
import 'package:share_plus/share_plus.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import '../../data/models/cash_entry.dart';
import 'home_controller.dart';
import '../settings/settings_page.dart';

const _cashInColor = Color(0xFF16A34A);
const _cashOutColor = Color(0xFFDC2626);

class HomePage extends GetView<HomeController> {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final appLocale = Get.locale;
    final dateFormat = DateFormat('MMMM yyyy', appLocale?.toLanguageTag());
    final txnDateFormat = DateFormat(
      'dd MMM, HH:mm',
      appLocale?.toLanguageTag(),
    );
    final usdFormat = NumberFormat.currency(symbol: r'$', decimalDigits: 2);
    final khrFormat = NumberFormat.currency(symbol: '៛', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: Text('app.title'.tr),
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            tooltip: 'download'.tr,
            onPressed: () async {
              if (Get.isBottomSheetOpen == true || Get.isDialogOpen == true) {
                Get.back();
                await Future.delayed(const Duration(milliseconds: 5));
              }
              final choice = await showModalBottomSheet<String>(
                context: context,
                showDragHandle: true,
                useRootNavigator: true,
                builder: (context) {
                  final m = controller.selectedMonth.value;
                  final mLabel = DateFormat(
                    'MMMM yyyy',
                    Get.locale?.toLanguageTag(),
                  ).format(m);
                  return SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          leading: const Icon(Icons.file_download_outlined),
                          title: Text('download_current_month_pdf'.tr),
                          subtitle: Text(mLabel),
                          onTap: () => Navigator.of(context).pop('month'),
                        ),
                        ListTile(
                          leading: const Icon(Icons.calendar_month_outlined),
                          title: Text('download_choose_month_pdf'.tr),
                          onTap: () => Navigator.of(context).pop('choose'),
                        ),
                        ListTile(
                          leading: const Icon(Icons.archive_outlined),
                          title: Text('download_all_data_pdf'.tr),
                          onTap: () => Navigator.of(context).pop('all'),
                        ),
                      ],
                    ),
                  );
                },
              );

              if (choice == 'month') {
                await _exportPdf();
              } else if (choice == 'all') {
                await _exportPdf(allMonths: true);
              } else if (choice == 'choose') {
                final picked = await showModalBottomSheet<DateTime>(
                  context: context,
                  showDragHandle: true,
                  useRootNavigator: true,
                  builder: (context) {
                    final loc = Get.locale?.toLanguageTag();
                    final fmt = DateFormat('MMMM yyyy', loc);
                    final current = controller.selectedMonth.value;
                    return SafeArea(
                      child: ListView(
                        children: controller.availableMonths.map((m) {
                          final selected =
                              m.year == current.year &&
                              m.month == current.month;
                          return ListTile(
                            title: Text(fmt.format(m)),
                            trailing: selected ? const Icon(Icons.check) : null,
                            onTap: () => Navigator.of(context).pop(m),
                          );
                        }).toList(),
                      ),
                    );
                  },
                );
                if (picked != null) {
                  await _exportPdf(month: picked);
                }
              }
            },
            icon: const Icon(Icons.download_outlined),
          ),
          IconButton(
            tooltip: 'settings'.tr,
            onPressed: () async {
              if (Get.isBottomSheetOpen == true || Get.isDialogOpen == true) {
                Get.back();
                await Future.delayed(const Duration(milliseconds: 5));
              }
              await Get.to(() => const SettingsPage());
            },
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          if (Get.isBottomSheetOpen == true || Get.isDialogOpen == true) {
            Get.back();
            await Future.delayed(const Duration(milliseconds: 50));
          }

          await _openAddSheet(context);
        },
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.white
            : Colors.black,
        foregroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.black
            : Colors.white,
        elevation: 8,
        extendedPadding: const EdgeInsets.symmetric(
          horizontal: 22,
          vertical: 14,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        icon: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color:
                (Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black)
                    .withValues(
                      alpha: Theme.of(context).brightness == Brightness.dark
                          ? 0.15
                          : 0.08,
                    ),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.add_rounded, size: 22),
        ),
        label: Text(
          'add'.tr,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),
      body: Obx(() {
        final month = controller.selectedMonth.value;
        final entries = controller.entriesForSelectedMonth;

        return Column(
          children: [
            Padding(
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
                    style: FilledButton.styleFrom(
                      backgroundColor:
                          Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black,
                      foregroundColor:
                          Theme.of(context).brightness == Brightness.dark
                          ? Colors.black
                          : Colors.white,
                    ),
                    onPressed: () async {
                      final picked = await showModalBottomSheet<DateTime>(
                        context: context,
                        showDragHandle: true,
                        useRootNavigator: true,
                        builder: (context) {
                          return SafeArea(
                            child: ListView(
                              children: controller.availableMonths.map((m) {
                                final selected =
                                    m.year == month.year &&
                                    m.month == month.month;
                                return ListTile(
                                  title: Text(dateFormat.format(m)),
                                  trailing: selected
                                      ? const Icon(Icons.check)
                                      : null,
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
                    label: Text('month'.tr),
                  ),
                ],
              ),
            ),
            Padding(
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
                onCashInTap: () =>
                    _openAddSheet(context, initialType: CashEntryType.cashIn),
                onCashOutTap: () =>
                    _openAddSheet(context, initialType: CashEntryType.cashOut),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'transactions'.tr,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
            Expanded(
              child: entries.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: Text(
                          'no_transactions'.tr,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                      itemCount: entries.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final e = entries[index];
                        final isIn = e.type == CashEntryType.cashIn;
                        final amountColor = isIn ? _cashInColor : _cashOutColor;

                        Future<bool> confirmDelete() async {
                          return await showDialog<bool>(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    icon: Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: Colors.red.withValues(
                                          alpha: 0.12,
                                        ),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      alignment: Alignment.center,
                                      child: const Icon(
                                        Icons.delete_outline,
                                        color: Colors.red,
                                      ),
                                    ),
                                    title: Text(
                                      'delete_entry_q'.tr,
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                    content: Text(
                                      'delete_entry_desc'.tr,
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                          ),
                                    ),
                                    actionsAlignment: MainAxisAlignment.center,
                                    actionsPadding: const EdgeInsets.fromLTRB(
                                      16,
                                      0,
                                      16,
                                      14,
                                    ),
                                    actions: [
                                      OutlinedButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(false),
                                        child: Text('cancel'.tr),
                                      ),
                                      const SizedBox(width: 10),
                                      FilledButton(
                                        style: FilledButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          foregroundColor: Colors.white,
                                        ),
                                        onPressed: () =>
                                            Navigator.of(context).pop(true),
                                        child: Text('delete'.tr),
                                      ),
                                    ],
                                  );
                                },
                              ) ??
                              false;
                        }

                        final usdText = e.amountUsd == 0
                            ? null
                            : usdFormat.format(e.amountUsd);
                        final khrText = e.amountKhr == 0
                            ? null
                            : khrFormat.format(e.amountKhr);

                        return Dismissible(
                          key: ValueKey(e.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
                          ),
                          confirmDismiss: (dir) async {
                            return await confirmDelete();
                          },
                          onDismissed: (_) async {
                            await Get.find<HomeController>().deleteEntry(e.id);
                            Get.snackbar(
                              'deleted'.tr,
                              'deleted_desc'.tr,
                              snackPosition: SnackPosition.BOTTOM,
                            );
                          },
                          child: Card(
                            elevation: 0,
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: Theme.of(context)
                                    .colorScheme
                                    .outlineVariant
                                    .withValues(alpha: 0.55),
                              ),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Ink(
                              child: InkWell(
                                onTap: () async {
                                  await _openAddSheet(context, existing: e);
                                },
                                child: IntrinsicHeight(
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Container(
                                        width: 5,
                                        decoration: BoxDecoration(
                                          color: amountColor,
                                          borderRadius: const BorderRadius.only(
                                            topLeft: Radius.circular(16),
                                            bottomLeft: Radius.circular(16),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                            12,
                                            12,
                                            12,
                                            12,
                                          ),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Container(
                                                width: 40,
                                                height: 40,
                                                decoration: BoxDecoration(
                                                  color: amountColor.withValues(
                                                    alpha: 0.12,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                alignment: Alignment.center,
                                                child: Icon(
                                                  isIn
                                                      ? Icons.south_west
                                                      : Icons.north_east,
                                                  color: amountColor,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      isIn
                                                          ? 'cash_in'.tr
                                                          : 'cash_out'.tr,
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .titleMedium
                                                          ?.copyWith(
                                                            color: amountColor,
                                                            fontWeight:
                                                                FontWeight.w800,
                                                          ),
                                                    ),
                                                    const SizedBox(height: 6),
                                                    Row(
                                                      children: [
                                                        Icon(
                                                          Icons.schedule,
                                                          size: 16,
                                                          color: Theme.of(context)
                                                              .colorScheme
                                                              .onSurfaceVariant,
                                                        ),
                                                        const SizedBox(
                                                          width: 6,
                                                        ),
                                                        Expanded(
                                                          child: Text(
                                                            txnDateFormat
                                                                .format(
                                                                  e.createdAt,
                                                                ),
                                                            style: Theme.of(context)
                                                                .textTheme
                                                                .bodySmall
                                                                ?.copyWith(
                                                                  color: Theme.of(
                                                                    context,
                                                                  ).colorScheme.onSurfaceVariant,
                                                                ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    if (!isIn &&
                                                        e.note
                                                            .trim()
                                                            .isNotEmpty) ...[
                                                      const SizedBox(height: 6),
                                                      Text(
                                                        '${'note'.tr}: ${e.note}',
                                                        maxLines: 2,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: Theme.of(
                                                          context,
                                                        ).textTheme.bodySmall,
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.end,
                                                children: [
                                                  Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      IconButton(
                                                        tooltip: 'edit'.tr,
                                                        visualDensity:
                                                            VisualDensity
                                                                .compact,
                                                        constraints:
                                                            const BoxConstraints.tightFor(
                                                              width: 36,
                                                              height: 36,
                                                            ),
                                                        padding:
                                                            EdgeInsets.zero,
                                                        style: IconButton.styleFrom(
                                                          backgroundColor:
                                                              Theme.of(context)
                                                                  .colorScheme
                                                                  .surface
                                                                  .withValues(
                                                                    alpha: 0.55,
                                                                  ),
                                                          foregroundColor:
                                                              Theme.of(context)
                                                                  .colorScheme
                                                                  .onSurface,
                                                        ),
                                                        onPressed: () async {
                                                          await _openAddSheet(
                                                            context,
                                                            existing: e,
                                                          );
                                                        },
                                                        icon: const Icon(
                                                          Icons.edit_outlined,
                                                          size: 18,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 6),
                                                      IconButton(
                                                        tooltip: 'delete'.tr,
                                                        visualDensity:
                                                            VisualDensity
                                                                .compact,
                                                        constraints:
                                                            const BoxConstraints.tightFor(
                                                              width: 36,
                                                              height: 36,
                                                            ),
                                                        padding:
                                                            EdgeInsets.zero,
                                                        style: IconButton.styleFrom(
                                                          backgroundColor:
                                                              Colors.red
                                                                  .withValues(
                                                                    alpha: 0.10,
                                                                  ),
                                                          foregroundColor:
                                                              Colors.red,
                                                        ),
                                                        onPressed: () async {
                                                          final ok =
                                                              await confirmDelete();
                                                          if (!ok) return;
                                                          await Get.find<
                                                                HomeController
                                                              >()
                                                              .deleteEntry(
                                                                e.id,
                                                              );
                                                          Get.snackbar(
                                                            'deleted'.tr,
                                                            'deleted_desc'.tr,
                                                            snackPosition:
                                                                SnackPosition
                                                                    .BOTTOM,
                                                          );
                                                        },
                                                        icon: const Icon(
                                                          Icons.delete_outline,
                                                          size: 18,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 8),
                                                  if (usdText != null)
                                                    Text(
                                                      usdText,
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .titleSmall
                                                          ?.copyWith(
                                                            color: amountColor,
                                                            fontWeight:
                                                                FontWeight.w900,
                                                          ),
                                                    ),
                                                  if (khrText != null)
                                                    Text(
                                                      khrText,
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .titleSmall
                                                          ?.copyWith(
                                                            color: amountColor,
                                                            fontWeight:
                                                                FontWeight.w900,
                                                          ),
                                                    ),
                                                  if (usdText == null &&
                                                      khrText == null)
                                                    Text(
                                                      usdFormat.format(0),
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .titleSmall
                                                          ?.copyWith(
                                                            color: amountColor,
                                                            fontWeight:
                                                                FontWeight.w900,
                                                          ),
                                                    ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
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

  Future<({Uint8List bytes, double width, double height})> _renderPdfText(
    String text, {
    double fontSize = 10,
    FontWeight fontWeight = FontWeight.normal,
    Color color = Colors.black,
    double maxWidth = 160,
    TextAlign textAlign = TextAlign.left,
  }) async {
    const padding = 2.0;
    const scale = 3.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.scale(scale);
    final painter = TextPainter(
      text: TextSpan(
        text: text.isEmpty ? ' ' : text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
          height: 1.25,
          fontFamilyFallback: const [
            'Noto Sans Khmer',
            'Khmer OS',
            'Arial Unicode MS',
          ],
        ),
      ),
      textAlign: textAlign,
      textDirection: ui.TextDirection.ltr,
    );

    painter.layout(maxWidth: maxWidth);
    final width = (painter.width + padding * 2).ceil().clamp(
      1,
      (maxWidth + padding * 2).ceil(),
    );
    final height = (painter.height + padding * 2).ceil().clamp(1, 10000);
    painter.paint(canvas, const Offset(padding, padding));

    final picture = recorder.endRecording();
    final image = await picture.toImage(
      (width * scale).ceil(),
      (height * scale).ceil(),
    );
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    picture.dispose();

    return (
      bytes: byteData!.buffer.asUint8List(),
      width: width.toDouble(),
      height: height.toDouble(),
    );
  }

  Future<void> _exportPdf({DateTime? month, bool allMonths = false}) async {
    final appLocale = Get.locale;
    final ym = DateFormat('MMMM yyyy', appLocale?.toLanguageTag());
    final dateLabel = DateFormat(
      'dd MMM yyyy, HH:mm',
      appLocale?.toLanguageTag(),
    );
    final localeTag = appLocale?.toLanguageTag();
    final moneyUsd = NumberFormat('#,##0.00', localeTag);
    final moneyKhr = NumberFormat('#,##0', localeTag);
    final ctrl = Get.find<HomeController>();

    // Collect rows
    List<CashEntry> rows;
    if (allMonths) {
      rows = ctrl.entries.toList();
    } else {
      final m = month ?? ctrl.selectedMonth.value;
      final start = DateTime(m.year, m.month);
      final end = DateTime(m.year, m.month + 1);
      rows = ctrl.entries
          .where(
            (e) => !e.createdAt.isBefore(start) && e.createdAt.isBefore(end),
          )
          .toList();
    }
    rows.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // Build PDF
    final doc = pw.Document();
    final heading = allMonths
        ? 'all_data'.tr
        : ym.format(month ?? ctrl.selectedMonth.value);
    final cellWidths = [70.0, 60.0, 60.0, 70.0, 70.0, 125.0, 65.0];

    final tableHeaders = [
      'type'.tr,
      'usd'.tr,
      'khr'.tr,
      'net_usd'.tr,
      'net_khr'.tr,
      'date'.tr,
      'note'.tr,
    ];

    final tableData = <List<String>>[];
    for (final e in rows) {
      final sign = e.isCashIn ? 1 : -1;
      tableData.add([
        e.isCashIn ? 'cash_in'.tr : 'cash_out'.tr,
        moneyUsd.format(e.amountUsd),
        moneyKhr.format(e.amountKhr),
        moneyUsd.format(e.amountUsd * sign),
        moneyKhr.format(e.amountKhr * sign),
        dateLabel.format(e.createdAt),
        e.note,
      ]);
    }

    final titleImage = await _renderPdfText(
      'app.title'.tr,
      fontSize: 18,
      fontWeight: FontWeight.bold,
      maxWidth: 520,
    );
    final headingImage = await _renderPdfText(
      heading,
      fontSize: 12,
      color: Colors.grey.shade700,
      maxWidth: 520,
    );
    final headerImages = <({Uint8List bytes, double width, double height})>[];
    for (var i = 0; i < tableHeaders.length; i++) {
      headerImages.add(
        await _renderPdfText(
          tableHeaders[i],
          fontSize: 10,
          fontWeight: FontWeight.bold,
          maxWidth: cellWidths[i],
          textAlign: TextAlign.center,
        ),
      );
    }
    final rowImages =
        <List<({Uint8List bytes, double width, double height})>>[];
    for (final row in tableData) {
      final imageRow = <({Uint8List bytes, double width, double height})>[];
      for (var i = 0; i < row.length; i++) {
        imageRow.add(await _renderPdfText(row[i], maxWidth: cellWidths[i]));
      }
      rowImages.add(imageRow);
    }

    doc.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(margin: const pw.EdgeInsets.all(24)),
        build: (context) => [
          pw.Image(
            pw.MemoryImage(titleImage.bytes),
            width: titleImage.width,
            height: titleImage.height,
          ),
          pw.SizedBox(height: 4),
          pw.Image(
            pw.MemoryImage(headingImage.bytes),
            width: headingImage.width,
            height: headingImage.height,
          ),
          pw.SizedBox(height: 12),
          pw.Table(
            columnWidths: {
              for (var i = 0; i < cellWidths.length; i++)
                i: pw.FixedColumnWidth(cellWidths[i]),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                children: headerImages
                    .map(
                      (image) => pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(
                          vertical: 6,
                          horizontal: 6,
                        ),
                        child: pw.Center(
                          child: pw.Image(
                            pw.MemoryImage(image.bytes),
                            width: image.width,
                            height: image.height,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              for (final row in rowImages)
                pw.TableRow(
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                      bottom: pw.BorderSide(
                        color: PdfColors.grey300,
                        width: .5,
                      ),
                    ),
                  ),
                  children: [
                    for (final image in row)
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(
                          vertical: 6,
                          horizontal: 6,
                        ),
                        child: pw.Image(
                          pw.MemoryImage(image.bytes),
                          width: image.width,
                          height: image.height,
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );

    final bytes = await doc.save();

    // Filename cash_ddMMyyyy.pdf
    DateTime stamp = allMonths
        ? DateTime.now()
        : (month ?? ctrl.selectedMonth.value);
    final ddmmyyyy = DateFormat(
      'ddMMyyyy',
      appLocale?.toLanguageTag(),
    ).format(stamp);
    final name = 'cash_$ddmmyyyy.pdf';

    if (Platform.isAndroid || Platform.isIOS) {
      final xFile = XFile.fromData(
        bytes,
        name: name,
        mimeType: 'application/pdf',
      );
      await Share.shareXFiles([xFile]);
    } else {
      Get.snackbar(
        'download'.tr,
        'export_mobile_only'.tr,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(12),
      );
    }
  }

  // Future<void> _exportPdf({DateTime? month, bool allMonths = false}) async {
  //   final appLocale = Get.locale;
  //   final ym = DateFormat('MMMM yyyy', appLocale?.toLanguageTag());
  //   final dateLabel = DateFormat('dd MMM yyyy, HH:mm', appLocale?.toLanguageTag());
  //   final localeTag = appLocale?.toLanguageTag();
  //   final moneyUsd = NumberFormat('#,##0.00', localeTag);
  //   final moneyKhr = NumberFormat('#,##0', localeTag);
  //   final ctrl = Get.find<HomeController>();

  //   // Collect rows
  //   List<CashEntry> rows;
  //   if (allMonths) {
  //     rows = ctrl.entries.toList();
  //   } else {
  //     final m = month ?? ctrl.selectedMonth.value;
  //     final start = DateTime(m.year, m.month);
  //     final end = DateTime(m.year, m.month + 1);
  //     rows = ctrl.entries
  //         .where((e) => !e.createdAt.isBefore(start) && e.createdAt.isBefore(end))
  //         .toList();
  //   }
  //   rows.sort((a, b) => b.createdAt.compareTo(a.createdAt));

  //   // Build PDF
  //   final doc = pw.Document();
  //   final heading = allMonths ? 'all_data'.tr : ym.format(month ?? ctrl.selectedMonth.value);

  //   // Load Khmer-capable fonts
  //   final fontBase = await printing.PdfGoogleFonts.notoSansKhmerRegular();
  //   final fontBold = await printing.PdfGoogleFonts.notoSansKhmerBold();

  //   final tableData = <List<String>>[];
  //   for (final e in rows) {
  //     tableData.add([
  //       e.isCashIn ? 'cash_in'.tr : 'cash_out'.tr,
  //       moneyUsd.format(e.amountUsd),
  //       moneyKhr.format(e.amountKhr),
  //       dateLabel.format(e.createdAt),
  //       e.note,
  //     ]);
  //   }

  //   doc.addPage(
  //     pw.MultiPage(
  //       pageTheme: pw.PageTheme(
  //         margin: const pw.EdgeInsets.all(24),
  //         theme: pw.ThemeData.withFont(
  //           base: fontBase,
  //           bold: fontBold,
  //         ),
  //       ),
  //       build: (context) => [
  //         pw.Text('app.title'.tr, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
  //         pw.SizedBox(height: 4),
  //         pw.Text(heading, style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
  //         pw.SizedBox(height: 12),
  //         pw.TableHelper.fromTextArray(
  //           headers: [
  //             'type'.tr,
  //             'usd'.tr,
  //             'khr'.tr,
  //             'date'.tr,
  //             'note'.tr,
  //           ],
  //           data: tableData,
  //           headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
  //           headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
  //           cellAlignment: pw.Alignment.centerLeft,
  //           cellStyle: const pw.TextStyle(fontSize: 10),
  //           cellPadding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 6),
  //           border: null,
  //           rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: .5))),
  //         ),
  //       ],
  //     ),
  //   );

  //   final bytes = await doc.save();

  //   // Filename cash_ddMMyyyy.pdf (use selected month first day; for All, current date)
  //   DateTime stamp;
  //   if (allMonths) {
  //     stamp = DateTime.now();
  //   } else {
  //     final m = month ?? ctrl.selectedMonth.value;
  //     stamp = DateTime(m.year, m.month, 1);
  //   }
  //   final ddmmyyyy = DateFormat('ddMMyyyy', appLocale?.toLanguageTag()).format(stamp);
  //   final name = 'cash_$ddmmyyyy.pdf';

  //   if (Platform.isAndroid || Platform.isIOS) {
  //     final xFile = XFile.fromData(bytes, name: name, mimeType: 'application/pdf');
  //     await Share.shareXFiles([xFile]);
  //   } else {
  //     Get.snackbar(
  //       'download'.tr,
  //       'export_mobile_only'.tr,
  //       snackPosition: SnackPosition.BOTTOM,
  //       margin: const EdgeInsets.all(12),
  //     );
  //   }
  // }

  Future<void> _openAddSheet(
    BuildContext context, {
    CashEntryType initialType = CashEntryType.cashIn,
    CashEntry? existing,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return _AddEntrySheet(initialType: initialType, existing: existing);
      },
    );
  }
}

class _AddEntrySheet extends StatefulWidget {
  const _AddEntrySheet({required this.initialType, this.existing});

  final CashEntryType initialType;
  final CashEntry? existing;

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

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _type.value = e?.type ?? widget.initialType;
    if (e != null) {
      if (e.amountUsd != 0) {
        _amountUsdController.text = e.amountUsd.toStringAsFixed(2);
      }
      if (e.amountKhr != 0) {
        _amountKhrController.text = e.amountKhr.toStringAsFixed(0);
      }
      _noteController.text = e.note;
      _selectedDate.value = DateTime(
        e.createdAt.year,
        e.createdAt.month,
        e.createdAt.day,
      );
    }
  }

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
    final appLocale = Get.locale;
    final dateLabel = DateFormat(
      'EEE, dd MMM yyyy',
      appLocale?.toLanguageTag(),
    );
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
                          'new_txn'.tr,
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Obx(() {
                          final isOut = _type.value == CashEntryType.cashOut;
                          return Text(
                            isOut
                                ? '${'cash_out'.tr} (${'note_required'.tr})'
                                : 'cash_in'.tr,
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
                    segments: [
                      ButtonSegment(
                        value: CashEntryType.cashIn,
                        label: Text('cash_in'.tr),
                        icon: Icon(Icons.south_west),
                      ),
                      ButtonSegment(
                        value: CashEntryType.cashOut,
                        label: Text('cash_out'.tr),
                        icon: Icon(Icons.north_east),
                      ),
                    ],
                    selected: {_type.value},
                    onSelectionChanged: (s) => _type.value = s.first,
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.resolveWith((
                        states,
                      ) {
                        if (states.contains(WidgetState.selected)) {
                          return selectedColor.withValues(alpha: 0.14);
                        }
                        return scheme.surfaceContainerLow;
                      }),
                      foregroundColor: WidgetStateProperty.resolveWith((
                        states,
                      ) {
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
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        textInputAction: TextInputAction.next,
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                        decoration: fieldDecoration(
                          label: 'usd'.tr,
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
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: false,
                        ),
                        textInputAction: TextInputAction.next,
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                        decoration: fieldDecoration(
                          label: 'khr'.tr,
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
                        locale: appLocale,
                      );
                      if (picked == null) return;
                      _selectedDate.value = DateTime(
                        picked.year,
                        picked.month,
                        picked.day,
                      );
                    },
                    child: Container(
                      decoration: sectionDecoration,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      child: ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        leading: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.event_outlined),
                        ),
                        title: Text('date'.tr),
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
                      label: isOut ? 'note_required'.tr : 'note_optional'.tr,
                      hint: isOut ? 'note_required'.tr : 'note_optional'.tr,
                      icon: Icons.sticky_note_2_outlined,
                    ),
                    validator: (v) {
                      if (!isOut) return null;
                      if ((v ?? '').trim().isEmpty)
                        return 'Please add a note for Cash Out';
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
                        child: Text('cancel'.tr),
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
                          final amountUsd = usdRaw.isEmpty
                              ? 0.0
                              : (double.tryParse(usdRaw) ?? double.nan);
                          final amountKhr = khrRaw.isEmpty
                              ? 0.0
                              : (double.tryParse(khrRaw) ?? double.nan);

                          if (amountUsd.isNaN || amountKhr.isNaN) {
                            Get.snackbar(
                              'invalid_amount'.tr,
                              'invalid_amount_desc'.tr,
                              snackPosition: SnackPosition.BOTTOM,
                              margin: const EdgeInsets.all(12),
                            );
                            return;
                          }

                          if (amountUsd <= 0 && amountKhr <= 0) {
                            Get.snackbar(
                              'amount_required'.tr,
                              'amount_required_desc'.tr,
                              snackPosition: SnackPosition.BOTTOM,
                              margin: const EdgeInsets.all(12),
                            );
                            return;
                          }

                          final note = _noteController.text.trim();
                          final type = _type.value;
                          final now = DateTime.now();
                          final d = _selectedDate.value;
                          final base = widget.existing?.createdAt ?? now;
                          final createdAt = DateTime(
                            d.year,
                            d.month,
                            d.day,
                            base.hour,
                            base.minute,
                            base.second,
                            base.millisecond,
                            base.microsecond,
                          );

                          if (widget.existing == null) {
                            await Get.find<HomeController>().addEntry(
                              type: type,
                              amountUsd: amountUsd,
                              amountKhr: amountKhr,
                              note: note,
                              createdAt: createdAt,
                            );
                          } else {
                            await Get.find<HomeController>().updateEntry(
                              id: widget.existing!.id,
                              type: type,
                              amountUsd: amountUsd,
                              amountKhr: amountKhr,
                              note: note,
                              createdAt: createdAt,
                            );
                          }

                          Get.back();
                          _showSavedSnack(
                            type: type,
                            amountUsd: amountUsd,
                            amountKhr: amountKhr,
                          );
                        },
                        icon: const Icon(Icons.save_outlined),
                        label: Text('save'.tr),
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
    required this.onCashInTap,
    required this.onCashOutTap,
  });

  final double cashInUsd;
  final double cashOutUsd;
  final double netUsd;
  final double cashInKhr;
  final double cashOutKhr;
  final double netKhr;
  final NumberFormat usdFormat;
  final NumberFormat khrFormat;
  final VoidCallback onCashInTap;
  final VoidCallback onCashOutTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                title: 'cash_in'.tr,
                value: khrFormat.format(cashInKhr),
                secondaryValue: usdFormat.format(cashInUsd),
                icon: Icons.south_west,
                color: _cashInColor,
                valueColor: _cashInColor,
                secondaryValueColor: _cashInColor,
                onTap: onCashInTap,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                title: 'cash_out'.tr,
                value: khrFormat.format(cashOutKhr),
                secondaryValue: usdFormat.format(cashOutUsd),
                icon: Icons.north_east,
                color: _cashOutColor,
                valueColor: _cashOutColor,
                secondaryValueColor: _cashOutColor,
                onTap: onCashOutTap,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _MetricCard(
          title: 'net'.tr,
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
    this.onTap,
  });

  final String title;
  final String value;
  final String? secondaryValue;
  final IconData icon;
  final Color color;
  final Color? valueColor;
  final Color? secondaryValueColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = Card(
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
                  Text(title, style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
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

    if (onTap == null) return card;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: card,
    );
  }
}
