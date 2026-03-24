// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'theme_settings_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetThemeSettingsModelCollection on Isar {
  IsarCollection<ThemeSettingsModel> get themeSettingsModels =>
      this.collection();
}

const ThemeSettingsModelSchema = CollectionSchema(
  name: r'ThemeSettingsModel',
  id: -3907399705378014781,
  properties: {
    r'primaryColorValue': PropertySchema(
      id: 0,
      name: r'primaryColorValue',
      type: IsarType.long,
    ),
    r'themeModeIndex': PropertySchema(
      id: 1,
      name: r'themeModeIndex',
      type: IsarType.long,
    )
  },
  estimateSize: _themeSettingsModelEstimateSize,
  serialize: _themeSettingsModelSerialize,
  deserialize: _themeSettingsModelDeserialize,
  deserializeProp: _themeSettingsModelDeserializeProp,
  idName: r'isarId',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _themeSettingsModelGetId,
  getLinks: _themeSettingsModelGetLinks,
  attach: _themeSettingsModelAttach,
  version: '3.1.0+1',
);

int _themeSettingsModelEstimateSize(
  ThemeSettingsModel object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  return bytesCount;
}

void _themeSettingsModelSerialize(
  ThemeSettingsModel object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.primaryColorValue);
  writer.writeLong(offsets[1], object.themeModeIndex);
}

ThemeSettingsModel _themeSettingsModelDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = ThemeSettingsModel();
  object.isarId = id;
  object.primaryColorValue = reader.readLong(offsets[0]);
  object.themeModeIndex = reader.readLong(offsets[1]);
  return object;
}

P _themeSettingsModelDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLong(offset)) as P;
    case 1:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _themeSettingsModelGetId(ThemeSettingsModel object) {
  return object.isarId;
}

List<IsarLinkBase<dynamic>> _themeSettingsModelGetLinks(
    ThemeSettingsModel object) {
  return [];
}

void _themeSettingsModelAttach(
    IsarCollection<dynamic> col, Id id, ThemeSettingsModel object) {
  object.isarId = id;
}

extension ThemeSettingsModelQueryWhereSort
    on QueryBuilder<ThemeSettingsModel, ThemeSettingsModel, QWhere> {
  QueryBuilder<ThemeSettingsModel, ThemeSettingsModel, QAfterWhere>
      anyIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension ThemeSettingsModelQueryWhere
    on QueryBuilder<ThemeSettingsModel, ThemeSettingsModel, QWhereClause> {
  QueryBuilder<ThemeSettingsModel, ThemeSettingsModel, QAfterWhereClause>
      isarIdEqualTo(Id isarId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: isarId,
        upper: isarId,
      ));
    });
  }

  QueryBuilder<ThemeSettingsModel, ThemeSettingsModel, QAfterWhereClause>
      isarIdNotEqualTo(Id isarId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: isarId, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: isarId, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: isarId, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: isarId, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<ThemeSettingsModel, ThemeSettingsModel, QAfterWhereClause>
      isarIdGreaterThan(Id isarId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: isarId, includeLower: include),
      );
    });
  }

  QueryBuilder<ThemeSettingsModel, ThemeSettingsModel, QAfterWhereClause>
      isarIdLessThan(Id isarId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: isarId, includeUpper: include),
      );
    });
  }

  QueryBuilder<ThemeSettingsModel, ThemeSettingsModel, QAfterWhereClause>
      isarIdBetween(
    Id lowerIsarId,
    Id upperIsarId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerIsarId,
        includeLower: includeLower,
        upper: upperIsarId,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension ThemeSettingsModelQueryFilter
    on QueryBuilder<ThemeSettingsModel, ThemeSettingsModel, QFilterCondition> {
  QueryBuilder<ThemeSettingsModel, ThemeSettingsModel, QAfterFilterCondition>
      isarIdEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<ThemeSettingsModel, ThemeSettingsModel, QAfterFilterCondition>
      isarIdGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<ThemeSettingsModel, ThemeSettingsModel, QAfterFilterCondition>
      isarIdLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<ThemeSettingsModel, ThemeSettingsModel, QAfterFilterCondition>
      isarIdBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'isarId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ThemeSettingsModel, ThemeSettingsModel, QAfterFilterCondition>
      primaryColorValueEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'primaryColorValue',
        value: value,
      ));
    });
  }

  QueryBuilder<ThemeSettingsModel, ThemeSettingsModel, QAfterFilterCondition>
      primaryColorValueGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'primaryColorValue',
        value: value,
      ));
    });
  }

  QueryBuilder<ThemeSettingsModel, ThemeSettingsModel, QAfterFilterCondition>
      primaryColorValueLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'primaryColorValue',
        value: value,
      ));
    });
  }

  QueryBuilder<ThemeSettingsModel, ThemeSettingsModel, QAfterFilterCondition>
      primaryColorValueBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'primaryColorValue',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ThemeSettingsModel, ThemeSettingsModel, QAfterFilterCondition>
      themeModeIndexEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'themeModeIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<ThemeSettingsModel, ThemeSettingsModel, QAfterFilterCondition>
      themeModeIndexGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'themeModeIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<ThemeSettingsModel, ThemeSettingsModel, QAfterFilterCondition>
      themeModeIndexLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'themeModeIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<ThemeSettingsModel, ThemeSettingsModel, QAfterFilterCondition>
      themeModeIndexBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'themeModeIndex',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension ThemeSettingsModelQueryObject
    on QueryBuilder<ThemeSettingsModel, ThemeSettingsModel, QFilterCondition> {}

