// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $MemoriesTable extends Memories with TableInfo<$MemoriesTable, Memory> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MemoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _embeddingMeta = const VerificationMeta(
    'embedding',
  );
  @override
  late final GeneratedColumn<String> embedding = GeneratedColumn<String>(
    'embedding',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _originalPathMeta = const VerificationMeta(
    'originalPath',
  );
  @override
  late final GeneratedColumn<String> originalPath = GeneratedColumn<String>(
    'original_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _visionCaptionMeta = const VerificationMeta(
    'visionCaption',
  );
  @override
  late final GeneratedColumn<String> visionCaption = GeneratedColumn<String>(
    'vision_caption',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _visionSceneMeta = const VerificationMeta(
    'visionScene',
  );
  @override
  late final GeneratedColumn<String> visionScene = GeneratedColumn<String>(
    'vision_scene',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _visionObjectsMeta = const VerificationMeta(
    'visionObjects',
  );
  @override
  late final GeneratedColumn<String> visionObjects = GeneratedColumn<String>(
    'vision_objects',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _visionKeywordsMeta = const VerificationMeta(
    'visionKeywords',
  );
  @override
  late final GeneratedColumn<String> visionKeywords = GeneratedColumn<String>(
    'vision_keywords',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _visionColorsMeta = const VerificationMeta(
    'visionColors',
  );
  @override
  late final GeneratedColumn<String> visionColors = GeneratedColumn<String>(
    'vision_colors',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _visionModelMeta = const VerificationMeta(
    'visionModel',
  );
  @override
  late final GeneratedColumn<String> visionModel = GeneratedColumn<String>(
    'vision_model',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _visionImageHashMeta = const VerificationMeta(
    'visionImageHash',
  );
  @override
  late final GeneratedColumn<String> visionImageHash = GeneratedColumn<String>(
    'vision_image_hash',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _visionProcessedAtMeta = const VerificationMeta(
    'visionProcessedAt',
  );
  @override
  late final GeneratedColumn<DateTime> visionProcessedAt =
      GeneratedColumn<DateTime>(
        'vision_processed_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _isFavoriteMeta = const VerificationMeta(
    'isFavorite',
  );
  @override
  late final GeneratedColumn<bool> isFavorite = GeneratedColumn<bool>(
    'is_favorite',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_favorite" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    type,
    title,
    content,
    embedding,
    originalPath,
    visionCaption,
    visionScene,
    visionObjects,
    visionKeywords,
    visionColors,
    visionModel,
    visionImageHash,
    visionProcessedAt,
    isFavorite,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'memories';
  @override
  VerificationContext validateIntegrity(
    Insertable<Memory> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    }
    if (data.containsKey('embedding')) {
      context.handle(
        _embeddingMeta,
        embedding.isAcceptableOrUnknown(data['embedding']!, _embeddingMeta),
      );
    }
    if (data.containsKey('original_path')) {
      context.handle(
        _originalPathMeta,
        originalPath.isAcceptableOrUnknown(
          data['original_path']!,
          _originalPathMeta,
        ),
      );
    }
    if (data.containsKey('vision_caption')) {
      context.handle(
        _visionCaptionMeta,
        visionCaption.isAcceptableOrUnknown(
          data['vision_caption']!,
          _visionCaptionMeta,
        ),
      );
    }
    if (data.containsKey('vision_scene')) {
      context.handle(
        _visionSceneMeta,
        visionScene.isAcceptableOrUnknown(
          data['vision_scene']!,
          _visionSceneMeta,
        ),
      );
    }
    if (data.containsKey('vision_objects')) {
      context.handle(
        _visionObjectsMeta,
        visionObjects.isAcceptableOrUnknown(
          data['vision_objects']!,
          _visionObjectsMeta,
        ),
      );
    }
    if (data.containsKey('vision_keywords')) {
      context.handle(
        _visionKeywordsMeta,
        visionKeywords.isAcceptableOrUnknown(
          data['vision_keywords']!,
          _visionKeywordsMeta,
        ),
      );
    }
    if (data.containsKey('vision_colors')) {
      context.handle(
        _visionColorsMeta,
        visionColors.isAcceptableOrUnknown(
          data['vision_colors']!,
          _visionColorsMeta,
        ),
      );
    }
    if (data.containsKey('vision_model')) {
      context.handle(
        _visionModelMeta,
        visionModel.isAcceptableOrUnknown(
          data['vision_model']!,
          _visionModelMeta,
        ),
      );
    }
    if (data.containsKey('vision_image_hash')) {
      context.handle(
        _visionImageHashMeta,
        visionImageHash.isAcceptableOrUnknown(
          data['vision_image_hash']!,
          _visionImageHashMeta,
        ),
      );
    }
    if (data.containsKey('vision_processed_at')) {
      context.handle(
        _visionProcessedAtMeta,
        visionProcessedAt.isAcceptableOrUnknown(
          data['vision_processed_at']!,
          _visionProcessedAtMeta,
        ),
      );
    }
    if (data.containsKey('is_favorite')) {
      context.handle(
        _isFavoriteMeta,
        isFavorite.isAcceptableOrUnknown(data['is_favorite']!, _isFavoriteMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Memory map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Memory(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      ),
      embedding: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}embedding'],
      ),
      originalPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}original_path'],
      ),
      visionCaption: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}vision_caption'],
      ),
      visionScene: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}vision_scene'],
      ),
      visionObjects: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}vision_objects'],
      ),
      visionKeywords: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}vision_keywords'],
      ),
      visionColors: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}vision_colors'],
      ),
      visionModel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}vision_model'],
      ),
      visionImageHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}vision_image_hash'],
      ),
      visionProcessedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}vision_processed_at'],
      ),
      isFavorite: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_favorite'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $MemoriesTable createAlias(String alias) {
    return $MemoriesTable(attachedDatabase, alias);
  }
}

