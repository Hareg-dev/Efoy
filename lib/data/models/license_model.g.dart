// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'license_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetLicenseModelCollection on Isar {
  IsarCollection<LicenseModel> get licenseModels => this.collection();
}

const LicenseModelSchema = CollectionSchema(
  name: r'LicenseModel',
  id: 2291380629547682491,
  properties: {
    r'activatedAt': PropertySchema(
      id: 0,
      name: r'activatedAt',
      type: IsarType.dateTime,
    ),
    r'daysRemaining': PropertySchema(
      id: 1,
      name: r'daysRemaining',
      type: IsarType.long,
    ),
    r'deviceId': PropertySchema(
      id: 2,
      name: r'deviceId',
      type: IsarType.string,
    ),
    r'expiresAt': PropertySchema(
      id: 3,
      name: r'expiresAt',
      type: IsarType.dateTime,
    ),
    r'isActive': PropertySchema(
      id: 4,
      name: r'isActive',
      type: IsarType.bool,
    ),
    r'isExpired': PropertySchema(
      id: 5,
      name: r'isExpired',
      type: IsarType.bool,
    ),
    r'isValid': PropertySchema(
      id: 6,
      name: r'isValid',
      type: IsarType.bool,
    ),
    r'licenseKey': PropertySchema(
      id: 7,
      name: r'licenseKey',
      type: IsarType.string,
    ),
    r'licenseType': PropertySchema(
      id: 8,
      name: r'licenseType',
      type: IsarType.byte,
      enumMap: _LicenseModellicenseTypeEnumValueMap,
    ),
    r'ownerPhone': PropertySchema(
      id: 9,
      name: r'ownerPhone',
      type: IsarType.string,
    ),
    r'storeName': PropertySchema(
      id: 10,
      name: r'storeName',
      type: IsarType.string,
    )
  },
  estimateSize: _licenseModelEstimateSize,
  serialize: _licenseModelSerialize,
  deserialize: _licenseModelDeserialize,
  deserializeProp: _licenseModelDeserializeProp,
  idName: r'id',
  indexes: {
    r'activatedAt': IndexSchema(
      id: -5947525253472437360,
      name: r'activatedAt',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'activatedAt',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    ),
    r'isActive': IndexSchema(
      id: 8092228061260947457,
      name: r'isActive',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'isActive',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _licenseModelGetId,
  getLinks: _licenseModelGetLinks,
  attach: _licenseModelAttach,
  version: '3.1.0+1',
);

int _licenseModelEstimateSize(
  LicenseModel object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.deviceId.length * 3;
  bytesCount += 3 + object.licenseKey.length * 3;
  {
    final value = object.ownerPhone;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.storeName;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _licenseModelSerialize(
  LicenseModel object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.activatedAt);
  writer.writeLong(offsets[1], object.daysRemaining);
  writer.writeString(offsets[2], object.deviceId);
  writer.writeDateTime(offsets[3], object.expiresAt);
  writer.writeBool(offsets[4], object.isActive);
  writer.writeBool(offsets[5], object.isExpired);
  writer.writeBool(offsets[6], object.isValid);
  writer.writeString(offsets[7], object.licenseKey);
  writer.writeByte(offsets[8], object.licenseType.index);
  writer.writeString(offsets[9], object.ownerPhone);
  writer.writeString(offsets[10], object.storeName);
}

LicenseModel _licenseModelDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = LicenseModel(
    activatedAt: reader.readDateTime(offsets[0]),
    deviceId: reader.readString(offsets[2]),
    expiresAt: reader.readDateTime(offsets[3]),
    isActive: reader.readBoolOrNull(offsets[4]) ?? true,
    isExpired: reader.readBoolOrNull(offsets[5]) ?? false,
    licenseKey: reader.readString(offsets[7]),
    licenseType: _LicenseModellicenseTypeValueEnumMap[
            reader.readByteOrNull(offsets[8])] ??
        LicenseType.trial,
    ownerPhone: reader.readStringOrNull(offsets[9]),
    storeName: reader.readStringOrNull(offsets[10]),
  );
  object.id = id;
  return object;
}

P _licenseModelDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTime(offset)) as P;
    case 1:
      return (reader.readLong(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readDateTime(offset)) as P;
    case 4:
      return (reader.readBoolOrNull(offset) ?? true) as P;
    case 5:
      return (reader.readBoolOrNull(offset) ?? false) as P;
    case 6:
      return (reader.readBool(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    case 8:
      return (_LicenseModellicenseTypeValueEnumMap[
              reader.readByteOrNull(offset)] ??
          LicenseType.trial) as P;
    case 9:
      return (reader.readStringOrNull(offset)) as P;
    case 10:
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _LicenseModellicenseTypeEnumValueMap = {
  'trial': 0,
  'monthly': 1,
  'yearly': 2,
  'lifetime': 3,
};
const _LicenseModellicenseTypeValueEnumMap = {
  0: LicenseType.trial,
  1: LicenseType.monthly,
  2: LicenseType.yearly,
  3: LicenseType.lifetime,
};

Id _licenseModelGetId(LicenseModel object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _licenseModelGetLinks(LicenseModel object) {
  return [];
}

void _licenseModelAttach(
    IsarCollection<dynamic> col, Id id, LicenseModel object) {
  object.id = id;
}

extension LicenseModelQueryWhereSort
    on QueryBuilder<LicenseModel, LicenseModel, QWhere> {
  QueryBuilder<LicenseModel, LicenseModel, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<LicenseModel, LicenseModel, QAfterWhere> anyActivatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'activatedAt'),
      );
    });
  }

  QueryBuilder<LicenseModel, LicenseModel, QAfterWhere> anyIsActive() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'isActive'),
      );
    });
  }
}

