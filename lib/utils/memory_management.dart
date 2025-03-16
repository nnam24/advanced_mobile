import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// A utility class for managing memory in the application
class MemoryManager {
  static final MemoryManager _instance = MemoryManager._internal();

  factory MemoryManager() {
    return _instance;
  }

  MemoryManager._internal();

  final List<VoidCallback> _lowMemoryCallbacks = [];
  Timer? _gcTimer;

  /// Initialize the memory manager
  void initialize() {
    // Set up periodic garbage collection in debug mode
    if (kDebugMode) {
      _gcTimer = Timer.periodic(const Duration(minutes: 2), (_) {
        collectGarbage();
      });
    }

    // Listen for low memory warnings on the platform
    // This would typically use platform channels in a real app
    // For this example, we'll simulate it with a timer
    Timer.periodic(const Duration(minutes: 5), (_) {
      // Simulate a low memory warning
      if (kDebugMode && DateTime.now().second % 10 == 0) {
        _notifyLowMemory();
      }
    });
  }

  /// Register a callback to be called when memory is low
  void registerLowMemoryCallback(VoidCallback callback) {
    _lowMemoryCallbacks.add(callback);
  }

  /// Unregister a low memory callback
  void unregisterLowMemoryCallback(VoidCallback callback) {
    _lowMemoryCallbacks.remove(callback);
  }

  /// Notify all registered callbacks of low memory
  void _notifyLowMemory() {
    for (final callback in _lowMemoryCallbacks) {
      callback();
    }
  }

  /// Manually trigger garbage collection
  void collectGarbage() {
    // In a real app, you might want to use the GC API if available
    // or implement platform-specific memory cleanup
    if (kDebugMode) {
      debugPrint('🧹 Manual garbage collection triggered');
    }
  }

  /// Clear image caches
  void clearImageCache() {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  }

  // Add a method to optimize memory usage during heavy operations
  void optimizeForHeavyOperation() {
    // Clear image cache
    clearImageCache();

    // Trigger garbage collection in debug mode
    if (kDebugMode) {
      collectGarbage();
    }

    // Reduce memory pressure by clearing any unnecessary caches
    // This is a placeholder for app-specific cache clearing
  }

  // Add a method to handle low memory situations more aggressively
  void handleLowMemory() {
    // Clear all caches
    clearImageCache();

    // Notify all registered callbacks
    _notifyLowMemory();

    // Force garbage collection in debug mode
    if (kDebugMode) {
      collectGarbage();
    }
  }

  /// Dispose the memory manager
  void dispose() {
    _gcTimer?.cancel();
    _lowMemoryCallbacks.clear();
  }
}

/// A widget that automatically manages memory
class MemoryAwareWidget extends StatefulWidget {
  final Widget child;
  final VoidCallback? onLowMemory;

  const MemoryAwareWidget({
    super.key,
    required this.child,
    this.onLowMemory,
  });

  @override
  State<MemoryAwareWidget> createState() => _MemoryAwareWidgetState();
}

class _MemoryAwareWidgetState extends State<MemoryAwareWidget>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    if (widget.onLowMemory != null) {
      MemoryManager().registerLowMemoryCallback(widget.onLowMemory!);
    }
  }

  @override
  void didUpdateWidget(MemoryAwareWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.onLowMemory != widget.onLowMemory) {
      if (oldWidget.onLowMemory != null) {
        MemoryManager().unregisterLowMemoryCallback(oldWidget.onLowMemory!);
      }

      if (widget.onLowMemory != null) {
        MemoryManager().registerLowMemoryCallback(widget.onLowMemory!);
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // App is in background, free up resources
      MemoryManager().clearImageCache();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    if (widget.onLowMemory != null) {
      MemoryManager().unregisterLowMemoryCallback(widget.onLowMemory!);
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
