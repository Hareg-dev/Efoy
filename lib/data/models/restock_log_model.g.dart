// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'restock_log_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetRestockLogModelCollection on Isar {
  IsarCollection<RestockLogModel> get restockLogModels => this.collection();
}

const RestockLogModelSchema = CollectionSchema(
  name: r'RestockLogModel',
  id: 2343846767443349402,
  properties: {
    r'createdAt': PropertySchema(
      id: 0,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'invoiceNumber': PropertySchema(
      id: 1,
      name: r'invoiceNumber',
      type: IsarType.string,
    ),
    r'notes': PropertySchema(
      id: 2,
      name: r'notes',
      type: IsarType.string,
    ),
    r'productId': PropertySchema(
      id: 3,
      name: r'productId',
      type: IsarType.long,
    ),
    r'productName': PropertySchema(
      id: 4,
      name: r'productName',
      type: IsarType.string,
    ),
    r'purchasePrice': PropertySchema(
      id: 5,
      name: r'purchasePrice',
      type: IsarType.double,
    ),
    r'quantityAdded': PropertySchema(
      id: 6,
      name: r'quantityAdded',
      type: IsarType.long,
    ),
    r'restockDate': PropertySchema(
      id: 7,
      name: r'restockDate',
      type: IsarType.dateTime,
    ),
    r'stockAfter': PropertySchema(
      id: 8,
      name: r'stockAfter',
      type: IsarType.long,
    ),
    r'stockBefore': PropertySchema(
      id: 9,
      name: r'stockBefore',
      type: IsarType.long,
    ),
    r'supplierName': PropertySchema(
      id: 10,
      name: r'supplierName',
      type: IsarType.string,
    ),
    r'totalCost': PropertySchema(
      id: 11,
      name: r'totalCost',
      type: IsarType.double,
    ),
    r'wacAfter': PropertySchema(
      id: 12,
      name: r'wacAfter',
      type: IsarType.double,
    ),
    r'wacBefore': PropertySchema(
      id: 13,
      name: r'wacBefore',
      type: IsarType.double,
    )
  },
  estimateSize: _restockLogModelEstimateSize,
  serialize: _restockLogModelSerialize,
  deserialize: _restockLogModelDeserialize,
  deserializeProp: _restockLogModelDeserializeProp,
  idName: r'id',
  indexes: {
    r'productId': IndexSchema(
      id: 5580769080710688203,
      name: r'productId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'productId',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    ),
    r'restockDate': IndexSchema(
      id: -7837362293775498934,
      name: r'restockDate',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'restockDate',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _restockLogModelGetId,
  getLinks: _restockLogModelGetLinks,
  attach: _restockLogModelAttach,
  version: '3.1.0+1',
);

int _restockLogModelEstimateSize(
  RestockLogModel object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.invoiceNumber;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.notes;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.productName.length * 3;
  {
    final value = object.supplierName;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _restockLogModelSerialize(
  RestockLogModel object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.createdAt);
  writer.writeString(offsets[1], object.invoiceNumber);
  writer.writeString(offsets[2], object.notes);
  writer.writeLong(offsets[3], object.productId);
  writer.writeString(offsets[4], object.productName);
  writer.writeDouble(offsets[5], object.purchasePrice);
  writer.writeLong(offsets[6], object.quantityAdded);
  writer.writeDateTime(offsets[7], object.restockDate);
  writer.writeLong(offsets[8], object.stockAfter);
  writer.writeLong(offsets[9], object.stockBefore);
  writer.writeString(offsets[10], object.supplierName);
  writer.writeDouble(offsets[11], object.totalCost);
  writer.writeDouble(offsets[12], object.wacAfter);
  writer.writeDouble(offsets[13], object.wacBefore);
}

RestockLogModel _restockLogModelDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = RestockLogModel(
    createdAt: reader.readDateTime(offsets[0]),
    invoiceNumber: reader.readStringOrNull(offsets[1]),
    notes: reader.readStringOrNull(offsets[2]),
    productId: reader.readLong(offsets[3]),
    productName: reader.readString(offsets[4]),
    purchasePrice: reader.readDouble(offsets[5]),
    quantityAdded: reader.readLong(offsets[6]),
    restockDate: reader.readDateTime(offsets[7]),
    stockAfter: reader.readLong(offsets[8]),
    stockBefore: reader.readLong(offsets[9]),
    supplierName: reader.readStringOrNull(offsets[10]),
    totalCost: reader.readDouble(offsets[11]),
    wacAfter: reader.readDouble(offsets[12]),
    wacBefore: reader.readDouble(offsets[13]),
  );
  object.id = id;
  return object;
}

P _restockLogModelDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTime(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readDouble(offset)) as P;
    case 6:
      return (reader.readLong(offset)) as P;
    case 7:
      return (reader.readDateTime(offset)) as P;
    case 8:
      return (reader.readLong(offset)) as P;
    case 9:
      return (reader.readLong(offset)) as P;
    case 10:
      return (reader.readStringOrNull(offset)) as P;
    case 11:
      return (reader.readDouble(offset)) as P;
    case 12:
      return (reader.readDouble(offset)) as P;
    case 13:
      return (reader.readDouble(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _restockLogModelGetId(RestockLogModel object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _restockLogModelGetLinks(RestockLogModel object) {
  return [];
}

void _restockLogModelAttach(
    IsarCollection<dynamic> col, Id id, RestockLogModel object) {
  object.id = id;
}

extension RestockLogModelQueryWhereSort
    on QueryBuilder<RestockLogModel, RestockLogModel, QWhere> {
  QueryBuilder<RestockLogModel, RestockLogModel, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterWhere> anyProductId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'productId'),
      );
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterWhere> anyRestockDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'restockDate'),
      );
    });
  }
}