extension LicenseModelQueryWhere
    on QueryBuilder<LicenseModel, LicenseModel, QWhereClause> {
  QueryBuilder<LicenseModel, LicenseModel, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<LicenseModel, LicenseModel, QAfterWhereClause> idNotEqualTo(
      Id id) {
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

  QueryBuilder<LicenseModel, LicenseModel, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<LicenseModel, LicenseModel, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<LicenseModel, LicenseModel, QAfterWhereClause> idBetween(
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

  QueryBuilder<LicenseModel, LicenseModel, QAfterWhereClause>
      activatedAtEqualTo(DateTime activatedAt) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'activatedAt',
        value: [activatedAt],
      ));
    });
  }

  QueryBuilder<LicenseModel, LicenseModel, QAfterWhereClause>
      activatedAtNotEqualTo(DateTime activatedAt) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'activatedAt',
              lower: [],
              upper: [activatedAt],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'activatedAt',
              lower: [activatedAt],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'activatedAt',
              lower: [activatedAt],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'activatedAt',
              lower: [],
              upper: [activatedAt],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<LicenseModel, LicenseModel, QAfterWhereClause>
      activatedAtGreaterThan(
    DateTime activatedAt, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'activatedAt',
        lower: [activatedAt],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<LicenseModel, LicenseModel, QAfterWhereClause>
      activatedAtLessThan(
    DateTime activatedAt, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'activatedAt',
        lower: [],
        upper: [activatedAt],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<LicenseModel, LicenseModel, QAfterWhereClause>
      activatedAtBetween(
    DateTime lowerActivatedAt,
    DateTime upperActivatedAt, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'activatedAt',
        lower: [lowerActivatedAt],
        includeLower: includeLower,
        upper: [upperActivatedAt],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<LicenseModel, LicenseModel, QAfterWhereClause> isActiveEqualTo(
      bool isActive) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'isActive',
        value: [isActive],
      ));
    });
  }

  QueryBuilder<LicenseModel, LicenseModel, QAfterWhereClause>
      isActiveNotEqualTo(bool isActive) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'isActive',
              lower: [],
              upper: [isActive],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'isActive',
              lower: [isActive],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'isActive',
              lower: [isActive],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'isActive',
              lower: [],
              upper: [isActive],
              includeUpper: false,
            ));
      }
    });
  }
}