extension ThemeSettingsModelQueryLinks
    on QueryBuilder<ThemeSettingsModel, ThemeSettingsModel, QFilterCondition> {}

extension ThemeSettingsModelQuerySortBy
    on QueryBuilder<ThemeSettingsModel, ThemeSettingsModel, QSortBy> {
  QueryBuilder<ThemeSettingsModel, ThemeSettingsModel, QAfterSortBy>
      sortByPrimaryColorValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'primaryColorValue', Sort.asc);
    });
  }

  QueryBuilder<ThemeSettingsModel, ThemeSettingsModel, QAfterSortBy>
      sortByPrimaryColorValueDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'primaryColorValue', Sort.desc);
    });
  }

  QueryBuilder<ThemeSettingsModel, ThemeSettingsModel, QAfterSortBy>
      sortByThemeModeIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'themeModeIndex', Sort.asc);
    });
  }

  QueryBuilder<ThemeSettingsModel, ThemeSettingsModel, QAfterSortBy>
      sortByThemeModeIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'themeModeIndex', Sort.desc);
    });
  }
}

extension ThemeSettingsModelQuerySortThenBy
    on QueryBuilder<ThemeSettingsModel, ThemeSettingsModel, QSortThenBy> {
  QueryBuilder<ThemeSettingsModel, ThemeSettingsModel, QAfterSortBy>
      thenByIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.asc);
    });
  }

  QueryBuilder<ThemeSettingsModel, ThemeSettingsModel, QAfterSortBy>
      thenByIsarIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.desc);
    });
  }

  QueryBuilder<ThemeSettingsModel, ThemeSettingsModel, QAfterSortBy>
      thenByPrimaryColorValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'primaryColorValue', Sort.asc);
    });
  }

  QueryBuilder<ThemeSettingsModel, ThemeSettingsModel, QAfterSortBy>
      thenByPrimaryColorValueDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'primaryColorValue', Sort.desc);
    });
  }

  QueryBuilder<ThemeSettingsModel, ThemeSettingsModel, QAfterSortBy>
      thenByThemeModeIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'themeModeIndex', Sort.asc);
    });
  }

  QueryBuilder<ThemeSettingsModel, ThemeSettingsModel, QAfterSortBy>
      thenByThemeModeIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'themeModeIndex', Sort.desc);
    });
  }
}

extension ThemeSettingsModelQueryWhereDistinct
    on QueryBuilder<ThemeSettingsModel, ThemeSettingsModel, QDistinct> {
  QueryBuilder<ThemeSettingsModel, ThemeSettingsModel, QDistinct>
      distinctByPrimaryColorValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'primaryColorValue');
    });
  }

  QueryBuilder<ThemeSettingsModel, ThemeSettingsModel, QDistinct>
      distinctByThemeModeIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'themeModeIndex');
    });
  }
}

extension ThemeSettingsModelQueryProperty
    on QueryBuilder<ThemeSettingsModel, ThemeSettingsModel, QQueryProperty> {
  QueryBuilder<ThemeSettingsModel, int, QQueryOperations> isarIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isarId');
    });
  }

  QueryBuilder<ThemeSettingsModel, int, QQueryOperations>
      primaryColorValueProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'primaryColorValue');
    });
  }

  QueryBuilder<ThemeSettingsModel, int, QQueryOperations>
      themeModeIndexProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'themeModeIndex');
    });
  }
}