extension RestockLogModelQueryWhere
    on QueryBuilder<RestockLogModel, RestockLogModel, QWhereClause> {
  QueryBuilder<RestockLogModel, RestockLogModel, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterWhereClause>
      idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterWhereClause>
      productIdEqualTo(int productId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'productId',
        value: [productId],
      ));
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterWhereClause>
      productIdNotEqualTo(int productId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'productId',
              lower: [],
              upper: [productId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'productId',
              lower: [productId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'productId',
              lower: [productId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'productId',
              lower: [],
              upper: [productId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterWhereClause>
      productIdGreaterThan(
    int productId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'productId',
        lower: [productId],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterWhereClause>
      productIdLessThan(
    int productId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'productId',
        lower: [],
        upper: [productId],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterWhereClause>
      productIdBetween(
    int lowerProductId,
    int upperProductId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'productId',
        lower: [lowerProductId],
        includeLower: includeLower,
        upper: [upperProductId],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterWhereClause>
      restockDateEqualTo(DateTime restockDate) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'restockDate',
        value: [restockDate],
      ));
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterWhereClause>
      restockDateNotEqualTo(DateTime restockDate) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'restockDate',
              lower: [],
              upper: [restockDate],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'restockDate',
              lower: [restockDate],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'restockDate',
              lower: [restockDate],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'restockDate',
              lower: [],
              upper: [restockDate],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterWhereClause>
      restockDateGreaterThan(
    DateTime restockDate, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'restockDate',
        lower: [restockDate],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterWhereClause>
      restockDateLessThan(
    DateTime restockDate, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'restockDate',
        lower: [],
        upper: [restockDate],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterWhereClause>
      restockDateBetween(
    DateTime lowerRestockDate,
    DateTime upperRestockDate, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'restockDate',
        lower: [lowerRestockDate],
        includeLower: includeLower,
        upper: [upperRestockDate],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension RestockLogModelQueryFilter
    on QueryBuilder<RestockLogModel, RestockLogModel, QFilterCondition> {
  QueryBuilder<RestockLogModel, RestockLogModel, QAfterFilterCondition>
      createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterFilterCondition>
      createdAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterFilterCondition>
      createdAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterFilterCondition>
      createdAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'createdAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterFilterCondition>
      idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterFilterCondition>
      idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterFilterCondition>
      idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterFilterCondition>
      invoiceNumberIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'invoiceNumber',
      ));
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterFilterCondition>
      invoiceNumberIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'invoiceNumber',
      ));
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterFilterCondition>
      invoiceNumberEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'invoiceNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterFilterCondition>
      invoiceNumberGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'invoiceNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterFilterCondition>
      invoiceNumberLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'invoiceNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterFilterCondition>
      invoiceNumberBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'invoiceNumber',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterFilterCondition>
      invoiceNumberStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'invoiceNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterFilterCondition>
      invoiceNumberEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'invoiceNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterFilterCondition>
      invoiceNumberContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'invoiceNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterFilterCondition>
      invoiceNumberMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'invoiceNumber',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterFilterCondition>
      invoiceNumberIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'invoiceNumber',
        value: '',
      ));
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterFilterCondition>
      invoiceNumberIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'invoiceNumber',
        value: '',
      ));
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterFilterCondition>
      notesIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'notes',
      ));
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterFilterCondition>
      notesIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'notes',
      ));
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterFilterCondition>
      notesEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterFilterCondition>
      notesGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterFilterCondition>
      notesLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterFilterCondition>
      notesBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'notes',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterFilterCondition>
      notesStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterFilterCondition>
      notesEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterFilterCondition>
      notesContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterFilterCondition>
      notesMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'notes',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterFilterCondition>
      notesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'notes',
        value: '',
      ));
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterFilterCondition>
      notesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'notes',
        value: '',
      ));
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterFilterCondition>
      productIdEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'productId',
        value: value,
      ));
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterFilterCondition>
      productIdGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'productId',
        value: value,
      ));
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterFilterCondition>
      productIdLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'productId',
        value: value,
      ));
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterFilterCondition>
      productIdBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'productId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterFilterCondition>
      productNameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'productName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterFilterCondition>
      productNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'productName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterFilterCondition>
      productNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'productName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterFilterCondition>
      productNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'productName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterFilterCondition>
      productNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'productName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterFilterCondition>
      productNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'productName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterFilterCondition>
      productNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'productName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterFilterCondition>
      productNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'productName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterFilterCondition>
      productNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'productName',
        value: '',
      ));
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterFilterCondition>
      productNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'productName',
        value: '',
      ));
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterFilterCondition>
      purchasePriceEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'purchasePrice',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterFilterCondition>
      purchasePriceGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'purchasePrice',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterFilterCondition>
      purchasePriceLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'purchasePrice',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterFilterCondition>
      purchasePriceBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'purchasePrice',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterFilterCondition>
      quantityAddedEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'quantityAdded',
        value: value,
      ));
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterFilterCondition>
      quantityAddedGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'quantityAdded',
        value: value,
      ));
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterFilterCondition>
      quantityAddedLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'quantityAdded',
        value: value,
      ));
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterFilterCondition>
      quantityAddedBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'quantityAdded',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterFilterCondition>
      restockDateEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'restockDate',
        value: value,
      ));
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterFilterCondition>
      restockDateGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'restockDate',
        value: value,
      ));
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterFilterCondition>
      restockDateLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'restockDate',
        value: value,
      ));
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterFilterCondition>
      restockDateBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'restockDate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterFilterCondition>
      stockAfterEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'stockAfter',
        value: value,
      ));
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterFilterCondition>
      stockAfterGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'stockAfter',
        value: value,
      ));
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterFilterCondition>
      stockAfterLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'stockAfter',
        value: value,
      ));
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterFilterCondition>
      stockAfterBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'stockAfter',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterFilterCondition>
      stockBeforeEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'stockBefore',
        value: value,
      ));
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterFilterCondition>
      stockBeforeGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'stockBefore',
        value: value,
      ));
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterFilterCondition>
      stockBeforeLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'stockBefore',
        value: value,
      ));
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterFilterCondition>
      stockBeforeBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'stockBefore',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterFilterCondition>
      supplierNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'supplierName',
      ));
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterFilterCondition>
      supplierNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'supplierName',
      ));
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterFilterCondition>
      supplierNameEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'supplierName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterFilterCondition>
      supplierNameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'supplierName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterFilterCondition>
      supplierNameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'supplierName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterFilterCondition>
      supplierNameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'supplierName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterFilterCondition>
      supplierNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'supplierName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterFilterCondition>
      supplierNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'supplierName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterFilterCondition>
      supplierNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'supplierName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterFilterCondition>
      supplierNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'supplierName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterFilterCondition>
      supplierNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'supplierName',
        value: '',
      ));
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterFilterCondition>
      supplierNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'supplierName',
        value: '',
      ));
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterFilterCondition>
      totalCostEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'totalCost',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterFilterCondition>
      totalCostGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'totalCost',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterFilterCondition>
      totalCostLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'totalCost',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterFilterCondition>
      totalCostBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'totalCost',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterFilterCondition>
      wacAfterEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'wacAfter',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterFilterCondition>
      wacAfterGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'wacAfter',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterFilterCondition>
      wacAfterLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'wacAfter',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterFilterCondition>
      wacAfterBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'wacAfter',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterFilterCondition>
      wacBeforeEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'wacBefore',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterFilterCondition>
      wacBeforeGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'wacBefore',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterFilterCondition>
      wacBeforeLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'wacBefore',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterFilterCondition>
      wacBeforeBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'wacBefore',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }
}