extension LicenseModelQueryFilter
    on QueryBuilder<LicenseModel, LicenseModel, QFilterCondition> {
  QueryBuilder<LicenseModel, LicenseModel, QAfterFilterCondition>
      activatedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'activatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<LicenseModel, LicenseModel, QAfterFilterCondition>
      activatedAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'activatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<LicenseModel, LicenseModel, QAfterFilterCondition>
      activatedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'activatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<LicenseModel, LicenseModel, QAfterFilterCondition>
      activatedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'activatedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<LicenseModel, LicenseModel, QAfterFilterCondition>
      daysRemainingEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'daysRemaining',
        value: value,
      ));
    });
  }

  QueryBuilder<LicenseModel, LicenseModel, QAfterFilterCondition>
      daysRemainingGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'daysRemaining',
        value: value,
      ));
    });
  }

  QueryBuilder<LicenseModel, LicenseModel, QAfterFilterCondition>
      daysRemainingLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'daysRemaining',
        value: value,
      ));
    });
  }

  QueryBuilder<LicenseModel, LicenseModel, QAfterFilterCondition>
      daysRemainingBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'daysRemaining',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<LicenseModel, LicenseModel, QAfterFilterCondition>
      deviceIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'deviceId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LicenseModel, LicenseModel, QAfterFilterCondition>
      deviceIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'deviceId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LicenseModel, LicenseModel, QAfterFilterCondition>
      deviceIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'deviceId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LicenseModel, LicenseModel, QAfterFilterCondition>
      deviceIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'deviceId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LicenseModel, LicenseModel, QAfterFilterCondition>
      deviceIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'deviceId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LicenseModel, LicenseModel, QAfterFilterCondition>
      deviceIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'deviceId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LicenseModel, LicenseModel, QAfterFilterCondition>
      deviceIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'deviceId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LicenseModel, LicenseModel, QAfterFilterCondition>
      deviceIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'deviceId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LicenseModel, LicenseModel, QAfterFilterCondition>
      deviceIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'deviceId',
        value: '',
      ));
    });
  }

  QueryBuilder<LicenseModel, LicenseModel, QAfterFilterCondition>
      deviceIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'deviceId',
        value: '',
      ));
    });
  }

  QueryBuilder<LicenseModel, LicenseModel, QAfterFilterCondition>
      expiresAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'expiresAt',
        value: value,
      ));
    });
  }

  QueryBuilder<LicenseModel, LicenseModel, QAfterFilterCondition>
      expiresAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'expiresAt',
        value: value,
      ));
    });
  }

  QueryBuilder<LicenseModel, LicenseModel, QAfterFilterCondition>
      expiresAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'expiresAt',
        value: value,
      ));
    });
  }

  QueryBuilder<LicenseModel, LicenseModel, QAfterFilterCondition>
      expiresAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'expiresAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<LicenseModel, LicenseModel, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<LicenseModel, LicenseModel, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<LicenseModel, LicenseModel, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<LicenseModel, LicenseModel, QAfterFilterCondition> idBetween(
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

  QueryBuilder<LicenseModel, LicenseModel, QAfterFilterCondition>
      isActiveEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isActive',
        value: value,
      ));
    });
  }

  QueryBuilder<LicenseModel, LicenseModel, QAfterFilterCondition>
      isExpiredEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isExpired',
        value: value,
      ));
    });
  }

  QueryBuilder<LicenseModel, LicenseModel, QAfterFilterCondition>
      isValidEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isValid',
        value: value,
      ));
    });
  }

  QueryBuilder<LicenseModel, LicenseModel, QAfterFilterCondition>
      licenseKeyEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'licenseKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LicenseModel, LicenseModel, QAfterFilterCondition>
      licenseKeyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'licenseKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LicenseModel, LicenseModel, QAfterFilterCondition>
      licenseKeyLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'licenseKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LicenseModel, LicenseModel, QAfterFilterCondition>
      licenseKeyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'licenseKey',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LicenseModel, LicenseModel, QAfterFilterCondition>
      licenseKeyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'licenseKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LicenseModel, LicenseModel, QAfterFilterCondition>
      licenseKeyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'licenseKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LicenseModel, LicenseModel, QAfterFilterCondition>
      licenseKeyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'licenseKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LicenseModel, LicenseModel, QAfterFilterCondition>
      licenseKeyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'licenseKey',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LicenseModel, LicenseModel, QAfterFilterCondition>
      licenseKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'licenseKey',
        value: '',
      ));
    });
  }

  QueryBuilder<LicenseModel, LicenseModel, QAfterFilterCondition>
      licenseKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'licenseKey',
        value: '',
      ));
    });
  }

  QueryBuilder<LicenseModel, LicenseModel, QAfterFilterCondition>
      licenseTypeEqualTo(LicenseType value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'licenseType',
        value: value,
      ));
    });
  }

  QueryBuilder<LicenseModel, LicenseModel, QAfterFilterCondition>
      licenseTypeGreaterThan(
    LicenseType value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'licenseType',
        value: value,
      ));
    });
  }

  QueryBuilder<LicenseModel, LicenseModel, QAfterFilterCondition>
      licenseTypeLessThan(
    LicenseType value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'licenseType',
        value: value,
      ));
    });
  }

  QueryBuilder<LicenseModel, LicenseModel, QAfterFilterCondition>
      licenseTypeBetween(
    LicenseType lower,
    LicenseType upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'licenseType',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<LicenseModel, LicenseModel, QAfterFilterCondition>
      ownerPhoneIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'ownerPhone',
      ));
    });
  }

  QueryBuilder<LicenseModel, LicenseModel, QAfterFilterCondition>
      ownerPhoneIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'ownerPhone',
      ));
    });
  }

  QueryBuilder<LicenseModel, LicenseModel, QAfterFilterCondition>
      ownerPhoneEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'ownerPhone',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LicenseModel, LicenseModel, QAfterFilterCondition>
      ownerPhoneGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'ownerPhone',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LicenseModel, LicenseModel, QAfterFilterCondition>
      ownerPhoneLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'ownerPhone',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LicenseModel, LicenseModel, QAfterFilterCondition>
      ownerPhoneBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'ownerPhone',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LicenseModel, LicenseModel, QAfterFilterCondition>
      ownerPhoneStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'ownerPhone',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LicenseModel, LicenseModel, QAfterFilterCondition>
      ownerPhoneEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'ownerPhone',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LicenseModel, LicenseModel, QAfterFilterCondition>
      ownerPhoneContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'ownerPhone',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LicenseModel, LicenseModel, QAfterFilterCondition>
      ownerPhoneMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'ownerPhone',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LicenseModel, LicenseModel, QAfterFilterCondition>
      ownerPhoneIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'ownerPhone',
        value: '',
      ));
    });
  }

  QueryBuilder<LicenseModel, LicenseModel, QAfterFilterCondition>
      ownerPhoneIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'ownerPhone',
        value: '',
      ));
    });
  }

  QueryBuilder<LicenseModel, LicenseModel, QAfterFilterCondition>
      storeNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'storeName',
      ));
    });
  }

  QueryBuilder<LicenseModel, LicenseModel, QAfterFilterCondition>
      storeNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'storeName',
      ));
    });
  }

  QueryBuilder<LicenseModel, LicenseModel, QAfterFilterCondition>
      storeNameEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'storeName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LicenseModel, LicenseModel, QAfterFilterCondition>
      storeNameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'storeName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LicenseModel, LicenseModel, QAfterFilterCondition>
      storeNameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'storeName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LicenseModel, LicenseModel, QAfterFilterCondition>
      storeNameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'storeName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LicenseModel, LicenseModel, QAfterFilterCondition>
      storeNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'storeName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LicenseModel, LicenseModel, QAfterFilterCondition>
      storeNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'storeName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LicenseModel, LicenseModel, QAfterFilterCondition>
      storeNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'storeName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LicenseModel, LicenseModel, QAfterFilterCondition>
      storeNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'storeName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LicenseModel, LicenseModel, QAfterFilterCondition>
      storeNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'storeName',
        value: '',
      ));
    });
  }

  QueryBuilder<LicenseModel, LicenseModel, QAfterFilterCondition>
      storeNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'storeName',
        value: '',
      ));
    });
  }
}

