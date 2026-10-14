import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:media_kit_video/media_kit_video.dart';

/// Desktop keeps the whole scene, with a blurred copy filling spare space.
class SceneBackground extends StatelessWidget {
  const SceneBackground({
    super.key,
    required this.preview,
    required this.desktop,
    this.video,
  });

  final ImageProvider<Object> preview;
  final bool desktop;
  final VideoController? video;

  Widget _layer(BoxFit fit, Key key) {
    if (video != null) {
      return Video(
        key: key,
        controller: video!,
        fit: fit,
        fill: const Color(0x00000000),
        controls: NoVideoControls,
      );
    }
    return Image(
      key: key,
      image: preview,
      fit: fit,
      errorBuilder: (_, error, stack) => const Align(
        alignment: Alignment.bottomLeft,
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            '背景无法读取，请重新导入',
            style: TextStyle(color: Color(0xFFFFFFFF)),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!desktop) {
      return _layer(BoxFit.cover, const Key('scene-foreground'));
    }
    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 26, sigmaY: 26),
            child: Transform.scale(
              scale: 1.12,
              child: _layer(BoxFit.cover, const Key('scene-blurred-fill')),
            ),
          ),
          _layer(BoxFit.contain, const Key('scene-foreground')),
        ],
      ),
    );
  }
}
