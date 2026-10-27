# Duck-Faker

<details>
<summary>Table of contents</summary>

- [Abstract](#abstract)
- [Project Setup](#project-setup)
  - [Requirements](#requirements)
- [Usage](#usage)
- [Implementation](#implementation)
  - [Macros](#macros)
  - [Field Definition](#field-definition)
    - [Data Types](#data-types)
    - [Properties](#properties)
- [Impediments](#impediments)

</details>

## Abstract

While testing [VARIANT shredding](https://duckdb.org/docs/2.0/sql/data_types/variant#storage) in DuckDB, I needed some sample dataset composed of JSON objects.

I could have used a [Python script](https://duckdb.org/docs/2.0/guides/snippets/create_synthetic_data#generating-text-with-faker) based on the famous library [Faker](https://faker.readthedocs.io/), or the DuckDB community extension [fakeit](https://duckdb.org/community_extensions/extensions/fakeit), but I couldn't resist to the opportunity of implementing a (less ambitious) solution in pure DuckDB (because I think working under constraint is a good way to go deeper inside a technology, and learn new things).

This project is all about this.

## Project Setup

### Requirements

```bash
# Install DuckDB
# https://duckdb.org/
curl https://install.duckdb.org | bash
```

> [!IMPORTANT]
> The minimum version `2.0.0` must be used, as some new syntax (such as the `$variable` [shorthand](https://duckdb.org/docs/2.0/sql/statements/set_variable#the-name-shorthand)) is used in the SQL scripts.

## Usage

Running the demonstration:

```bash
duckdb -init ./sql/faker.sql -f ./sql/demo-social.sql

duckdb -init ./sql/faker.sql -f ./sql/demo-penguins.sql
```

Starting a DuckDB session with the [duck-faker functions](#macros):

```bash
duckdb -init ./sql/faker.sql
```

## Implementation

The implementation can be found in the file [faker.sql](./sql/faker.sql).

It relies on multiple [macros](https://duckdb.org/docs/2.0/sql/statements/create_macro) (with the prefix `fake_`).  
They can be listed with the command:

```sql
SELECT
    function_name,
    function_type,
    parameters,
    comment,
FROM duckdb_functions()
WHERE function_name LIKE 'fake_%';
```

### Macros

The random value generation macros (`fake_integer`, `fake_numeric`, `fake_text`, `fake_date`, `fake_enum`) take a [MAP](https://duckdb.org/docs/2.0/sql/data_types/map) as a parameter, and returns a value of type [VARIANT](https://duckdb.org/docs/2.0/sql/data_types/variant).

The main macro `fake_table` is used to generate a table of JSON objects, using the following parameters:

| Parameter    | Type      | Description                                                                   | Default |
| ------------ | --------- | ----------------------------------------------------------------------------- | ------- |
| `fields`     | `MAP`     | [Definition](#field-definition) of the fields of the JSON object to generate. |         |
| `count`      | `INTEGER` | Number of rows to return.                                                     | `10`    |
| `extra`      | `MAP`     | Definition of the optional fields to be added to the JSON object.             | `map()` |
| `extra_prob` | `DOUBLE`  | Probability (`[0, 1]`) to add the optional fields to the JSON object.         | `0.5`   |

> [!NOTE]
> In [VARIANT shredding](https://parquet.apache.org/docs/file-format/types/variantshredding/), the auto-shredding mechanism only handles common fields.  
> The support of optional fields allows observing this feature.

### Field Definition

A field is defined by:

- Its name: the key in the MAP.
- Its [properties](#properties): the JSON object assigned to the key.

For example, the definition of the field `year`, of [type](#data-types) `INTEGER`, [taking a value](#properties) between `2020` and `2025`:

```sql
{
  'year': {'type': 'INTEGER', 'min': 2020, 'max': 2025}
}
```

#### Data Types

The following data types are supported:

- `INTEGER`: integer value.
- `NUMERIC`: decimal value.
- `TEXT`: string value.
- `DATE`: date value (day only).
- `ENUM`: enumeration (i.e. choice in a list of values).

#### Properties

The properties define how a random value is generated:

- `min`: minimum value.
- `max`: maximum value.
- `precision`: number of digits after the decimal.
- `enum`: available values for an enumeration.
- `upper_prob`: probability (`[0, 1]`) of picking an upper case character for a string (the higher, the more the string will be composed of upper-case letters).

> [!IMPORTANT]
> The **boundaries**, defined by the properties `min` and `max`, are **inclusive**.  
> For the type `DATE`, the dates must be formatted as `YYYY-MM-DD`.

The properties of a field depend on its [type](#data-types) (defined by the property `type`).

The table below enumerates the properties, with their default values.  
They are marked with a `-` when not supported by the type.

| `type`    | `min` |  `max`   | `precision` |          `enum`           | `upper_prob` |
| --------- | :---: | :------: | :---------: | :-----------------------: | :----------: |
| `INTEGER` |   0   |   100    |      -      |             -             |      -       |
| `NUMERIC` |   0   |   100    |      2      |             -             |      -       |
| `TEXT`    |   1   |    20    |      -      |             -             |     0.5      |
| `DATE`    | today | tomorrow |      -      |             -             |      -       |
| `ENUM`    |   -   |    -     |      -      | `[val1, val2, ..., valN]` |      -       |

## Impediments

- The macros generating random values (using the function [random()](https://duckdb.org/docs/2.0/sql/functions/numeric#random)), when involved in a [join operation](https://duckdb.org/docs/2.0/guides/performance/join_operations), must be of type **scalar** (i.e. not **table**) to be evaluated on each call. Otherwise, some DuckDB engine optimization may limit the number of time they are invoked.

> [!NOTE]
> See also the column `stability` returned by the function [duckdb_functions()](https://duckdb.org/docs/2.0/sql/meta/duckdb_table_functions#duckdb_functions).

- The SQL formula `(min + random() * (max - min))::INTEGER` leads to less values at the boundaries.  
  As an alternative, the SQL formula `floor(min + random() * (max - min + 1))` was used.  
  The SQL script [test.sql](./sql/test.sql) can be executed to verify the uniform distribution when generating random values: .`duckdb -init ./sql/faker.sql -f ./sql/test.sql`.

> [!TIP]
> The equivalent Python code can be used to compare the distribution of both formulas:
>
> ```python
> from random import random
> from itertools import groupby
> from math import floor
> from pprint import pprint
>
> buckets = 10
>
> # (min + random() * (max - min))::INTEGER
> pprint([
>     (k, len(list(g)))
>     for (k, g)
>     in groupby(
>         sorted([
>             round(random() * (buckets - 1))
>             for r
>             in range(10_000)
>         ])
>     )
> ])
>
> # floor(min + random() * (max - min + 1))
> pprint([
>     (k, len(list(g)))
>     for (k, g)
>     in groupby(
>         sorted([
>             floor(random() * buckets)
>             for r
>             in range(10_000)
>         ])
>     )
> ])
> ```