extension LicenseModelQueryObject
    on QueryBuilder<LicenseModel, LicenseModel, QFilterCondition> {}

extension LicenseModelQueryLinks
    on QueryBuilder<LicenseModel, LicenseModel, QFilterCondition> {}

extension LicenseModelQuerySortBy
    on QueryBuilder<LicenseModel, LicenseModel, QSortBy> {
  QueryBuilder<LicenseModel, LicenseModel, QAfterSortBy> sortByActivatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'activatedAt', Sort.asc);
    });
  }

  QueryBuilder<LicenseModel, LicenseModel, QAfterSortBy>
      sortByActivatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'activatedAt', Sort.desc);
    });
  }

  QueryBuilder<LicenseModel, LicenseModel, QAfterSortBy> sortByDaysRemaining() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'daysRemaining', Sort.asc);
    });
  }

  QueryBuilder<LicenseModel, LicenseModel, QAfterSortBy>
      sortByDaysRemainingDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'daysRemaining', Sort.desc);
    });
  }

  QueryBuilder<LicenseModel, LicenseModel, QAfterSortBy> sortByDeviceId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deviceId', Sort.asc);
    });
  }

  QueryBuilder<LicenseModel, LicenseModel, QAfterSortBy> sortByDeviceIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deviceId', Sort.desc);
    });
  }

  QueryBuilder<LicenseModel, LicenseModel, QAfterSortBy> sortByExpiresAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'expiresAt', Sort.asc);
    });
  }

  QueryBuilder<LicenseModel, LicenseModel, QAfterSortBy> sortByExpiresAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'expiresAt', Sort.desc);
    });
  }

  QueryBuilder<LicenseModel, LicenseModel, QAfterSortBy> sortByIsActive() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isActive', Sort.asc);
    });
  }

  QueryBuilder<LicenseModel, LicenseModel, QAfterSortBy> sortByIsActiveDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isActive', Sort.desc);
    });
  }

  QueryBuilder<LicenseModel, LicenseModel, QAfterSortBy> sortByIsExpired() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isExpired', Sort.asc);
    });
  }

  QueryBuilder<LicenseModel, LicenseModel, QAfterSortBy> sortByIsExpiredDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isExpired', Sort.desc);
    });
  }

  QueryBuilder<LicenseModel, LicenseModel, QAfterSortBy> sortByIsValid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isValid', Sort.asc);
    });
  }

  QueryBuilder<LicenseModel, LicenseModel, QAfterSortBy> sortByIsValidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isValid', Sort.desc);
    });
  }

  QueryBuilder<LicenseModel, LicenseModel, QAfterSortBy> sortByLicenseKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'licenseKey', Sort.asc);
    });
  }

  QueryBuilder<LicenseModel, LicenseModel, QAfterSortBy>
      sortByLicenseKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'licenseKey', Sort.desc);
    });
  }

  QueryBuilder<LicenseModel, LicenseModel, QAfterSortBy> sortByLicenseType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'licenseType', Sort.asc);
    });
  }

  QueryBuilder<LicenseModel, LicenseModel, QAfterSortBy>
      sortByLicenseTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'licenseType', Sort.desc);
    });
  }

  QueryBuilder<LicenseModel, LicenseModel, QAfterSortBy> sortByOwnerPhone() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerPhone', Sort.asc);
    });
  }

  QueryBuilder<LicenseModel, LicenseModel, QAfterSortBy>
      sortByOwnerPhoneDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerPhone', Sort.desc);
    });
  }

  QueryBuilder<LicenseModel, LicenseModel, QAfterSortBy> sortByStoreName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'storeName', Sort.asc);
    });
  }

  QueryBuilder<LicenseModel, LicenseModel, QAfterSortBy> sortByStoreNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'storeName', Sort.desc);
    });
  }
}