extension RestockLogModelQueryObject
    on QueryBuilder<RestockLogModel, RestockLogModel, QFilterCondition> {}

extension RestockLogModelQueryLinks
    on QueryBuilder<RestockLogModel, RestockLogModel, QFilterCondition> {}

extension RestockLogModelQuerySortBy
    on QueryBuilder<RestockLogModel, RestockLogModel, QSortBy> {
  QueryBuilder<RestockLogModel, RestockLogModel, QAfterSortBy>
      sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterSortBy>
      sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterSortBy>
      sortByInvoiceNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'invoiceNumber', Sort.asc);
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterSortBy>
      sortByInvoiceNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'invoiceNumber', Sort.desc);
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterSortBy> sortByNotes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.asc);
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterSortBy>
      sortByNotesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.desc);
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterSortBy>
      sortByProductId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'productId', Sort.asc);
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterSortBy>
      sortByProductIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'productId', Sort.desc);
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterSortBy>
      sortByProductName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'productName', Sort.asc);
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterSortBy>
      sortByProductNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'productName', Sort.desc);
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterSortBy>
      sortByPurchasePrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'purchasePrice', Sort.asc);
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterSortBy>
      sortByPurchasePriceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'purchasePrice', Sort.desc);
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterSortBy>
      sortByQuantityAdded() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'quantityAdded', Sort.asc);
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterSortBy>
      sortByQuantityAddedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'quantityAdded', Sort.desc);
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterSortBy>
      sortByRestockDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'restockDate', Sort.asc);
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterSortBy>
      sortByRestockDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'restockDate', Sort.desc);
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterSortBy>
      sortByStockAfter() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'stockAfter', Sort.asc);
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterSortBy>
      sortByStockAfterDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'stockAfter', Sort.desc);
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterSortBy>
      sortByStockBefore() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'stockBefore', Sort.asc);
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterSortBy>
      sortByStockBeforeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'stockBefore', Sort.desc);
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterSortBy>
      sortBySupplierName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'supplierName', Sort.asc);
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterSortBy>
      sortBySupplierNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'supplierName', Sort.desc);
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterSortBy>
      sortByTotalCost() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalCost', Sort.asc);
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterSortBy>
      sortByTotalCostDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalCost', Sort.desc);
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterSortBy>
      sortByWacAfter() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'wacAfter', Sort.asc);
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterSortBy>
      sortByWacAfterDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'wacAfter', Sort.desc);
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterSortBy>
      sortByWacBefore() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'wacBefore', Sort.asc);
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterSortBy>
      sortByWacBeforeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'wacBefore', Sort.desc);
    });
  }
}

