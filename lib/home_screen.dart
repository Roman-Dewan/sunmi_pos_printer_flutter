import 'package:flutter/material.dart';
import 'pos_printer/printer_service.dart';
import 'wifi_external_printer/external_printer_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _ipController = TextEditingController(
    text: "192.168.100.112",
  );
  bool _isConnected = false;
  bool _isConnecting = false;

  @override
  void initState() {
    super.initState();
    PrinterService.bindPrinter();
  }

  @override
  void dispose() {
    _ipController.dispose();
    super.dispose();
  }

  /// INBuild Pos Printer
  /* 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sunmi V3 POS Printer"),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: .center,
          crossAxisAlignment: .center,
          children: [
            ElevatedButton.icon(
              onPressed: PrinterService.printReceipt,
              icon: const Icon(Icons.print),
              label: const Text(
                "Print Receipt (English)",
                style: TextStyle(fontSize: 18),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
            SizedBox(height: 20,),
            ElevatedButton.icon(
              onPressed: PrinterService.printBanglaReceipt,
              icon: const Icon(Icons.print),
              label: const Text(
                "Print Receipt (Bangla)",
                style: TextStyle(fontSize: 18),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
  */

  /// Wifi External Colud printer.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sunmi Cloud Printer"),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              TextField(
                controller: _ipController,
                decoration: const InputDecoration(
                  labelText: 'Printer IP Address',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., 192.168.1.100',
                  prefixIcon: Icon(Icons.wifi),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                enabled: !_isConnected && !_isConnecting,
              ),
              const SizedBox(height: 20),
              if (!_isConnected)
                ElevatedButton.icon(
                  onPressed: _isConnecting
                      ? null
                      : () async {
                          if (_ipController.text.isEmpty) return;

                          setState(() {
                            _isConnecting = true;
                          });

                          bool success =
                              await ExternalPrinterService.connectPrinter(
                                _ipController.text.trim(),
                              );

                          if (context.mounted) {
                            setState(() {
                              _isConnecting = false;
                              _isConnected = success;
                            });

                            if (success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Connected to printer successfully!',
                                  ),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Failed to connect. Please check IP and printer status.',
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                  icon: _isConnecting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.link),
                  label: Text(
                    _isConnecting ? "Connecting..." : "Connect",
                    style: const TextStyle(fontSize: 18),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                )
              else
                ElevatedButton.icon(
                  onPressed: () {
                    ExternalPrinterService.disconnectPrinter();
                    setState(() {
                      _isConnected = false;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Disconnected from printer'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.link_off),
                  label: const Text(
                    "Disconnect",
                    style: TextStyle(fontSize: 18),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: _isConnected
                    ? () async {
                        await ExternalPrinterService.printReceipt();
                      }
                    : null,
                icon: const Icon(Icons.print),
                label: const Text(
                  "Print Receipt",
                  style: TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
