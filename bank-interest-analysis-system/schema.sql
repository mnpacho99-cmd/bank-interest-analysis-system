--|================================|
--| TABLES                         |
--|================================|


-- Table of Banks:
CREATE TABLE "banks" (
    "id" INTEGER,
    "name" TEXT NOT NULL UNIQUE,
    "country_origin" TEXT,
    "branches" INTEGER CHECK("branches" >= 0),
    "assets_bcra" INTEGER,
    "opening_year" INTEGER CHECK("opening_year" > 1810 AND "opening_year" <= 2026),
    "is_active" INTEGER DEFAULT 1 CHECK("is_active" IN (0, 1)),
    PRIMARY KEY("id")
);

-- Table of Products:
CREATE TABLE "products" (
    "id" INTEGER,
    "bank_id" INTEGER,
    "type" TEXT CHECK("type" IN ('personal_loan', 'savings_account')) NOT NULL,
    "minimum_amount" NUMERIC,
    "maximum_amount" NUMERIC,
    "minimum_term_days" INTEGER,
    "maximum_term_days" INTEGER,
    "is_active" INTEGER DEFAULT 1 CHECK("is_active" IN (0, 1)),
    PRIMARY KEY("id"),
    FOREIGN KEY("bank_id") REFERENCES "banks"("id")
);

-- Table of Historical Rates:
CREATE TABLE "historical_rates" (
    "id" INTEGER,
    "product_id" INTEGER,
    "date" TEXT,
    "average_effective_rate" NUMERIC,
    PRIMARY KEY("id"),
    FOREIGN KEY("product_id") REFERENCES "products"("id")
);


--|================================|
--| TRIGGERS                       |
--|================================|


-- Soft Delete Trigger for Banks and Products:
CREATE TRIGGER "soft_delete_bank_products"
AFTER UPDATE OF "is_active" ON "banks"
WHEN NEW."is_active" = 0 AND OLD."is_active" = 1
BEGIN
    UPDATE "products" 
    SET "is_active" = 0 
    WHERE "bank_id" = OLD."id";
END;


--|================================|
--| VIEWS                          |
--|================================|


-- Spread Analysis View:
CREATE VIEW "bank_spread_analysis" AS
WITH "active_rates" AS (
    SELECT
        "banks"."name" AS "bank_name",
        "historical_rates"."date" AS "record_month",
        "historical_rates"."average_effective_rate" AS "active_rate"
    FROM "banks"
    JOIN "products" ON "banks"."id" = "products"."bank_id"
    JOIN "historical_rates" ON "products"."id" = "historical_rates"."product_id"
    WHERE "products"."type" = 'personal_loan'
    AND "historical_rates"."date" = (SELECT MAX("date") FROM "historical_rates")
    AND "banks"."is_active" = 1 
    AND "products"."is_active" = 1
),

"passive_rates" AS (
    SELECT
        "banks"."name" AS "bank_name",
        "historical_rates"."date" AS "record_month",
        "historical_rates"."average_effective_rate" AS "passive_rate"
    FROM "banks"
    JOIN "products" ON "banks"."id" = "products"."bank_id"
    JOIN "historical_rates" ON "products"."id" = "historical_rates"."product_id"
    WHERE "products"."type" = 'savings_account'
    AND "historical_rates"."date" = (SELECT MAX("date") FROM "historical_rates")
    AND "banks"."is_active" = 1 
    AND "products"."is_active" = 1
)

SELECT
    "bank_name",
    "record_month",
    "active_rate",
    "passive_rate",
    ("active_rate" - "passive_rate") AS "spread"
FROM "active_rates"
JOIN "passive_rates" USING ("bank_name", "record_month")
ORDER BY "spread" DESC;

-- Lowest Loan Rates View:
CREATE VIEW "lowest_loan_rates" AS
SELECT
    "historical_rates"."average_effective_rate" AS "loan_rate",
    "historical_rates"."date",
    "banks"."name" AS "bank_name"
FROM "historical_rates"
JOIN "products" ON "historical_rates"."product_id" = "products"."id"
JOIN "banks" ON "products"."bank_id" = "banks"."id"
WHERE "products"."type" = 'personal_loan'
AND "historical_rates"."date" = (SELECT MAX("date") FROM "historical_rates")
AND "banks"."is_active" = 1 
AND "products"."is_active" = 1
ORDER BY "historical_rates"."average_effective_rate" ASC;

-- Highest Deposit Rates View:
CREATE VIEW "highest_deposit_rates" AS
SELECT
    "historical_rates"."average_effective_rate" AS "deposit_rate",
    "historical_rates"."date",
    "banks"."name" AS "bank_name"
FROM "historical_rates"
JOIN "products" ON "historical_rates"."product_id" = "products"."id"
JOIN "banks" ON "products"."bank_id" = "banks"."id"
WHERE "products"."type" = 'savings_account'
AND "historical_rates"."date" = (SELECT MAX("date") FROM "historical_rates")
AND "banks"."is_active" = 1 
AND "products"."is_active" = 1
ORDER BY "historical_rates"."average_effective_rate" DESC;


--|================================|
--| INDEXES                        |
--|================================|


CREATE INDEX "idx_products_bank_id" ON "products"("bank_id");

CREATE INDEX "idx_rates_product_id" ON "historical_rates"("product_id");

CREATE INDEX "idx_products_type" ON "products"("type");

CREATE INDEX "idx_rates_value" ON "historical_rates"("average_effective_rate");
