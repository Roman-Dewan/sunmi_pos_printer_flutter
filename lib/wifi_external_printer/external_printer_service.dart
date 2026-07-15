import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:esc_pos_printer/esc_pos_printer.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';

class ExternalPrinterService {
  static NetworkPrinter? _printer;

  static Future<bool> connectPrinter(String ipAddress) async {
    try {
      // Create a profile and network printer
      final profile = await CapabilityProfile.load();
      // Using 80mm paper size
      final printer = NetworkPrinter(PaperSize.mm80, profile);

      final PosPrintResult res = await printer.connect(ipAddress, port: 9100);

      if (res == PosPrintResult.success) {
        _printer = printer;
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

  static Future<void> printReceipt() async {
    if (_printer == null) {
      debugPrint("Printer is not connected!");
      return;
    }

    try {
      // Read JSON data
      String jsonString = await rootBundle.loadString(
        'lib/data/order_data_en.json',
      );
      Map<String, dynamic> jsonData = jsonDecode(jsonString);
      List<dynamic> orders = jsonData['orders'];

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

      // Separator
      _printer!.text('------------------------------------------------');

      // Column Headers - esc_pos_utils requires widths that sum to 12.
      // SL: 1, Item: 5, Qty: 2, Price: 2, Total: 2
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
      int slNo = 1;

      // Items
      for (var item in orders) {
        String name = item['itemName'];
        int qty = item['qty'] ?? 1;
        double unitPrice = item['price'];
        double itemTotal = unitPrice * qty;
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

      // Total
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

      // Feed lines and cut paper
      _printer!.feed(2);
      _printer!.cut();
    } catch (e) {
      debugPrint("Error printing: $e");
    }
  }
}
