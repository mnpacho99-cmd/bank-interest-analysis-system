--|================================|
--| CREATE QUERIES                 |
--|================================|


-- |X| DISCLAIMER |X|: The data used for the examples is not real, the banks and their data are fictional,
-- builded in base of public information and modified to suit the needs of the example.


-- In the CREATE category, we will mainly have queries related to the adittion of banks,
-- or the adittion of interest rates (passive or active) month by month.
-- As an example, we will add a bank and add the interest rates for loans and savings
-- recorded in the month of May for that bank.

-- Add a bank to the database (for this example we are going to add the
-- Citibank, an american bank that at the moment operates in Argentina).

INSERT INTO "banks" ("name", "country_origin", "branches", "assets_bcra", "opening_year")
VALUES ('BANCO CITIBANK', 'United States', 4, 6230382039, 1914);

-- Insert personal loan data (Now, with the bank in the database we can add the terms of the
-- loans offered by the bank).

INSERT INTO "products" ("bank_id", "type", "minimum_amount", "maximum_amount", "minimum_term_days", "maximum_term_days")
VALUES (
    (SELECT "id" FROM "banks" WHERE "name" = 'BANCO CITIBANK'),
    'personal_loan', 100000, 150000000, 1, 2160
);

-- Insert savings data (Now, with the bank in the database we can add the terms of the
-- saving accounts offered by the bank).

INSERT INTO "products" ("bank_id", "type", "minimum_amount", "maximum_amount", "minimum_term_days", "maximum_term_days")
VALUES (
    (SELECT "id" FROM "banks" WHERE "name" = 'BANCO CITIBANK'),
    'savings_account', 4000, NULL, 30, NULL
);

-- Insert monthly interest rates (Now we add the interest rates for Citibank loans and savings accounts in the month of May,
-- respectively).

INSERT INTO "historical_rates" ("product_id", "date", "average_effective_rate")
VALUES (
    (
        SELECT "products"."id"
        FROM "products"
        JOIN "banks" ON "products"."bank_id" = "banks"."id"
        WHERE "banks"."name" = 'BANCO CITIBANK' AND "products"."type" = 'personal_loan'
    ),
    '2026-05', 115.50
);

INSERT INTO "historical_rates" ("product_id", "date", "average_effective_rate")
VALUES (
    (
        SELECT "products"."id"
        FROM "products"
        JOIN "banks" ON "products"."bank_id" = "banks"."id"
        WHERE "banks"."name" = 'BANCO CITIBANK' AND "products"."type" = 'savings_account'
    ),
    '2026-05', 17.80
);


--|================================|
--| READ QUERIES                   |
--|================================|


-- For the READ category, we will look at three examples of using views. And three general examples of queries that could be 
-- performed based on the expected data.

-- Spread View: Top 3 banks with the highest spread.
SELECT * FROM "bank_spread_analysis" 
LIMIT 3;

-- Lowest Loan Rates View: List the banks with the lowest loan interest rates.
SELECT * FROM "lowest_loan_rates";

-- Highest Deposit Rates View:: List the bank with the highest deposit interest rate.
SELECT * FROM "highest_deposit_rates" LIMIT 1;

-- Which bank has the most physical branches in the country and what interest rate does it currently offer for savings accounts?
SELECT "banks"."name", "banks"."branches", "historical_rates"."average_effective_rate"
AS "current_savings_rate"
FROM "banks"
JOIN "products" ON "banks"."id" = "products"."bank_id"
JOIN "historical_rates" ON "products"."id" = "historical_rates"."product_id"
WHERE "products"."type" = 'savings_account'
AND "historical_rates"."date" = (SELECT MAX("date") FROM "historical_rates")
AND "banks"."is_active" = 1 
AND "products"."is_active" = 1
ORDER BY "banks"."branches" DESC
LIMIT 1;

-- List all foreign capital banks (not originating from Argentina) along with their country of origin and year of foundation.
SELECT "name", "country_origin", "opening_year"
FROM "banks"
WHERE "country_origin" != 'Argentina'
AND "is_active" = 1
ORDER BY "opening_year" ASC;

-- Calculate the overall market average interest rate (rounded to two decimal places) for personal loans in a specific historical
-- month (April 2026). (Here we omit the WHERE clause for the bank and product active status, as we want to calculate the market
-- average rate for all banks, regardless of their current status, as we are looking for the market average rate in a specific
-- historical month.

SELECT ROUND(AVG("historical_rates"."average_effective_rate"), 2) 
AS "market_avg_loan_rate_april"
FROM "historical_rates"
JOIN "products" ON "historical_rates"."product_id" = "products"."id"
WHERE "products"."type" = 'personal_loan'
AND "historical_rates"."date" = '2026-04';


--|================================|
--| UPDATE QUERIES                 |
--|================================|


-- For the UPDATE category, we will look at two examples of updating data in the database, examples for this could be updating the
-- number of branches of a bank, or updating the terms of a product offered by a bank.

-- Banco De La Nacion Argentina has opened one more branch in the country:
UPDATE "banks" 
SET "branches" = "branches" + 1 
WHERE "id" = 11;

-- Banco De La Nacion Argentina also has updated the minimum amount of its savings account to 3000 pesos:
UPDATE "products"
SET "minimum_amount" = 3000
WHERE "id" = 2;


--|================================|
--| DELETE QUERIES  (SOFT DELETE)  |
--|================================|

-- As we use soft delete triggers, we will not delete any data from the database, so when a bank or product ceases to be active 
-- our delete queries will be in reality update queries that will set the "is_active" column to 0 for banks and products, which
-- will make them inactive in the database but will keep the entire history in "historical_rates" table intact for the analysis.

-- Banco Patagonia has decided to close its operations in Argentina, so we will set its "is_active" column to 0:
UPDATE "banks"
SET "is_active" = 0
WHERE "name" = 'BANCO PATAGONIA';
