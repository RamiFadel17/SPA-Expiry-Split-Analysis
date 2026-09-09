USE SPA_Expiry_Split_Analysis;
GO

SELECT
    Agreement_ID,
    COUNT(*) AS Evaluation_Count,
    SUM(Benefit_Flag) AS Benefit_Count,
    SUM(Review_Flag) AS Review_Count,

    CASE
        WHEN SUM(Benefit_Flag) = 0
            THEN 'DELETE SPA'

        WHEN SUM(Benefit_Flag) = COUNT(*)
            THEN 'KEEP AS IS'

        ELSE 'SPLIT / UPDATE SPA'
    END AS Agreement_Action

FROM dbo.vw_spa_analysis_base

GROUP BY Agreement_ID;