extension RestockLogModelQuerySortThenBy
    on QueryBuilder<RestockLogModel, RestockLogModel, QSortThenBy> {
  QueryBuilder<RestockLogModel, RestockLogModel, QAfterSortBy>
      thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterSortBy>
      thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterSortBy>
      thenByInvoiceNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'invoiceNumber', Sort.asc);
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterSortBy>
      thenByInvoiceNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'invoiceNumber', Sort.desc);
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterSortBy> thenByNotes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.asc);
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterSortBy>
      thenByNotesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.desc);
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterSortBy>
      thenByProductId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'productId', Sort.asc);
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterSortBy>
      thenByProductIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'productId', Sort.desc);
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterSortBy>
      thenByProductName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'productName', Sort.asc);
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterSortBy>
      thenByProductNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'productName', Sort.desc);
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterSortBy>
      thenByPurchasePrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'purchasePrice', Sort.asc);
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterSortBy>
      thenByPurchasePriceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'purchasePrice', Sort.desc);
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterSortBy>
      thenByQuantityAdded() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'quantityAdded', Sort.asc);
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterSortBy>
      thenByQuantityAddedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'quantityAdded', Sort.desc);
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterSortBy>
      thenByRestockDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'restockDate', Sort.asc);
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterSortBy>
      thenByRestockDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'restockDate', Sort.desc);
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterSortBy>
      thenByStockAfter() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'stockAfter', Sort.asc);
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterSortBy>
      thenByStockAfterDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'stockAfter', Sort.desc);
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterSortBy>
      thenByStockBefore() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'stockBefore', Sort.asc);
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterSortBy>
      thenByStockBeforeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'stockBefore', Sort.desc);
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterSortBy>
      thenBySupplierName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'supplierName', Sort.asc);
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterSortBy>
      thenBySupplierNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'supplierName', Sort.desc);
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterSortBy>
      thenByTotalCost() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalCost', Sort.asc);
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterSortBy>
      thenByTotalCostDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalCost', Sort.desc);
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterSortBy>
      thenByWacAfter() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'wacAfter', Sort.asc);
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterSortBy>
      thenByWacAfterDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'wacAfter', Sort.desc);
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterSortBy>
      thenByWacBefore() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'wacBefore', Sort.asc);
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QAfterSortBy>
      thenByWacBeforeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'wacBefore', Sort.desc);
    });
  }
}