extension LicenseModelQuerySortThenBy
    on QueryBuilder<LicenseModel, LicenseModel, QSortThenBy> {
  QueryBuilder<LicenseModel, LicenseModel, QAfterSortBy> thenByActivatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'activatedAt', Sort.asc);
    });
  }

  QueryBuilder<LicenseModel, LicenseModel, QAfterSortBy>
      thenByActivatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'activatedAt', Sort.desc);
    });
  }

  QueryBuilder<LicenseModel, LicenseModel, QAfterSortBy> thenByDaysRemaining() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'daysRemaining', Sort.asc);
    });
  }

  QueryBuilder<LicenseModel, LicenseModel, QAfterSortBy>
      thenByDaysRemainingDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'daysRemaining', Sort.desc);
    });
  }

  QueryBuilder<LicenseModel, LicenseModel, QAfterSortBy> thenByDeviceId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deviceId', Sort.asc);
    });
  }

  QueryBuilder<LicenseModel, LicenseModel, QAfterSortBy> thenByDeviceIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deviceId', Sort.desc);
    });
  }

  QueryBuilder<LicenseModel, LicenseModel, QAfterSortBy> thenByExpiresAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'expiresAt', Sort.asc);
    });
  }

  QueryBuilder<LicenseModel, LicenseModel, QAfterSortBy> thenByExpiresAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'expiresAt', Sort.desc);
    });
  }

  QueryBuilder<LicenseModel, LicenseModel, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<LicenseModel, LicenseModel, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<LicenseModel, LicenseModel, QAfterSortBy> thenByIsActive() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isActive', Sort.asc);
    });
  }

  QueryBuilder<LicenseModel, LicenseModel, QAfterSortBy> thenByIsActiveDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isActive', Sort.desc);
    });
  }

  QueryBuilder<LicenseModel, LicenseModel, QAfterSortBy> thenByIsExpired() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isExpired', Sort.asc);
    });
  }

  QueryBuilder<LicenseModel, LicenseModel, QAfterSortBy> thenByIsExpiredDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isExpired', Sort.desc);
    });
  }

  QueryBuilder<LicenseModel, LicenseModel, QAfterSortBy> thenByIsValid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isValid', Sort.asc);
    });
  }

  QueryBuilder<LicenseModel, LicenseModel, QAfterSortBy> thenByIsValidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isValid', Sort.desc);
    });
  }

  QueryBuilder<LicenseModel, LicenseModel, QAfterSortBy> thenByLicenseKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'licenseKey', Sort.asc);
    });
  }

  QueryBuilder<LicenseModel, LicenseModel, QAfterSortBy>
      thenByLicenseKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'licenseKey', Sort.desc);
    });
  }

  QueryBuilder<LicenseModel, LicenseModel, QAfterSortBy> thenByLicenseType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'licenseType', Sort.asc);
    });
  }

  QueryBuilder<LicenseModel, LicenseModel, QAfterSortBy>
      thenByLicenseTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'licenseType', Sort.desc);
    });
  }

  QueryBuilder<LicenseModel, LicenseModel, QAfterSortBy> thenByOwnerPhone() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerPhone', Sort.asc);
    });
  }

  QueryBuilder<LicenseModel, LicenseModel, QAfterSortBy>
      thenByOwnerPhoneDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerPhone', Sort.desc);
    });
  }

  QueryBuilder<LicenseModel, LicenseModel, QAfterSortBy> thenByStoreName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'storeName', Sort.asc);
    });
  }

  QueryBuilder<LicenseModel, LicenseModel, QAfterSortBy> thenByStoreNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'storeName', Sort.desc);
    });
  }
}

