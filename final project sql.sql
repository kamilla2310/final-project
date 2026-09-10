create database Customers_transactions;
select * from customers;

SELECT Gender, LENGTH(Gender)
FROM customers
WHERE TRIM(Gender) = '';
UPDATE customers
SET Gender = NULL
WHERE TRIM(Gender) = '';
UPDATE customers
SET Age = NULL
WHERE TRIM(Age) = '';
alter table customers modify Age int null;

create table transactions
(data_new date,
Id_check int,
Id_client int,
Count_products decimal(10,3),
Sum_payment decimal(10,2));

load data infile "C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\TRANSACTIONS (1).csv"
into table transactions
fields terminated by ','
lines terminated by '\n'
ignore 1 rows;

show variables like 'secure_file_priv';
select * from transactions;

#1
WITH checks AS (
    SELECT
        Id_client,
        Id_check,
        DATE_FORMAT(MIN(data_new), '%Y-%m') AS month,
        SUM(Sum_payment) AS check_amount
    FROM transactions
    WHERE data_new >= '2015-06-01'
      AND data_new < '2016-06-01'
    GROUP BY Id_client, Id_check
),

monthly_clients AS (
    SELECT
        Id_client,
        month
    FROM checks
    GROUP BY Id_client, month
),

continuous_clients AS (
    SELECT
        Id_client
    FROM monthly_clients
    GROUP BY Id_client
    HAVING COUNT(DISTINCT month) = 12
)

SELECT
    cc.Id_client,
    c.Gender,
    c.Age,

    ROUND(AVG(ch.check_amount), 2) AS average_check_year,

    ROUND(SUM(ch.check_amount) / 12, 2) AS average_monthly_spending,

    COUNT(DISTINCT ch.Id_check) AS total_operations

FROM continuous_clients cc

JOIN checks ch
    ON cc.Id_client = ch.Id_client

LEFT JOIN customers c
    ON cc.Id_client = c.Id_client

GROUP BY
    cc.Id_client,
    c.Gender,
    c.Age

ORDER BY
    total_operations DESC;
    
#2
#средняя сумма чека в месяц
WITH checks AS (
    SELECT
        Id_client,
        Id_check,
        DATE_FORMAT(MIN(data_new), '%Y-%m') AS month,
        SUM(Sum_payment) AS check_amount
    FROM transactions
    WHERE data_new >= '2015-06-01'
      AND data_new < '2016-06-01'
    GROUP BY Id_client, Id_check
)

SELECT
    month,
    ROUND(AVG(check_amount), 2) AS average_check
FROM checks
GROUP BY month
ORDER BY month;

#среднее количество операций в месяц;
WITH checks AS (
    SELECT
        Id_check,
        DATE_FORMAT(MIN(data_new), '%Y-%m') AS month
    FROM transactions
    WHERE data_new >= '2015-06-01'
      AND data_new < '2016-06-01'
    GROUP BY Id_check
)

SELECT
    month,
    COUNT(*) AS operations
FROM checks
GROUP BY month
ORDER BY month;

#среднее количество клиентов, которые совершали операции
SELECT
    DATE_FORMAT(data_new, '%Y-%m') AS month,
    COUNT(DISTINCT Id_client) AS active_clients
FROM transactions
WHERE data_new >= '2015-06-01'
  AND data_new < '2016-06-01'
GROUP BY DATE_FORMAT(data_new, '%Y-%m')
ORDER BY month;

#долю от общего количества операций за год и долю в месяц от общей суммы операций
WITH checks AS (
    SELECT
        Id_check,
        DATE_FORMAT(MIN(data_new), '%Y-%m') AS month,
        SUM(Sum_payment) AS check_amount
    FROM transactions
    WHERE data_new >= '2015-06-01'
      AND data_new < '2016-06-01'
    GROUP BY Id_check
),

monthly AS (
    SELECT
        month,
        COUNT(*) AS operations,
        SUM(check_amount) AS total_amount
    FROM checks
    GROUP BY month
)

SELECT
    month,
    operations,
    ROUND(
        operations / SUM(operations) OVER () * 100,
        2
    ) AS operations_share_percent,

    ROUND(total_amount, 2) AS total_amount,

    ROUND(
        total_amount / SUM(total_amount) OVER () * 100,
        2
    ) AS amount_share_percent

FROM monthly
ORDER BY month;

