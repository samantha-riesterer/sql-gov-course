--======================================================================================
--PART 2: State agency budget performance analysis
--PURPOSE: 
--======================================================================================


--=====================================================================================
-- QUESTION 1 : Agency Budget Variance Analysis
-- LEGISLATIVE QUESTION: Which state agencies are consistently over or under budget, 
-- and in which spending categories?


-- QUERY: agency_budget_performance

--Q: Calculate budget vs. actual variance by agency for current fiscal year
--Identify agencies with highest positive and negative variances
--Calculate variance percentages for comparison across different-sized agencies

SELECT 
    a.agency_name,
    SUM(ae.amount) - SUM(ba.budgeted_amount) AS budget_variance,
    ROUND(((SUM(ae.amount) - ba.budgeted_amount) / SUM(ae.amount)) * 100, 2) AS percent_variance
FROM agencies a
JOIN budget_allocations ba ON a.agency_id = ba.agency_id
LEFT JOIN actual_expenditures ae ON a.agency_id = ae.agency_id
WHERE ba.fy_id = 2
GROUP BY a.agency_name
ORDER BY budget_variance DESC;

--NOTES
-- need to think about variance timeline - Q1 vs Q1 OR annualize for projection
--does it make a difference to ROUND before or after multiplying by 100 ?
