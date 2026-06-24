import 'dart:io';

import 'package:flutter/material.dart';

class ProductImagePickerCard extends StatelessWidget {
  const ProductImagePickerCard({
    super.key,
    this.localImagePath,
    this.imageUrl,
    required this.onPickImage,
    this.onRemoveImage,
  });

  final String? localImagePath;
  final String? imageUrl;
  final VoidCallback onPickImage;
  final VoidCallback? onRemoveImage;

  @override
  Widget build(BuildContext context) {
    final previewPath = localImagePath?.trim();
    final remotePath = imageUrl?.trim();
    final hasLocalImage = previewPath != null && previewPath.isNotEmpty;
    final hasRemoteImage = remotePath != null && remotePath.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 16 / 10,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: DecoratedBox(
              decoration: const BoxDecoration(color: Color(0xFFFFF4F5)),
              child: hasLocalImage
                  ? Image.file(File(previewPath), fit: BoxFit.cover)
                  : hasRemoteImage
                  ? Image.network(
                      remotePath,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _placeholder();
                      },
                    )
                  : _placeholder(),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onPickImage,
                icon: const Icon(Icons.photo_library_outlined),
                label: Text(
                  hasLocalImage || hasRemoteImage ? 'Ganti Foto' : 'Pilih Foto',
                ),
              ),
            ),
            if (hasLocalImage || hasRemoteImage) ...[
              const SizedBox(width: 12),
              TextButton.icon(
                onPressed: onRemoveImage,
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('Hapus'),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'Gunakan foto produk yang jelas agar tampil rapi di katalog pelanggan.',
          style: TextStyle(color: Color(0xFF6D5A58)),
        ),
      ],
    );
  }

  Widget _placeholder() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.image_outlined, size: 40, color: Color(0xFFD9001B)),
          SizedBox(height: 10),
          Text(
            'Belum ada foto produk',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
