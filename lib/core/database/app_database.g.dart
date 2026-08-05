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
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [memories];
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
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

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

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
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

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
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
          (Memory, BaseReferences<_$AppDatabase, $MemoriesTable, Memory>),
          Memory,
          PrefetchHooks Function()
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
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
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
      (Memory, BaseReferences<_$AppDatabase, $MemoriesTable, Memory>),
      Memory,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$MemoriesTableTableManager get memories =>
      $$MemoriesTableTableManager(_db, _db.memories);
}