#вывести % соотношение M/F/NA в каждом месяце с их долей затрат
WITH checks AS (
    SELECT
        Id_client,
        Id_check,
        DATE_FORMAT(MIN(data_new), '%Y-%m') AS month,
        SUM(Sum_payment) AS check_amount
    FROM transactions
    WHERE data_new >= '2015-06-01'
      AND data_new < '2016-06-01'
    GROUP BY Id_client, Id_check
),

monthly_gender AS (
    SELECT
        ch.month,

        CASE
            WHEN c.Gender IS NULL
                 OR TRIM(c.Gender) = ''
            THEN 'NA'
            ELSE c.Gender
        END AS gender,

        COUNT(DISTINCT ch.Id_client) AS clients,
        COUNT(*) AS operations,
        SUM(ch.check_amount) AS spending

    FROM checks ch

    LEFT JOIN customers c
        ON ch.Id_client = c.Id_client

    GROUP BY
        ch.month,
        CASE
            WHEN c.Gender IS NULL
                 OR TRIM(c.Gender) = ''
            THEN 'NA'
            ELSE c.Gender
        END
)

SELECT
    month,
    gender,
    clients,
    operations,
    ROUND(spending, 2) AS spending,

    ROUND(
        clients /
        SUM(clients) OVER (PARTITION BY month) * 100,
        2
    ) AS clients_share_percent,

    ROUND(
        spending /
        SUM(spending) OVER (PARTITION BY month) * 100,
        2
    ) AS spending_share_percent

FROM monthly_gender
ORDER BY month, gender;

#3
#возрастные группы клиентов с шагом 10 лет
WITH checks AS (
    SELECT
        Id_client,
        Id_check,
        SUM(Sum_payment) AS check_amount
    FROM transactions
    WHERE data_new >= '2015-06-01'
      AND data_new < '2016-06-01'
    GROUP BY Id_client, Id_check
)

SELECT

    CASE
        WHEN c.Age IS NULL THEN 'NA'
        WHEN c.Age < 10 THEN '0-9'
        WHEN c.Age < 20 THEN '10-19'
        WHEN c.Age < 30 THEN '20-29'
        WHEN c.Age < 40 THEN '30-39'
        WHEN c.Age < 50 THEN '40-49'
        WHEN c.Age < 60 THEN '50-59'
        WHEN c.Age < 70 THEN '60-69'
        WHEN c.Age < 80 THEN '70-79'
        WHEN c.Age < 90 THEN '80-89'
        ELSE '90+'
    END AS age_group,

    COUNT(DISTINCT ch.Id_client) AS clients,

    COUNT(DISTINCT ch.Id_check) AS operations,

    ROUND(SUM(ch.check_amount), 2) AS total_amount

FROM checks ch

LEFT JOIN customers c
    ON ch.Id_client = c.Id_client

GROUP BY
    CASE
        WHEN c.Age IS NULL THEN 'NA'
        WHEN c.Age < 10 THEN '0-9'
        WHEN c.Age < 20 THEN '10-19'
        WHEN c.Age < 30 THEN '20-29'
        WHEN c.Age < 40 THEN '30-39'
        WHEN c.Age < 50 THEN '40-49'
        WHEN c.Age < 60 THEN '50-59'
        WHEN c.Age < 70 THEN '60-69'
        WHEN c.Age < 80 THEN '70-79'
        WHEN c.Age < 90 THEN '80-89'
        ELSE '90+'
    END

ORDER BY
    MIN(COALESCE(c.Age, 999));
    
#Доля каждой возрастной группы
WITH checks AS (
    SELECT
        Id_client,
        Id_check,
        SUM(Sum_payment) AS check_amount
    FROM transactions
    WHERE data_new >= '2015-06-01'
      AND data_new < '2016-06-01'
    GROUP BY Id_client, Id_check
),

age_groups AS (
    SELECT

        CASE
            WHEN c.Age IS NULL THEN 'NA'
            WHEN c.Age < 10 THEN '0-9'
            WHEN c.Age < 20 THEN '10-19'
            WHEN c.Age < 30 THEN '20-29'
            WHEN c.Age < 40 THEN '30-39'
            WHEN c.Age < 50 THEN '40-49'
            WHEN c.Age < 60 THEN '50-59'
            WHEN c.Age < 70 THEN '60-69'
            WHEN c.Age < 80 THEN '70-79'
            WHEN c.Age < 90 THEN '80-89'
            ELSE '90+'
        END AS age_group,

        ch.Id_client,
        ch.Id_check,
        ch.check_amount

    FROM checks ch

    LEFT JOIN customers c
        ON ch.Id_client = c.Id_client
)

