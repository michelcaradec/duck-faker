-- NOTE: this macro will be reused wherever a random integer is required, as its uniform distribution is guaranteed
CREATE OR REPLACE MACRO _fake_integer_impl (min, max) AS (
  floor(min + random() * (max - min + 1))
)::INTEGER;

-- properties: {'min': 0, 'max': 100}
CREATE OR REPLACE MACRO fake_integer (properties) AS _fake_integer_impl (
  coalesce((properties ->> '$.min')::INTEGER, 0),
  coalesce((properties ->> '$.max')::INTEGER, 100)
);

COMMENT ON MACRO fake_integer IS 'Generate a random integer value, between [`min`, `max`]. Boundaries are inclusive.';

CREATE OR REPLACE MACRO _fake_numeric_impl (min, max, digits) AS (
  _fake_integer_impl(
    min * 10^digits,
    max * 10^digits
  ) / 10^digits
);

-- properties: {'min': 0, 'max': 100, 'precision': 2}
CREATE OR REPLACE MACRO fake_numeric (properties) AS (
  _fake_numeric_impl(
    coalesce((properties ->> '$.min')::INTEGER, 0),
    coalesce((properties ->> '$.max')::INTEGER, 100),
    coalesce((properties ->> '$.precision')::INTEGER, 2)
  )
);

COMMENT ON MACRO fake_numeric IS 'Generate a random numeric value, between [`min`, `max`], with `precision` decimal digits. Boundaries are inclusive.';

-- properties: {'min': 1, 'max': 20, 'upper_prob': 0.5}
CREATE OR REPLACE MACRO fake_text (properties) AS array_to_string(
  [
    chr(if(
      random() > coalesce((properties ->> '$.upper_prob')::DOUBLE, 0.5),
      _fake_integer_impl(ascii('a'), ascii('z')),
      _fake_integer_impl(ascii('A'), ascii('Z'))
    ))
    for _ in range(
      _fake_integer_impl (
        coalesce((properties ->> '$.min')::INTEGER, 1),
        coalesce((properties ->> '$.max')::INTEGER, 20)
      )
    )
  ],
  ''
);

COMMENT ON MACRO fake_text IS 'Generate a random string value, of length between [`min`, `max`]. Boundaries are inclusive.';

-- properties: {'min': today, 'max': tomorrow}
CREATE OR REPLACE MACRO fake_date (properties) AS (
  DATE(coalesce((properties ->> '$.min')::VARCHAR, CURRENT_DATE::VARCHAR)) + _fake_integer_impl (
    0,
    DATE(coalesce((properties ->> '$.max'), CURRENT_DATE::VARCHAR)) - DATE(coalesce((properties ->> '$.min'), (CURRENT_DATE + 1)::VARCHAR))
  )
);

COMMENT ON MACRO fake_date IS 'Generate a random date value, between [`min`, `max`]. Boundaries are inclusive.';

-- properties: {'enum': [val1, val2, ..., valN]}
CREATE OR REPLACE MACRO fake_enum (properties) AS (
  (properties -> '$.enum') [_fake_integer_impl (0, json_array_length(properties, 'enum') - 1)]
);

COMMENT ON MACRO fake_enum IS 'Randomly pick a value taken from a list `enum`.';

-- properties: {'type': 'INTEGER|NUMERIC|TEXT|DATE|ENUM', ...}
CREATE OR REPLACE MACRO fake_value (properties) AS CASE properties ->> '$.type'
  WHEN 'INTEGER' THEN fake_integer (properties)::VARIANT
  WHEN 'NUMERIC' THEN fake_numeric (properties)::VARIANT
  WHEN 'TEXT' THEN fake_text (properties)::VARIANT
  WHEN 'DATE' THEN fake_date (properties)::VARIANT
  WHEN 'ENUM' THEN fake_enum (properties)::VARIANT
  ELSE NULL
END;

COMMENT ON MACRO fake_value IS 'Generate a random value of type `type`.';

CREATE OR REPLACE MACRO fake_json (fields) AS
map_from_entries(
  [
    {
      'k': field,
      'v': fake_value (
        -- Get the properties (value) of the field (key)
        json_extract_string(fields, '$.' || field))
    } for field in json_keys(fields)
  ]
);

COMMENT ON MACRO fake_json IS 'Generate a random JSON object, containing fields with random values.';

CREATE OR REPLACE MACRO fake_table(
  fields,
  count := 10,
  extra := map(),
  extra_prob := 0.5,
) AS TABLE
  SELECT
    map_concat(
      -- Technical ID
      MAP {'_id': (range + 1)::VARIANT},
      -- Common fields
      fake_json(fields),
      -- Extra fields, randomly added
      if(random() >= extra_prob, fake_json(extra), MAP {})
    ) as json,
  FROM range(count)
  GROUP BY range;

COMMENT ON MACRO TABLE fake_table IS 'Generate a view with random JSON objects.';
