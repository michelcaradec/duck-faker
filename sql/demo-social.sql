-- Permanent fields
SET VARIABLE common = {
  'id': {'type': 'TEXT'},
  'date': {'type': 'DATE', 'min': '2026-01-01'},
  'name': {'type': 'TEXT', 'min': 5, 'max': 30},
  'followers': {'type': 'INTEGER', 'min': 10_000, 'max': 100_000},
  'views': {'type': 'INTEGER'},
  'engagement_avg': {'type': 'NUMERIC', 'min': 10, 'max': 80, 'precision': 3},
};

-- Fields appearing from time to time
SET VARIABLE extra = {
  'description': {'type': 'TEXT'},
  'impressions': {'type': 'INTEGER'},
  'category': {'type': 'ENUM', 'enum': ['text', 'image', 'video']},
};

FROM fake_table(
  $common,
  50,
  $extra
)
ORDER BY (json->'$._id')::INTEGER;
