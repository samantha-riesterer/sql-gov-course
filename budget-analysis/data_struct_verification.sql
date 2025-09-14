--======================================================================================
--TASK 1.2: State budget database structure analysis
--PURPOSE: Data validation and analysis of database structure
--======================================================================================


--=====================================================================================
-- QUERY: budget_data_structure
-- PURPOSE: General overview of database structure, selects all tables, 
-- columns & shows data type

SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_schema = 'public'
ORDER BY table_name, ordinal_position;

--ANALYSIS: 
-- 11 tables with 6 tables containing macro/structural data and 5 tables containing 
-- micro fund information
-- actual_expenditures : contains expenditure_date and processed_date - difference 
-- may be important in calculations
-- agencies: divided by cabinet_area, fte_authorized important for labor budget analysis 
-- budget_allocations : multiple foreign keys, potential join point
-- revenue_collections: source_agency_id is agency_id of agency that collected  revenue
-- fund_sources: revenue_source
-- clear foreign key structure, most used foreign key agency_id and category_id


--=====================================================================================
-- QUERY: table_row_count
-- PURPOSE: verify count for tables, approximate size

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

-- ANALYSIS:
-- largest table is expenditures, 33 rows
-- 10 agencies 
-- 3 fiscal years 
-- currently 10 fund sources and 10 budget categories 


--====================================================================================
-- Query: orphaned_records_check
-- Purpose: check referential integrity, check for orphaned records (bad data structure)

-- 1. Expenditures without valid agency reference
SELECT 'Expenditures - orphaned agencies' as check_type, COUNT(*) as orphaned_count
FROM actual_expenditures ae
LEFT JOIN agencies a ON ae.agency_id = a.agency_id
WHERE a.agency_id IS NULL

UNION ALL

-- 2. Expenditures without valid category reference  
SELECT 'Expenditures - orphaned categories', COUNT(*)
FROM actual_expenditures ae
LEFT JOIN budget_categories bc ON ae.category_id = bc.category_id
WHERE bc.category_id IS NULL

UNION ALL

-- 3. Expenditures without valid fund reference
SELECT 'Expenditures - orphaned funds', COUNT(*)
FROM actual_expenditures ae
LEFT JOIN fund_sources fs ON ae.fund_id = fs.fund_id
WHERE fs.fund_id IS NULL

UNION ALL

-- 4. Budget allocations without valid agency reference
SELECT 'Budget allocations - orphaned agencies', COUNT(*)
FROM budget_allocations ba
LEFT JOIN agencies a ON ba.agency_id = a.agency_id
WHERE a.agency_id IS NULL

UNION ALL

-- 5. Revenue collections without valid fund reference
SELECT 'Revenue collections - orphaned funds', COUNT(*)
FROM revenue_collections rc
LEFT JOIN fund_sources fs ON rc.fund_id = fs.fund_id
WHERE fs.fund_id IS NULL

UNION ALL

-- 6. Revenue collections without valid source agency reference
SELECT 'Revenue collections - orphaned source agencies', COUNT(*)
FROM revenue_collections rc
LEFT JOIN agencies a ON rc.source_agency_id = a.agency_id
WHERE a.agency_id IS NULL;

--ANALYSIS 
-- 0 orphaned records 


--====================================================================================
-- QUERY: data_quality
-- PURPOSE: Check for data quality issues (invalid or missing data)

-- Check for budget allocations WITHOUT corresponding expenditures
SELECT 
    'Budget lines with no spending' as issue_type,
    COUNT(*) as count
FROM budget_allocations ba
LEFT JOIN actual_expenditures ae ON ba.agency_id = ae.agency_id 
    AND ba.category_id = ae.category_id 
    AND ba.fund_id = ae.fund_id 
    AND ba.fy_id = ae.fy_id
WHERE ae.expenditure_id IS NULL AND ba.fy_id = 2 

UNION ALL

-- Check for expenditures WITHOUT budget authorization
SELECT 
    'Spending without budget authorization',
    COUNT(*)
FROM actual_expenditures ae
LEFT JOIN budget_allocations ba ON ae.agency_id = ba.agency_id 
    AND ae.category_id = ba.category_id 
    AND ae.fund_id = ba.fund_id 
    AND ae.fy_id = ba.fy_id
WHERE ba.allocation_id IS NULL AND ae.fy_id = 2; -- Fiscal Year 2024

--ANALYSIS 
-- budget allocations are for FY 2024, actual expenditures are from Q1 FY 2024
-- 6 budget allocations with no expenditure yet 
-- 0 expenditures without budget authorization - all expense activities have been approved
