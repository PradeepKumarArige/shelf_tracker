import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/voice_assistant_service.dart';
import '../../core/theme/app_colors.dart';

class VoiceAssistantButton extends StatelessWidget {
  final VoidCallback onPressed;

  const VoiceAssistantButton({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<VoiceAssistantService>(
      builder: (context, voiceService, child) {
        final isListening = voiceService.isListening;
        final isSpeaking = voiceService.state == VoiceAssistantState.speaking;

        return FloatingActionButton(
          onPressed: onPressed,
          backgroundColor: isListening
              ? AppColors.expiredLight
              : isSpeaking
                  ? AppColors.groceryLight
                  : AppColors.primary,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              isListening
                  ? Icons.mic
                  : isSpeaking
                      ? Icons.volume_up
                      : Icons.mic_none,
              key: ValueKey(voiceService.state),
              color: Colors.white,
            ),
          ),
        );
      },
    );
  }
}

class VoiceAssistantOverlay extends StatefulWidget {
  final VoidCallback onClose;
  final Function(VoiceCommand) onCommand;

  const VoiceAssistantOverlay({
    super.key,
    required this.onClose,
    required this.onCommand,
  });

  @override
  State<VoiceAssistantOverlay> createState() => _VoiceAssistantOverlayState();
}

class _VoiceAssistantOverlayState extends State<VoiceAssistantOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    );
    _animationController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startListening();
    });
  }

  void _startListening() {
    final voiceService = context.read<VoiceAssistantService>();
    voiceService.startListening();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.black54,
      child: SafeArea(
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Consumer<VoiceAssistantService>(
            builder: (context, voiceService, child) {
              if (voiceService.lastCommand != null) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  widget.onCommand(voiceService.lastCommand!);
                  voiceService.clearCommand();
                });
              }

              return Column(
                children: [
                  const Spacer(),
                  Container(
                    margin: const EdgeInsets.all(24),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.cardDark : AppColors.cardLight,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Voice Assistant',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                voiceService.stopListening();
                                voiceService.stopSpeaking();
                                widget.onClose();
                              },
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _buildMicrophoneButton(voiceService, isDark),
                        const SizedBox(height: 24),
                        _buildStatusText(voiceService, theme),
                        const SizedBox(height: 16),
                        if (voiceService.state == VoiceAssistantState.error ||
                            voiceService.state == VoiceAssistantState.permissionDenied)
                          _buildErrorWidget(voiceService, theme)
                        else if (voiceService.lastWords.isEmpty &&
                            voiceService.state == VoiceAssistantState.idle)
                          _buildHelpButton(voiceService, theme),
                      ],
                    ),
                  ),
                  const Spacer(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMicrophoneButton(VoiceAssistantService voiceService, bool isDark) {
    final isListening = voiceService.isListening;
    final isSpeaking = voiceService.state == VoiceAssistantState.speaking;
    final isProcessing = voiceService.state == VoiceAssistantState.processing;

    return GestureDetector(
      onTap: () {
        if (isListening) {
          voiceService.stopListening();
        } else if (isSpeaking) {
          voiceService.stopSpeaking();
        } else {
          voiceService.startListening();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: isListening ? 120 : 100,
        height: isListening ? 120 : 100,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isListening
              ? AppColors.expiredLight
              : isSpeaking
                  ? AppColors.groceryLight
                  : AppColors.primary,
          boxShadow: [
            BoxShadow(
              color: (isListening
                      ? AppColors.expiredLight
                      : isSpeaking
                          ? AppColors.groceryLight
                          : AppColors.primary)
                  .withOpacity(0.4),
              blurRadius: isListening ? 30 : 20,
              spreadRadius: isListening ? 5 : 0,
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (isListening)
              ...List.generate(3, (index) {
                return AnimatedContainer(
                  duration: Duration(milliseconds: 300 + (index * 200)),
                  width: 120 + (index * 30),
                  height: 120 + (index * 30),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.expiredLight.withOpacity(0.3 - (index * 0.1)),
                      width: 2,
                    ),
                  ),
                );
              }),
            Icon(
              isListening
                  ? Icons.mic
                  : isSpeaking
                      ? Icons.volume_up
                      : isProcessing
                          ? Icons.hourglass_empty
                          : Icons.mic_none,
              color: Colors.white,
              size: 40,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusText(VoiceAssistantService voiceService, ThemeData theme) {
    String statusText;
    switch (voiceService.state) {
      case VoiceAssistantState.listening:
        statusText = voiceService.lastWords.isEmpty
            ? 'Listening...'
            : '"${voiceService.lastWords}"';
        break;
      case VoiceAssistantState.processing:
        statusText = 'Processing...';
        break;
      case VoiceAssistantState.speaking:
        statusText = 'Speaking...';
        break;
      case VoiceAssistantState.error:
        statusText = 'Error occurred';
        break;
      case VoiceAssistantState.permissionDenied:
        statusText = 'Microphone permission required';
        break;
      default:
        statusText = voiceService.lastWords.isEmpty
            ? 'Tap the microphone and speak'
            : '"${voiceService.lastWords}"';
    }

    return Container(
      constraints: const BoxConstraints(minHeight: 50),
      child: Text(
        statusText,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: voiceService.state == VoiceAssistantState.listening
              ? FontWeight.w600
              : FontWeight.normal,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildErrorWidget(VoiceAssistantService voiceService, ThemeData theme) {
    final isPermissionDenied = voiceService.state == VoiceAssistantState.permissionDenied;
    
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.expiredLight.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                isPermissionDenied ? Icons.mic_off : Icons.error_outline,
                color: AppColors.expiredLight,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  voiceService.errorMessage,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.expiredLight,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (isPermissionDenied)
          ElevatedButton.icon(
            onPressed: () => voiceService.openSettings(),
            icon: const Icon(Icons.settings, size: 18),
            label: const Text('Open Settings'),
          )
        else
          TextButton(
            onPressed: () {
              voiceService.clearError();
              voiceService.startListening();
            },
            child: const Text('Try Again'),
          ),
      ],
    );
  }

  Widget _buildHelpButton(VoiceAssistantService voiceService, ThemeData theme) {
    return TextButton.icon(
      onPressed: () {
        _showHelpDialog(voiceService);
      },
      icon: const Icon(Icons.help_outline, size: 18),
      label: const Text('What can I say?'),
    );
  }

  void _showHelpDialog(VoiceAssistantService voiceService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Voice Commands'),
        content: SingleChildScrollView(
          child: Text(
            voiceService.getHelpText(),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}

class VoiceAssistantFAB extends StatefulWidget {
  final Function(VoiceCommand) onCommand;

  const VoiceAssistantFAB({
    super.key,
    required this.onCommand,
  });

  @override
  State<VoiceAssistantFAB> createState() => _VoiceAssistantFABState();
}

class _VoiceAssistantFABState extends State<VoiceAssistantFAB> {
  bool _showOverlay = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (_showOverlay)
          Positioned.fill(
            child: VoiceAssistantOverlay(
              onClose: () => setState(() => _showOverlay = false),
              onCommand: (command) {
                setState(() => _showOverlay = false);
                widget.onCommand(command);
              },
            ),
          ),
        Positioned(
          right: 16,
          bottom: 16,
          child: VoiceAssistantButton(
            onPressed: () => setState(() => _showOverlay = !_showOverlay),
          ),
        ),
      ],
    );
  }
}