extension RestockLogModelQueryWhereDistinct
    on QueryBuilder<RestockLogModel, RestockLogModel, QDistinct> {
  QueryBuilder<RestockLogModel, RestockLogModel, QDistinct>
      distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QDistinct>
      distinctByInvoiceNumber({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'invoiceNumber',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QDistinct> distinctByNotes(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'notes', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QDistinct>
      distinctByProductId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'productId');
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QDistinct>
      distinctByProductName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'productName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QDistinct>
      distinctByPurchasePrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'purchasePrice');
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QDistinct>
      distinctByQuantityAdded() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'quantityAdded');
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QDistinct>
      distinctByRestockDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'restockDate');
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QDistinct>
      distinctByStockAfter() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'stockAfter');
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QDistinct>
      distinctByStockBefore() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'stockBefore');
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QDistinct>
      distinctBySupplierName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'supplierName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QDistinct>
      distinctByTotalCost() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'totalCost');
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QDistinct>
      distinctByWacAfter() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'wacAfter');
    });
  }

  QueryBuilder<RestockLogModel, RestockLogModel, QDistinct>
      distinctByWacBefore() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'wacBefore');
    });
  }
}

extension RestockLogModelQueryProperty
    on QueryBuilder<RestockLogModel, RestockLogModel, QQueryProperty> {
  QueryBuilder<RestockLogModel, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<RestockLogModel, DateTime, QQueryOperations>
      createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<RestockLogModel, String?, QQueryOperations>
      invoiceNumberProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'invoiceNumber');
    });
  }

  QueryBuilder<RestockLogModel, String?, QQueryOperations> notesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'notes');
    });
  }

  QueryBuilder<RestockLogModel, int, QQueryOperations> productIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'productId');
    });
  }

  QueryBuilder<RestockLogModel, String, QQueryOperations>
      productNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'productName');
    });
  }

  QueryBuilder<RestockLogModel, double, QQueryOperations>
      purchasePriceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'purchasePrice');
    });
  }

  QueryBuilder<RestockLogModel, int, QQueryOperations> quantityAddedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'quantityAdded');
    });
  }

  QueryBuilder<RestockLogModel, DateTime, QQueryOperations>
      restockDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'restockDate');
    });
  }

  QueryBuilder<RestockLogModel, int, QQueryOperations> stockAfterProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'stockAfter');
    });
  }

  QueryBuilder<RestockLogModel, int, QQueryOperations> stockBeforeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'stockBefore');
    });
  }

  QueryBuilder<RestockLogModel, String?, QQueryOperations>
      supplierNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'supplierName');
    });
  }

  QueryBuilder<RestockLogModel, double, QQueryOperations> totalCostProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'totalCost');
    });
  }

  QueryBuilder<RestockLogModel, double, QQueryOperations> wacAfterProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'wacAfter');
    });
  }

  QueryBuilder<RestockLogModel, double, QQueryOperations> wacBeforeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'wacBefore');
    });
  }
}