SELECT
    age_group,

    COUNT(DISTINCT Id_client) AS clients,

    COUNT(DISTINCT Id_check) AS operations,

    ROUND(SUM(check_amount), 2) AS total_amount,

    ROUND(
        COUNT(DISTINCT Id_check) /
        SUM(COUNT(DISTINCT Id_check)) OVER () * 100,
        2
    ) AS operations_share_percent,

    ROUND(
        SUM(check_amount) /
        SUM(SUM(check_amount)) OVER () * 100,
        2
    ) AS amount_share_percent

FROM age_groups

GROUP BY age_group

ORDER BY
    CASE
        WHEN age_group = 'NA' THEN 999
        ELSE CAST(SUBSTRING_INDEX(age_group, '-', 1) AS UNSIGNED)
    END;
    
#Поквартальные показатели по возрастным группам
WITH checks AS (
    SELECT
        Id_client,
        Id_check,
        DATE_FORMAT(MIN(data_new), '%Y-%m') AS month,
        SUM(Sum_payment) AS check_amount
    FROM transactions
    WHERE data_new >= '2015-06-01'
      AND data_new < '2016-06-01'
    GROUP BY Id_client, Id_check
),

age_checks AS (
    SELECT
        ch.*,

        CASE
            WHEN MONTH(STR_TO_DATE(CONCAT(month, '-01'), '%Y-%m-%d'))
                 IN (6, 7, 8)
            THEN 'Q1'

            WHEN MONTH(STR_TO_DATE(CONCAT(month, '-01'), '%Y-%m-%d'))
                 IN (9, 10, 11)
            THEN 'Q2'

            WHEN MONTH(STR_TO_DATE(CONCAT(month, '-01'), '%Y-%m-%d'))
                 IN (12, 1, 2)
            THEN 'Q3'

            WHEN MONTH(STR_TO_DATE(CONCAT(month, '-01'), '%Y-%m-%d'))
                 IN (3, 4, 5)
            THEN 'Q4'
        END AS quarter_period,

        CASE
            WHEN c.Age IS NULL THEN 'NA'
            WHEN c.Age < 10 THEN '0-9'
            WHEN c.Age < 20 THEN '10-19'
            WHEN c.Age < 30 THEN '20-29'
            WHEN c.Age < 40 THEN '30-39'
            WHEN c.Age < 50 THEN '40-49'
            WHEN c.Age < 60 THEN '50-59'
            WHEN c.Age < 70 THEN '60-69'
            WHEN c.Age < 80 THEN '70-79'
            WHEN c.Age < 90 THEN '80-89'
            ELSE '90+'
        END AS age_group

    FROM checks ch

    LEFT JOIN customers c
        ON ch.Id_client = c.Id_client
),

monthly_age AS (
    SELECT
        quarter_period,
        month,
        age_group,

        AVG(check_amount) AS monthly_average_check,

        COUNT(DISTINCT Id_check) AS monthly_operations,

        COUNT(DISTINCT Id_client) AS monthly_clients,

        SUM(check_amount) AS monthly_spending

    FROM age_checks

    GROUP BY
        quarter_period,
        month,
        age_group
),

quarterly_age AS (
    SELECT
        quarter_period,
        age_group,

        AVG(monthly_average_check) AS average_check,

        AVG(monthly_operations) AS average_operations_per_month,

        AVG(monthly_clients) AS average_clients_per_month,

        AVG(monthly_spending) AS average_spending_per_month,

        SUM(monthly_operations) AS quarter_operations,

        SUM(monthly_spending) AS quarter_spending

    FROM monthly_age

    GROUP BY
        quarter_period,
        age_group
)

SELECT
    quarter_period,
    age_group,

    ROUND(average_check, 2) AS average_check,

    ROUND(average_operations_per_month, 2)
        AS average_operations_per_month,

    ROUND(average_clients_per_month, 2)
        AS average_clients_per_month,

    ROUND(average_spending_per_month, 2)
        AS average_spending_per_month,

    quarter_operations,

    ROUND(quarter_spending, 2) AS quarter_spending,

    ROUND(
        quarter_spending /
        SUM(quarter_spending)
            OVER (PARTITION BY quarter_period) * 100,
        2
    ) AS spending_share_percent

FROM quarterly_age

ORDER BY
    quarter_period,
    CASE
        WHEN age_group = 'NA' THEN 999
        ELSE CAST(SUBSTRING_INDEX(age_group, '-', 1) AS UNSIGNED)
    END;




