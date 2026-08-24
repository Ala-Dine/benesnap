// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ProductsTable extends Products
    with TableInfo<$ProductsTable, ProductRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProductsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _barcodeMeta = const VerificationMeta(
    'barcode',
  );
  @override
  late final GeneratedColumn<String> barcode = GeneratedColumn<String>(
    'barcode',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 128,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _brandNameMeta = const VerificationMeta(
    'brandName',
  );
  @override
  late final GeneratedColumn<String> brandName = GeneratedColumn<String>(
    'brand_name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 200,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _productNameMeta = const VerificationMeta(
    'productName',
  );
  @override
  late final GeneratedColumn<String> productName = GeneratedColumn<String>(
    'product_name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 200,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _keyIngredientsMeta = const VerificationMeta(
    'keyIngredients',
  );
  @override
  late final GeneratedColumn<String> keyIngredients = GeneratedColumn<String>(
    'key_ingredients',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _coreBenefitsMeta = const VerificationMeta(
    'coreBenefits',
  );
  @override
  late final GeneratedColumn<String> coreBenefits = GeneratedColumn<String>(
    'core_benefits',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _imagePathMeta = const VerificationMeta(
    'imagePath',
  );
  @override
  late final GeneratedColumn<String> imagePath = GeneratedColumn<String>(
    'image_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    barcode,
    brandName,
    productName,
    keyIngredients,
    coreBenefits,
    imagePath,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'products';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProductRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('barcode')) {
      context.handle(
        _barcodeMeta,
        barcode.isAcceptableOrUnknown(data['barcode']!, _barcodeMeta),
      );
    } else if (isInserting) {
      context.missing(_barcodeMeta);
    }
    if (data.containsKey('brand_name')) {
      context.handle(
        _brandNameMeta,
        brandName.isAcceptableOrUnknown(data['brand_name']!, _brandNameMeta),
      );
    } else if (isInserting) {
      context.missing(_brandNameMeta);
    }
    if (data.containsKey('product_name')) {
      context.handle(
        _productNameMeta,
        productName.isAcceptableOrUnknown(
          data['product_name']!,
          _productNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_productNameMeta);
    }
    if (data.containsKey('key_ingredients')) {
      context.handle(
        _keyIngredientsMeta,
        keyIngredients.isAcceptableOrUnknown(
          data['key_ingredients']!,
          _keyIngredientsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_keyIngredientsMeta);
    }
    if (data.containsKey('core_benefits')) {
      context.handle(
        _coreBenefitsMeta,
        coreBenefits.isAcceptableOrUnknown(
          data['core_benefits']!,
          _coreBenefitsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_coreBenefitsMeta);
    }
    if (data.containsKey('image_path')) {
      context.handle(
        _imagePathMeta,
        imagePath.isAcceptableOrUnknown(data['image_path']!, _imagePathMeta),
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
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {barcode},
  ];
  @override
  ProductRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProductRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      barcode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}barcode'],
      )!,
      brandName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}brand_name'],
      )!,
      productName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_name'],
      )!,
      keyIngredients: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key_ingredients'],
      )!,
      coreBenefits: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}core_benefits'],
      )!,
      imagePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_path'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ProductsTable createAlias(String alias) {
    return $ProductsTable(attachedDatabase, alias);
  }
}

class ProductRow extends DataClass implements Insertable<ProductRow> {
  final int id;

  /// The scan lookup key. Unique — see [Products.uniqueKeys].
  final String barcode;
  final String brandName;
  final String productName;
  final String keyIngredients;
  final String coreBenefits;

