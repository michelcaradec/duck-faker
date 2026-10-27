-- https://allisonhorst.github.io/palmerpenguins/
SET VARIABLE fields = {
    'species': {'type': 'ENUM', 'enum': ['Adelie', 'Chinstrap', 'Gentoo']},
    'island': {'type': 'ENUM', 'enum': ['Biscoe', 'Dream', 'Torgersen']},
    'bill_length_mm': {'type': 'NUMERIC', 'min': 32.1, 'max': 59.6, 'precision': 1},
    'bill_depth_mm': {'type': 'NUMERIC', 'min': 13.1, 'max': 21.5, 'precision': 1},
    'flipper_length_mm': {'type': 'INTEGER', 'min': 172, 'max': 231},
    'body_mass_g': {'type': 'INTEGER', 'min': 2700, 'max': 6300},
    'sex': {'type': 'ENUM', 'enum': ['female', 'male']},
    'year': {'type': 'INTEGER', 'min': 2020, 'max': 2025},
    'month': {'type': 'INTEGER', 'min': 1, 'max': 12},
};

FROM fake_table(
  $fields,
  100
)
ORDER BY (json->'$._id')::INTEGER;
