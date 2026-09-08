-- SPA Expiry & Split Analysis
-- 01 - Build Analysis Base

USE SPA_Expiry_Split_Analysis;
GO
CREATE OR ALTER VIEW dbo.vw_spa_analysis_base
AS
WITH AnalysisBase AS
(
    SELECT
    sl.Agreement_ID,
    sl.Material_ID,
    sl.SPA_Price,
    sl.Start_Date,
    sl.End_Date,
    sl.Price_Unit AS SPA_Price_Unit,
    sl.Currency AS SPA_Currency,
    sc.Customer_ID,
    cm.Customer_Name,
    cm.Region,
    mm.Material_Description,
    mm.Material_Group,
    mm.Unit_Cost,
    mm.Stock_Price,
    mm.Price_Unit AS Stock_Price_Unit,
    mm.Currency AS Stock_Currency,
    cp.Pricing_Level,
    cp.Item_Price,
    cp.MG2_Multiplier,
    cp.MPG_Multiplier,
    cp.Book_Price,

    sl.SPA_Price / sl.Price_Unit AS SPA_Unit_Price,

    CASE
    WHEN cp.Pricing_Level = 'ITEM'
        THEN cp.Item_Price / cp.Price_Unit

    WHEN cp.Pricing_Level = 'MG2'
        THEN (mm.Stock_Price / mm.Price_Unit) * cp.MG2_Multiplier

    WHEN cp.Pricing_Level = 'MPG'
        THEN (mm.Stock_Price / mm.Price_Unit) * cp.MPG_Multiplier

    WHEN cp.Pricing_Level = 'BOOK'
        THEN cp.Book_Price / cp.Price_Unit

    ELSE mm.Stock_Price / mm.Price_Unit
END AS Into_Stock_Price

FROM dbo.spa_lines AS sl

INNER JOIN dbo.spa_customers AS sc
    ON sl.Agreement_ID = sc.Agreement_ID

INNER JOIN dbo.customer_master AS cm
    ON sc.Customer_ID = cm.Customer_ID
    
INNER JOIN dbo.material_master AS mm
    ON sl.Material_ID = mm.Material_ID
    
LEFT JOIN dbo.customer_pricing AS cp
    ON sc.Customer_ID = cp.Customer_ID
    AND sl.Material_ID = cp.Material_ID
    ),
    PriceAnalysis AS
   (
    SELECT *,
    Into_Stock_Price - SPA_Unit_Price AS Price_Difference,
    ((SPA_Unit_Price-Unit_Cost)/SPA_Unit_Price)*100 AS SPA_Margin_Percent
FROM AnalysisBase
),
FlagAnalysis AS
(
Select *,
CASE 
WHEN Price_Difference > 0 THEN 'SPA BENEFIT' 
ELSE 'NO SPA BENEFIT' 
END AS SPA_Benefit,

CASE WHEN SPA_Margin_Percent < 0 THEN 'NEGATIVE MARGIN'
        ELSE 'OK'
    END AS Margin_Flag
FROM PriceAnalysis),
ExpiryAnalysis AS
(
SELECT *,
    CASE
        WHEN SPA_Benefit = 'SPA BENEFIT' THEN 1
        ELSE 0
    END AS Benefit_Flag,
        DATEDIFF(day, CAST(GETDATE() AS date), End_Date) AS Days_To_Expiry
    FROM FlagAnalysis
),

StatusAnalysis AS
(
    SELECT
        *,
        CASE
            WHEN Days_To_Expiry < 0 THEN 'EXPIRED'
            WHEN Days_To_Expiry <= 30 THEN 'EXPIRING <=30 DAYS'
            WHEN Days_To_Expiry <= 90 THEN 'EXPIRING <=90 DAYS'
            ELSE 'ACTIVE'
        END AS Expiry_Status
    FROM ExpiryAnalysis
),
FinalAnalysis AS
(
    SELECT
        *,
        CASE
            WHEN Expiry_Status = 'EXPIRED' THEN 1
            ELSE 0
        END AS Expiry_Flag
    FROM StatusAnalysis
),
ReviewAnalysis AS
(
    SELECT
        *,
        CASE
            WHEN Margin_Flag = 'NEGATIVE MARGIN'
                 OR Expiry_Flag = 1
            THEN 1
            ELSE 0
        END AS Review_Flag
    FROM FinalAnalysis
)
SELECT *
FROM ReviewAnalysis;