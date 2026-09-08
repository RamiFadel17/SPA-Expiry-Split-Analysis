SELECT *
FROM dbo.customer_master;
EXEC sp_help 'dbo.customer_master';
DELETE FROM dbo.customer_master
WHERE Customer_ID IS NULL;
SELECT *
FROM dbo.customer_master;
SELECT *
FROM dbo.material_master;

EXEC sp_help 'dbo.material_master';
ALTER TABLE dbo.material_master
ALTER COLUMN Unit_Cost DECIMAL(18,2);

ALTER TABLE dbo.material_master
ALTER COLUMN Stock_Price DECIMAL(18,2);
SELECT *
FROM dbo.material_master;

SELECT *
FROM dbo.customer_pricing;

EXEC sp_help 'dbo.customer_pricing';

ALTER TABLE dbo.customer_pricing
ALTER COLUMN Item_Price DECIMAL(18,2) NULL;

ALTER TABLE dbo.customer_pricing
ALTER COLUMN MG2_Multiplier DECIMAL(10,4) NULL;

ALTER TABLE dbo.customer_pricing
ALTER COLUMN MPG_Multiplier DECIMAL(10,4) NULL;

ALTER TABLE dbo.customer_pricing
ALTER COLUMN Book_Price DECIMAL(18,2) NULL;

ALTER TABLE dbo.customer_pricing
ALTER COLUMN Price_Unit SMALLINT NOT NULL;

SELECT *
FROM dbo.customer_pricing;

EXEC sp_help 'dbo.customer_pricing';

SELECT *
FROM dbo.spa_customers;

EXEC sp_help 'dbo.spa_customers';

SELECT *
FROM dbo.spa_lines;

EXEC sp_help 'dbo.spa_lines';

ALTER TABLE dbo.spa_lines
ALTER COLUMN SPA_Price DECIMAL(18,2) NOT NULL;

ALTER TABLE dbo.spa_lines
ALTER COLUMN Price_Unit SMALLINT NOT NULL;

SELECT *
FROM dbo.spa_lines;

EXEC sp_help 'dbo.spa_lines';