----
.print Random INTEGER distribution test
SELECT
  number,
  count() AS "count",
FROM (
  SELECT fake_integer({'min': 0, 'max': 9}) AS number
  FROM range(100_000)
)
GROUP BY ALL
ORDER BY ALL;

----
.print Random NUMERIC distribution test
.maxrows 100

SELECT
  number,
  count() AS "count",
FROM (
  SELECT fake_numeric({'min': 0, 'max': 1, 'precision': 2}) AS number
  FROM range(100_000)
)
GROUP BY ALL
ORDER BY ALL;

----
.print Random TEXT (both cases) distribution test
.maxrows 52

SELECT
  "text",
  count() AS "count",
FROM (
  SELECT fake_text({'min': 1, 'max': 1}) AS "text"
  FROM range(100_000)
)
GROUP BY ALL
ORDER BY ALL;

----
.print Random TEXT (lower case) distribution test
SELECT
  "text",
  count() AS "count",
FROM (
  SELECT fake_text({'min': 1, 'max': 1, 'upper_prob': 0}) AS "text"
  FROM range(100_000)
)
GROUP BY ALL
ORDER BY ALL;

----
.print Random TEXT (upper case) distribution test
SELECT
  "text",
  count() AS "count",
FROM (
  SELECT fake_text({'min': 1, 'max': 1, 'upper_prob': 1}) AS "text"
  FROM range(100_000)
)
GROUP BY ALL
ORDER BY ALL;

----
.print Random DATE distribution test
SELECT
  "day",
  count() AS "count",
FROM (
  SELECT fake_date({'min': '2026-01-01', 'max': '2026-01-07'}) AS "day"
  FROM range(100_000)
)
GROUP BY ALL
ORDER BY ALL;

----
.print Random ENUM distribution test
SELECT
  json ->> '$.category' as category,
  count() AS "count",
FROM
  fake_table (
    {
      'category': {
        'type': 'ENUM',
        'enum': ['1-extra-small', '2-small', '3-medium', '4-large', '5-extra-large']
      }
    },
    100_000
  )
GROUP BY ALL
ORDER BY ALL;
