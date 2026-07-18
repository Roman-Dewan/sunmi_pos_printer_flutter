# Flutter POS Printer Integration

A comprehensive Flutter project demonstrating how to connect and print to various POS (Point of Sale) printers. This project specifically supports complex localizations like **Bangla** alongside English, ensuring perfect text alignment and rendering on thermal printers.

## 🚀 Features Currently Implemented

### 1. Mobile POS In-built Printer (58mm)
Integration with in-built thermal printers on Android mobile POS devices (like Sunmi V2/V3 series).
- **Paper Size:** 58mm
- **English Printing:** Fully supported with perfect column alignment.
- **Bangla Printing:** Fully supported. Uses a custom bitmap-rendered Canvas approach to bypass standard ESC/POS byte-padding limitations, guaranteeing pixel-perfect alignment for multi-byte UTF-8 Bengali characters.

### 2. Wi-Fi / LAN Network Printer
Integration with external network POS printers, including the **Sunmi External Cloud Printer**, via IP address over Wi-Fi.
- **Paper Size:** 80mm (Configurable)
- **English Printing:** Standard ESC/POS text-based printing for fast, perfectly aligned ASCII text.
- **Bangla Printing:** Supported via a custom rasterization pipeline. The invoice is drawn onto a Flutter Canvas, converted to an image, and sent to the printer, solving all proportional-width font alignment issues inherent to thermal printer firmware.

## 🚧 Upcoming Features (Work In Progress)

- **[ ] 80mm In-built POS Printer Support:** Expanding the in-device SDK implementation to support wider 80mm in-built printers on larger POS terminals.
- **[ ] Bluetooth Printer Integration:** Adding support for pairing, connecting, and printing to standard ESC/POS Bluetooth thermal printers.

## 🛠️ Technical Details: How Bangla Alignment is Solved

Standard ESC/POS libraries (like `esc_pos_utils`) pad columns based on *byte length*. Because Bangla characters use 3+ bytes per glyph and are proportionally spaced, space-padding never aligns correctly on the printer hardware. 

This project solves this by:
1. Drawing the entire Bangla receipt on a hidden Flutter `Canvas`.
2. Positioning text using exact pixel coordinates.
3. Rasterizing the canvas into a bitmap `Image`.
4. Sending the bitmap to the printer using `printer.image()`.

## 📦 Dependencies
- [`sunmi_printer_plus`](https://pub.dev/packages/sunmi_printer_plus): For in-device Sunmi POS printing.
- [`esc_pos_printer`](https://pub.dev/packages/esc_pos_printer): For Wi-Fi/Network ESC/POS printing.
- [`esc_pos_utils`](https://pub.dev/packages/esc_pos_utils): For ESC/POS formatting.
- [`image`](https://pub.dev/packages/image): For processing the Canvas to bitmap data.
