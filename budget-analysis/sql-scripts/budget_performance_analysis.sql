-- ===================================================================================
-- PART 2: STATE AGENCY BUDGET PERFORMANCE ANALYSIS
-- Analyst: Samantha Riesterer
-- ===================================================================================

-- ===================================================================================
-- QUESTION 1 : Agency Budget Variance Analysis
-- Legislative question: Which state agencies are consistently over or under budget, 
-- and in which spending categories?
-- ===================================================================================
-- QUERY 1.1: Overrall agency budget performance
-- 1.Calculate budget vs. actual variance by agency for current fiscal year
-- 2.Identify agencies with highest positive and negative variances
-- 3.Calculate variance percentages for comparison across different-sized agencies

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
        SUM(ba.quarter_1_target) AS q1_target
    FROM agencies a 
    JOIN budget_allocations ba ON a.agency_id = ba.agency_id
    WHERE ba.fy_id = 2
    GROUP BY a.agency_name,a.agency_id
),

-- calculates variance data using Q1 expenditure data and Q1 target budget 
-- then project for annual expenditure
variance_data AS (
    SELECT
        ab.agency_name,
        ab.total_budget,
        qd.q1_actual - ab.q1_target AS variance,
        (qd.q1_actual - ab.q1_target) / ab.q1_target AS variance_rate,
        ab.total_budget * (1 + ((qd.q1_actual - ab.q1_target) / ab.q1_target)) AS annual_projection
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

-- ANALYSIS RESULTS
-- Dept. of Commerce approx. 35% over budget as of Q1, projected to be approx.$56.5 million over annual budget 
-- Every other department under budget as of Q1, with Dept. of L&I approx. 71% under budget


-- DATA VALIDATION
-- total_target values are ~20-25% of total budget 
-- positive/negative rates corresponding to over or under budget projections
/*
--Data Validation Test
SELECT 
    ab.agency_name,
    qd.q1_actual, 
    ab.q1_target,
    ab.total_budget,
   (ab.q1_target / ab.total_budget) * 100  AS percent_of_budget
   FROM annual_budgets ab
   JOIN q1_data qd ON ab.agency_id = qd.agency_id;
*/
-- ===================================================================================
-- ===================================================================================
-- QUERY 1.2: Spending category analysis
-- TASKS: 
-- 1.Analyze variances by budget category (personnel, operations, capital, etc.)
-- 2.Identify which types of spending are most difficult to predict/control
-- 3.Compare category performance across similar agencies (agency_type) 
-- --> UPDATE: All agency_types were "Cabinet" for Q1, changed to agency budget size 
--NOTES:
-- Data limited to Q1 FY 2023-2024
-- variance consistency & range analysis


--Pure Category Analysis
--aggregate spending & Q1 target budget by category-agency for FY 
WITH category_spending AS (
    SELECT 
        bc.category_id,
        bc.category_name,
        ae.agency_id,
        SUM(ae.amount) AS actual_spending,
        SUM(ba.quarter_1_target) AS target_spending,
       (SUM(ae.amount) - SUM(ba.quarter_1_target)) / SUM(ba.quarter_1_target) AS variance_rate
    FROM budget_categories bc
    JOIN actual_expenditures ae ON bc.category_id = ae.category_id
    JOIN budget_allocations ba ON bc.category_id = ba.category_id 
        AND ae.agency_id = ba.agency_id
    WHERE ae.fy_id = 2 AND ae.quarter = 1  
    GROUP BY bc.category_id, ae.agency_id
)

-- variance consistency: standard deviation of variance rates within each category 
-- range analysis: min/max variance rates by category 
SELECT 
    category_name,
   -- ROUND(STDDEV(variance_rate),2) AS std_variance,
    ROUND(AVG(variance_rate),2) AS avg_variance,
    ROUND(MIN(variance_rate),2) AS min_variance,
    ROUND(MAX(variance_rate),2) AS max_variance
FROM category_spending
GROUP BY category_name
ORDER BY min_variance ASC;

--Category Perforamnce by Agency Size
--retrieve agency data and link to spending, category & budget size
WITH agency_data AS (
    SELECT
        a.agency_id,
        a.agency_name,
        ae.amount, 
        ae.category_id,
        ba.budgeted_amount 
    FROM agencies a 
    JOIN actual_expenditures ae ON a.agency_id = ae.agency_id
    JOIN budget_allocations ba ON a.agency_id = ba.agency_id AND ae.category_id = ba.category_id
    WHERE ae.fy_id = 2
),

budget_size AS (
    SELECT
       ad.agency_id,
       ad.agency_name,
       NTILE(3) OVER (ORDER BY SUM(ad.budgeted_amount) DESC) AS budget_size
    FROM agency_data ad
    GROUP BY ad.agency_id,agency_name
)



--TO DO 
-- calculate variance 
-- range analysis


--ANALYSIS 
-- Q: Identify which categories are most/least predictable
-- Q: How budget size affects category management

-- 




-- ===================================================================================
-- ===================================================================================