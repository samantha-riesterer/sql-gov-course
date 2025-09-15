--======================================================================================
--PART 2: State agency budget performance analysis
--PURPOSE: 


--=====================================================================================
-- QUESTION 1 : Agency Budget Variance Analysis

-- LEGISLATIVE QUESTION: Which state agencies are consistently over or under budget, 
-- and in which spending categories?

-- ===================================================================================
-- QUERY: agency_budget_performance

-- TASKS: Calculate budget vs. actual variance by agency for current fiscal year
-- Identify agencies with highest positive and negative variances
-- Calculate variance percentages for comparison across different-sized agencies


--retrieve Q1 expenditure data for each agency for fiscal year 2023-2024 
WITH q1_data AS (
    SELECT
        agency_id,
        SUM(amount) AS q1_actual
    FROM actual_expenditures 
    WHERE fy_id = 2 AND quarter = 1
    GROUP BY agency_id
),

--calculate total budget and total target for Q1 by agency
annual_budgets AS (
    SELECT 
        a.agency_id,
        a.agency_name, 
        SUM(ba.budgeted_amount) AS total_budget,
        SUM(ba.quarter_1_target) AS total_target
    FROM agencies a 
    JOIN budget_allocations ba ON a.agency_id = ba.agency_id
    WHERE ba.fy_id = 2
    GROUP BY a.agency_name,a.agency_id
),

-- calculates variance data using Q1 expenditure data and Q1 target budget, then project for annual expenditure
variance_data AS (
    SELECT
        ab.agency_name,
        ab.total_budget,
        qd.q1_actual - ab.total_target AS variance,
        (qd.q1_actual - ab.total_target) / ab.total_target AS variance_rate,
        ab.total_budget * (1 + ((qd.q1_actual - ab.total_target) / ab.total_target)) AS annual_projection
    FROM annual_budgets ab
    JOIN q1_data qd ON ab.agency_id = qd.agency_id
)

-- format and display data
SELECT 
   vd.agency_name,
   ROUND(vd.variance, 2) AS q1_variance,
   ROUND(vd.variance_rate,2)  AS variance_rate,
   ROUND(vd.variance_rate * 100,2) || '%' AS percentage_variance,
   ROUND(vd.annual_projection,2) AS projected_annual_expenditure,
   vd.total_budget AS annual_budget,
   ROUND(vd.annual_projection - vd.total_budget,2) AS projected_fy_budget_variance
FROM variance_data vd
ORDER BY variance_rate DESC;

--Data Validation Check 
--Are your total_target values reasonable? (Should be roughly 25% of annual budget if spending is evenly distributed)
--Do your variance rates make sense? (Should be decimals like 0.15 or -0.20, not huge numbers)
--Are agencies with positive variance rates showing projected expenditures above their annual budget?

--ANALYSIS RESULTS
--