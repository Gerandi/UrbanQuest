import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import '../atoms/custom_button.dart';
import '../atoms/custom_card.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/quest_stop_model.dart';

class ChallengeQrCodeWidget extends StatefulWidget {
  final QuestStop questStop;
  final Function(String) onQrCodeScanned;
  final bool isSubmitting;

  const ChallengeQrCodeWidget({
    Key? key,
    required this.questStop,
    required this.onQrCodeScanned,
    this.isSubmitting = false,
  }) : super(key: key);

  @override
  State<ChallengeQrCodeWidget> createState() => _ChallengeQrCodeWidgetState();
}

class _ChallengeQrCodeWidgetState extends State<ChallengeQrCodeWidget> {
  MobileScannerController? controller;
  bool _isScanning = false;
  bool _hasPermission = false;
  String? _scannedCode;

  @override
  void initState() {
    super.initState();
    _checkCameraPermission();
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  Future<void> _checkCameraPermission() async {
    final status = await Permission.camera.status;
    if (status.isGranted) {
      setState(() {
        _hasPermission = true;
      });
    } else if (status.isDenied) {
      final result = await Permission.camera.request();
      setState(() {
        _hasPermission = result.isGranted;
      });
    }
  }

  void _onDetect(BarcodeCapture capture) {
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty && !widget.isSubmitting) {
      final code = barcodes.first.rawValue;
      if (code != null) {
        setState(() {
          _scannedCode = code;
          _isScanning = false;
        });
        controller?.stop();
        widget.onQrCodeScanned(code);
      }
    }
  }

  void _startScanning() {
    setState(() {
      _isScanning = true;
      _scannedCode = null;
    });
    controller = MobileScannerController();
    controller?.start();
  }

  void _stopScanning() {
    setState(() {
      _isScanning = false;
    });
    controller?.stop();
  }

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Challenge Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.deepPurple, Colors.purple],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.deepPurple.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.qr_code_scanner,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'QR Code Challenge',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Scan the QR code to continue',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Challenge Instructions
          if (widget.questStop.challengeInstructions?.isNotEmpty == true) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.blackOpacity10,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.blackOpacity20,
                ),
              ),
              child: Text(
                widget.questStop.challengeInstructions!,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  height: 1.5,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // QR Scanner or Result
          if (!_hasPermission) ...[
            _buildPermissionRequest(),
          ] else if (_scannedCode != null) ...[
            _buildScannedResult(),
          ] else if (_isScanning) ...[
            _buildQRScanner(),
          ] else ...[
            _buildScannerPrompt(),
          ],
          
          const SizedBox(height: 16),
          
          // Control Buttons
          Row(
            children: [
              if (_isScanning) ...[
                Expanded(
                  child: CustomButton(
                    text: 'Stop Scanning',
                    icon: Icons.stop,
                    onPressed: _stopScanning,
                    variant: ButtonVariant.secondary,
                  ),
                ),
              ] else if (_scannedCode != null) ...[
                Expanded(
                  child: CustomButton(
                    text: 'Scan Again',
                    icon: Icons.refresh,
                    onPressed: _startScanning,
                    variant: ButtonVariant.secondary,
                  ),
                ),
              ] else ...[
                Expanded(
                  child: CustomButton(
                    text: 'Start Scanning',
                    icon: Icons.qr_code_scanner,
                    onPressed: _hasPermission ? _startScanning : _checkCameraPermission,
                    isLoading: widget.isSubmitting,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionRequest() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.orange.withOpacity(0.3),
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.camera_alt,
              size: 48,
              color: Colors.orange,
            ),
            SizedBox(height: 16),
            Text(
              'Camera Permission Required',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Please grant camera permission to scan QR codes',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.orange,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQRScanner() {
    return Container(
      height: 250,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.deepPurple,
          width: 2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: MobileScanner(
          controller: controller,
          onDetect: _onDetect,
        ),
      ),
    );
  }

  Widget _buildScannerPrompt() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.deepPurple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.deepPurple.withOpacity(0.3),
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.qr_code_scanner,
              size: 48,
              color: Colors.deepPurple,
            ),
            SizedBox(height: 16),
            Text(
              'Ready to Scan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Tap "Start Scanning" to begin',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.deepPurple,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScannedResult() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.green.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 24),
              SizedBox(width: 8),
              Text(
                'QR Code Scanned Successfully!',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.qr_code, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _scannedCode ?? '',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}