  /// Filename relative to the `images/` folder beside the database, so the
  /// catalogue survives the app being moved or reinstalled.
  final String? imagePath;
  final int createdAt;
  final int updatedAt;
  const ProductRow({
    required this.id,
    required this.barcode,
    required this.brandName,
    required this.productName,
    required this.keyIngredients,
    required this.coreBenefits,
    this.imagePath,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['barcode'] = Variable<String>(barcode);
    map['brand_name'] = Variable<String>(brandName);
    map['product_name'] = Variable<String>(productName);
    map['key_ingredients'] = Variable<String>(keyIngredients);
    map['core_benefits'] = Variable<String>(coreBenefits);
    if (!nullToAbsent || imagePath != null) {
      map['image_path'] = Variable<String>(imagePath);
    }
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  ProductsCompanion toCompanion(bool nullToAbsent) {
    return ProductsCompanion(
      id: Value(id),
      barcode: Value(barcode),
      brandName: Value(brandName),
      productName: Value(productName),
      keyIngredients: Value(keyIngredients),
      coreBenefits: Value(coreBenefits),
      imagePath: imagePath == null && nullToAbsent
          ? const Value.absent()
          : Value(imagePath),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory ProductRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProductRow(
      id: serializer.fromJson<int>(json['id']),
      barcode: serializer.fromJson<String>(json['barcode']),
      brandName: serializer.fromJson<String>(json['brandName']),
      productName: serializer.fromJson<String>(json['productName']),
      keyIngredients: serializer.fromJson<String>(json['keyIngredients']),
      coreBenefits: serializer.fromJson<String>(json['coreBenefits']),
      imagePath: serializer.fromJson<String?>(json['imagePath']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'barcode': serializer.toJson<String>(barcode),
      'brandName': serializer.toJson<String>(brandName),
      'productName': serializer.toJson<String>(productName),
      'keyIngredients': serializer.toJson<String>(keyIngredients),
      'coreBenefits': serializer.toJson<String>(coreBenefits),
      'imagePath': serializer.toJson<String?>(imagePath),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  ProductRow copyWith({
    int? id,
    String? barcode,
    String? brandName,
    String? productName,
    String? keyIngredients,
    String? coreBenefits,
    Value<String?> imagePath = const Value.absent(),
    int? createdAt,
    int? updatedAt,
  }) => ProductRow(
    id: id ?? this.id,
    barcode: barcode ?? this.barcode,
    brandName: brandName ?? this.brandName,
    productName: productName ?? this.productName,
    keyIngredients: keyIngredients ?? this.keyIngredients,
    coreBenefits: coreBenefits ?? this.coreBenefits,
    imagePath: imagePath.present ? imagePath.value : this.imagePath,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ProductRow copyWithCompanion(ProductsCompanion data) {
    return ProductRow(
      id: data.id.present ? data.id.value : this.id,
      barcode: data.barcode.present ? data.barcode.value : this.barcode,
      brandName: data.brandName.present ? data.brandName.value : this.brandName,
      productName: data.productName.present
          ? data.productName.value
          : this.productName,
      keyIngredients: data.keyIngredients.present
          ? data.keyIngredients.value
          : this.keyIngredients,
      coreBenefits: data.coreBenefits.present
          ? data.coreBenefits.value
          : this.coreBenefits,
      imagePath: data.imagePath.present ? data.imagePath.value : this.imagePath,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProductRow(')
          ..write('id: $id, ')
          ..write('barcode: $barcode, ')
          ..write('brandName: $brandName, ')
          ..write('productName: $productName, ')
          ..write('keyIngredients: $keyIngredients, ')
          ..write('coreBenefits: $coreBenefits, ')
          ..write('imagePath: $imagePath, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    barcode,
    brandName,
    productName,
    keyIngredients,
    coreBenefits,
    imagePath,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProductRow &&
          other.id == this.id &&
          other.barcode == this.barcode &&
          other.brandName == this.brandName &&
          other.productName == this.productName &&
          other.keyIngredients == this.keyIngredients &&
          other.coreBenefits == this.coreBenefits &&
          other.imagePath == this.imagePath &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ProductsCompanion extends UpdateCompanion<ProductRow> {
  final Value<int> id;
  final Value<String> barcode;
  final Value<String> brandName;
  final Value<String> productName;
  final Value<String> keyIngredients;
  final Value<String> coreBenefits;
  final Value<String?> imagePath;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  const ProductsCompanion({
    this.id = const Value.absent(),
    this.barcode = const Value.absent(),
    this.brandName = const Value.absent(),
    this.productName = const Value.absent(),
    this.keyIngredients = const Value.absent(),
    this.coreBenefits = const Value.absent(),
    this.imagePath = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  ProductsCompanion.insert({
    this.id = const Value.absent(),
    required String barcode,
    required String brandName,
    required String productName,
    required String keyIngredients,
    required String coreBenefits,
    this.imagePath = const Value.absent(),
    required int createdAt,
    required int updatedAt,
  }) : barcode = Value(barcode),
       brandName = Value(brandName),
       productName = Value(productName),
       keyIngredients = Value(keyIngredients),
       coreBenefits = Value(coreBenefits),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<ProductRow> custom({
    Expression<int>? id,
    Expression<String>? barcode,
    Expression<String>? brandName,
    Expression<String>? productName,
    Expression<String>? keyIngredients,
    Expression<String>? coreBenefits,
    Expression<String>? imagePath,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (barcode != null) 'barcode': barcode,
      if (brandName != null) 'brand_name': brandName,
      if (productName != null) 'product_name': productName,
      if (keyIngredients != null) 'key_ingredients': keyIngredients,
      if (coreBenefits != null) 'core_benefits': coreBenefits,
      if (imagePath != null) 'image_path': imagePath,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  ProductsCompanion copyWith({
    Value<int>? id,
    Value<String>? barcode,
    Value<String>? brandName,
    Value<String>? productName,
    Value<String>? keyIngredients,
    Value<String>? coreBenefits,
    Value<String?>? imagePath,
    Value<int>? createdAt,
    Value<int>? updatedAt,
  }) {
    return ProductsCompanion(
      id: id ?? this.id,
      barcode: barcode ?? this.barcode,
      brandName: brandName ?? this.brandName,
      productName: productName ?? this.productName,
      keyIngredients: keyIngredients ?? this.keyIngredients,
      coreBenefits: coreBenefits ?? this.coreBenefits,
      imagePath: imagePath ?? this.imagePath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (barcode.present) {
      map['barcode'] = Variable<String>(barcode.value);
    }
    if (brandName.present) {
      map['brand_name'] = Variable<String>(brandName.value);
    }
    if (productName.present) {
      map['product_name'] = Variable<String>(productName.value);
    }
    if (keyIngredients.present) {
      map['key_ingredients'] = Variable<String>(keyIngredients.value);
    }
    if (coreBenefits.present) {
      map['core_benefits'] = Variable<String>(coreBenefits.value);
    }
    if (imagePath.present) {
      map['image_path'] = Variable<String>(imagePath.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProductsCompanion(')
          ..write('id: $id, ')
          ..write('barcode: $barcode, ')
          ..write('brandName: $brandName, ')
          ..write('productName: $productName, ')
          ..write('keyIngredients: $keyIngredients, ')
          ..write('coreBenefits: $coreBenefits, ')
          ..write('imagePath: $imagePath, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $SuitabilityTagsTable extends SuitabilityTags
    with TableInfo<$SuitabilityTagsTable, SuitabilityTagRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SuitabilityTagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 60,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<TagCategory, String> category =
      GeneratedColumn<String>(
        'category',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<TagCategory>($SuitabilityTagsTable.$convertercategory);
  @override
  List<GeneratedColumn> get $columns => [id, label, category];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'suitability_tags';
  @override
  VerificationContext validateIntegrity(
    Insertable<SuitabilityTagRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {label, category},
  ];
  @override
  SuitabilityTagRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SuitabilityTagRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
      category: $SuitabilityTagsTable.$convertercategory.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}category'],
        )!,
      ),
    );
  }

  @override
  $SuitabilityTagsTable createAlias(String alias) {
    return $SuitabilityTagsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<TagCategory, String, String> $convertercategory =
      const EnumNameConverter<TagCategory>(TagCategory.values);
}

class SuitabilityTagRow extends DataClass
    implements Insertable<SuitabilityTagRow> {
  final int id;
  final String label;
  final TagCategory category;
  const SuitabilityTagRow({
    required this.id,
    required this.label,
    required this.category,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['label'] = Variable<String>(label);
    {
      map['category'] = Variable<String>(
        $SuitabilityTagsTable.$convertercategory.toSql(category),
      );
    }
    return map;
  }

  SuitabilityTagsCompanion toCompanion(bool nullToAbsent) {
    return SuitabilityTagsCompanion(
      id: Value(id),
      label: Value(label),
      category: Value(category),
    );
  }

  factory SuitabilityTagRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SuitabilityTagRow(
      id: serializer.fromJson<int>(json['id']),
      label: serializer.fromJson<String>(json['label']),
      category: $SuitabilityTagsTable.$convertercategory.fromJson(
        serializer.fromJson<String>(json['category']),
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'label': serializer.toJson<String>(label),
      'category': serializer.toJson<String>(
        $SuitabilityTagsTable.$convertercategory.toJson(category),
      ),
    };
  }

  SuitabilityTagRow copyWith({int? id, String? label, TagCategory? category}) =>
      SuitabilityTagRow(
        id: id ?? this.id,
        label: label ?? this.label,
        category: category ?? this.category,
      );
  SuitabilityTagRow copyWithCompanion(SuitabilityTagsCompanion data) {
    return SuitabilityTagRow(
      id: data.id.present ? data.id.value : this.id,
      label: data.label.present ? data.label.value : this.label,
      category: data.category.present ? data.category.value : this.category,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SuitabilityTagRow(')
          ..write('id: $id, ')
          ..write('label: $label, ')
          ..write('category: $category')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, label, category);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SuitabilityTagRow &&
          other.id == this.id &&
          other.label == this.label &&
          other.category == this.category);
}

class SuitabilityTagsCompanion extends UpdateCompanion<SuitabilityTagRow> {
  final Value<int> id;
  final Value<String> label;
  final Value<TagCategory> category;
  const SuitabilityTagsCompanion({
    this.id = const Value.absent(),
    this.label = const Value.absent(),
    this.category = const Value.absent(),
  });
  SuitabilityTagsCompanion.insert({
    this.id = const Value.absent(),
    required String label,
    required TagCategory category,
  }) : label = Value(label),
       category = Value(category);
  static Insertable<SuitabilityTagRow> custom({
    Expression<int>? id,
    Expression<String>? label,
    Expression<String>? category,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (label != null) 'label': label,
      if (category != null) 'category': category,
    });
  }

  SuitabilityTagsCompanion copyWith({
    Value<int>? id,
    Value<String>? label,
    Value<TagCategory>? category,
  }) {
    return SuitabilityTagsCompanion(
      id: id ?? this.id,
      label: label ?? this.label,
      category: category ?? this.category,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(
        $SuitabilityTagsTable.$convertercategory.toSql(category.value),
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SuitabilityTagsCompanion(')
          ..write('id: $id, ')
          ..write('label: $label, ')
          ..write('category: $category')
          ..write(')'))
        .toString();
  }
}

class $ProductTagsTable extends ProductTags
    with TableInfo<$ProductTagsTable, ProductTagRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProductTagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<int> productId = GeneratedColumn<int>(
    'product_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES products (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _tagIdMeta = const VerificationMeta('tagId');
  @override
  late final GeneratedColumn<int> tagId = GeneratedColumn<int>(
    'tag_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES suitability_tags (id) ON DELETE CASCADE',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [productId, tagId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'product_tags';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProductTagRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('tag_id')) {
      context.handle(
        _tagIdMeta,
        tagId.isAcceptableOrUnknown(data['tag_id']!, _tagIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tagIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {productId, tagId};
  @override
  ProductTagRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProductTagRow(
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}product_id'],
      )!,
      tagId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tag_id'],
      )!,
    );
  }

  @override
  $ProductTagsTable createAlias(String alias) {
    return $ProductTagsTable(attachedDatabase, alias);
  }
}

class ProductTagRow extends DataClass implements Insertable<ProductTagRow> {
  final int productId;
  final int tagId;
  const ProductTagRow({required this.productId, required this.tagId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['product_id'] = Variable<int>(productId);
    map['tag_id'] = Variable<int>(tagId);
    return map;
  }

  ProductTagsCompanion toCompanion(bool nullToAbsent) {
    return ProductTagsCompanion(
      productId: Value(productId),
      tagId: Value(tagId),
    );
  }

  factory ProductTagRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProductTagRow(
      productId: serializer.fromJson<int>(json['productId']),
      tagId: serializer.fromJson<int>(json['tagId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'productId': serializer.toJson<int>(productId),
      'tagId': serializer.toJson<int>(tagId),
    };
  }

  ProductTagRow copyWith({int? productId, int? tagId}) => ProductTagRow(
    productId: productId ?? this.productId,
    tagId: tagId ?? this.tagId,
  );
  ProductTagRow copyWithCompanion(ProductTagsCompanion data) {
    return ProductTagRow(
      productId: data.productId.present ? data.productId.value : this.productId,
      tagId: data.tagId.present ? data.tagId.value : this.tagId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProductTagRow(')
          ..write('productId: $productId, ')
          ..write('tagId: $tagId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(productId, tagId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProductTagRow &&
          other.productId == this.productId &&
          other.tagId == this.tagId);
}

class ProductTagsCompanion extends UpdateCompanion<ProductTagRow> {
  final Value<int> productId;
  final Value<int> tagId;
  final Value<int> rowid;
  const ProductTagsCompanion({
    this.productId = const Value.absent(),
    this.tagId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProductTagsCompanion.insert({
    required int productId,
    required int tagId,
    this.rowid = const Value.absent(),
  }) : productId = Value(productId),
       tagId = Value(tagId);
  static Insertable<ProductTagRow> custom({
    Expression<int>? productId,
    Expression<int>? tagId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (productId != null) 'product_id': productId,
      if (tagId != null) 'tag_id': tagId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProductTagsCompanion copyWith({
    Value<int>? productId,
    Value<int>? tagId,
    Value<int>? rowid,
  }) {
    return ProductTagsCompanion(
      productId: productId ?? this.productId,
      tagId: tagId ?? this.tagId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (productId.present) {
      map['product_id'] = Variable<int>(productId.value);
    }
    if (tagId.present) {
      map['tag_id'] = Variable<int>(tagId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProductTagsCompanion(')
          ..write('productId: $productId, ')
          ..write('tagId: $tagId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AdminsTable extends Admins with TableInfo<$AdminsTable, AdminRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AdminsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _usernameMeta = const VerificationMeta(
    'username',
  );
  @override
  late final GeneratedColumn<String> username = GeneratedColumn<String>(
    'username',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 60,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _passwordHashMeta = const VerificationMeta(
    'passwordHash',
  );
  @override
  late final GeneratedColumn<String> passwordHash = GeneratedColumn<String>(
    'password_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, username, passwordHash, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'admins';
  @override
  VerificationContext validateIntegrity(
    Insertable<AdminRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('username')) {
      context.handle(
        _usernameMeta,
        username.isAcceptableOrUnknown(data['username']!, _usernameMeta),
      );
    } else if (isInserting) {
      context.missing(_usernameMeta);
    }
    if (data.containsKey('password_hash')) {
      context.handle(
        _passwordHashMeta,
        passwordHash.isAcceptableOrUnknown(
          data['password_hash']!,
          _passwordHashMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_passwordHashMeta);
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
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {username},
  ];
  @override
  AdminRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AdminRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      username: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}username'],
      )!,
      passwordHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}password_hash'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $AdminsTable createAlias(String alias) {
    return $AdminsTable(attachedDatabase, alias);
  }
}

class AdminRow extends DataClass implements Insertable<AdminRow> {
  final int id;
  final String username;

  /// bcrypt hash. Plaintext is never stored.
  final String passwordHash;
  final int createdAt;
  const AdminRow({
    required this.id,
    required this.username,
    required this.passwordHash,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['username'] = Variable<String>(username);
    map['password_hash'] = Variable<String>(passwordHash);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  AdminsCompanion toCompanion(bool nullToAbsent) {
    return AdminsCompanion(
      id: Value(id),
      username: Value(username),
      passwordHash: Value(passwordHash),
      createdAt: Value(createdAt),
    );
  }

  factory AdminRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AdminRow(
      id: serializer.fromJson<int>(json['id']),
      username: serializer.fromJson<String>(json['username']),
      passwordHash: serializer.fromJson<String>(json['passwordHash']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'username': serializer.toJson<String>(username),
      'passwordHash': serializer.toJson<String>(passwordHash),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  AdminRow copyWith({
    int? id,
    String? username,
    String? passwordHash,
    int? createdAt,
  }) => AdminRow(
    id: id ?? this.id,
    username: username ?? this.username,
    passwordHash: passwordHash ?? this.passwordHash,
    createdAt: createdAt ?? this.createdAt,
  );
  AdminRow copyWithCompanion(AdminsCompanion data) {
    return AdminRow(
      id: data.id.present ? data.id.value : this.id,
      username: data.username.present ? data.username.value : this.username,
      passwordHash: data.passwordHash.present
          ? data.passwordHash.value
          : this.passwordHash,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AdminRow(')
          ..write('id: $id, ')
          ..write('username: $username, ')
          ..write('passwordHash: $passwordHash, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, username, passwordHash, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AdminRow &&
          other.id == this.id &&
          other.username == this.username &&
          other.passwordHash == this.passwordHash &&
          other.createdAt == this.createdAt);
}

class AdminsCompanion extends UpdateCompanion<AdminRow> {
  final Value<int> id;
  final Value<String> username;
  final Value<String> passwordHash;
  final Value<int> createdAt;
  const AdminsCompanion({
    this.id = const Value.absent(),
    this.username = const Value.absent(),
    this.passwordHash = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  AdminsCompanion.insert({
    this.id = const Value.absent(),
    required String username,
    required String passwordHash,
    required int createdAt,
  }) : username = Value(username),
       passwordHash = Value(passwordHash),
       createdAt = Value(createdAt);
  static Insertable<AdminRow> custom({
    Expression<int>? id,
    Expression<String>? username,
    Expression<String>? passwordHash,
    Expression<int>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (username != null) 'username': username,
      if (passwordHash != null) 'password_hash': passwordHash,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  AdminsCompanion copyWith({
    Value<int>? id,
    Value<String>? username,
    Value<String>? passwordHash,
    Value<int>? createdAt,
  }) {
    return AdminsCompanion(
      id: id ?? this.id,
      username: username ?? this.username,
      passwordHash: passwordHash ?? this.passwordHash,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (username.present) {
      map['username'] = Variable<String>(username.value);
    }
    if (passwordHash.present) {
      map['password_hash'] = Variable<String>(passwordHash.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AdminsCompanion(')
          ..write('id: $id, ')
          ..write('username: $username, ')
          ..write('passwordHash: $passwordHash, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $SeededTagOffersTable extends SeededTagOffers
    with TableInfo<$SeededTagOffersTable, SeededTagOfferRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SeededTagOffersTable(this.attachedDatabase, [this._alias]);
  @override
  late final GeneratedColumnWithTypeConverter<TagCategory, String> category =
      GeneratedColumn<String>(
        'category',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<TagCategory>($SeededTagOffersTable.$convertercategory);
  static const VerificationMeta _seedIndexMeta = const VerificationMeta(
    'seedIndex',
  );
  @override
  late final GeneratedColumn<int> seedIndex = GeneratedColumn<int>(
    'seed_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [category, seedIndex];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'seeded_tag_offers';
  @override
  VerificationContext validateIntegrity(
    Insertable<SeededTagOfferRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('seed_index')) {
      context.handle(
        _seedIndexMeta,
        seedIndex.isAcceptableOrUnknown(data['seed_index']!, _seedIndexMeta),
      );
    } else if (isInserting) {
      context.missing(_seedIndexMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {category, seedIndex};
  @override
  SeededTagOfferRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SeededTagOfferRow(
      category: $SeededTagOffersTable.$convertercategory.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}category'],
        )!,
      ),
      seedIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seed_index'],
      )!,
    );
  }

  @override
  $SeededTagOffersTable createAlias(String alias) {
    return $SeededTagOffersTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<TagCategory, String, String> $convertercategory =
      const EnumNameConverter<TagCategory>(TagCategory.values);
}

class SeededTagOfferRow extends DataClass
    implements Insertable<SeededTagOfferRow> {
  final TagCategory category;
  final int seedIndex;
  const SeededTagOfferRow({required this.category, required this.seedIndex});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    {
      map['category'] = Variable<String>(
        $SeededTagOffersTable.$convertercategory.toSql(category),
      );
    }
    map['seed_index'] = Variable<int>(seedIndex);
    return map;
  }

  SeededTagOffersCompanion toCompanion(bool nullToAbsent) {
    return SeededTagOffersCompanion(
      category: Value(category),
      seedIndex: Value(seedIndex),
    );
  }

  factory SeededTagOfferRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SeededTagOfferRow(
      category: $SeededTagOffersTable.$convertercategory.fromJson(
        serializer.fromJson<String>(json['category']),
      ),
      seedIndex: serializer.fromJson<int>(json['seedIndex']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'category': serializer.toJson<String>(
        $SeededTagOffersTable.$convertercategory.toJson(category),
      ),
      'seedIndex': serializer.toJson<int>(seedIndex),
    };
  }

  SeededTagOfferRow copyWith({TagCategory? category, int? seedIndex}) =>
      SeededTagOfferRow(
        category: category ?? this.category,
        seedIndex: seedIndex ?? this.seedIndex,
      );
  SeededTagOfferRow copyWithCompanion(SeededTagOffersCompanion data) {
    return SeededTagOfferRow(
      category: data.category.present ? data.category.value : this.category,
      seedIndex: data.seedIndex.present ? data.seedIndex.value : this.seedIndex,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SeededTagOfferRow(')
          ..write('category: $category, ')
          ..write('seedIndex: $seedIndex')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(category, seedIndex);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SeededTagOfferRow &&
          other.category == this.category &&
          other.seedIndex == this.seedIndex);
}

class SeededTagOffersCompanion extends UpdateCompanion<SeededTagOfferRow> {
  final Value<TagCategory> category;
  final Value<int> seedIndex;
  final Value<int> rowid;
  const SeededTagOffersCompanion({
    this.category = const Value.absent(),
    this.seedIndex = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SeededTagOffersCompanion.insert({
    required TagCategory category,
    required int seedIndex,
    this.rowid = const Value.absent(),
  }) : category = Value(category),
       seedIndex = Value(seedIndex);
  static Insertable<SeededTagOfferRow> custom({
    Expression<String>? category,
    Expression<int>? seedIndex,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (category != null) 'category': category,
      if (seedIndex != null) 'seed_index': seedIndex,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SeededTagOffersCompanion copyWith({
    Value<TagCategory>? category,
    Value<int>? seedIndex,
    Value<int>? rowid,
  }) {
    return SeededTagOffersCompanion(
      category: category ?? this.category,
      seedIndex: seedIndex ?? this.seedIndex,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (category.present) {
      map['category'] = Variable<String>(
        $SeededTagOffersTable.$convertercategory.toSql(category.value),
      );
    }
    if (seedIndex.present) {
      map['seed_index'] = Variable<int>(seedIndex.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SeededTagOffersCompanion(')
          ..write('category: $category, ')
          ..write('seedIndex: $seedIndex, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, AppSettingsRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _welcomeTitleMeta = const VerificationMeta(
    'welcomeTitle',
  );
  @override
  late final GeneratedColumn<String> welcomeTitle = GeneratedColumn<String>(
    'welcome_title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _extraLineMeta = const VerificationMeta(
    'extraLine',
  );
  @override
  late final GeneratedColumn<String> extraLine = GeneratedColumn<String>(
    'extra_line',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, welcomeTitle, extraLine];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppSettingsRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('welcome_title')) {
      context.handle(
        _welcomeTitleMeta,
        welcomeTitle.isAcceptableOrUnknown(
          data['welcome_title']!,
          _welcomeTitleMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_welcomeTitleMeta);
    }
    if (data.containsKey('extra_line')) {
      context.handle(
        _extraLineMeta,
        extraLine.isAcceptableOrUnknown(data['extra_line']!, _extraLineMeta),
      );
    } else if (isInserting) {
      context.missing(_extraLineMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AppSettingsRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSettingsRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      welcomeTitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}welcome_title'],
      )!,
      extraLine: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}extra_line'],
      )!,
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }
}

class AppSettingsRow extends DataClass implements Insertable<AppSettingsRow> {
  final int id;
  final String welcomeTitle;
  final String extraLine;
  const AppSettingsRow({
    required this.id,
    required this.welcomeTitle,
    required this.extraLine,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['welcome_title'] = Variable<String>(welcomeTitle);
    map['extra_line'] = Variable<String>(extraLine);
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(
      id: Value(id),
      welcomeTitle: Value(welcomeTitle),
      extraLine: Value(extraLine),
    );
  }

  factory AppSettingsRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSettingsRow(
      id: serializer.fromJson<int>(json['id']),
      welcomeTitle: serializer.fromJson<String>(json['welcomeTitle']),
      extraLine: serializer.fromJson<String>(json['extraLine']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'welcomeTitle': serializer.toJson<String>(welcomeTitle),
      'extraLine': serializer.toJson<String>(extraLine),
    };
  }

  AppSettingsRow copyWith({int? id, String? welcomeTitle, String? extraLine}) =>
      AppSettingsRow(
        id: id ?? this.id,
        welcomeTitle: welcomeTitle ?? this.welcomeTitle,
        extraLine: extraLine ?? this.extraLine,
      );
  AppSettingsRow copyWithCompanion(AppSettingsCompanion data) {
    return AppSettingsRow(
      id: data.id.present ? data.id.value : this.id,
      welcomeTitle: data.welcomeTitle.present
          ? data.welcomeTitle.value
          : this.welcomeTitle,
      extraLine: data.extraLine.present ? data.extraLine.value : this.extraLine,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsRow(')
          ..write('id: $id, ')
          ..write('welcomeTitle: $welcomeTitle, ')
          ..write('extraLine: $extraLine')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, welcomeTitle, extraLine);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSettingsRow &&
          other.id == this.id &&
          other.welcomeTitle == this.welcomeTitle &&
          other.extraLine == this.extraLine);
}

class AppSettingsCompanion extends UpdateCompanion<AppSettingsRow> {
  final Value<int> id;
  final Value<String> welcomeTitle;
  final Value<String> extraLine;
  const AppSettingsCompanion({
    this.id = const Value.absent(),
    this.welcomeTitle = const Value.absent(),
    this.extraLine = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    this.id = const Value.absent(),
    required String welcomeTitle,
    required String extraLine,
  }) : welcomeTitle = Value(welcomeTitle),
       extraLine = Value(extraLine);
  static Insertable<AppSettingsRow> custom({
    Expression<int>? id,
    Expression<String>? welcomeTitle,
    Expression<String>? extraLine,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (welcomeTitle != null) 'welcome_title': welcomeTitle,
      if (extraLine != null) 'extra_line': extraLine,
    });
  }

  AppSettingsCompanion copyWith({
    Value<int>? id,
    Value<String>? welcomeTitle,
    Value<String>? extraLine,
  }) {
    return AppSettingsCompanion(
      id: id ?? this.id,
      welcomeTitle: welcomeTitle ?? this.welcomeTitle,
      extraLine: extraLine ?? this.extraLine,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (welcomeTitle.present) {
      map['welcome_title'] = Variable<String>(welcomeTitle.value);
    }
    if (extraLine.present) {
      map['extra_line'] = Variable<String>(extraLine.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('id: $id, ')
          ..write('welcomeTitle: $welcomeTitle, ')
          ..write('extraLine: $extraLine')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ProductsTable products = $ProductsTable(this);
  late final $SuitabilityTagsTable suitabilityTags = $SuitabilityTagsTable(
    this,
  );
  late final $ProductTagsTable productTags = $ProductTagsTable(this);
  late final $AdminsTable admins = $AdminsTable(this);
  late final $SeededTagOffersTable seededTagOffers = $SeededTagOffersTable(
    this,
  );
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    products,
    suitabilityTags,
    productTags,
    admins,
    seededTagOffers,
    appSettings,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'products',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('product_tags', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'suitability_tags',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('product_tags', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$ProductsTableCreateCompanionBuilder =
    ProductsCompanion Function({
      Value<int> id,
      required String barcode,
      required String brandName,
      required String productName,
      required String keyIngredients,
      required String coreBenefits,
      Value<String?> imagePath,
      required int createdAt,
      required int updatedAt,
    });
typedef $$ProductsTableUpdateCompanionBuilder =
    ProductsCompanion Function({
      Value<int> id,
      Value<String> barcode,
      Value<String> brandName,
      Value<String> productName,
      Value<String> keyIngredients,
      Value<String> coreBenefits,
      Value<String?> imagePath,
      Value<int> createdAt,
      Value<int> updatedAt,
    });

final class $$ProductsTableReferences
    extends BaseReferences<_$AppDatabase, $ProductsTable, ProductRow> {
  $$ProductsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ProductTagsTable, List<ProductTagRow>>
  _productTagsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.productTags,
    aliasName: 'products__id__product_tags__product_id',
  );

  $$ProductTagsTableProcessedTableManager get productTagsRefs {
    final manager = $$ProductTagsTableTableManager(
      $_db,
      $_db.productTags,
    ).filter((f) => f.productId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_productTagsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ProductsTableFilterComposer
    extends Composer<_$AppDatabase, $ProductsTable> {
  $$ProductsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get barcode => $composableBuilder(
    column: $table.barcode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get brandName => $composableBuilder(
    column: $table.brandName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productName => $composableBuilder(
    column: $table.productName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get keyIngredients => $composableBuilder(
    column: $table.keyIngredients,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get coreBenefits => $composableBuilder(
    column: $table.coreBenefits,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imagePath => $composableBuilder(
    column: $table.imagePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> productTagsRefs(
    Expression<bool> Function($$ProductTagsTableFilterComposer f) f,
  ) {
    final $$ProductTagsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.productTags,
      getReferencedColumn: (t) => t.productId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductTagsTableFilterComposer(
            $db: $db,
            $table: $db.productTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ProductsTableOrderingComposer
    extends Composer<_$AppDatabase, $ProductsTable> {
  $$ProductsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get barcode => $composableBuilder(
    column: $table.barcode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get brandName => $composableBuilder(
    column: $table.brandName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productName => $composableBuilder(
    column: $table.productName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get keyIngredients => $composableBuilder(
    column: $table.keyIngredients,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get coreBenefits => $composableBuilder(
    column: $table.coreBenefits,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imagePath => $composableBuilder(
    column: $table.imagePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProductsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProductsTable> {
  $$ProductsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get barcode =>
      $composableBuilder(column: $table.barcode, builder: (column) => column);

  GeneratedColumn<String> get brandName =>
      $composableBuilder(column: $table.brandName, builder: (column) => column);

  GeneratedColumn<String> get productName => $composableBuilder(
    column: $table.productName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get keyIngredients => $composableBuilder(
    column: $table.keyIngredients,
    builder: (column) => column,
  );

  GeneratedColumn<String> get coreBenefits => $composableBuilder(
    column: $table.coreBenefits,
    builder: (column) => column,
  );

  GeneratedColumn<String> get imagePath =>
      $composableBuilder(column: $table.imagePath, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> productTagsRefs<T extends Object>(
    Expression<T> Function($$ProductTagsTableAnnotationComposer a) f,
  ) {
    final $$ProductTagsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.productTags,
      getReferencedColumn: (t) => t.productId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductTagsTableAnnotationComposer(
            $db: $db,
            $table: $db.productTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ProductsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProductsTable,
          ProductRow,
          $$ProductsTableFilterComposer,
          $$ProductsTableOrderingComposer,
          $$ProductsTableAnnotationComposer,
          $$ProductsTableCreateCompanionBuilder,
          $$ProductsTableUpdateCompanionBuilder,
          (ProductRow, $$ProductsTableReferences),
          ProductRow,
          PrefetchHooks Function({bool productTagsRefs})
        > {
  $$ProductsTableTableManager(_$AppDatabase db, $ProductsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProductsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProductsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProductsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> barcode = const Value.absent(),
                Value<String> brandName = const Value.absent(),
                Value<String> productName = const Value.absent(),
                Value<String> keyIngredients = const Value.absent(),
                Value<String> coreBenefits = const Value.absent(),
                Value<String?> imagePath = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
              }) => ProductsCompanion(
                id: id,
                barcode: barcode,
                brandName: brandName,
                productName: productName,
                keyIngredients: keyIngredients,
                coreBenefits: coreBenefits,
                imagePath: imagePath,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String barcode,
                required String brandName,
                required String productName,
                required String keyIngredients,
                required String coreBenefits,
                Value<String?> imagePath = const Value.absent(),
                required int createdAt,
                required int updatedAt,
              }) => ProductsCompanion.insert(
                id: id,
                barcode: barcode,
                brandName: brandName,
                productName: productName,
                keyIngredients: keyIngredients,
                coreBenefits: coreBenefits,
                imagePath: imagePath,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ProductsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({productTagsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (productTagsRefs) db.productTags],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (productTagsRefs)
                    await $_getPrefetchedData<
                      ProductRow,
                      $ProductsTable,
                      ProductTagRow
                    >(
                      currentTable: table,
                      referencedTable: $$ProductsTableReferences
                          ._productTagsRefsTable(db),
                      managerFromTypedResult: (p0) => $$ProductsTableReferences(
                        db,
                        table,
                        p0,
                      ).productTagsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.productId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$ProductsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProductsTable,
      ProductRow,
      $$ProductsTableFilterComposer,
      $$ProductsTableOrderingComposer,
      $$ProductsTableAnnotationComposer,
      $$ProductsTableCreateCompanionBuilder,
      $$ProductsTableUpdateCompanionBuilder,
      (ProductRow, $$ProductsTableReferences),
      ProductRow,
      PrefetchHooks Function({bool productTagsRefs})
    >;
typedef $$SuitabilityTagsTableCreateCompanionBuilder =
    SuitabilityTagsCompanion Function({
      Value<int> id,
      required String label,
      required TagCategory category,
    });
typedef $$SuitabilityTagsTableUpdateCompanionBuilder =
    SuitabilityTagsCompanion Function({
      Value<int> id,
      Value<String> label,
      Value<TagCategory> category,
    });

final class $$SuitabilityTagsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $SuitabilityTagsTable,
          SuitabilityTagRow
        > {
  $$SuitabilityTagsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$ProductTagsTable, List<ProductTagRow>>
  _productTagsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.productTags,
    aliasName: 'suitability_tags__id__product_tags__tag_id',
  );

  $$ProductTagsTableProcessedTableManager get productTagsRefs {
    final manager = $$ProductTagsTableTableManager(
      $_db,
      $_db.productTags,
    ).filter((f) => f.tagId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_productTagsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SuitabilityTagsTableFilterComposer
    extends Composer<_$AppDatabase, $SuitabilityTagsTable> {
  $$SuitabilityTagsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<TagCategory, TagCategory, String>
  get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  Expression<bool> productTagsRefs(
    Expression<bool> Function($$ProductTagsTableFilterComposer f) f,
  ) {
    final $$ProductTagsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.productTags,
      getReferencedColumn: (t) => t.tagId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductTagsTableFilterComposer(
            $db: $db,
            $table: $db.productTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SuitabilityTagsTableOrderingComposer
    extends Composer<_$AppDatabase, $SuitabilityTagsTable> {
  $$SuitabilityTagsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SuitabilityTagsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SuitabilityTagsTable> {
  $$SuitabilityTagsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumnWithTypeConverter<TagCategory, String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  Expression<T> productTagsRefs<T extends Object>(
    Expression<T> Function($$ProductTagsTableAnnotationComposer a) f,
  ) {
    final $$ProductTagsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.productTags,
      getReferencedColumn: (t) => t.tagId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductTagsTableAnnotationComposer(
            $db: $db,
            $table: $db.productTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SuitabilityTagsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SuitabilityTagsTable,
          SuitabilityTagRow,
          $$SuitabilityTagsTableFilterComposer,
          $$SuitabilityTagsTableOrderingComposer,
          $$SuitabilityTagsTableAnnotationComposer,
          $$SuitabilityTagsTableCreateCompanionBuilder,
          $$SuitabilityTagsTableUpdateCompanionBuilder,
          (SuitabilityTagRow, $$SuitabilityTagsTableReferences),
          SuitabilityTagRow,
          PrefetchHooks Function({bool productTagsRefs})
        > {
  $$SuitabilityTagsTableTableManager(
    _$AppDatabase db,
    $SuitabilityTagsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SuitabilityTagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SuitabilityTagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SuitabilityTagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<TagCategory> category = const Value.absent(),
              }) => SuitabilityTagsCompanion(
                id: id,
                label: label,
                category: category,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String label,
                required TagCategory category,
              }) => SuitabilityTagsCompanion.insert(
                id: id,
                label: label,
                category: category,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SuitabilityTagsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({productTagsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (productTagsRefs) db.productTags],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (productTagsRefs)
                    await $_getPrefetchedData<
                      SuitabilityTagRow,
                      $SuitabilityTagsTable,
                      ProductTagRow
                    >(
                      currentTable: table,
                      referencedTable: $$SuitabilityTagsTableReferences
                          ._productTagsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$SuitabilityTagsTableReferences(
                            db,
                            table,
                            p0,
                          ).productTagsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.tagId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$SuitabilityTagsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SuitabilityTagsTable,
      SuitabilityTagRow,
      $$SuitabilityTagsTableFilterComposer,
      $$SuitabilityTagsTableOrderingComposer,
      $$SuitabilityTagsTableAnnotationComposer,
      $$SuitabilityTagsTableCreateCompanionBuilder,
      $$SuitabilityTagsTableUpdateCompanionBuilder,
      (SuitabilityTagRow, $$SuitabilityTagsTableReferences),
      SuitabilityTagRow,
      PrefetchHooks Function({bool productTagsRefs})
    >;
typedef $$ProductTagsTableCreateCompanionBuilder =
    ProductTagsCompanion Function({
      required int productId,
      required int tagId,
      Value<int> rowid,
    });
typedef $$ProductTagsTableUpdateCompanionBuilder =
    ProductTagsCompanion Function({
      Value<int> productId,
      Value<int> tagId,
      Value<int> rowid,
    });

final class $$ProductTagsTableReferences
    extends BaseReferences<_$AppDatabase, $ProductTagsTable, ProductTagRow> {
  $$ProductTagsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ProductsTable _productIdTable(_$AppDatabase db) =>
      db.products.createAlias('product_tags__product_id__products__id');

  $$ProductsTableProcessedTableManager get productId {
    final $_column = $_itemColumn<int>('product_id')!;

    final manager = $$ProductsTableTableManager(
      $_db,
      $_db.products,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_productIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $SuitabilityTagsTable _tagIdTable(_$AppDatabase db) => db
      .suitabilityTags
      .createAlias('product_tags__tag_id__suitability_tags__id');

  $$SuitabilityTagsTableProcessedTableManager get tagId {
    final $_column = $_itemColumn<int>('tag_id')!;

    final manager = $$SuitabilityTagsTableTableManager(
      $_db,
      $_db.suitabilityTags,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_tagIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ProductTagsTableFilterComposer
    extends Composer<_$AppDatabase, $ProductTagsTable> {
  $$ProductTagsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$ProductsTableFilterComposer get productId {
    final $$ProductsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableFilterComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$SuitabilityTagsTableFilterComposer get tagId {
    final $$SuitabilityTagsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tagId,
      referencedTable: $db.suitabilityTags,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SuitabilityTagsTableFilterComposer(
            $db: $db,
            $table: $db.suitabilityTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProductTagsTableOrderingComposer
    extends Composer<_$AppDatabase, $ProductTagsTable> {
  $$ProductTagsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$ProductsTableOrderingComposer get productId {
    final $$ProductsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableOrderingComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$SuitabilityTagsTableOrderingComposer get tagId {
    final $$SuitabilityTagsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tagId,
      referencedTable: $db.suitabilityTags,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SuitabilityTagsTableOrderingComposer(
            $db: $db,
            $table: $db.suitabilityTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProductTagsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProductTagsTable> {
  $$ProductTagsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$ProductsTableAnnotationComposer get productId {
    final $$ProductsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableAnnotationComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$SuitabilityTagsTableAnnotationComposer get tagId {
    final $$SuitabilityTagsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tagId,
      referencedTable: $db.suitabilityTags,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SuitabilityTagsTableAnnotationComposer(
            $db: $db,
            $table: $db.suitabilityTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProductTagsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProductTagsTable,
          ProductTagRow,
          $$ProductTagsTableFilterComposer,
          $$ProductTagsTableOrderingComposer,
          $$ProductTagsTableAnnotationComposer,
          $$ProductTagsTableCreateCompanionBuilder,
          $$ProductTagsTableUpdateCompanionBuilder,
          (ProductTagRow, $$ProductTagsTableReferences),
          ProductTagRow,
          PrefetchHooks Function({bool productId, bool tagId})
        > {
  $$ProductTagsTableTableManager(_$AppDatabase db, $ProductTagsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProductTagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProductTagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProductTagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> productId = const Value.absent(),
                Value<int> tagId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProductTagsCompanion(
                productId: productId,
                tagId: tagId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int productId,
                required int tagId,
                Value<int> rowid = const Value.absent(),
              }) => ProductTagsCompanion.insert(
                productId: productId,
                tagId: tagId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ProductTagsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({productId = false, tagId = false}) {
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
                    if (productId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.productId,
                                referencedTable: $$ProductTagsTableReferences
                                    ._productIdTable(db),
                                referencedColumn: $$ProductTagsTableReferences
                                    ._productIdTable(db)
                                    .id,
                              )
                              as T;
                    }
                    if (tagId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.tagId,
                                referencedTable: $$ProductTagsTableReferences
                                    ._tagIdTable(db),
                                referencedColumn: $$ProductTagsTableReferences
                                    ._tagIdTable(db)
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

typedef $$ProductTagsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProductTagsTable,
      ProductTagRow,
      $$ProductTagsTableFilterComposer,
      $$ProductTagsTableOrderingComposer,
      $$ProductTagsTableAnnotationComposer,
      $$ProductTagsTableCreateCompanionBuilder,
      $$ProductTagsTableUpdateCompanionBuilder,
      (ProductTagRow, $$ProductTagsTableReferences),
      ProductTagRow,
      PrefetchHooks Function({bool productId, bool tagId})
    >;
typedef $$AdminsTableCreateCompanionBuilder =
    AdminsCompanion Function({
      Value<int> id,
      required String username,
      required String passwordHash,
      required int createdAt,
    });
typedef $$AdminsTableUpdateCompanionBuilder =
    AdminsCompanion Function({
      Value<int> id,
      Value<String> username,
      Value<String> passwordHash,
      Value<int> createdAt,
    });

class $$AdminsTableFilterComposer
    extends Composer<_$AppDatabase, $AdminsTable> {
  $$AdminsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get username => $composableBuilder(
    column: $table.username,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get passwordHash => $composableBuilder(
    column: $table.passwordHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AdminsTableOrderingComposer
    extends Composer<_$AppDatabase, $AdminsTable> {
  $$AdminsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get username => $composableBuilder(
    column: $table.username,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get passwordHash => $composableBuilder(
    column: $table.passwordHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AdminsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AdminsTable> {
  $$AdminsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get username =>
      $composableBuilder(column: $table.username, builder: (column) => column);

  GeneratedColumn<String> get passwordHash => $composableBuilder(
    column: $table.passwordHash,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$AdminsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AdminsTable,
          AdminRow,
          $$AdminsTableFilterComposer,
          $$AdminsTableOrderingComposer,
          $$AdminsTableAnnotationComposer,
          $$AdminsTableCreateCompanionBuilder,
          $$AdminsTableUpdateCompanionBuilder,
          (AdminRow, BaseReferences<_$AppDatabase, $AdminsTable, AdminRow>),
          AdminRow,
          PrefetchHooks Function()
        > {
  $$AdminsTableTableManager(_$AppDatabase db, $AdminsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AdminsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AdminsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AdminsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> username = const Value.absent(),
                Value<String> passwordHash = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
              }) => AdminsCompanion(
                id: id,
                username: username,
                passwordHash: passwordHash,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String username,
                required String passwordHash,
                required int createdAt,
              }) => AdminsCompanion.insert(
                id: id,
                username: username,
                passwordHash: passwordHash,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AdminsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AdminsTable,
      AdminRow,
      $$AdminsTableFilterComposer,
      $$AdminsTableOrderingComposer,
      $$AdminsTableAnnotationComposer,
      $$AdminsTableCreateCompanionBuilder,
      $$AdminsTableUpdateCompanionBuilder,
      (AdminRow, BaseReferences<_$AppDatabase, $AdminsTable, AdminRow>),
      AdminRow,
      PrefetchHooks Function()
    >;
typedef $$SeededTagOffersTableCreateCompanionBuilder =
    SeededTagOffersCompanion Function({
      required TagCategory category,
      required int seedIndex,
      Value<int> rowid,
    });
typedef $$SeededTagOffersTableUpdateCompanionBuilder =
    SeededTagOffersCompanion Function({
      Value<TagCategory> category,
      Value<int> seedIndex,
      Value<int> rowid,
    });

class $$SeededTagOffersTableFilterComposer
    extends Composer<_$AppDatabase, $SeededTagOffersTable> {
  $$SeededTagOffersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnWithTypeConverterFilters<TagCategory, TagCategory, String>
  get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get seedIndex => $composableBuilder(
    column: $table.seedIndex,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SeededTagOffersTableOrderingComposer
    extends Composer<_$AppDatabase, $SeededTagOffersTable> {
  $$SeededTagOffersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get seedIndex => $composableBuilder(
    column: $table.seedIndex,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SeededTagOffersTableAnnotationComposer
    extends Composer<_$AppDatabase, $SeededTagOffersTable> {
  $$SeededTagOffersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumnWithTypeConverter<TagCategory, String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<int> get seedIndex =>
      $composableBuilder(column: $table.seedIndex, builder: (column) => column);
}

class $$SeededTagOffersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SeededTagOffersTable,
          SeededTagOfferRow,
          $$SeededTagOffersTableFilterComposer,
          $$SeededTagOffersTableOrderingComposer,
          $$SeededTagOffersTableAnnotationComposer,
          $$SeededTagOffersTableCreateCompanionBuilder,
          $$SeededTagOffersTableUpdateCompanionBuilder,
          (
            SeededTagOfferRow,
            BaseReferences<
              _$AppDatabase,
              $SeededTagOffersTable,
              SeededTagOfferRow
            >,
          ),
          SeededTagOfferRow,
          PrefetchHooks Function()
        > {
  $$SeededTagOffersTableTableManager(
    _$AppDatabase db,
    $SeededTagOffersTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SeededTagOffersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SeededTagOffersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SeededTagOffersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<TagCategory> category = const Value.absent(),
                Value<int> seedIndex = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SeededTagOffersCompanion(
                category: category,
                seedIndex: seedIndex,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required TagCategory category,
                required int seedIndex,
                Value<int> rowid = const Value.absent(),
              }) => SeededTagOffersCompanion.insert(
                category: category,
                seedIndex: seedIndex,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SeededTagOffersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SeededTagOffersTable,
      SeededTagOfferRow,
      $$SeededTagOffersTableFilterComposer,
      $$SeededTagOffersTableOrderingComposer,
      $$SeededTagOffersTableAnnotationComposer,
      $$SeededTagOffersTableCreateCompanionBuilder,
      $$SeededTagOffersTableUpdateCompanionBuilder,
      (
        SeededTagOfferRow,
        BaseReferences<_$AppDatabase, $SeededTagOffersTable, SeededTagOfferRow>,
      ),
      SeededTagOfferRow,
      PrefetchHooks Function()
    >;
typedef $$AppSettingsTableCreateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<int> id,
      required String welcomeTitle,
      required String extraLine,
    });
typedef $$AppSettingsTableUpdateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<int> id,
      Value<String> welcomeTitle,
      Value<String> extraLine,
    });

class $$AppSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get welcomeTitle => $composableBuilder(
    column: $table.welcomeTitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get extraLine => $composableBuilder(
    column: $table.extraLine,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get welcomeTitle => $composableBuilder(
    column: $table.welcomeTitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get extraLine => $composableBuilder(
    column: $table.extraLine,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get welcomeTitle => $composableBuilder(
    column: $table.welcomeTitle,
    builder: (column) => column,
  );

  GeneratedColumn<String> get extraLine =>
      $composableBuilder(column: $table.extraLine, builder: (column) => column);
}

class $$AppSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppSettingsTable,
          AppSettingsRow,
          $$AppSettingsTableFilterComposer,
          $$AppSettingsTableOrderingComposer,
          $$AppSettingsTableAnnotationComposer,
          $$AppSettingsTableCreateCompanionBuilder,
          $$AppSettingsTableUpdateCompanionBuilder,
          (
            AppSettingsRow,
            BaseReferences<_$AppDatabase, $AppSettingsTable, AppSettingsRow>,
          ),
          AppSettingsRow,
          PrefetchHooks Function()
        > {
  $$AppSettingsTableTableManager(_$AppDatabase db, $AppSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> welcomeTitle = const Value.absent(),
                Value<String> extraLine = const Value.absent(),
              }) => AppSettingsCompanion(
                id: id,
                welcomeTitle: welcomeTitle,
                extraLine: extraLine,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String welcomeTitle,
                required String extraLine,
              }) => AppSettingsCompanion.insert(
                id: id,
                welcomeTitle: welcomeTitle,
                extraLine: extraLine,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppSettingsTable,
      AppSettingsRow,
      $$AppSettingsTableFilterComposer,
      $$AppSettingsTableOrderingComposer,
      $$AppSettingsTableAnnotationComposer,
      $$AppSettingsTableCreateCompanionBuilder,
      $$AppSettingsTableUpdateCompanionBuilder,
      (
        AppSettingsRow,
        BaseReferences<_$AppDatabase, $AppSettingsTable, AppSettingsRow>,
      ),
      AppSettingsRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ProductsTableTableManager get products =>
      $$ProductsTableTableManager(_db, _db.products);
  $$SuitabilityTagsTableTableManager get suitabilityTags =>
      $$SuitabilityTagsTableTableManager(_db, _db.suitabilityTags);
  $$ProductTagsTableTableManager get productTags =>
      $$ProductTagsTableTableManager(_db, _db.productTags);
  $$AdminsTableTableManager get admins =>
      $$AdminsTableTableManager(_db, _db.admins);
  $$SeededTagOffersTableTableManager get seededTagOffers =>
      $$SeededTagOffersTableTableManager(_db, _db.seededTagOffers);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
}
