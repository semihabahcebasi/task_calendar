import 'package:flutter/material.dart';

const List<String> avatarListesi = [
  'avatar_1',
  'avatar_2',
  'avatar_3',
  'avatar_4',
  'avatar_5',
  'avatar_6',
];

class AvatarPicker extends StatefulWidget {
  final String secilenAvatar;
  final Function(String) onAvatarSec;

  const AvatarPicker({
    super.key,
    required this.secilenAvatar,
    required this.onAvatarSec,
  });

  @override
  State<AvatarPicker> createState() => _AvatarPickerState();
}

class _AvatarPickerState extends State<AvatarPicker> {
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: avatarListesi.length,
      itemBuilder: (context, index) {
        final avatar = avatarListesi[index];
        final secili = avatar == widget.secilenAvatar;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => widget.onAvatarSec(avatar),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: secili ? Colors.blue : Colors.transparent,
                width: 3,
              ),
            ),
            child: CircleAvatar(
              backgroundImage: AssetImage('assets/avatars/$avatar.png'),
            ),
          ),
        );
      },
    );
  }
}