class Memory extends DataClass implements Insertable<Memory> {
  final String id;
  final String type;
  final String title;
  final String? content;
  final String? embedding;
  final String? originalPath;
  final String? visionCaption;
  final String? visionScene;
  final String? visionObjects;
  final String? visionKeywords;
  final String? visionColors;
  final String? visionModel;
  final String? visionImageHash;
  final DateTime? visionProcessedAt;
  final bool isFavorite;
  final DateTime createdAt;
  const Memory({
    required this.id,
    required this.type,
    required this.title,
    this.content,
    this.embedding,
    this.originalPath,
    this.visionCaption,
    this.visionScene,
    this.visionObjects,
    this.visionKeywords,
    this.visionColors,
    this.visionModel,
    this.visionImageHash,
    this.visionProcessedAt,
    required this.isFavorite,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['type'] = Variable<String>(type);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || content != null) {
      map['content'] = Variable<String>(content);
    }
    if (!nullToAbsent || embedding != null) {
      map['embedding'] = Variable<String>(embedding);
    }
    if (!nullToAbsent || originalPath != null) {
      map['original_path'] = Variable<String>(originalPath);
    }
    if (!nullToAbsent || visionCaption != null) {
      map['vision_caption'] = Variable<String>(visionCaption);
    }
    if (!nullToAbsent || visionScene != null) {
      map['vision_scene'] = Variable<String>(visionScene);
    }
    if (!nullToAbsent || visionObjects != null) {
      map['vision_objects'] = Variable<String>(visionObjects);
    }
    if (!nullToAbsent || visionKeywords != null) {
      map['vision_keywords'] = Variable<String>(visionKeywords);
    }
    if (!nullToAbsent || visionColors != null) {
      map['vision_colors'] = Variable<String>(visionColors);
    }
    if (!nullToAbsent || visionModel != null) {
      map['vision_model'] = Variable<String>(visionModel);
    }
    if (!nullToAbsent || visionImageHash != null) {
      map['vision_image_hash'] = Variable<String>(visionImageHash);
    }
    if (!nullToAbsent || visionProcessedAt != null) {
      map['vision_processed_at'] = Variable<DateTime>(visionProcessedAt);
    }
    map['is_favorite'] = Variable<bool>(isFavorite);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  MemoriesCompanion toCompanion(bool nullToAbsent) {
    return MemoriesCompanion(
      id: Value(id),
      type: Value(type),
      title: Value(title),
      content: content == null && nullToAbsent
          ? const Value.absent()
          : Value(content),
      embedding: embedding == null && nullToAbsent
          ? const Value.absent()
          : Value(embedding),
      originalPath: originalPath == null && nullToAbsent
          ? const Value.absent()
          : Value(originalPath),
      visionCaption: visionCaption == null && nullToAbsent
          ? const Value.absent()
          : Value(visionCaption),
      visionScene: visionScene == null && nullToAbsent
          ? const Value.absent()
          : Value(visionScene),
      visionObjects: visionObjects == null && nullToAbsent
          ? const Value.absent()
          : Value(visionObjects),
      visionKeywords: visionKeywords == null && nullToAbsent
          ? const Value.absent()
          : Value(visionKeywords),
      visionColors: visionColors == null && nullToAbsent
          ? const Value.absent()
          : Value(visionColors),
      visionModel: visionModel == null && nullToAbsent
          ? const Value.absent()
          : Value(visionModel),
      visionImageHash: visionImageHash == null && nullToAbsent
          ? const Value.absent()
          : Value(visionImageHash),
      visionProcessedAt: visionProcessedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(visionProcessedAt),
      isFavorite: Value(isFavorite),
      createdAt: Value(createdAt),
    );
  }

  factory Memory.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Memory(
      id: serializer.fromJson<String>(json['id']),
      type: serializer.fromJson<String>(json['type']),
      title: serializer.fromJson<String>(json['title']),
      content: serializer.fromJson<String?>(json['content']),
      embedding: serializer.fromJson<String?>(json['embedding']),
      originalPath: serializer.fromJson<String?>(json['originalPath']),
      visionCaption: serializer.fromJson<String?>(json['visionCaption']),
      visionScene: serializer.fromJson<String?>(json['visionScene']),
      visionObjects: serializer.fromJson<String?>(json['visionObjects']),
      visionKeywords: serializer.fromJson<String?>(json['visionKeywords']),
      visionColors: serializer.fromJson<String?>(json['visionColors']),
      visionModel: serializer.fromJson<String?>(json['visionModel']),
      visionImageHash: serializer.fromJson<String?>(json['visionImageHash']),
      visionProcessedAt: serializer.fromJson<DateTime?>(
        json['visionProcessedAt'],
      ),
      isFavorite: serializer.fromJson<bool>(json['isFavorite']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'type': serializer.toJson<String>(type),
      'title': serializer.toJson<String>(title),
      'content': serializer.toJson<String?>(content),
      'embedding': serializer.toJson<String?>(embedding),
      'originalPath': serializer.toJson<String?>(originalPath),
      'visionCaption': serializer.toJson<String?>(visionCaption),
      'visionScene': serializer.toJson<String?>(visionScene),
      'visionObjects': serializer.toJson<String?>(visionObjects),
      'visionKeywords': serializer.toJson<String?>(visionKeywords),
      'visionColors': serializer.toJson<String?>(visionColors),
      'visionModel': serializer.toJson<String?>(visionModel),
      'visionImageHash': serializer.toJson<String?>(visionImageHash),
      'visionProcessedAt': serializer.toJson<DateTime?>(visionProcessedAt),
      'isFavorite': serializer.toJson<bool>(isFavorite),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Memory copyWith({
    String? id,
    String? type,
    String? title,
    Value<String?> content = const Value.absent(),
    Value<String?> embedding = const Value.absent(),
    Value<String?> originalPath = const Value.absent(),
    Value<String?> visionCaption = const Value.absent(),
    Value<String?> visionScene = const Value.absent(),
    Value<String?> visionObjects = const Value.absent(),
    Value<String?> visionKeywords = const Value.absent(),
    Value<String?> visionColors = const Value.absent(),
    Value<String?> visionModel = const Value.absent(),
    Value<String?> visionImageHash = const Value.absent(),
    Value<DateTime?> visionProcessedAt = const Value.absent(),
    bool? isFavorite,
    DateTime? createdAt,
  }) => Memory(
    id: id ?? this.id,
    type: type ?? this.type,
    title: title ?? this.title,
    content: content.present ? content.value : this.content,
    embedding: embedding.present ? embedding.value : this.embedding,
    originalPath: originalPath.present ? originalPath.value : this.originalPath,
    visionCaption: visionCaption.present
        ? visionCaption.value
        : this.visionCaption,
    visionScene: visionScene.present ? visionScene.value : this.visionScene,
    visionObjects: visionObjects.present
        ? visionObjects.value
        : this.visionObjects,
    visionKeywords: visionKeywords.present
        ? visionKeywords.value
        : this.visionKeywords,
    visionColors: visionColors.present ? visionColors.value : this.visionColors,
    visionModel: visionModel.present ? visionModel.value : this.visionModel,
    visionImageHash: visionImageHash.present
        ? visionImageHash.value
        : this.visionImageHash,
    visionProcessedAt: visionProcessedAt.present
        ? visionProcessedAt.value
        : this.visionProcessedAt,
    isFavorite: isFavorite ?? this.isFavorite,
    createdAt: createdAt ?? this.createdAt,
  );
  Memory copyWithCompanion(MemoriesCompanion data) {
    return Memory(
      id: data.id.present ? data.id.value : this.id,
      type: data.type.present ? data.type.value : this.type,
      title: data.title.present ? data.title.value : this.title,
      content: data.content.present ? data.content.value : this.content,
      embedding: data.embedding.present ? data.embedding.value : this.embedding,
      originalPath: data.originalPath.present
          ? data.originalPath.value
          : this.originalPath,
      visionCaption: data.visionCaption.present
          ? data.visionCaption.value
          : this.visionCaption,
      visionScene: data.visionScene.present
          ? data.visionScene.value
          : this.visionScene,
      visionObjects: data.visionObjects.present
          ? data.visionObjects.value
          : this.visionObjects,
      visionKeywords: data.visionKeywords.present
          ? data.visionKeywords.value
          : this.visionKeywords,
      visionColors: data.visionColors.present
          ? data.visionColors.value
          : this.visionColors,
      visionModel: data.visionModel.present
          ? data.visionModel.value
          : this.visionModel,
      visionImageHash: data.visionImageHash.present
          ? data.visionImageHash.value
          : this.visionImageHash,
      visionProcessedAt: data.visionProcessedAt.present
          ? data.visionProcessedAt.value
          : this.visionProcessedAt,
      isFavorite: data.isFavorite.present
          ? data.isFavorite.value
          : this.isFavorite,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Memory(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('title: $title, ')
          ..write('content: $content, ')
          ..write('embedding: $embedding, ')
          ..write('originalPath: $originalPath, ')
          ..write('visionCaption: $visionCaption, ')
          ..write('visionScene: $visionScene, ')
          ..write('visionObjects: $visionObjects, ')
          ..write('visionKeywords: $visionKeywords, ')
          ..write('visionColors: $visionColors, ')
          ..write('visionModel: $visionModel, ')
          ..write('visionImageHash: $visionImageHash, ')
          ..write('visionProcessedAt: $visionProcessedAt, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    type,
    title,
    content,
    embedding,
    originalPath,
    visionCaption,
    visionScene,
    visionObjects,
    visionKeywords,
    visionColors,
    visionModel,
    visionImageHash,
    visionProcessedAt,
    isFavorite,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Memory &&
          other.id == this.id &&
          other.type == this.type &&
          other.title == this.title &&
          other.content == this.content &&
          other.embedding == this.embedding &&
          other.originalPath == this.originalPath &&
          other.visionCaption == this.visionCaption &&
          other.visionScene == this.visionScene &&
          other.visionObjects == this.visionObjects &&
          other.visionKeywords == this.visionKeywords &&
          other.visionColors == this.visionColors &&
          other.visionModel == this.visionModel &&
          other.visionImageHash == this.visionImageHash &&
          other.visionProcessedAt == this.visionProcessedAt &&
          other.isFavorite == this.isFavorite &&
          other.createdAt == this.createdAt);
}

class MemoriesCompanion extends UpdateCompanion<Memory> {
  final Value<String> id;
  final Value<String> type;
  final Value<String> title;
  final Value<String?> content;
  final Value<String?> embedding;
  final Value<String?> originalPath;
  final Value<String?> visionCaption;
  final Value<String?> visionScene;
  final Value<String?> visionObjects;
  final Value<String?> visionKeywords;
  final Value<String?> visionColors;
  final Value<String?> visionModel;
  final Value<String?> visionImageHash;
  final Value<DateTime?> visionProcessedAt;
  final Value<bool> isFavorite;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const MemoriesCompanion({
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.title = const Value.absent(),
    this.content = const Value.absent(),
    this.embedding = const Value.absent(),
    this.originalPath = const Value.absent(),
    this.visionCaption = const Value.absent(),
    this.visionScene = const Value.absent(),
    this.visionObjects = const Value.absent(),
    this.visionKeywords = const Value.absent(),
    this.visionColors = const Value.absent(),
    this.visionModel = const Value.absent(),
    this.visionImageHash = const Value.absent(),
    this.visionProcessedAt = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MemoriesCompanion.insert({
    required String id,
    required String type,
    required String title,
    this.content = const Value.absent(),
    this.embedding = const Value.absent(),
    this.originalPath = const Value.absent(),
    this.visionCaption = const Value.absent(),
    this.visionScene = const Value.absent(),
    this.visionObjects = const Value.absent(),
    this.visionKeywords = const Value.absent(),
    this.visionColors = const Value.absent(),
    this.visionModel = const Value.absent(),
    this.visionImageHash = const Value.absent(),
    this.visionProcessedAt = const Value.absent(),
    this.isFavorite = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       type = Value(type),
       title = Value(title),
       createdAt = Value(createdAt);
  static Insertable<Memory> custom({
    Expression<String>? id,
    Expression<String>? type,
    Expression<String>? title,
    Expression<String>? content,
    Expression<String>? embedding,
    Expression<String>? originalPath,
    Expression<String>? visionCaption,
    Expression<String>? visionScene,
    Expression<String>? visionObjects,
    Expression<String>? visionKeywords,
    Expression<String>? visionColors,
    Expression<String>? visionModel,
    Expression<String>? visionImageHash,
    Expression<DateTime>? visionProcessedAt,
    Expression<bool>? isFavorite,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (title != null) 'title': title,
      if (content != null) 'content': content,
      if (embedding != null) 'embedding': embedding,
      if (originalPath != null) 'original_path': originalPath,
      if (visionCaption != null) 'vision_caption': visionCaption,
      if (visionScene != null) 'vision_scene': visionScene,
      if (visionObjects != null) 'vision_objects': visionObjects,
      if (visionKeywords != null) 'vision_keywords': visionKeywords,
      if (visionColors != null) 'vision_colors': visionColors,
      if (visionModel != null) 'vision_model': visionModel,
      if (visionImageHash != null) 'vision_image_hash': visionImageHash,
      if (visionProcessedAt != null) 'vision_processed_at': visionProcessedAt,
      if (isFavorite != null) 'is_favorite': isFavorite,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MemoriesCompanion copyWith({
    Value<String>? id,
    Value<String>? type,
    Value<String>? title,
    Value<String?>? content,
    Value<String?>? embedding,
    Value<String?>? originalPath,
    Value<String?>? visionCaption,
    Value<String?>? visionScene,
    Value<String?>? visionObjects,
    Value<String?>? visionKeywords,
    Value<String?>? visionColors,
    Value<String?>? visionModel,
    Value<String?>? visionImageHash,
    Value<DateTime?>? visionProcessedAt,
    Value<bool>? isFavorite,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return MemoriesCompanion(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      content: content ?? this.content,
      embedding: embedding ?? this.embedding,
      originalPath: originalPath ?? this.originalPath,
      visionCaption: visionCaption ?? this.visionCaption,
      visionScene: visionScene ?? this.visionScene,
      visionObjects: visionObjects ?? this.visionObjects,
      visionKeywords: visionKeywords ?? this.visionKeywords,
      visionColors: visionColors ?? this.visionColors,
      visionModel: visionModel ?? this.visionModel,
      visionImageHash: visionImageHash ?? this.visionImageHash,
      visionProcessedAt: visionProcessedAt ?? this.visionProcessedAt,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (embedding.present) {
      map['embedding'] = Variable<String>(embedding.value);
    }
    if (originalPath.present) {
      map['original_path'] = Variable<String>(originalPath.value);
    }
    if (visionCaption.present) {
      map['vision_caption'] = Variable<String>(visionCaption.value);
    }
    if (visionScene.present) {
      map['vision_scene'] = Variable<String>(visionScene.value);
    }
    if (visionObjects.present) {
      map['vision_objects'] = Variable<String>(visionObjects.value);
    }
    if (visionKeywords.present) {
      map['vision_keywords'] = Variable<String>(visionKeywords.value);
    }
    if (visionColors.present) {
      map['vision_colors'] = Variable<String>(visionColors.value);
    }
    if (visionModel.present) {
      map['vision_model'] = Variable<String>(visionModel.value);
    }
    if (visionImageHash.present) {
      map['vision_image_hash'] = Variable<String>(visionImageHash.value);
    }
    if (visionProcessedAt.present) {
      map['vision_processed_at'] = Variable<DateTime>(visionProcessedAt.value);
    }
    if (isFavorite.present) {
      map['is_favorite'] = Variable<bool>(isFavorite.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MemoriesCompanion(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('title: $title, ')
          ..write('content: $content, ')
          ..write('embedding: $embedding, ')
          ..write('originalPath: $originalPath, ')
          ..write('visionCaption: $visionCaption, ')
          ..write('visionScene: $visionScene, ')
          ..write('visionObjects: $visionObjects, ')
          ..write('visionKeywords: $visionKeywords, ')
          ..write('visionColors: $visionColors, ')
          ..write('visionModel: $visionModel, ')
          ..write('visionImageHash: $visionImageHash, ')
          ..write('visionProcessedAt: $visionProcessedAt, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PeopleTable extends People with TableInfo<$PeopleTable, PeopleData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PeopleTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _coverFacePathMeta = const VerificationMeta(
    'coverFacePath',
  );
  @override
  late final GeneratedColumn<String> coverFacePath = GeneratedColumn<String>(
    'cover_face_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _clusterIdMeta = const VerificationMeta(
    'clusterId',
  );
  @override
  late final GeneratedColumn<String> clusterId = GeneratedColumn<String>(
    'cluster_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    coverFacePath,
    clusterId,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'people';
  @override
  VerificationContext validateIntegrity(
    Insertable<PeopleData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    if (data.containsKey('cover_face_path')) {
      context.handle(
        _coverFacePathMeta,
        coverFacePath.isAcceptableOrUnknown(
          data['cover_face_path']!,
          _coverFacePathMeta,
        ),
      );
    }
    if (data.containsKey('cluster_id')) {
      context.handle(
        _clusterIdMeta,
        clusterId.isAcceptableOrUnknown(data['cluster_id']!, _clusterIdMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PeopleData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PeopleData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      ),
      coverFacePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cover_face_path'],
      ),
      clusterId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cluster_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $PeopleTable createAlias(String alias) {
    return $PeopleTable(attachedDatabase, alias);
  }
}

class PeopleData extends DataClass implements Insertable<PeopleData> {
  final String id;
  final String? name;
  final String? coverFacePath;
  final String? clusterId;
  final DateTime createdAt;
  final DateTime updatedAt;
  const PeopleData({
    required this.id,
    this.name,
    this.coverFacePath,
    this.clusterId,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name);
    }
    if (!nullToAbsent || coverFacePath != null) {
      map['cover_face_path'] = Variable<String>(coverFacePath);
    }
    if (!nullToAbsent || clusterId != null) {
      map['cluster_id'] = Variable<String>(clusterId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  PeopleCompanion toCompanion(bool nullToAbsent) {
    return PeopleCompanion(
      id: Value(id),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
      coverFacePath: coverFacePath == null && nullToAbsent
          ? const Value.absent()
          : Value(coverFacePath),
      clusterId: clusterId == null && nullToAbsent
          ? const Value.absent()
          : Value(clusterId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory PeopleData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PeopleData(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String?>(json['name']),
      coverFacePath: serializer.fromJson<String?>(json['coverFacePath']),
      clusterId: serializer.fromJson<String?>(json['clusterId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String?>(name),
      'coverFacePath': serializer.toJson<String?>(coverFacePath),
      'clusterId': serializer.toJson<String?>(clusterId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  PeopleData copyWith({
    String? id,
    Value<String?> name = const Value.absent(),
    Value<String?> coverFacePath = const Value.absent(),
    Value<String?> clusterId = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => PeopleData(
    id: id ?? this.id,
    name: name.present ? name.value : this.name,
    coverFacePath: coverFacePath.present
        ? coverFacePath.value
        : this.coverFacePath,
    clusterId: clusterId.present ? clusterId.value : this.clusterId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  PeopleData copyWithCompanion(PeopleCompanion data) {
    return PeopleData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      coverFacePath: data.coverFacePath.present
          ? data.coverFacePath.value
          : this.coverFacePath,
      clusterId: data.clusterId.present ? data.clusterId.value : this.clusterId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PeopleData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('coverFacePath: $coverFacePath, ')
          ..write('clusterId: $clusterId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, coverFacePath, clusterId, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PeopleData &&
          other.id == this.id &&
          other.name == this.name &&
          other.coverFacePath == this.coverFacePath &&
          other.clusterId == this.clusterId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class PeopleCompanion extends UpdateCompanion<PeopleData> {
  final Value<String> id;
  final Value<String?> name;
  final Value<String?> coverFacePath;
  final Value<String?> clusterId;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const PeopleCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.coverFacePath = const Value.absent(),
    this.clusterId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PeopleCompanion.insert({
    required String id,
    this.name = const Value.absent(),
    this.coverFacePath = const Value.absent(),
    this.clusterId = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<PeopleData> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? coverFacePath,
    Expression<String>? clusterId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (coverFacePath != null) 'cover_face_path': coverFacePath,
      if (clusterId != null) 'cluster_id': clusterId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PeopleCompanion copyWith({
    Value<String>? id,
    Value<String?>? name,
    Value<String?>? coverFacePath,
    Value<String?>? clusterId,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return PeopleCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      coverFacePath: coverFacePath ?? this.coverFacePath,
      clusterId: clusterId ?? this.clusterId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (coverFacePath.present) {
      map['cover_face_path'] = Variable<String>(coverFacePath.value);
    }
    if (clusterId.present) {
      map['cluster_id'] = Variable<String>(clusterId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PeopleCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('coverFacePath: $coverFacePath, ')
          ..write('clusterId: $clusterId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FaceEmbeddingsTable extends FaceEmbeddings
    with TableInfo<$FaceEmbeddingsTable, FaceEmbedding> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FaceEmbeddingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _memoryIdMeta = const VerificationMeta(
    'memoryId',
  );
  @override
  late final GeneratedColumn<String> memoryId = GeneratedColumn<String>(
    'memory_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES memories (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _personIdMeta = const VerificationMeta(
    'personId',
  );
  @override
  late final GeneratedColumn<String> personId = GeneratedColumn<String>(
    'person_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES people (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _embeddingMeta = const VerificationMeta(
    'embedding',
  );
  @override
  late final GeneratedColumn<String> embedding = GeneratedColumn<String>(
    'embedding',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _modelMeta = const VerificationMeta('model');
  @override
  late final GeneratedColumn<String> model = GeneratedColumn<String>(
    'model',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _embeddingDimensionMeta =
      const VerificationMeta('embeddingDimension');
  @override
  late final GeneratedColumn<int> embeddingDimension = GeneratedColumn<int>(
    'embedding_dimension',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _boundingLeftMeta = const VerificationMeta(
    'boundingLeft',
  );
  @override
  late final GeneratedColumn<double> boundingLeft = GeneratedColumn<double>(
    'bounding_left',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _boundingTopMeta = const VerificationMeta(
    'boundingTop',
  );
  @override
  late final GeneratedColumn<double> boundingTop = GeneratedColumn<double>(
    'bounding_top',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _boundingWidthMeta = const VerificationMeta(
    'boundingWidth',
  );
  @override
  late final GeneratedColumn<double> boundingWidth = GeneratedColumn<double>(
    'bounding_width',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _boundingHeightMeta = const VerificationMeta(
    'boundingHeight',
  );
  @override
  late final GeneratedColumn<double> boundingHeight = GeneratedColumn<double>(
    'bounding_height',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _detectionConfidenceMeta =
      const VerificationMeta('detectionConfidence');
  @override
  late final GeneratedColumn<double> detectionConfidence =
      GeneratedColumn<double>(
        'detection_confidence',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _faceCropPathMeta = const VerificationMeta(
    'faceCropPath',
  );
  @override
  late final GeneratedColumn<String> faceCropPath = GeneratedColumn<String>(
    'face_crop_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _faceHashMeta = const VerificationMeta(
    'faceHash',
  );
  @override
  late final GeneratedColumn<String> faceHash = GeneratedColumn<String>(
    'face_hash',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    memoryId,
    personId,
    embedding,
    model,
    embeddingDimension,
    boundingLeft,
    boundingTop,
    boundingWidth,
    boundingHeight,
    detectionConfidence,
    faceCropPath,
    faceHash,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'face_embeddings';
  @override
  VerificationContext validateIntegrity(
    Insertable<FaceEmbedding> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('memory_id')) {
      context.handle(
        _memoryIdMeta,
        memoryId.isAcceptableOrUnknown(data['memory_id']!, _memoryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_memoryIdMeta);
    }
    if (data.containsKey('person_id')) {
      context.handle(
        _personIdMeta,
        personId.isAcceptableOrUnknown(data['person_id']!, _personIdMeta),
      );
    }
    if (data.containsKey('embedding')) {
      context.handle(
        _embeddingMeta,
        embedding.isAcceptableOrUnknown(data['embedding']!, _embeddingMeta),
      );
    } else if (isInserting) {
      context.missing(_embeddingMeta);
    }
    if (data.containsKey('model')) {
      context.handle(
        _modelMeta,
        model.isAcceptableOrUnknown(data['model']!, _modelMeta),
      );
    } else if (isInserting) {
      context.missing(_modelMeta);
    }
    if (data.containsKey('embedding_dimension')) {
      context.handle(
        _embeddingDimensionMeta,
        embeddingDimension.isAcceptableOrUnknown(
          data['embedding_dimension']!,
          _embeddingDimensionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_embeddingDimensionMeta);
    }
    if (data.containsKey('bounding_left')) {
      context.handle(
        _boundingLeftMeta,
        boundingLeft.isAcceptableOrUnknown(
          data['bounding_left']!,
          _boundingLeftMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_boundingLeftMeta);
    }
    if (data.containsKey('bounding_top')) {
      context.handle(
        _boundingTopMeta,
        boundingTop.isAcceptableOrUnknown(
          data['bounding_top']!,
          _boundingTopMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_boundingTopMeta);
    }
    if (data.containsKey('bounding_width')) {
      context.handle(
        _boundingWidthMeta,
        boundingWidth.isAcceptableOrUnknown(
          data['bounding_width']!,
          _boundingWidthMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_boundingWidthMeta);
    }
    if (data.containsKey('bounding_height')) {
      context.handle(
        _boundingHeightMeta,
        boundingHeight.isAcceptableOrUnknown(
          data['bounding_height']!,
          _boundingHeightMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_boundingHeightMeta);
    }
    if (data.containsKey('detection_confidence')) {
      context.handle(
        _detectionConfidenceMeta,
        detectionConfidence.isAcceptableOrUnknown(
          data['detection_confidence']!,
          _detectionConfidenceMeta,
        ),
      );
    }
    if (data.containsKey('face_crop_path')) {
      context.handle(
        _faceCropPathMeta,
        faceCropPath.isAcceptableOrUnknown(
          data['face_crop_path']!,
          _faceCropPathMeta,
        ),
      );
    }
    if (data.containsKey('face_hash')) {
      context.handle(
        _faceHashMeta,
        faceHash.isAcceptableOrUnknown(data['face_hash']!, _faceHashMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FaceEmbedding map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FaceEmbedding(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      memoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}memory_id'],
      )!,
      personId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}person_id'],
      ),
      embedding: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}embedding'],
      )!,
      model: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model'],
      )!,
      embeddingDimension: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}embedding_dimension'],
      )!,
      boundingLeft: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}bounding_left'],
      )!,
      boundingTop: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}bounding_top'],
      )!,
      boundingWidth: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}bounding_width'],
      )!,
      boundingHeight: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}bounding_height'],
      )!,
      detectionConfidence: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}detection_confidence'],
      ),
      faceCropPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}face_crop_path'],
      ),
      faceHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}face_hash'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $FaceEmbeddingsTable createAlias(String alias) {
    return $FaceEmbeddingsTable(attachedDatabase, alias);
  }
}

class FaceEmbedding extends DataClass implements Insertable<FaceEmbedding> {
  final String id;
  final String memoryId;
  final String? personId;
  final String embedding;
  final String model;
  final int embeddingDimension;
  final double boundingLeft;
  final double boundingTop;
  final double boundingWidth;
  final double boundingHeight;
  final double? detectionConfidence;
  final String? faceCropPath;
  final String? faceHash;
  final DateTime createdAt;
  const FaceEmbedding({
    required this.id,
    required this.memoryId,
    this.personId,
    required this.embedding,
    required this.model,
    required this.embeddingDimension,
    required this.boundingLeft,
    required this.boundingTop,
    required this.boundingWidth,
    required this.boundingHeight,
    this.detectionConfidence,
    this.faceCropPath,
    this.faceHash,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['memory_id'] = Variable<String>(memoryId);
    if (!nullToAbsent || personId != null) {
      map['person_id'] = Variable<String>(personId);
    }
    map['embedding'] = Variable<String>(embedding);
    map['model'] = Variable<String>(model);
    map['embedding_dimension'] = Variable<int>(embeddingDimension);
    map['bounding_left'] = Variable<double>(boundingLeft);
    map['bounding_top'] = Variable<double>(boundingTop);
    map['bounding_width'] = Variable<double>(boundingWidth);
    map['bounding_height'] = Variable<double>(boundingHeight);
    if (!nullToAbsent || detectionConfidence != null) {
      map['detection_confidence'] = Variable<double>(detectionConfidence);
    }
    if (!nullToAbsent || faceCropPath != null) {
      map['face_crop_path'] = Variable<String>(faceCropPath);
    }
    if (!nullToAbsent || faceHash != null) {
      map['face_hash'] = Variable<String>(faceHash);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  FaceEmbeddingsCompanion toCompanion(bool nullToAbsent) {
    return FaceEmbeddingsCompanion(
      id: Value(id),
      memoryId: Value(memoryId),
      personId: personId == null && nullToAbsent
          ? const Value.absent()
          : Value(personId),
      embedding: Value(embedding),
      model: Value(model),
      embeddingDimension: Value(embeddingDimension),
      boundingLeft: Value(boundingLeft),
      boundingTop: Value(boundingTop),
      boundingWidth: Value(boundingWidth),
      boundingHeight: Value(boundingHeight),
      detectionConfidence: detectionConfidence == null && nullToAbsent
          ? const Value.absent()
          : Value(detectionConfidence),
      faceCropPath: faceCropPath == null && nullToAbsent
          ? const Value.absent()
          : Value(faceCropPath),
      faceHash: faceHash == null && nullToAbsent
          ? const Value.absent()
          : Value(faceHash),
      createdAt: Value(createdAt),
    );
  }

  factory FaceEmbedding.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FaceEmbedding(
      id: serializer.fromJson<String>(json['id']),
      memoryId: serializer.fromJson<String>(json['memoryId']),
      personId: serializer.fromJson<String?>(json['personId']),
      embedding: serializer.fromJson<String>(json['embedding']),
      model: serializer.fromJson<String>(json['model']),
      embeddingDimension: serializer.fromJson<int>(json['embeddingDimension']),
      boundingLeft: serializer.fromJson<double>(json['boundingLeft']),
      boundingTop: serializer.fromJson<double>(json['boundingTop']),
      boundingWidth: serializer.fromJson<double>(json['boundingWidth']),
      boundingHeight: serializer.fromJson<double>(json['boundingHeight']),
      detectionConfidence: serializer.fromJson<double?>(
        json['detectionConfidence'],
      ),
      faceCropPath: serializer.fromJson<String?>(json['faceCropPath']),
      faceHash: serializer.fromJson<String?>(json['faceHash']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'memoryId': serializer.toJson<String>(memoryId),
      'personId': serializer.toJson<String?>(personId),
      'embedding': serializer.toJson<String>(embedding),
      'model': serializer.toJson<String>(model),
      'embeddingDimension': serializer.toJson<int>(embeddingDimension),
      'boundingLeft': serializer.toJson<double>(boundingLeft),
      'boundingTop': serializer.toJson<double>(boundingTop),
      'boundingWidth': serializer.toJson<double>(boundingWidth),
      'boundingHeight': serializer.toJson<double>(boundingHeight),
      'detectionConfidence': serializer.toJson<double?>(detectionConfidence),
      'faceCropPath': serializer.toJson<String?>(faceCropPath),
      'faceHash': serializer.toJson<String?>(faceHash),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  FaceEmbedding copyWith({
    String? id,
    String? memoryId,
    Value<String?> personId = const Value.absent(),
    String? embedding,
    String? model,
    int? embeddingDimension,
    double? boundingLeft,
    double? boundingTop,
    double? boundingWidth,
    double? boundingHeight,
    Value<double?> detectionConfidence = const Value.absent(),
    Value<String?> faceCropPath = const Value.absent(),
    Value<String?> faceHash = const Value.absent(),
    DateTime? createdAt,
  }) => FaceEmbedding(
    id: id ?? this.id,
    memoryId: memoryId ?? this.memoryId,
    personId: personId.present ? personId.value : this.personId,
    embedding: embedding ?? this.embedding,
    model: model ?? this.model,
    embeddingDimension: embeddingDimension ?? this.embeddingDimension,
    boundingLeft: boundingLeft ?? this.boundingLeft,
    boundingTop: boundingTop ?? this.boundingTop,
    boundingWidth: boundingWidth ?? this.boundingWidth,
    boundingHeight: boundingHeight ?? this.boundingHeight,
    detectionConfidence: detectionConfidence.present
        ? detectionConfidence.value
        : this.detectionConfidence,
    faceCropPath: faceCropPath.present ? faceCropPath.value : this.faceCropPath,
    faceHash: faceHash.present ? faceHash.value : this.faceHash,
    createdAt: createdAt ?? this.createdAt,
  );
  FaceEmbedding copyWithCompanion(FaceEmbeddingsCompanion data) {
    return FaceEmbedding(
      id: data.id.present ? data.id.value : this.id,
      memoryId: data.memoryId.present ? data.memoryId.value : this.memoryId,
      personId: data.personId.present ? data.personId.value : this.personId,
      embedding: data.embedding.present ? data.embedding.value : this.embedding,
      model: data.model.present ? data.model.value : this.model,
      embeddingDimension: data.embeddingDimension.present
          ? data.embeddingDimension.value
          : this.embeddingDimension,
      boundingLeft: data.boundingLeft.present
          ? data.boundingLeft.value
          : this.boundingLeft,
      boundingTop: data.boundingTop.present
          ? data.boundingTop.value
          : this.boundingTop,
      boundingWidth: data.boundingWidth.present
          ? data.boundingWidth.value
          : this.boundingWidth,
      boundingHeight: data.boundingHeight.present
          ? data.boundingHeight.value
          : this.boundingHeight,
      detectionConfidence: data.detectionConfidence.present
          ? data.detectionConfidence.value
          : this.detectionConfidence,
      faceCropPath: data.faceCropPath.present
          ? data.faceCropPath.value
          : this.faceCropPath,
      faceHash: data.faceHash.present ? data.faceHash.value : this.faceHash,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FaceEmbedding(')
          ..write('id: $id, ')
          ..write('memoryId: $memoryId, ')
          ..write('personId: $personId, ')
          ..write('embedding: $embedding, ')
          ..write('model: $model, ')
          ..write('embeddingDimension: $embeddingDimension, ')
          ..write('boundingLeft: $boundingLeft, ')
          ..write('boundingTop: $boundingTop, ')
          ..write('boundingWidth: $boundingWidth, ')
          ..write('boundingHeight: $boundingHeight, ')
          ..write('detectionConfidence: $detectionConfidence, ')
          ..write('faceCropPath: $faceCropPath, ')
          ..write('faceHash: $faceHash, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    memoryId,
    personId,
    embedding,
    model,
    embeddingDimension,
    boundingLeft,
    boundingTop,
    boundingWidth,
    boundingHeight,
    detectionConfidence,
    faceCropPath,
    faceHash,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FaceEmbedding &&
          other.id == this.id &&
          other.memoryId == this.memoryId &&
          other.personId == this.personId &&
          other.embedding == this.embedding &&
          other.model == this.model &&
          other.embeddingDimension == this.embeddingDimension &&
          other.boundingLeft == this.boundingLeft &&
          other.boundingTop == this.boundingTop &&
          other.boundingWidth == this.boundingWidth &&
          other.boundingHeight == this.boundingHeight &&
          other.detectionConfidence == this.detectionConfidence &&
          other.faceCropPath == this.faceCropPath &&
          other.faceHash == this.faceHash &&
          other.createdAt == this.createdAt);
}

class FaceEmbeddingsCompanion extends UpdateCompanion<FaceEmbedding> {
  final Value<String> id;
  final Value<String> memoryId;
  final Value<String?> personId;
  final Value<String> embedding;
  final Value<String> model;
  final Value<int> embeddingDimension;
  final Value<double> boundingLeft;
  final Value<double> boundingTop;
  final Value<double> boundingWidth;
  final Value<double> boundingHeight;
  final Value<double?> detectionConfidence;
  final Value<String?> faceCropPath;
  final Value<String?> faceHash;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const FaceEmbeddingsCompanion({
    this.id = const Value.absent(),
    this.memoryId = const Value.absent(),
    this.personId = const Value.absent(),
    this.embedding = const Value.absent(),
    this.model = const Value.absent(),
    this.embeddingDimension = const Value.absent(),
    this.boundingLeft = const Value.absent(),
    this.boundingTop = const Value.absent(),
    this.boundingWidth = const Value.absent(),
    this.boundingHeight = const Value.absent(),
    this.detectionConfidence = const Value.absent(),
    this.faceCropPath = const Value.absent(),
    this.faceHash = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FaceEmbeddingsCompanion.insert({
    required String id,
    required String memoryId,
    this.personId = const Value.absent(),
    required String embedding,
    required String model,
    required int embeddingDimension,
    required double boundingLeft,
    required double boundingTop,
    required double boundingWidth,
    required double boundingHeight,
    this.detectionConfidence = const Value.absent(),
    this.faceCropPath = const Value.absent(),
    this.faceHash = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       memoryId = Value(memoryId),
       embedding = Value(embedding),
       model = Value(model),
       embeddingDimension = Value(embeddingDimension),
       boundingLeft = Value(boundingLeft),
       boundingTop = Value(boundingTop),
       boundingWidth = Value(boundingWidth),
       boundingHeight = Value(boundingHeight),
       createdAt = Value(createdAt);
  static Insertable<FaceEmbedding> custom({
    Expression<String>? id,
    Expression<String>? memoryId,
    Expression<String>? personId,
    Expression<String>? embedding,
    Expression<String>? model,
    Expression<int>? embeddingDimension,
    Expression<double>? boundingLeft,
    Expression<double>? boundingTop,
    Expression<double>? boundingWidth,
    Expression<double>? boundingHeight,
    Expression<double>? detectionConfidence,
    Expression<String>? faceCropPath,
    Expression<String>? faceHash,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (memoryId != null) 'memory_id': memoryId,
      if (personId != null) 'person_id': personId,
      if (embedding != null) 'embedding': embedding,
      if (model != null) 'model': model,
      if (embeddingDimension != null) 'embedding_dimension': embeddingDimension,
      if (boundingLeft != null) 'bounding_left': boundingLeft,
      if (boundingTop != null) 'bounding_top': boundingTop,
      if (boundingWidth != null) 'bounding_width': boundingWidth,
      if (boundingHeight != null) 'bounding_height': boundingHeight,
      if (detectionConfidence != null)
        'detection_confidence': detectionConfidence,
      if (faceCropPath != null) 'face_crop_path': faceCropPath,
      if (faceHash != null) 'face_hash': faceHash,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FaceEmbeddingsCompanion copyWith({
    Value<String>? id,
    Value<String>? memoryId,
    Value<String?>? personId,
    Value<String>? embedding,
    Value<String>? model,
    Value<int>? embeddingDimension,
    Value<double>? boundingLeft,
    Value<double>? boundingTop,
    Value<double>? boundingWidth,
    Value<double>? boundingHeight,
    Value<double?>? detectionConfidence,
    Value<String?>? faceCropPath,
    Value<String?>? faceHash,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return FaceEmbeddingsCompanion(
      id: id ?? this.id,
      memoryId: memoryId ?? this.memoryId,
      personId: personId ?? this.personId,
      embedding: embedding ?? this.embedding,
      model: model ?? this.model,
      embeddingDimension: embeddingDimension ?? this.embeddingDimension,
      boundingLeft: boundingLeft ?? this.boundingLeft,
      boundingTop: boundingTop ?? this.boundingTop,
      boundingWidth: boundingWidth ?? this.boundingWidth,
      boundingHeight: boundingHeight ?? this.boundingHeight,
      detectionConfidence: detectionConfidence ?? this.detectionConfidence,
      faceCropPath: faceCropPath ?? this.faceCropPath,
      faceHash: faceHash ?? this.faceHash,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (memoryId.present) {
      map['memory_id'] = Variable<String>(memoryId.value);
    }
    if (personId.present) {
      map['person_id'] = Variable<String>(personId.value);
    }
    if (embedding.present) {
      map['embedding'] = Variable<String>(embedding.value);
    }
    if (model.present) {
      map['model'] = Variable<String>(model.value);
    }
    if (embeddingDimension.present) {
      map['embedding_dimension'] = Variable<int>(embeddingDimension.value);
    }
    if (boundingLeft.present) {
      map['bounding_left'] = Variable<double>(boundingLeft.value);
    }
    if (boundingTop.present) {
      map['bounding_top'] = Variable<double>(boundingTop.value);
    }
    if (boundingWidth.present) {
      map['bounding_width'] = Variable<double>(boundingWidth.value);
    }
    if (boundingHeight.present) {
      map['bounding_height'] = Variable<double>(boundingHeight.value);
    }
    if (detectionConfidence.present) {
      map['detection_confidence'] = Variable<double>(detectionConfidence.value);
    }
    if (faceCropPath.present) {
      map['face_crop_path'] = Variable<String>(faceCropPath.value);
    }
    if (faceHash.present) {
      map['face_hash'] = Variable<String>(faceHash.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FaceEmbeddingsCompanion(')
          ..write('id: $id, ')
          ..write('memoryId: $memoryId, ')
          ..write('personId: $personId, ')
          ..write('embedding: $embedding, ')
          ..write('model: $model, ')
          ..write('embeddingDimension: $embeddingDimension, ')
          ..write('boundingLeft: $boundingLeft, ')
          ..write('boundingTop: $boundingTop, ')
          ..write('boundingWidth: $boundingWidth, ')
          ..write('boundingHeight: $boundingHeight, ')
          ..write('detectionConfidence: $detectionConfidence, ')
          ..write('faceCropPath: $faceCropPath, ')
          ..write('faceHash: $faceHash, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MemoryPeopleTable extends MemoryPeople
    with TableInfo<$MemoryPeopleTable, MemoryPeopleData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MemoryPeopleTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _memoryIdMeta = const VerificationMeta(
    'memoryId',
  );
  @override
  late final GeneratedColumn<String> memoryId = GeneratedColumn<String>(
    'memory_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES memories (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _personIdMeta = const VerificationMeta(
    'personId',
  );
  @override
  late final GeneratedColumn<String> personId = GeneratedColumn<String>(
    'person_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES people (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _similarityMeta = const VerificationMeta(
    'similarity',
  );
  @override
  late final GeneratedColumn<double> similarity = GeneratedColumn<double>(
    'similarity',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    memoryId,
    personId,
    similarity,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'memory_people';
  @override
  VerificationContext validateIntegrity(
    Insertable<MemoryPeopleData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('memory_id')) {
      context.handle(
        _memoryIdMeta,
        memoryId.isAcceptableOrUnknown(data['memory_id']!, _memoryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_memoryIdMeta);
    }
    if (data.containsKey('person_id')) {
      context.handle(
        _personIdMeta,
        personId.isAcceptableOrUnknown(data['person_id']!, _personIdMeta),
      );
    } else if (isInserting) {
      context.missing(_personIdMeta);
    }
    if (data.containsKey('similarity')) {
      context.handle(
        _similarityMeta,
        similarity.isAcceptableOrUnknown(data['similarity']!, _similarityMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {memoryId, personId};
  @override
  MemoryPeopleData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MemoryPeopleData(
      memoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}memory_id'],
      )!,
      personId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}person_id'],
      )!,
      similarity: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}similarity'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $MemoryPeopleTable createAlias(String alias) {
    return $MemoryPeopleTable(attachedDatabase, alias);
  }
}

class MemoryPeopleData extends DataClass
    implements Insertable<MemoryPeopleData> {
  final String memoryId;
  final String personId;
  final double? similarity;
  final DateTime createdAt;
  const MemoryPeopleData({
    required this.memoryId,
    required this.personId,
    this.similarity,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['memory_id'] = Variable<String>(memoryId);
    map['person_id'] = Variable<String>(personId);
    if (!nullToAbsent || similarity != null) {
      map['similarity'] = Variable<double>(similarity);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  MemoryPeopleCompanion toCompanion(bool nullToAbsent) {
    return MemoryPeopleCompanion(
      memoryId: Value(memoryId),
      personId: Value(personId),
      similarity: similarity == null && nullToAbsent
          ? const Value.absent()
          : Value(similarity),
      createdAt: Value(createdAt),
    );
  }

  factory MemoryPeopleData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MemoryPeopleData(
      memoryId: serializer.fromJson<String>(json['memoryId']),
      personId: serializer.fromJson<String>(json['personId']),
      similarity: serializer.fromJson<double?>(json['similarity']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'memoryId': serializer.toJson<String>(memoryId),
      'personId': serializer.toJson<String>(personId),
      'similarity': serializer.toJson<double?>(similarity),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  MemoryPeopleData copyWith({
    String? memoryId,
    String? personId,
    Value<double?> similarity = const Value.absent(),
    DateTime? createdAt,
  }) => MemoryPeopleData(
    memoryId: memoryId ?? this.memoryId,
    personId: personId ?? this.personId,
    similarity: similarity.present ? similarity.value : this.similarity,
    createdAt: createdAt ?? this.createdAt,
  );
  MemoryPeopleData copyWithCompanion(MemoryPeopleCompanion data) {
    return MemoryPeopleData(
      memoryId: data.memoryId.present ? data.memoryId.value : this.memoryId,
      personId: data.personId.present ? data.personId.value : this.personId,
      similarity: data.similarity.present
          ? data.similarity.value
          : this.similarity,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MemoryPeopleData(')
          ..write('memoryId: $memoryId, ')
          ..write('personId: $personId, ')
          ..write('similarity: $similarity, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(memoryId, personId, similarity, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MemoryPeopleData &&
          other.memoryId == this.memoryId &&
          other.personId == this.personId &&
          other.similarity == this.similarity &&
          other.createdAt == this.createdAt);
}

class MemoryPeopleCompanion extends UpdateCompanion<MemoryPeopleData> {
  final Value<String> memoryId;
  final Value<String> personId;
  final Value<double?> similarity;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const MemoryPeopleCompanion({
    this.memoryId = const Value.absent(),
    this.personId = const Value.absent(),
    this.similarity = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MemoryPeopleCompanion.insert({
    required String memoryId,
    required String personId,
    this.similarity = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : memoryId = Value(memoryId),
       personId = Value(personId),
       createdAt = Value(createdAt);
  static Insertable<MemoryPeopleData> custom({
    Expression<String>? memoryId,
    Expression<String>? personId,
    Expression<double>? similarity,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (memoryId != null) 'memory_id': memoryId,
      if (personId != null) 'person_id': personId,
      if (similarity != null) 'similarity': similarity,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MemoryPeopleCompanion copyWith({
    Value<String>? memoryId,
    Value<String>? personId,
    Value<double?>? similarity,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return MemoryPeopleCompanion(
      memoryId: memoryId ?? this.memoryId,
      personId: personId ?? this.personId,
      similarity: similarity ?? this.similarity,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (memoryId.present) {
      map['memory_id'] = Variable<String>(memoryId.value);
    }
    if (personId.present) {
      map['person_id'] = Variable<String>(personId.value);
    }
    if (similarity.present) {
      map['similarity'] = Variable<double>(similarity.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MemoryPeopleCompanion(')
          ..write('memoryId: $memoryId, ')
          ..write('personId: $personId, ')
          ..write('similarity: $similarity, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $MemoriesTable memories = $MemoriesTable(this);
  late final $PeopleTable people = $PeopleTable(this);
  late final $FaceEmbeddingsTable faceEmbeddings = $FaceEmbeddingsTable(this);
  late final $MemoryPeopleTable memoryPeople = $MemoryPeopleTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    memories,
    people,
    faceEmbeddings,
    memoryPeople,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'memories',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('face_embeddings', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'people',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('face_embeddings', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'memories',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('memory_people', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'people',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('memory_people', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$MemoriesTableCreateCompanionBuilder =
    MemoriesCompanion Function({
      required String id,
      required String type,
      required String title,
      Value<String?> content,
      Value<String?> embedding,
      Value<String?> originalPath,
      Value<String?> visionCaption,
      Value<String?> visionScene,
      Value<String?> visionObjects,
      Value<String?> visionKeywords,
      Value<String?> visionColors,
      Value<String?> visionModel,
      Value<String?> visionImageHash,
      Value<DateTime?> visionProcessedAt,
      Value<bool> isFavorite,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$MemoriesTableUpdateCompanionBuilder =
    MemoriesCompanion Function({
      Value<String> id,
      Value<String> type,
      Value<String> title,
      Value<String?> content,
      Value<String?> embedding,
      Value<String?> originalPath,
      Value<String?> visionCaption,
      Value<String?> visionScene,
      Value<String?> visionObjects,
      Value<String?> visionKeywords,
      Value<String?> visionColors,
      Value<String?> visionModel,
      Value<String?> visionImageHash,
      Value<DateTime?> visionProcessedAt,
      Value<bool> isFavorite,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$MemoriesTableReferences
    extends BaseReferences<_$AppDatabase, $MemoriesTable, Memory> {
  $$MemoriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$FaceEmbeddingsTable, List<FaceEmbedding>>
  _faceEmbeddingsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.faceEmbeddings,
    aliasName: 'memories__id__face_embeddings__memory_id',
  );

  $$FaceEmbeddingsTableProcessedTableManager get faceEmbeddingsRefs {
    final manager = $$FaceEmbeddingsTableTableManager(
      $_db,
      $_db.faceEmbeddings,
    ).filter((f) => f.memoryId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_faceEmbeddingsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$MemoryPeopleTable, List<MemoryPeopleData>>
  _memoryPeopleRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.memoryPeople,
    aliasName: 'memories__id__memory_people__memory_id',
  );

  $$MemoryPeopleTableProcessedTableManager get memoryPeopleRefs {
    final manager = $$MemoryPeopleTableTableManager(
      $_db,
      $_db.memoryPeople,
    ).filter((f) => f.memoryId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_memoryPeopleRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$MemoriesTableFilterComposer
    extends Composer<_$AppDatabase, $MemoriesTable> {
  $$MemoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get embedding => $composableBuilder(
    column: $table.embedding,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originalPath => $composableBuilder(
    column: $table.originalPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get visionCaption => $composableBuilder(
    column: $table.visionCaption,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get visionScene => $composableBuilder(
    column: $table.visionScene,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get visionObjects => $composableBuilder(
    column: $table.visionObjects,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get visionKeywords => $composableBuilder(
    column: $table.visionKeywords,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get visionColors => $composableBuilder(
    column: $table.visionColors,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get visionModel => $composableBuilder(
    column: $table.visionModel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get visionImageHash => $composableBuilder(
    column: $table.visionImageHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get visionProcessedAt => $composableBuilder(
    column: $table.visionProcessedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> faceEmbeddingsRefs(
    Expression<bool> Function($$FaceEmbeddingsTableFilterComposer f) f,
  ) {
    final $$FaceEmbeddingsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.faceEmbeddings,
      getReferencedColumn: (t) => t.memoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FaceEmbeddingsTableFilterComposer(
            $db: $db,
            $table: $db.faceEmbeddings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> memoryPeopleRefs(
    Expression<bool> Function($$MemoryPeopleTableFilterComposer f) f,
  ) {
    final $$MemoryPeopleTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.memoryPeople,
      getReferencedColumn: (t) => t.memoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MemoryPeopleTableFilterComposer(
            $db: $db,
            $table: $db.memoryPeople,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$MemoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $MemoriesTable> {
  $$MemoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get embedding => $composableBuilder(
    column: $table.embedding,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originalPath => $composableBuilder(
    column: $table.originalPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get visionCaption => $composableBuilder(
    column: $table.visionCaption,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get visionScene => $composableBuilder(
    column: $table.visionScene,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get visionObjects => $composableBuilder(
    column: $table.visionObjects,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get visionKeywords => $composableBuilder(
    column: $table.visionKeywords,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get visionColors => $composableBuilder(
    column: $table.visionColors,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get visionModel => $composableBuilder(
    column: $table.visionModel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get visionImageHash => $composableBuilder(
    column: $table.visionImageHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get visionProcessedAt => $composableBuilder(
    column: $table.visionProcessedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MemoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MemoriesTable> {
  $$MemoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get embedding =>
      $composableBuilder(column: $table.embedding, builder: (column) => column);

  GeneratedColumn<String> get originalPath => $composableBuilder(
    column: $table.originalPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get visionCaption => $composableBuilder(
    column: $table.visionCaption,
    builder: (column) => column,
  );

  GeneratedColumn<String> get visionScene => $composableBuilder(
    column: $table.visionScene,
    builder: (column) => column,
  );

  GeneratedColumn<String> get visionObjects => $composableBuilder(
    column: $table.visionObjects,
    builder: (column) => column,
  );

  GeneratedColumn<String> get visionKeywords => $composableBuilder(
    column: $table.visionKeywords,
    builder: (column) => column,
  );

  GeneratedColumn<String> get visionColors => $composableBuilder(
    column: $table.visionColors,
    builder: (column) => column,
  );

  GeneratedColumn<String> get visionModel => $composableBuilder(
    column: $table.visionModel,
    builder: (column) => column,
  );

  GeneratedColumn<String> get visionImageHash => $composableBuilder(
    column: $table.visionImageHash,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get visionProcessedAt => $composableBuilder(
    column: $table.visionProcessedAt,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> faceEmbeddingsRefs<T extends Object>(
    Expression<T> Function($$FaceEmbeddingsTableAnnotationComposer a) f,
  ) {
    final $$FaceEmbeddingsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.faceEmbeddings,
      getReferencedColumn: (t) => t.memoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FaceEmbeddingsTableAnnotationComposer(
            $db: $db,
            $table: $db.faceEmbeddings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> memoryPeopleRefs<T extends Object>(
    Expression<T> Function($$MemoryPeopleTableAnnotationComposer a) f,
  ) {
    final $$MemoryPeopleTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.memoryPeople,
      getReferencedColumn: (t) => t.memoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MemoryPeopleTableAnnotationComposer(
            $db: $db,
            $table: $db.memoryPeople,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$MemoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MemoriesTable,
          Memory,
          $$MemoriesTableFilterComposer,
          $$MemoriesTableOrderingComposer,
          $$MemoriesTableAnnotationComposer,
          $$MemoriesTableCreateCompanionBuilder,
          $$MemoriesTableUpdateCompanionBuilder,
          (Memory, $$MemoriesTableReferences),
          Memory,
          PrefetchHooks Function({
            bool faceEmbeddingsRefs,
            bool memoryPeopleRefs,
          })
        > {
  $$MemoriesTableTableManager(_$AppDatabase db, $MemoriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MemoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MemoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MemoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> content = const Value.absent(),
                Value<String?> embedding = const Value.absent(),
                Value<String?> originalPath = const Value.absent(),
                Value<String?> visionCaption = const Value.absent(),
                Value<String?> visionScene = const Value.absent(),
                Value<String?> visionObjects = const Value.absent(),
                Value<String?> visionKeywords = const Value.absent(),
                Value<String?> visionColors = const Value.absent(),
                Value<String?> visionModel = const Value.absent(),
                Value<String?> visionImageHash = const Value.absent(),
                Value<DateTime?> visionProcessedAt = const Value.absent(),
                Value<bool> isFavorite = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MemoriesCompanion(
                id: id,
                type: type,
                title: title,
                content: content,
                embedding: embedding,
                originalPath: originalPath,
                visionCaption: visionCaption,
                visionScene: visionScene,
                visionObjects: visionObjects,
                visionKeywords: visionKeywords,
                visionColors: visionColors,
                visionModel: visionModel,
                visionImageHash: visionImageHash,
                visionProcessedAt: visionProcessedAt,
                isFavorite: isFavorite,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String type,
                required String title,
                Value<String?> content = const Value.absent(),
                Value<String?> embedding = const Value.absent(),
                Value<String?> originalPath = const Value.absent(),
                Value<String?> visionCaption = const Value.absent(),
                Value<String?> visionScene = const Value.absent(),
                Value<String?> visionObjects = const Value.absent(),
                Value<String?> visionKeywords = const Value.absent(),
                Value<String?> visionColors = const Value.absent(),
                Value<String?> visionModel = const Value.absent(),
                Value<String?> visionImageHash = const Value.absent(),
                Value<DateTime?> visionProcessedAt = const Value.absent(),
                Value<bool> isFavorite = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => MemoriesCompanion.insert(
                id: id,
                type: type,
                title: title,
                content: content,
                embedding: embedding,
                originalPath: originalPath,
                visionCaption: visionCaption,
                visionScene: visionScene,
                visionObjects: visionObjects,
                visionKeywords: visionKeywords,
                visionColors: visionColors,
                visionModel: visionModel,
                visionImageHash: visionImageHash,
                visionProcessedAt: visionProcessedAt,
                isFavorite: isFavorite,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$MemoriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({faceEmbeddingsRefs = false, memoryPeopleRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (faceEmbeddingsRefs) db.faceEmbeddings,
                    if (memoryPeopleRefs) db.memoryPeople,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (faceEmbeddingsRefs)
                        await $_getPrefetchedData<
                          Memory,
                          $MemoriesTable,
                          FaceEmbedding
                        >(
                          currentTable: table,
                          referencedTable: $$MemoriesTableReferences
                              ._faceEmbeddingsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$MemoriesTableReferences(
                                db,
                                table,
                                p0,
                              ).faceEmbeddingsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.memoryId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (memoryPeopleRefs)
                        await $_getPrefetchedData<
                          Memory,
                          $MemoriesTable,
                          MemoryPeopleData
                        >(
                          currentTable: table,
                          referencedTable: $$MemoriesTableReferences
                              ._memoryPeopleRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$MemoriesTableReferences(
                                db,
                                table,
                                p0,
                              ).memoryPeopleRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.memoryId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$MemoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MemoriesTable,
      Memory,
      $$MemoriesTableFilterComposer,
      $$MemoriesTableOrderingComposer,
      $$MemoriesTableAnnotationComposer,
      $$MemoriesTableCreateCompanionBuilder,
      $$MemoriesTableUpdateCompanionBuilder,
      (Memory, $$MemoriesTableReferences),
      Memory,
      PrefetchHooks Function({bool faceEmbeddingsRefs, bool memoryPeopleRefs})
    >;
typedef $$PeopleTableCreateCompanionBuilder =
    PeopleCompanion Function({
      required String id,
      Value<String?> name,
      Value<String?> coverFacePath,
      Value<String?> clusterId,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$PeopleTableUpdateCompanionBuilder =
    PeopleCompanion Function({
      Value<String> id,
      Value<String?> name,
      Value<String?> coverFacePath,
      Value<String?> clusterId,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$PeopleTableReferences
    extends BaseReferences<_$AppDatabase, $PeopleTable, PeopleData> {
  $$PeopleTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$FaceEmbeddingsTable, List<FaceEmbedding>>
  _faceEmbeddingsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.faceEmbeddings,
    aliasName: 'people__id__face_embeddings__person_id',
  );

  $$FaceEmbeddingsTableProcessedTableManager get faceEmbeddingsRefs {
    final manager = $$FaceEmbeddingsTableTableManager(
      $_db,
      $_db.faceEmbeddings,
    ).filter((f) => f.personId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_faceEmbeddingsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$MemoryPeopleTable, List<MemoryPeopleData>>
  _memoryPeopleRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.memoryPeople,
    aliasName: 'people__id__memory_people__person_id',
  );

  $$MemoryPeopleTableProcessedTableManager get memoryPeopleRefs {
    final manager = $$MemoryPeopleTableTableManager(
      $_db,
      $_db.memoryPeople,
    ).filter((f) => f.personId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_memoryPeopleRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$PeopleTableFilterComposer
    extends Composer<_$AppDatabase, $PeopleTable> {
  $$PeopleTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get coverFacePath => $composableBuilder(
    column: $table.coverFacePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clusterId => $composableBuilder(
    column: $table.clusterId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> faceEmbeddingsRefs(
    Expression<bool> Function($$FaceEmbeddingsTableFilterComposer f) f,
  ) {
    final $$FaceEmbeddingsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.faceEmbeddings,
      getReferencedColumn: (t) => t.personId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FaceEmbeddingsTableFilterComposer(
            $db: $db,
            $table: $db.faceEmbeddings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> memoryPeopleRefs(
    Expression<bool> Function($$MemoryPeopleTableFilterComposer f) f,
  ) {
    final $$MemoryPeopleTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.memoryPeople,
      getReferencedColumn: (t) => t.personId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MemoryPeopleTableFilterComposer(
            $db: $db,
            $table: $db.memoryPeople,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PeopleTableOrderingComposer
    extends Composer<_$AppDatabase, $PeopleTable> {
  $$PeopleTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get coverFacePath => $composableBuilder(
    column: $table.coverFacePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clusterId => $composableBuilder(
    column: $table.clusterId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PeopleTableAnnotationComposer
    extends Composer<_$AppDatabase, $PeopleTable> {
  $$PeopleTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get coverFacePath => $composableBuilder(
    column: $table.coverFacePath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get clusterId =>
      $composableBuilder(column: $table.clusterId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> faceEmbeddingsRefs<T extends Object>(
    Expression<T> Function($$FaceEmbeddingsTableAnnotationComposer a) f,
  ) {
    final $$FaceEmbeddingsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.faceEmbeddings,
      getReferencedColumn: (t) => t.personId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FaceEmbeddingsTableAnnotationComposer(
            $db: $db,
            $table: $db.faceEmbeddings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> memoryPeopleRefs<T extends Object>(
    Expression<T> Function($$MemoryPeopleTableAnnotationComposer a) f,
  ) {
    final $$MemoryPeopleTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.memoryPeople,
      getReferencedColumn: (t) => t.personId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MemoryPeopleTableAnnotationComposer(
            $db: $db,
            $table: $db.memoryPeople,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PeopleTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PeopleTable,
          PeopleData,
          $$PeopleTableFilterComposer,
          $$PeopleTableOrderingComposer,
          $$PeopleTableAnnotationComposer,
          $$PeopleTableCreateCompanionBuilder,
          $$PeopleTableUpdateCompanionBuilder,
          (PeopleData, $$PeopleTableReferences),
          PeopleData,
          PrefetchHooks Function({
            bool faceEmbeddingsRefs,
            bool memoryPeopleRefs,
          })
        > {
  $$PeopleTableTableManager(_$AppDatabase db, $PeopleTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PeopleTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PeopleTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PeopleTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> name = const Value.absent(),
                Value<String?> coverFacePath = const Value.absent(),
                Value<String?> clusterId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PeopleCompanion(
                id: id,
                name: name,
                coverFacePath: coverFacePath,
                clusterId: clusterId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> name = const Value.absent(),
                Value<String?> coverFacePath = const Value.absent(),
                Value<String?> clusterId = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => PeopleCompanion.insert(
                id: id,
                name: name,
                coverFacePath: coverFacePath,
                clusterId: clusterId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$PeopleTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({faceEmbeddingsRefs = false, memoryPeopleRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (faceEmbeddingsRefs) db.faceEmbeddings,
                    if (memoryPeopleRefs) db.memoryPeople,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (faceEmbeddingsRefs)
                        await $_getPrefetchedData<
                          PeopleData,
                          $PeopleTable,
                          FaceEmbedding
                        >(
                          currentTable: table,
                          referencedTable: $$PeopleTableReferences
                              ._faceEmbeddingsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PeopleTableReferences(
                                db,
                                table,
                                p0,
                              ).faceEmbeddingsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.personId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (memoryPeopleRefs)
                        await $_getPrefetchedData<
                          PeopleData,
                          $PeopleTable,
                          MemoryPeopleData
                        >(
                          currentTable: table,
                          referencedTable: $$PeopleTableReferences
                              ._memoryPeopleRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PeopleTableReferences(
                                db,
                                table,
                                p0,
                              ).memoryPeopleRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.personId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$PeopleTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PeopleTable,
      PeopleData,
      $$PeopleTableFilterComposer,
      $$PeopleTableOrderingComposer,
      $$PeopleTableAnnotationComposer,
      $$PeopleTableCreateCompanionBuilder,
      $$PeopleTableUpdateCompanionBuilder,
      (PeopleData, $$PeopleTableReferences),
      PeopleData,
      PrefetchHooks Function({bool faceEmbeddingsRefs, bool memoryPeopleRefs})
    >;
typedef $$FaceEmbeddingsTableCreateCompanionBuilder =
    FaceEmbeddingsCompanion Function({
      required String id,
      required String memoryId,
      Value<String?> personId,
      required String embedding,
      required String model,
      required int embeddingDimension,
      required double boundingLeft,
      required double boundingTop,
      required double boundingWidth,
      required double boundingHeight,
      Value<double?> detectionConfidence,
      Value<String?> faceCropPath,
      Value<String?> faceHash,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$FaceEmbeddingsTableUpdateCompanionBuilder =
    FaceEmbeddingsCompanion Function({
      Value<String> id,
      Value<String> memoryId,
      Value<String?> personId,
      Value<String> embedding,
      Value<String> model,
      Value<int> embeddingDimension,
      Value<double> boundingLeft,
      Value<double> boundingTop,
      Value<double> boundingWidth,
      Value<double> boundingHeight,
      Value<double?> detectionConfidence,
      Value<String?> faceCropPath,
      Value<String?> faceHash,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$FaceEmbeddingsTableReferences
    extends BaseReferences<_$AppDatabase, $FaceEmbeddingsTable, FaceEmbedding> {
  $$FaceEmbeddingsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $MemoriesTable _memoryIdTable(_$AppDatabase db) =>
      db.memories.createAlias('face_embeddings__memory_id__memories__id');

  $$MemoriesTableProcessedTableManager get memoryId {
    final $_column = $_itemColumn<String>('memory_id')!;

    final manager = $$MemoriesTableTableManager(
      $_db,
      $_db.memories,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_memoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $PeopleTable _personIdTable(_$AppDatabase db) =>
      db.people.createAlias('face_embeddings__person_id__people__id');

  $$PeopleTableProcessedTableManager? get personId {
    final $_column = $_itemColumn<String>('person_id');
    if ($_column == null) return null;
    final manager = $$PeopleTableTableManager(
      $_db,
      $_db.people,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_personIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$FaceEmbeddingsTableFilterComposer
    extends Composer<_$AppDatabase, $FaceEmbeddingsTable> {
  $$FaceEmbeddingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get embedding => $composableBuilder(
    column: $table.embedding,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get model => $composableBuilder(
    column: $table.model,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get embeddingDimension => $composableBuilder(
    column: $table.embeddingDimension,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get boundingLeft => $composableBuilder(
    column: $table.boundingLeft,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get boundingTop => $composableBuilder(
    column: $table.boundingTop,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get boundingWidth => $composableBuilder(
    column: $table.boundingWidth,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get boundingHeight => $composableBuilder(
    column: $table.boundingHeight,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get detectionConfidence => $composableBuilder(
    column: $table.detectionConfidence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get faceCropPath => $composableBuilder(
    column: $table.faceCropPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get faceHash => $composableBuilder(
    column: $table.faceHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$MemoriesTableFilterComposer get memoryId {
    final $$MemoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.memoryId,
      referencedTable: $db.memories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MemoriesTableFilterComposer(
            $db: $db,
            $table: $db.memories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PeopleTableFilterComposer get personId {
    final $$PeopleTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.personId,
      referencedTable: $db.people,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PeopleTableFilterComposer(
            $db: $db,
            $table: $db.people,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FaceEmbeddingsTableOrderingComposer
    extends Composer<_$AppDatabase, $FaceEmbeddingsTable> {
  $$FaceEmbeddingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get embedding => $composableBuilder(
    column: $table.embedding,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get model => $composableBuilder(
    column: $table.model,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get embeddingDimension => $composableBuilder(
    column: $table.embeddingDimension,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get boundingLeft => $composableBuilder(
    column: $table.boundingLeft,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get boundingTop => $composableBuilder(
    column: $table.boundingTop,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get boundingWidth => $composableBuilder(
    column: $table.boundingWidth,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get boundingHeight => $composableBuilder(
    column: $table.boundingHeight,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get detectionConfidence => $composableBuilder(
    column: $table.detectionConfidence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get faceCropPath => $composableBuilder(
    column: $table.faceCropPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get faceHash => $composableBuilder(
    column: $table.faceHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$MemoriesTableOrderingComposer get memoryId {
    final $$MemoriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.memoryId,
      referencedTable: $db.memories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MemoriesTableOrderingComposer(
            $db: $db,
            $table: $db.memories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PeopleTableOrderingComposer get personId {
    final $$PeopleTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.personId,
      referencedTable: $db.people,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PeopleTableOrderingComposer(
            $db: $db,
            $table: $db.people,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FaceEmbeddingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FaceEmbeddingsTable> {
  $$FaceEmbeddingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get embedding =>
      $composableBuilder(column: $table.embedding, builder: (column) => column);

  GeneratedColumn<String> get model =>
      $composableBuilder(column: $table.model, builder: (column) => column);

  GeneratedColumn<int> get embeddingDimension => $composableBuilder(
    column: $table.embeddingDimension,
    builder: (column) => column,
  );

  GeneratedColumn<double> get boundingLeft => $composableBuilder(
    column: $table.boundingLeft,
    builder: (column) => column,
  );

  GeneratedColumn<double> get boundingTop => $composableBuilder(
    column: $table.boundingTop,
    builder: (column) => column,
  );

  GeneratedColumn<double> get boundingWidth => $composableBuilder(
    column: $table.boundingWidth,
    builder: (column) => column,
  );

  GeneratedColumn<double> get boundingHeight => $composableBuilder(
    column: $table.boundingHeight,
    builder: (column) => column,
  );

  GeneratedColumn<double> get detectionConfidence => $composableBuilder(
    column: $table.detectionConfidence,
    builder: (column) => column,
  );

  GeneratedColumn<String> get faceCropPath => $composableBuilder(
    column: $table.faceCropPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get faceHash =>
      $composableBuilder(column: $table.faceHash, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$MemoriesTableAnnotationComposer get memoryId {
    final $$MemoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.memoryId,
      referencedTable: $db.memories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MemoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.memories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PeopleTableAnnotationComposer get personId {
    final $$PeopleTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.personId,
      referencedTable: $db.people,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PeopleTableAnnotationComposer(
            $db: $db,
            $table: $db.people,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FaceEmbeddingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FaceEmbeddingsTable,
          FaceEmbedding,
          $$FaceEmbeddingsTableFilterComposer,
          $$FaceEmbeddingsTableOrderingComposer,
          $$FaceEmbeddingsTableAnnotationComposer,
          $$FaceEmbeddingsTableCreateCompanionBuilder,
          $$FaceEmbeddingsTableUpdateCompanionBuilder,
          (FaceEmbedding, $$FaceEmbeddingsTableReferences),
          FaceEmbedding,
          PrefetchHooks Function({bool memoryId, bool personId})
        > {
  $$FaceEmbeddingsTableTableManager(
    _$AppDatabase db,
    $FaceEmbeddingsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FaceEmbeddingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FaceEmbeddingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FaceEmbeddingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> memoryId = const Value.absent(),
                Value<String?> personId = const Value.absent(),
                Value<String> embedding = const Value.absent(),
                Value<String> model = const Value.absent(),
                Value<int> embeddingDimension = const Value.absent(),
                Value<double> boundingLeft = const Value.absent(),
                Value<double> boundingTop = const Value.absent(),
                Value<double> boundingWidth = const Value.absent(),
                Value<double> boundingHeight = const Value.absent(),
                Value<double?> detectionConfidence = const Value.absent(),
                Value<String?> faceCropPath = const Value.absent(),
                Value<String?> faceHash = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FaceEmbeddingsCompanion(
                id: id,
                memoryId: memoryId,
                personId: personId,
                embedding: embedding,
                model: model,
                embeddingDimension: embeddingDimension,
                boundingLeft: boundingLeft,
                boundingTop: boundingTop,
                boundingWidth: boundingWidth,
                boundingHeight: boundingHeight,
                detectionConfidence: detectionConfidence,
                faceCropPath: faceCropPath,
                faceHash: faceHash,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String memoryId,
                Value<String?> personId = const Value.absent(),
                required String embedding,
                required String model,
                required int embeddingDimension,
                required double boundingLeft,
                required double boundingTop,
                required double boundingWidth,
                required double boundingHeight,
                Value<double?> detectionConfidence = const Value.absent(),
                Value<String?> faceCropPath = const Value.absent(),
                Value<String?> faceHash = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => FaceEmbeddingsCompanion.insert(
                id: id,
                memoryId: memoryId,
                personId: personId,
                embedding: embedding,
                model: model,
                embeddingDimension: embeddingDimension,
                boundingLeft: boundingLeft,
                boundingTop: boundingTop,
                boundingWidth: boundingWidth,
                boundingHeight: boundingHeight,
                detectionConfidence: detectionConfidence,
                faceCropPath: faceCropPath,
                faceHash: faceHash,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$FaceEmbeddingsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({memoryId = false, personId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (memoryId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.memoryId,
                                referencedTable: $$FaceEmbeddingsTableReferences
                                    ._memoryIdTable(db),
                                referencedColumn:
                                    $$FaceEmbeddingsTableReferences
                                        ._memoryIdTable(db)
                                        .id,
                              )
                              as T;
                    }
                    if (personId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.personId,
                                referencedTable: $$FaceEmbeddingsTableReferences
                                    ._personIdTable(db),
                                referencedColumn:
                                    $$FaceEmbeddingsTableReferences
                                        ._personIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$FaceEmbeddingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FaceEmbeddingsTable,
      FaceEmbedding,
      $$FaceEmbeddingsTableFilterComposer,
      $$FaceEmbeddingsTableOrderingComposer,
      $$FaceEmbeddingsTableAnnotationComposer,
      $$FaceEmbeddingsTableCreateCompanionBuilder,
      $$FaceEmbeddingsTableUpdateCompanionBuilder,
      (FaceEmbedding, $$FaceEmbeddingsTableReferences),
      FaceEmbedding,
      PrefetchHooks Function({bool memoryId, bool personId})
    >;
typedef $$MemoryPeopleTableCreateCompanionBuilder =
    MemoryPeopleCompanion Function({
      required String memoryId,
      required String personId,
      Value<double?> similarity,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$MemoryPeopleTableUpdateCompanionBuilder =
    MemoryPeopleCompanion Function({
      Value<String> memoryId,
      Value<String> personId,
      Value<double?> similarity,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$MemoryPeopleTableReferences
    extends
        BaseReferences<_$AppDatabase, $MemoryPeopleTable, MemoryPeopleData> {
  $$MemoryPeopleTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $MemoriesTable _memoryIdTable(_$AppDatabase db) =>
      db.memories.createAlias('memory_people__memory_id__memories__id');

  $$MemoriesTableProcessedTableManager get memoryId {
    final $_column = $_itemColumn<String>('memory_id')!;

    final manager = $$MemoriesTableTableManager(
      $_db,
      $_db.memories,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_memoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $PeopleTable _personIdTable(_$AppDatabase db) =>
      db.people.createAlias('memory_people__person_id__people__id');

  $$PeopleTableProcessedTableManager get personId {
    final $_column = $_itemColumn<String>('person_id')!;

    final manager = $$PeopleTableTableManager(
      $_db,
      $_db.people,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_personIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$MemoryPeopleTableFilterComposer
    extends Composer<_$AppDatabase, $MemoryPeopleTable> {
  $$MemoryPeopleTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<double> get similarity => $composableBuilder(
    column: $table.similarity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$MemoriesTableFilterComposer get memoryId {
    final $$MemoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.memoryId,
      referencedTable: $db.memories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MemoriesTableFilterComposer(
            $db: $db,
            $table: $db.memories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PeopleTableFilterComposer get personId {
    final $$PeopleTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.personId,
      referencedTable: $db.people,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PeopleTableFilterComposer(
            $db: $db,
            $table: $db.people,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MemoryPeopleTableOrderingComposer
    extends Composer<_$AppDatabase, $MemoryPeopleTable> {
  $$MemoryPeopleTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<double> get similarity => $composableBuilder(
    column: $table.similarity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$MemoriesTableOrderingComposer get memoryId {
    final $$MemoriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.memoryId,
      referencedTable: $db.memories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MemoriesTableOrderingComposer(
            $db: $db,
            $table: $db.memories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PeopleTableOrderingComposer get personId {
    final $$PeopleTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.personId,
      referencedTable: $db.people,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PeopleTableOrderingComposer(
            $db: $db,
            $table: $db.people,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MemoryPeopleTableAnnotationComposer
    extends Composer<_$AppDatabase, $MemoryPeopleTable> {
  $$MemoryPeopleTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<double> get similarity => $composableBuilder(
    column: $table.similarity,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$MemoriesTableAnnotationComposer get memoryId {
    final $$MemoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.memoryId,
      referencedTable: $db.memories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MemoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.memories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PeopleTableAnnotationComposer get personId {
    final $$PeopleTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.personId,
      referencedTable: $db.people,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PeopleTableAnnotationComposer(
            $db: $db,
            $table: $db.people,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MemoryPeopleTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MemoryPeopleTable,
          MemoryPeopleData,
          $$MemoryPeopleTableFilterComposer,
          $$MemoryPeopleTableOrderingComposer,
          $$MemoryPeopleTableAnnotationComposer,
          $$MemoryPeopleTableCreateCompanionBuilder,
          $$MemoryPeopleTableUpdateCompanionBuilder,
          (MemoryPeopleData, $$MemoryPeopleTableReferences),
          MemoryPeopleData,
          PrefetchHooks Function({bool memoryId, bool personId})
        > {
  $$MemoryPeopleTableTableManager(_$AppDatabase db, $MemoryPeopleTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MemoryPeopleTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MemoryPeopleTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MemoryPeopleTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> memoryId = const Value.absent(),
                Value<String> personId = const Value.absent(),
                Value<double?> similarity = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MemoryPeopleCompanion(
                memoryId: memoryId,
                personId: personId,
                similarity: similarity,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String memoryId,
                required String personId,
                Value<double?> similarity = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => MemoryPeopleCompanion.insert(
                memoryId: memoryId,
                personId: personId,
                similarity: similarity,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$MemoryPeopleTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({memoryId = false, personId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (memoryId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.memoryId,
                                referencedTable: $$MemoryPeopleTableReferences
                                    ._memoryIdTable(db),
                                referencedColumn: $$MemoryPeopleTableReferences
                                    ._memoryIdTable(db)
                                    .id,
                              )
                              as T;
                    }
                    if (personId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.personId,
                                referencedTable: $$MemoryPeopleTableReferences
                                    ._personIdTable(db),
                                referencedColumn: $$MemoryPeopleTableReferences
                                    ._personIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$MemoryPeopleTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MemoryPeopleTable,
      MemoryPeopleData,
      $$MemoryPeopleTableFilterComposer,
      $$MemoryPeopleTableOrderingComposer,
      $$MemoryPeopleTableAnnotationComposer,
      $$MemoryPeopleTableCreateCompanionBuilder,
      $$MemoryPeopleTableUpdateCompanionBuilder,
      (MemoryPeopleData, $$MemoryPeopleTableReferences),
      MemoryPeopleData,
      PrefetchHooks Function({bool memoryId, bool personId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$MemoriesTableTableManager get memories =>
      $$MemoriesTableTableManager(_db, _db.memories);
  $$PeopleTableTableManager get people =>
      $$PeopleTableTableManager(_db, _db.people);
  $$FaceEmbeddingsTableTableManager get faceEmbeddings =>
      $$FaceEmbeddingsTableTableManager(_db, _db.faceEmbeddings);
  $$MemoryPeopleTableTableManager get memoryPeople =>
      $$MemoryPeopleTableTableManager(_db, _db.memoryPeople);
}
