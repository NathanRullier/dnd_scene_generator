import 'package:flutter/foundation.dart';

enum ModelType { whisper, llm, stableDiffusion }

enum DownloadStatus { notDownloaded, downloading, downloaded, error }

@immutable
class ModelInfo {
  final String id;
  final String name;
  final String description;
  final ModelType type;
  final String downloadUrl;
  final String fileName;
  final int sizeBytes;
  final DownloadStatus status;
  final double downloadProgress;
  final String? localPath;
  final String qualityTier;

  const ModelInfo({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.downloadUrl,
    required this.fileName,
    required this.sizeBytes,
    this.status = DownloadStatus.notDownloaded,
    this.downloadProgress = 0.0,
    this.localPath,
    this.qualityTier = 'medium',
  });

  String get sizeLabel {
    if (sizeBytes >= 1024 * 1024 * 1024) {
      return '${(sizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(0)} MB';
  }

  ModelInfo copyWith({
    DownloadStatus? status,
    double? downloadProgress,
    String? localPath,
  }) {
    return ModelInfo(
      id: id,
      name: name,
      description: description,
      type: type,
      downloadUrl: downloadUrl,
      fileName: fileName,
      sizeBytes: sizeBytes,
      status: status ?? this.status,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      localPath: localPath ?? this.localPath,
      qualityTier: qualityTier,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'type': type.index,
        'downloadUrl': downloadUrl,
        'fileName': fileName,
        'sizeBytes': sizeBytes,
        'status': status.index,
        'downloadProgress': downloadProgress,
        'localPath': localPath,
        'qualityTier': qualityTier,
      };

  factory ModelInfo.fromJson(Map<String, dynamic> json) => ModelInfo(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String,
        type: ModelType.values[json['type'] as int],
        downloadUrl: json['downloadUrl'] as String,
        fileName: json['fileName'] as String,
        sizeBytes: json['sizeBytes'] as int,
        status: DownloadStatus.values[json['status'] as int? ?? 0],
        downloadProgress: (json['downloadProgress'] as num?)?.toDouble() ?? 0.0,
        localPath: json['localPath'] as String?,
        qualityTier: json['qualityTier'] as String? ?? 'medium',
      );
}
