import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sunmi_printer_plus/sunmi_printer_plus.dart';

class PrinterService {
  static Future<void> bindPrinter() async {
    // Rebind the printer service for v4
    await SunmiPrinterPlus().rebindPrinter();
  }

  static Future<void> printReceipt() async {
    try {
      // Read English JSON data
      String jsonString = await rootBundle.loadString(
        'lib/data/order_data_en.json',
      );
      Map<String, dynamic> jsonData = jsonDecode(jsonString);
      List<dynamic> orders = jsonData['orders'];

      // Header
      await SunmiPrinter.printText(
        'DEPARTMENT STORE',
        style: SunmiTextStyle(
          bold: true,
          align: SunmiPrintAlign.CENTER,
          fontSize: 36,
        ),
      );
      await SunmiPrinter.printText(
        'Sales Receipt',
        style: SunmiTextStyle(align: SunmiPrintAlign.CENTER),
      );
      await SunmiPrinter.lineWrap(1);

      // Separator
      await SunmiPrinter.printText('--------------------------------');

      // Column Headers
      // For 58mm paper, total width is roughly 30.
      await SunmiPrinter.printRow(
        cols: [
          SunmiColumn(
            text: 'SN',
            width: 2,
            style: SunmiTextStyle(align: SunmiPrintAlign.LEFT),
          ),
          SunmiColumn(
            text: 'Item',
            width: 10,
            style: SunmiTextStyle(align: SunmiPrintAlign.LEFT),
          ),
          SunmiColumn(
            text: 'Qty',
            width: 4,
            style: SunmiTextStyle(align: SunmiPrintAlign.CENTER),
          ),
          SunmiColumn(
            text: 'Price',
            width: 6,
            style: SunmiTextStyle(align: SunmiPrintAlign.RIGHT),
          ),
          SunmiColumn(
            text: 'Total',
            width: 8,
            style: SunmiTextStyle(align: SunmiPrintAlign.RIGHT),
          ),
        ],
      );

      await SunmiPrinter.printText('--------------------------------');

      double totalAmount = 0.0;
      final random = Random();

      // Items
      for (var item in orders) {
        String sn = item['serialNumber'].toString();
        String name = item['itemName'];

        // Truncate name if it's too long
        if (name.length > 9) {
          name = '${name.substring(0, 8)}.';
        }

        int qty = random.nextInt(5) + 1; // Random quantity 1 to 5
        double unitPrice = item['price'];
        double itemTotal = unitPrice * qty;
        totalAmount += itemTotal;

        await SunmiPrinter.printRow(
          cols: [
            SunmiColumn(
              text: sn,
              width: 2,
              style: SunmiTextStyle(align: SunmiPrintAlign.LEFT),
            ),
            SunmiColumn(
              text: name,
              width: 10,
              style: SunmiTextStyle(align: SunmiPrintAlign.LEFT),
            ),
            SunmiColumn(
              text: qty.toString(),
              width: 4,
              style: SunmiTextStyle(align: SunmiPrintAlign.CENTER),
            ),
            SunmiColumn(
              text: unitPrice.toStringAsFixed(2),
              width: 6,
              style: SunmiTextStyle(align: SunmiPrintAlign.RIGHT),
            ),
            SunmiColumn(
              text: itemTotal.toStringAsFixed(2),
              width: 8,
              style: SunmiTextStyle(align: SunmiPrintAlign.RIGHT),
            ),
          ],
        );
      }

      await SunmiPrinter.printText('--------------------------------');

      // Total
      await SunmiPrinter.printRow(
        cols: [
          SunmiColumn(
            text: 'Total:',
            width: 16,
            style: SunmiTextStyle(align: SunmiPrintAlign.LEFT),
          ),
          SunmiColumn(
            text: '\$${totalAmount.toStringAsFixed(2)}',
            width: 14,
            style: SunmiTextStyle(align: SunmiPrintAlign.RIGHT),
          ),
        ],
      );

      await SunmiPrinter.lineWrap(1);
      await SunmiPrinter.printText(
        'Thank you for shopping!',
        style: SunmiTextStyle(align: SunmiPrintAlign.CENTER),
      );

      // Feed 3 lines to ensure the receipt can be torn off properly
      await SunmiPrinter.lineWrap(3);
    } catch (e) {
      debugPrint("Error printing: $e");
    }
  }
}
