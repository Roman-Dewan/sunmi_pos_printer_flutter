import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:esc_pos_printer/esc_pos_printer.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';

class ExternalPrinterService {
  static NetworkPrinter? _printer;

  // ---------------------------------------------------------------------------
  // Connection
  // ---------------------------------------------------------------------------

  static Future<bool> connectPrinter(String ipAddress) async {
    try {
      final profile = await CapabilityProfile.load();
      final printer = NetworkPrinter(PaperSize.mm80, profile);
      final PosPrintResult res = await printer.connect(ipAddress, port: 9100);

      if (res == PosPrintResult.success) {
        _printer = printer;
        _printer!.text(
          'Connected [$ipAddress]',
          styles: const PosStyles(align: PosAlign.center, bold: true),
        );
        _printer!.cut();
        return true;
      }

      debugPrint("Error connecting: ${res.msg}");
      return false;
    } catch (e) {
      debugPrint("Error connecting to wifi printer: $e");
      return false;
    }
  }

  static void disconnectPrinter() {
    if (_printer != null) {
      _printer!.disconnect();
      _printer = null;
    }
  }

  // ---------------------------------------------------------------------------
  // English Invoice  (text-based — alignment works perfectly with ASCII)
  // ---------------------------------------------------------------------------

  static Future<void> printReceipt() async {
    if (_printer == null) {
      debugPrint("Printer is not connected!");
      return;
    }

    try {
      final String jsonString = await rootBundle.loadString(
        'lib/data/order_data_en.json',
      );
      final Map<String, dynamic> jsonData = jsonDecode(jsonString);
      final List<dynamic> orders = jsonData['orders'];

      // Header
      _printer!.text(
        'DEPARTMENT STORE',
        styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        ),
      );
      _printer!.text(
        'Sales Receipt',
        styles: const PosStyles(align: PosAlign.center, bold: true),
      );
      _printer!.emptyLines(1);

      _printer!.text('------------------------------------------------');

      // Column headers — widths must sum to 12
      _printer!.row([
        PosColumn(
          text: 'SL',
          width: 1,
          styles: const PosStyles(align: PosAlign.left),
        ),
        PosColumn(
          text: 'Item',
          width: 5,
          styles: const PosStyles(align: PosAlign.left),
        ),
        PosColumn(
          text: 'Qty',
          width: 2,
          styles: const PosStyles(align: PosAlign.center),
        ),
        PosColumn(
          text: 'Price',
          width: 2,
          styles: const PosStyles(align: PosAlign.right),
        ),
        PosColumn(
          text: 'Total',
          width: 2,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);

      _printer!.text('------------------------------------------------');

      double totalAmount = 0.0;

      for (var item in orders) {
        final String name = item['itemName'];
        final int qty = item['qty'] ?? 1;
        int slNo = item['serialNumber'];
        final double unitPrice = (item['price'] as num).toDouble();
        final double itemTotal = unitPrice * qty;
        totalAmount += itemTotal;

        _printer!.row([
          PosColumn(
            text: slNo.toString(),
            width: 1,
            styles: const PosStyles(align: PosAlign.left),
          ),
          PosColumn(
            text: name,
            width: 5,
            styles: const PosStyles(align: PosAlign.left),
          ),
          PosColumn(
            text: qty.toString(),
            width: 2,
            styles: const PosStyles(align: PosAlign.center),
          ),
          PosColumn(
            text: unitPrice.toStringAsFixed(2),
            width: 2,
            styles: const PosStyles(align: PosAlign.right),
          ),
          PosColumn(
            text: itemTotal.toStringAsFixed(2),
            width: 2,
            styles: const PosStyles(align: PosAlign.right),
          ),
        ]);
        slNo++;
      }

      _printer!.text('------------------------------------------------');

      _printer!.row([
        PosColumn(
          text: 'Total:',
          width: 8,
          styles: const PosStyles(align: PosAlign.left, bold: true),
        ),
        PosColumn(
          text: '\$${totalAmount.toStringAsFixed(2)}',
          width: 4,
          styles: const PosStyles(align: PosAlign.right, bold: true),
        ),
      ]);

      _printer!.emptyLines(1);
      _printer!.text(
        'Thank you for shopping!',
        styles: const PosStyles(align: PosAlign.center),
      );

      _printer!.feed(2);
      _printer!.cut();
    } catch (e) {
      debugPrint("Error printing English receipt: $e");
    }
  }

  // ---------------------------------------------------------------------------
  // Bangla Invoice  (bitmap-rendered — fixes alignment)
  //
  // Why bitmap?
  // esc_pos_utils' PosColumn/row() pads columns based on BYTE length.
  // Bangla glyphs are multi-byte UTF-8 (3+ bytes each) and proportional-
  // width, so space-padding never lines up. Rendering the entire receipt
  // onto a Flutter Canvas with exact pixel columns and then sending it as
  // an image guarantees perfect alignment regardless of font metrics.
  // ---------------------------------------------------------------------------

  /// 576 dots = standard printable width for 80 mm thermal printers at 203 dpi.
  static const double _imgWidth = 576;
  static const double _margin = 12;
  static const double _contentWidth = _imgWidth - _margin * 2;

  // Column pixel positions (left edge of each column).
  // SL(40) | Item(240) | Qty(60) | Price(96) | Total(116)  = 552 = _contentWidth
  static const double _wSl = 40;
  static const double _wItem = 240;
  static const double _wQty = 60;
  static const double _wPrice = 96;
  static const double _wTotal = 116;

  static double get _xSl => _margin;
  static double get _xItem => _xSl + _wSl;
  static double get _xQty => _xItem + _wItem;
  static double get _xPrice => _xQty + _wQty;
  static double get _xTotal => _xPrice + _wPrice;

  /// Draw a single text cell on the canvas.
  static void _drawCell(
    Canvas canvas, {
    required String text,
    required double x,
    required double width,
    required double y,
    TextAlign align = TextAlign.left,
    double fontSize = 24,
    FontWeight fontWeight = FontWeight.normal,
  }) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: Colors.black,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: align,
      maxLines: 1,
      ellipsis: '…',
    );
    // Setting minWidth == maxWidth forces the layout box to the full column
    // width so that TextAlign positions the glyphs correctly inside it.
    textPainter.layout(minWidth: width, maxWidth: width);
    textPainter.paint(canvas, Offset(x, y));
  }

  /// Draw a dashed separator line across the receipt width.
  static void _drawDashedLine(Canvas canvas, double y) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 1.5;
    const double dash = 6.0;
    const double gap = 4.0;
    double x = _margin;
    while (x < _imgWidth - _margin) {
      canvas.drawLine(Offset(x, y), Offset(x + dash, y), paint);
      x += dash + gap;
    }
  }

  /// Renders the complete Bangla receipt as an [img.Image].
  static Future<img.Image> _renderBanglaReceiptImage(
    List<dynamic> orders,
  ) async {
    const double headerFontSize = 30;
    const double subHeaderFontSize = 22;
    const double bodyFontSize = 24;
    const double totalFontSize = 26;

    const double headerRowH = 42;
    const double subHeaderRowH = 32;
    const double bodyRowH = 36;
    const double separatorH = 14;
    const double spacingSmall = 10;
    const double spacingMed = 16;

    // Calculate total canvas height
    double totalHeight = _margin;
    totalHeight += headerRowH; // title
    totalHeight += subHeaderRowH; // subtitle
    totalHeight += spacingMed; // gap
    totalHeight += separatorH; // ---
    totalHeight += bodyRowH; // column header row
    totalHeight += separatorH; // ---
    totalHeight += orders.length * bodyRowH; // item rows
    totalHeight += separatorH; // ---
    totalHeight += bodyRowH + spacingSmall; // total row
    totalHeight += spacingMed; // gap
    totalHeight += subHeaderRowH; // thank-you line
    totalHeight += _margin;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, _imgWidth, totalHeight),
    );

    // White background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, _imgWidth, totalHeight),
      Paint()..color = Colors.white,
    );

    double y = _margin;

    // ---- Title ----
    _drawCell(
      canvas,
      text: 'ডিপার্টমেন্ট স্টোর',
      x: _margin,
      width: _contentWidth,
      y: y,
      align: TextAlign.center,
      fontSize: headerFontSize,
      fontWeight: FontWeight.bold,
    );
    y += headerRowH;

    // ---- Subtitle ----
    _drawCell(
      canvas,
      text: 'বিক্রয় রসিদ',
      x: _margin,
      width: _contentWidth,
      y: y,
      align: TextAlign.center,
      fontSize: subHeaderFontSize,
      fontWeight: FontWeight.bold,
    );
    y += subHeaderRowH + spacingMed;

    // ---- Separator ----
    _drawDashedLine(canvas, y + separatorH / 2);
    y += separatorH;

    // ---- Column headers ----
    _drawCell(canvas, text: 'নং', x: _xSl, width: _wSl, y: y, fontWeight: FontWeight.bold, fontSize: bodyFontSize);
    _drawCell(canvas, text: 'আইটেম', x: _xItem, width: _wItem, y: y, fontWeight: FontWeight.bold, fontSize: bodyFontSize);
    _drawCell(canvas, text: 'পরিমাণ', x: _xQty, width: _wQty, y: y, align: TextAlign.center, fontWeight: FontWeight.bold, fontSize: bodyFontSize);
    _drawCell(canvas, text: 'মূল্য', x: _xPrice, width: _wPrice, y: y, align: TextAlign.right, fontWeight: FontWeight.bold, fontSize: bodyFontSize);
    _drawCell(canvas, text: 'মোট', x: _xTotal, width: _wTotal, y: y, align: TextAlign.right, fontWeight: FontWeight.bold, fontSize: bodyFontSize);
    y += bodyRowH;

    // ---- Separator ----
    _drawDashedLine(canvas, y + separatorH / 2);
    y += separatorH;

    // ---- Item rows ----
    double totalAmount = 0.0;

    for (var item in orders) {
      final String slNoStr = item['serialNumber'] ?? '';
      final String name = item['itemName'];
      final String qtyStr = item['qty'] ?? '১';
      final String priceStr = item['price'] ?? '০.০০';

      final int qty = int.parse(_banglaToEnglishNumber(qtyStr));
      final double unitPrice = double.parse(_banglaToEnglishNumber(priceStr));
      final double itemTotal = unitPrice * qty;
      totalAmount += itemTotal;

      final String itemTotalStr = _englishToBanglaNumber(
        itemTotal.toStringAsFixed(2),
      );

      _drawCell(canvas, text: slNoStr, x: _xSl, width: _wSl, y: y, fontSize: bodyFontSize);
      _drawCell(canvas, text: name, x: _xItem, width: _wItem, y: y, fontSize: bodyFontSize);
      _drawCell(canvas, text: qtyStr, x: _xQty, width: _wQty, y: y, align: TextAlign.center, fontSize: bodyFontSize);
      _drawCell(canvas, text: priceStr, x: _xPrice, width: _wPrice, y: y, align: TextAlign.right, fontSize: bodyFontSize);
      _drawCell(canvas, text: itemTotalStr, x: _xTotal, width: _wTotal, y: y, align: TextAlign.right, fontSize: bodyFontSize);
      y += bodyRowH;
    }

    // ---- Separator ----
    _drawDashedLine(canvas, y + separatorH / 2);
    y += separatorH;

    // ---- Total row ----
    final String totalAmountStr = _englishToBanglaNumber(
      totalAmount.toStringAsFixed(2),
    );
    _drawCell(
      canvas,
      text: 'সর্বমোট:',
      x: _xSl,
      width: _wSl + _wItem + _wQty,
      y: y,
      fontSize: totalFontSize,
      fontWeight: FontWeight.bold,
    );
    _drawCell(
      canvas,
      text: '৳$totalAmountStr',
      x: _xPrice,
      width: _wPrice + _wTotal,
      y: y,
      align: TextAlign.right,
      fontSize: totalFontSize,
      fontWeight: FontWeight.bold,
    );
    y += bodyRowH + spacingMed;

    // ---- Thank-you ----
    _drawCell(
      canvas,
      text: 'কেনাকাটার জন্য ধন্যবাদ!',
      x: _margin,
      width: _contentWidth,
      y: y,
      align: TextAlign.center,
      fontSize: subHeaderFontSize,
    );

    // ---- Rasterize ----
    final picture = recorder.endRecording();
    final ui.Image uiImage = await picture.toImage(
      _imgWidth.toInt(),
      totalHeight.toInt(),
    );
    final ByteData? byteData = await uiImage.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    );
    final Uint8List pixels = byteData!.buffer.asUint8List();

    return img.Image.fromBytes(
      _imgWidth.toInt(),
      totalHeight.toInt(),
      pixels,
    );
  }

  static Future<void> banglaPrintReceipt() async {
    if (_printer == null) {
      debugPrint("Printer is not connected!");
      return;
    }

    try {
      final String jsonString = await rootBundle.loadString(
        'lib/data/order_data_bn.json',
      );
      final Map<String, dynamic> jsonData = jsonDecode(jsonString);
      final List<dynamic> orders = jsonData['orders'];

      // Render the entire receipt as a bitmap image
      final img.Image receiptImage = await _renderBanglaReceiptImage(orders);

      _printer!.image(receiptImage);

      _printer!.feed(2);
      _printer!.cut();
    } catch (e) {
      debugPrint("Error printing Bangla receipt: $e");
    }
  }

  // ---------------------------------------------------------------------------
  // Number conversion helpers
  // ---------------------------------------------------------------------------

  static String _englishToBanglaNumber(String input) {
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const bangla = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
    for (int i = 0; i < english.length; i++) {
      input = input.replaceAll(english[i], bangla[i]);
    }
    return input;
  }

  static String _banglaToEnglishNumber(String input) {
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const bangla = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
    for (int i = 0; i < bangla.length; i++) {
      input = input.replaceAll(bangla[i], english[i]);
    }
    return input;
  }
}