extension LicenseModelQueryWhereDistinct
    on QueryBuilder<LicenseModel, LicenseModel, QDistinct> {
  QueryBuilder<LicenseModel, LicenseModel, QDistinct> distinctByActivatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'activatedAt');
    });
  }

  QueryBuilder<LicenseModel, LicenseModel, QDistinct>
      distinctByDaysRemaining() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'daysRemaining');
    });
  }

  QueryBuilder<LicenseModel, LicenseModel, QDistinct> distinctByDeviceId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'deviceId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LicenseModel, LicenseModel, QDistinct> distinctByExpiresAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'expiresAt');
    });
  }

  QueryBuilder<LicenseModel, LicenseModel, QDistinct> distinctByIsActive() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isActive');
    });
  }

  QueryBuilder<LicenseModel, LicenseModel, QDistinct> distinctByIsExpired() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isExpired');
    });
  }

  QueryBuilder<LicenseModel, LicenseModel, QDistinct> distinctByIsValid() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isValid');
    });
  }

  QueryBuilder<LicenseModel, LicenseModel, QDistinct> distinctByLicenseKey(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'licenseKey', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LicenseModel, LicenseModel, QDistinct> distinctByLicenseType() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'licenseType');
    });
  }

  QueryBuilder<LicenseModel, LicenseModel, QDistinct> distinctByOwnerPhone(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'ownerPhone', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LicenseModel, LicenseModel, QDistinct> distinctByStoreName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'storeName', caseSensitive: caseSensitive);
    });
  }
}

extension LicenseModelQueryProperty
    on QueryBuilder<LicenseModel, LicenseModel, QQueryProperty> {
  QueryBuilder<LicenseModel, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<LicenseModel, DateTime, QQueryOperations> activatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'activatedAt');
    });
  }

  QueryBuilder<LicenseModel, int, QQueryOperations> daysRemainingProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'daysRemaining');
    });
  }

  QueryBuilder<LicenseModel, String, QQueryOperations> deviceIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'deviceId');
    });
  }

  QueryBuilder<LicenseModel, DateTime, QQueryOperations> expiresAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'expiresAt');
    });
  }

  QueryBuilder<LicenseModel, bool, QQueryOperations> isActiveProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isActive');
    });
  }

  QueryBuilder<LicenseModel, bool, QQueryOperations> isExpiredProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isExpired');
    });
  }

  QueryBuilder<LicenseModel, bool, QQueryOperations> isValidProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isValid');
    });
  }

  QueryBuilder<LicenseModel, String, QQueryOperations> licenseKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'licenseKey');
    });
  }

  QueryBuilder<LicenseModel, LicenseType, QQueryOperations>
      licenseTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'licenseType');
    });
  }

  QueryBuilder<LicenseModel, String?, QQueryOperations> ownerPhoneProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'ownerPhone');
    });
  }

  QueryBuilder<LicenseModel, String?, QQueryOperations> storeNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'storeName');
    });
  }
}
