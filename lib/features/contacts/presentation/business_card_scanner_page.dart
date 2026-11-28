import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/utils/temp_file_cleanup.dart';
import '../data/business_card_parser.dart';
import '../domain/business_card_draft.dart';

class BusinessCardScannerPage extends StatefulWidget {
  const BusinessCardScannerPage({super.key, this.parser});

  final BusinessCardParser? parser;

  @override
  State<BusinessCardScannerPage> createState() =>
      _BusinessCardScannerPageState();
}

class _BusinessCardScannerPageState extends State<BusinessCardScannerPage>
    with WidgetsBindingObserver {
  CameraController? _camera;
  late final BusinessCardParser _parser;
  bool _initializing = true;
  bool _processing = false;
  String? _error;
  String _progress = 'Reading card...';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _parser = widget.parser ?? BusinessCardParser();
    _initializeCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final camera = _camera;
    if (camera == null || !camera.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      camera.dispose();
      _camera = null;
    } else if (state == AppLifecycleState.resumed && !_processing) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    if (!mounted) return;
    setState(() {
      _initializing = true;
      _error = null;
    });
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) throw StateError('No camera was found.');
      final selected = cameras
          .where((camera) => camera.lensDirection == CameraLensDirection.back)
          .firstOrNull;
      final controller = CameraController(
        selected ?? cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await controller.initialize();
      await controller.setFlashMode(FlashMode.auto);
      if (!mounted) {
        await controller.dispose();
        return;
      }
      await _camera?.dispose();
      setState(() {
        _camera = controller;
        _initializing = false;
      });
    } on CameraException catch (error) {
      _showError(
        error.code == 'CameraAccessDenied'
            ? 'Camera access is required to scan a business card.'
            : 'Could not open the camera. ${error.description ?? ''}'.trim(),
      );
    } on Object catch (error) {
      _showError(error.toString().replaceFirst('Bad state: ', ''));
    }
  }

  Future<void> _capture() async {
    final camera = _camera;
    if (_processing || camera == null || !camera.value.isInitialized) return;
    setState(() {
      _processing = true;
      _error = null;
      _progress = 'Reading card...';
    });
    XFile? photo;
    var recognizedText = '';
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      photo = await camera.takePicture();
      final result = await recognizer.processImage(
        InputImage.fromFilePath(photo.path),
      );
      final text = result.text.trim();
      recognizedText = text;
      if (text.isEmpty) {
        throw StateError(
          'No text was found. Move closer and keep the card inside the frame.',
        );
      }
      if (!mounted) return;
      setState(() => _progress = 'Organizing contact details...');
      final draft = await _parser.parse(text);
      if (!mounted) return;
      Navigator.pop(context, draft);
    } on Object catch (error) {
      if (!mounted) return;
      final message = error.toString().replaceFirst('Bad state: ', '');
      setState(() {
        _processing = false;
        _error = message;
      });
      if (recognizedText.isNotEmpty) {
        await _showOfflineChoice(recognizedText);
      }
    } finally {
      await recognizer.close();
      try {
        if (photo != null) await deleteTemporaryFile(photo.path);
      } on Object {
        // The temporary camera file can already be gone on some devices.
      }
    }
  }

  Future<void> _showOfflineChoice(String text) async {
    if (!mounted) return;
    final useOffline = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('AI parsing is unavailable'),
        content: const Text(
          'Email and LinkedIn can still be extracted on this phone. '
          'Name, company and role will need to be entered manually.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Try again'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Use local result'),
          ),
        ],
      ),
    );
    if (useOffline == true && mounted) {
      Navigator.pop(context, BusinessCardDraft.offline(text));
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    setState(() {
      _initializing = false;
      _processing = false;
      _error = message;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _camera?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    body: SafeArea(
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_camera?.value.isInitialized == true)
            _cameraPreview()
          else
            const ColoredBox(color: Color(0xFF15131A)),
          const _ScannerShade(),
          Positioned(
            left: 16,
            top: 12,
            child: _RoundButton(
              icon: Icons.close,
              tooltip: 'Close scanner',
              onPressed: _processing ? null : () => Navigator.pop(context),
            ),
          ),
          const Positioned(
            left: 24,
            right: 24,
            top: 30,
            child: Text(
              'Scan business card',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Positioned(
            left: 28,
            right: 28,
            bottom: 28,
            child: Column(
              children: [
                Text(
                  _processing
                      ? _progress
                      : 'Place the card inside the frame and keep it steady',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD9455F).withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                if (_initializing || _processing)
                  const SizedBox(
                    width: 66,
                    height: 66,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 4,
                    ),
                  )
                else
                  GestureDetector(
                    onTap: _capture,
                    child: Container(
                      width: 74,
                      height: 74,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(color: brandPurple, width: 6),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black38,
                            blurRadius: 16,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.document_scanner_outlined,
                        color: brandPurple,
                        size: 30,
                      ),
                    ),
                  ),
                if (_error != null && _camera == null) ...[
                  const SizedBox(height: 14),
                  TextButton(
                    onPressed: _initializeCamera,
                    child: const Text(
                      'Try again',
                      style: TextStyle(color: Colors.white),
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

  Widget _cameraPreview() {
    final camera = _camera!;
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportAspectRatio =
            constraints.maxWidth / constraints.maxHeight;
        final previewAspectRatio =
            MediaQuery.orientationOf(context) == Orientation.portrait
            ? 1 / camera.value.aspectRatio
            : camera.value.aspectRatio;
        final coverScale = viewportAspectRatio > previewAspectRatio
            ? viewportAspectRatio / previewAspectRatio
            : previewAspectRatio / viewportAspectRatio;

        return ClipRect(
          child: Transform.scale(
            scale: coverScale,
            child: Center(child: CameraPreview(camera)),
          ),
        );
      },
    );
  }
}

class _ScannerShade extends StatelessWidget {
  const _ScannerShade();

  @override
  Widget build(BuildContext context) => Center(
    child: AspectRatio(
      aspectRatio: 1.58,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white, width: 3),
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(color: Colors.black54, spreadRadius: 1000, blurRadius: 0),
          ],
        ),
      ),
    ),
  );
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.black45,
    shape: const CircleBorder(),
    child: IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      color: Colors.white,
      icon: Icon(icon),
    ),
  );
}
