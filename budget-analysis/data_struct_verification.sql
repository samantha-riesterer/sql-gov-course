-- Understanding state budget data structure
SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_schema = 'public'
ORDER BY table_name, ordinal_position;
 
 
 -- Agency financial data overview
SELECT 
    'agencies' as table_name, COUNT(*) as record_count FROM agencies
UNION ALL
SELECT 
    'budget_allocations', COUNT(*) FROM budget_allocations
UNION ALL
SELECT 
    'actual_expenditures', COUNT(*) FROM actual_expenditures
UNION ALL
SELECT 
    'budget_categories', COUNT(*) FROM budget_categories
UNION ALL
SELECT 
    'fiscal_years', COUNT(*) FROM fiscal_years
UNION ALL
SELECT 
    'fund_sources', COUNT(*) FROM fund_sources;
