--================================================================================
--TASK 1.2: State budget database structure analysis
--PURPOSE: Data validation and analysis of database structure
--================================================================================

--=====================================================
-- QUERY: budget_data_structure
-- PURPOSE: General overview of database structure,
-- selects all tables, columns & shows data type
--=====================================================
SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_schema = 'public'
ORDER BY table_name, ordinal_position;

--=====================================================
-- QUERY: table_row_count
-- PURPOSE: verify count for tables, approximate size
--=====================================================

SELECT 'agencies' as table_name, COUNT(*) as row_count FROM agencies
UNION ALL
SELECT 'budget_categories', COUNT(*) FROM budget_categories
UNION ALL
SELECT 'fund_sources', COUNT(*) FROM fund_sources
UNION ALL
SELECT 'fiscal_years', COUNT(*) FROM fiscal_years
UNION ALL
SELECT 'budget_allocations', COUNT(*) FROM budget_allocations
UNION ALL
SELECT 'actual_expenditures', COUNT(*) FROM actual_expenditures
UNION ALL
SELECT 'revenue_collections', COUNT(*) FROM revenue_collections
ORDER BY table_name;

--=====================================================
-- QUERY: table_row_count
-- PURPOSE: verify count for tables, approximate size
--=====================================================


-- Verify budget vs. actual data relationships
SELECT 
    a.agency_name,
    SUM(ba.budgeted_amount) as total_budgeted,
    SUM(ae.amount) as total_actual_q1,
    ROUND((SUM(ae.amount) / SUM(ba.budgeted_amount) * 4) * 100, 2) as projected_execution_rate
FROM agencies a
JOIN budget_allocations ba ON a.agency_id = ba.agency_id
LEFT JOIN actual_expenditures ae ON a.agency_id = ae.agency_id 
    AND ae.quarter = 1 AND ae.fy_id = 2
WHERE ba.fy_id = 2
GROUP BY a.agency_id, a.agency_name
ORDER BY total_budgeted DESC
LIMIT 10;

-- Check for data quality issues (missing relationships)
SELECT 
    'Expenditures without budget' as issue_type,
    COUNT(*) as count
FROM actual_expenditures ae
LEFT JOIN budget_allocations ba ON ae.agency_id = ba.agency_id 
    AND ae.category_id = ba.category_id 
    AND ae.fund_id = ba.fund_id 
    AND ae.fy_id = ba.fy_id
WHERE ba.allocation_id IS NULL

UNION ALL

SELECT 
    'Budget without expenditures',
    COUNT(*)
FROM budget_allocations ba
LEFT JOIN actual_expenditures ae ON ba.agency_id = ae.agency_id 
    AND ba.category_id = ae.category_id 
    AND ba.fund_id = ae.fund_id 
    AND ba.fy_id = ae.fy_id
WHERE ae.expenditure_id IS NULL AND ba.fy_id = 2;

 

--=====================================================
-- Query: agency_data_overview
-- Purpose: Agency financial data overview
--=====================================================
 

