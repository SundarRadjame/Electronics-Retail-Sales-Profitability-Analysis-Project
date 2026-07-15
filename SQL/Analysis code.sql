USE retail_star_schema;

-- (Data already loaded via load data code.py — this file assumes all 6 tables are populated and just covers the view + practice queries.)

-- Sanity check: row counts
SELECT 'DimDate' AS tbl, COUNT(*) AS all_rows FROM DimDate
UNION ALL SELECT 'DimGeography', COUNT(*) FROM DimGeography
UNION ALL SELECT 'DimProduct', COUNT(*) FROM DimProduct
UNION ALL SELECT 'DimCustomer', COUNT(*) FROM DimCustomer
UNION ALL SELECT 'DimEmployee', COUNT(*) FROM DimEmployee
UNION ALL SELECT 'FactSales', COUNT(*) FROM FactSales;

-- =====================================================================
-- STEP 1: A REUSABLE VIEW — flattens the star schema once.
-- Python and Power BI can both query this instead of you rewriting the same 6-table join logic in three different places.
-- =====================================================================

CREATE OR REPLACE VIEW vw_sales_full AS
SELECT
    f.SalesKey,
    od.Date            AS OrderDate,
    sd.Date            AS ShipDate,
    DATEDIFF(sd.Date, od.Date) AS ShipDelayDays,
    p.ProductName, p.Category, p.SubCategory,
    c.CustomerName, c.LoyaltyTier, c.Gender,
    g.Country, g.Region, g.City,
    e.EmployeeName, e.Role,
    f.Quantity, f.UnitPrice, f.Discount,
    f.SalesAmount, f.TotalCost, f.Profit,
    f.Channel, f.PaymentMethod, f.OrderPriority
FROM FactSales f
JOIN DimDate od      ON f.OrderDateKey = od.DateKey
LEFT JOIN DimDate sd ON f.ShipDateKey = sd.DateKey
JOIN DimProduct p    ON f.ProductKey = p.ProductKey
JOIN DimCustomer c   ON f.CustomerKey = c.CustomerKey
JOIN DimGeography g  ON f.GeographyKey = g.GeographyKey
JOIN DimEmployee e   ON f.EmployeeKey = e.EmployeeKey;


-- =====================================================================
-- STEP 2: SAMPLE ANALYSIS QUERYING 
-- =====================================================================

-- 1. Revenue and profit by region
SELECT Region, SUM(SalesAmount) AS Revenue, SUM(Profit) AS Profit
FROM vw_sales_full
GROUP BY Region
ORDER BY Revenue DESC;

-- 2. Revenue by category and channel (multi-dimension grouping)
SELECT Category, Channel, SUM(SalesAmount) AS Revenue
FROM vw_sales_full
GROUP BY Category, Channel
ORDER BY Category, Revenue DESC;

-- 3. Rank customers by total spend within their region
SELECT CustomerName, Region, TotalSpend, spend_rank
FROM (
    SELECT
        c.CustomerName, g.Region,
        SUM(f.SalesAmount) AS TotalSpend,
        RANK() OVER (PARTITION BY g.Region ORDER BY SUM(f.SalesAmount) DESC) AS spend_rank
    FROM FactSales f
    JOIN DimCustomer c  ON f.CustomerKey = c.CustomerKey
    JOIN DimGeography g ON f.GeographyKey = g.GeographyKey
    GROUP BY c.CustomerKey, c.CustomerName, g.Region
) ranked
WHERE spend_rank <= 5
ORDER BY Region, spend_rank;

-- 4. Year-over-year growth using LAG
SELECT
    d.Year,
    SUM(f.SalesAmount) AS YearlySales,
    LAG(SUM(f.SalesAmount)) OVER (ORDER BY d.Year) AS PrevYearSales,
    ROUND(
        (SUM(f.SalesAmount) - LAG(SUM(f.SalesAmount)) OVER (ORDER BY d.Year))
        / LAG(SUM(f.SalesAmount)) OVER (ORDER BY d.Year) * 100, 2
    ) AS YoY_Growth_Pct
FROM FactSales f
JOIN DimDate d ON f.OrderDateKey = d.DateKey
GROUP BY d.Year
ORDER BY d.Year;

-- 5. Running total of monthly sales (for a cumulative trend chart)
SELECT
    d.Year, d.Month,
    SUM(f.SalesAmount) AS MonthlySales,
    SUM(SUM(f.SalesAmount)) OVER (ORDER BY d.Year, d.Month) AS RunningTotal
FROM FactSales f
JOIN DimDate d ON f.OrderDateKey = d.DateKey
GROUP BY d.Year, d.Month
ORDER BY d.Year, d.Month;

-- 6. Shipping delay analysis
SELECT
    Channel,
    AVG(ShipDelayDays) AS AvgShipDelay,
    COUNT(*) AS OrderCount
FROM vw_sales_full
WHERE ShipDelayDays IS NOT NULL
GROUP BY Channel
ORDER BY AvgShipDelay DESC;
