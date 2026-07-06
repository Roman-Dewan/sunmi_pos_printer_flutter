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
            text: 'Qty',
            width: 4,
            style: SunmiTextStyle(align: SunmiPrintAlign.CENTER),
          ),
          SunmiColumn(
            text: 'Item',
            width: 16,
            style: SunmiTextStyle(align: SunmiPrintAlign.LEFT),
          ),
          SunmiColumn(
            text: 'Price',
            width: 10,
            style: SunmiTextStyle(align: SunmiPrintAlign.RIGHT),
          ),
        ],
      );

      await SunmiPrinter.printText('--------------------------------');

      double totalAmount = 0.0;
      final random = Random();

      // Items
      for (var item in orders) {
        String name = item['itemName'];

        // Truncate name if it's too long
        if (name.length > 15) {
          name = '${name.substring(0, 14)}.';
        }

        int qty = random.nextInt(5) + 1; // Random quantity 1 to 5
        double unitPrice = item['price'];
        double itemTotal = unitPrice * qty;
        totalAmount += itemTotal;

        await SunmiPrinter.printRow(
          cols: [
            SunmiColumn(
              text: qty.toString(),
              width: 4,
              style: SunmiTextStyle(align: SunmiPrintAlign.CENTER),
            ),
            SunmiColumn(
              text: name,
              width: 16,
              style: SunmiTextStyle(align: SunmiPrintAlign.LEFT, fontSize: 40),
            ),
            SunmiColumn(
              text: itemTotal.toStringAsFixed(2),
              width: 10,
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
            width: 20,
            style: SunmiTextStyle(align: SunmiPrintAlign.LEFT),
          ),
          SunmiColumn(
            text: '\$${totalAmount.toStringAsFixed(2)}',
            width: 10,
            style: SunmiTextStyle(align: SunmiPrintAlign.RIGHT),
          ),
        ],
      );

      await SunmiPrinter.lineWrap(1);
      await SunmiPrinter.printText(
        'Thank you for shopping!',
        style: SunmiTextStyle(align: SunmiPrintAlign.CENTER),
      );

      await SunmiPrinter.lineWrap(3);
      await SunmiPrinter.cutPaper();
    } catch (e) {
      debugPrint("Error printing: $e");
    }
  }

  static Future<void> printBanglaReceipt() async {
    try {
      // Read Bangla JSON data
      String jsonString = await rootBundle.loadString(
        'lib/data/order_data_bn.json',
      );
      Map<String, dynamic> jsonData = jsonDecode(jsonString);
      List<dynamic> orders = jsonData['orders'];

      // Header
      await SunmiPrinter.printText(
        'ডিপার্টমেন্ট স্টোর',
        style: SunmiTextStyle(
          bold: true,
          align: SunmiPrintAlign.CENTER,
          fontSize: 36,
        ),
      );
      await SunmiPrinter.printText(
        'বিক্রয় রসিদ',
        style: SunmiTextStyle(align: SunmiPrintAlign.CENTER),
      );
      await SunmiPrinter.lineWrap(1);

      // Separator
      await SunmiPrinter.printText('--------------------------------');

      // Column Headers
      await SunmiPrinter.printRow(
        cols: [
          SunmiColumn(
            text: 'পরিমাণ',
            width: 8,
            style: SunmiTextStyle(align: SunmiPrintAlign.CENTER),
          ),
          SunmiColumn(
            text: 'পণ্য',
            width: 16,
            style: SunmiTextStyle(align: SunmiPrintAlign.LEFT),
          ),
          SunmiColumn(
            text: 'মূল্য',
            width: 10,
            style: SunmiTextStyle(align: SunmiPrintAlign.RIGHT),
          ),
        ],
      );

      await SunmiPrinter.printText('--------------------------------');

      double totalAmount = 0.0;

      // Items
      for (var item in orders) {
        String name = item['itemName'];

        // Truncate name if it's too long
        if (name.length > 15) {
          name = '${name.substring(0, 14)}.';
        }

        // Parse Bangla numbers to English for calculation
        String qtyBangla = item['qty'].toString();
        String priceBangla = item['price'].toString();

        int qty = int.parse(convertBanglaToEnglishNumber(qtyBangla));
        double unitPrice = double.parse(
          convertBanglaToEnglishNumber(priceBangla),
        );

        double itemTotal = unitPrice * qty;
        totalAmount += itemTotal;

        String itemTotalBangla = convertEnglishToBanglaNumber(
          itemTotal.toStringAsFixed(2),
        );

        await SunmiPrinter.printRow(
          cols: [
            SunmiColumn(
              text: qtyBangla,
              width: 4,
              style: SunmiTextStyle(align: SunmiPrintAlign.CENTER),
            ),
            SunmiColumn(
              text: name,
              width: 16,
              style: SunmiTextStyle(align: SunmiPrintAlign.LEFT, fontSize: 40),
            ),
            SunmiColumn(
              text: itemTotalBangla,
              width: 10,
              style: SunmiTextStyle(align: SunmiPrintAlign.RIGHT),
            ),
          ],
        );
      }

      await SunmiPrinter.printText('--------------------------------');

      // Total
      String finalTotalBangla = convertEnglishToBanglaNumber(
        totalAmount.toStringAsFixed(2),
      );
      await SunmiPrinter.printRow(
        cols: [
          SunmiColumn(
            text: 'মোট:',
            width: 20,
            style: SunmiTextStyle(align: SunmiPrintAlign.LEFT),
          ),
          SunmiColumn(
            text: '৳ $finalTotalBangla',
            width: 10,
            style: SunmiTextStyle(align: SunmiPrintAlign.RIGHT),
          ),
        ],
      );

      await SunmiPrinter.lineWrap(1);
      await SunmiPrinter.printText(
        'ধন্যবাদ!',
        style: SunmiTextStyle(align: SunmiPrintAlign.CENTER),
      );

      // Feed 3 lines to ensure the receipt can be torn off properly
      await SunmiPrinter.lineWrap(3);
      await SunmiPrinter.cutPaper();
    } catch (e) {
      debugPrint("Error printing: $e");
    }
  }

  static String convertEnglishToBanglaNumber(String input) {
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const bangla = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
    for (int i = 0; i < english.length; i++) {
      input = input.replaceAll(english[i], bangla[i]);
    }
    return input;
  }

  static String convertBanglaToEnglishNumber(String input) {
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const bangla = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
    for (int i = 0; i < bangla.length; i++) {
      input = input.replaceAll(bangla[i], english[i]);
    }
    return input;
  }
}
