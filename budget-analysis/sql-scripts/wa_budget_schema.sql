-- ===================================================================
-- Washington State Budget Database Schema & Sample Data
-- Office of Financial Management (OFM) Analysis System
-- Fiscal Year 2023-2024 & 2024-2025 Data
-- ===================================================================

-- Create the database (run this first)
-- CREATE DATABASE wa_state_budget;
-- \c wa_state_budget;

-- ===================================================================
-- TABLE CREATION: Government Financial Structure
-- ===================================================================

-- Major Washington State Agencies
CREATE TABLE agencies (
    agency_id SERIAL PRIMARY KEY,
    agency_code VARCHAR(10) NOT NULL UNIQUE,
    agency_name VARCHAR(100) NOT NULL,
    agency_type VARCHAR(50) NOT NULL, -- Cabinet, Independent, Higher Ed, etc.
    cabinet_area VARCHAR(50),
    director_name VARCHAR(100),
    fte_authorized INTEGER,
    created_date DATE DEFAULT CURRENT_DATE
);

-- Budget Categories (standardized across state)
CREATE TABLE budget_categories (
    category_id SERIAL PRIMARY KEY,
    category_code VARCHAR(10) NOT NULL UNIQUE,
    category_name VARCHAR(50) NOT NULL,
    category_type VARCHAR(20) NOT NULL, -- Personnel, Operations, Capital
    description TEXT,
    is_mandated BOOLEAN DEFAULT FALSE
);

-- Fund Sources (General Fund, Federal, Dedicated, etc.)
CREATE TABLE fund_sources (
    fund_id SERIAL PRIMARY KEY,
    fund_code VARCHAR(10) NOT NULL UNIQUE,
    fund_name VARCHAR(100) NOT NULL,
    fund_type VARCHAR(30) NOT NULL, -- General, Federal, Dedicated, Bond
    revenue_source VARCHAR(100),
    restrictions TEXT,
    federal_cfda VARCHAR(20) -- Federal CFDA number if applicable
);

-- Fiscal Years
CREATE TABLE fiscal_years (
    fy_id SERIAL PRIMARY KEY,
    fiscal_year INTEGER NOT NULL UNIQUE, -- 2024 for FY 2023-24
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    biennium VARCHAR(10) NOT NULL, -- 2023-25
    budget_status VARCHAR(20) DEFAULT 'Active' -- Active, Closed, Planning
);

-- Budget Allocations (Legislative Appropriations)
CREATE TABLE budget_allocations (
    allocation_id SERIAL PRIMARY KEY,
    agency_id INTEGER REFERENCES agencies(agency_id),
    category_id INTEGER REFERENCES budget_categories(category_id),
    fund_id INTEGER REFERENCES fund_sources(fund_id),
    fy_id INTEGER REFERENCES fiscal_years(fy_id),
    budgeted_amount DECIMAL(15,2) NOT NULL,
    allotment_amount DECIMAL(15,2), -- May be less than budgeted
    quarter_1_target DECIMAL(15,2),
    quarter_2_target DECIMAL(15,2),
    quarter_3_target DECIMAL(15,2),
    quarter_4_target DECIMAL(15,2),
    budget_notes TEXT,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Actual Expenditures (What agencies actually spent)
CREATE TABLE actual_expenditures (
    expenditure_id SERIAL PRIMARY KEY,
    agency_id INTEGER REFERENCES agencies(agency_id),
    category_id INTEGER REFERENCES budget_categories(category_id),
    fund_id INTEGER REFERENCES fund_sources(fund_id),
    fy_id INTEGER REFERENCES fiscal_years(fy_id),
    expenditure_date DATE NOT NULL,
    amount DECIMAL(15,2) NOT NULL,
    transaction_number VARCHAR(50),
    vendor_name VARCHAR(100),
    description TEXT,
    quarter INTEGER GENERATED ALWAYS AS (
        CASE 
            WHEN EXTRACT(month FROM expenditure_date) BETWEEN 7 AND 9 THEN 1
            WHEN EXTRACT(month FROM expenditure_date) BETWEEN 10 AND 12 THEN 2
            WHEN EXTRACT(month FROM expenditure_date) BETWEEN 1 AND 3 THEN 3
            WHEN EXTRACT(month FROM expenditure_date) BETWEEN 4 AND 6 THEN 4
        END
    ) STORED,
    processed_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Revenue Collections (Actual revenue received)
CREATE TABLE revenue_collections (
    collection_id SERIAL PRIMARY KEY,
    fund_id INTEGER REFERENCES fund_sources(fund_id),
    fy_id INTEGER REFERENCES fiscal_years(fy_id),
    collection_date DATE NOT NULL,
    amount DECIMAL(15,2) NOT NULL,
    revenue_type VARCHAR(50), -- Tax, Fee, Federal Grant, etc.
    source_agency_id INTEGER REFERENCES agencies(agency_id),
    forecasted_amount DECIMAL(15,2), -- What was forecasted for this period
    notes TEXT
);

-- ===================================================================
-- SAMPLE DATA INSERTION
-- ===================================================================

-- Insert Fiscal Years
INSERT INTO fiscal_years (fiscal_year, start_date, end_date, biennium, budget_status) VALUES
(2023, '2022-07-01', '2023-06-30', '2021-23', 'Closed'),
(2024, '2023-07-01', '2024-06-30', '2023-25', 'Closed'),
(2025, '2024-07-01', '2025-06-30', '2023-25', 'Active');

-- Insert Major Washington State Agencies
INSERT INTO agencies (agency_code, agency_name, agency_type, cabinet_area, director_name, fte_authorized) VALUES
('DSHS', 'Department of Social and Health Services', 'Cabinet', 'Health and Human Services', 'Lori Melchiori', 16500),
('DOT', 'Department of Transportation', 'Cabinet', 'Transportation', 'Roger Millar', 7200),
('DOR', 'Department of Revenue', 'Cabinet', 'General Government', 'Drew MacEwen', 1850),
('COM', 'Department of Commerce', 'Cabinet', 'Economic Development', 'Lisa Brown', 450),
('ECY', 'Department of Ecology', 'Cabinet', 'Natural Resources', 'Laura Watson', 1950),
('L&I', 'Department of Labor and Industries', 'Cabinet', 'General Government', 'Joel Sacks', 2400),
('WSAC', 'Washington Student Achievement Council', 'Independent', 'Higher Education', 'Michael Meotti', 75),
('UTC', 'Utilities and Transportation Commission', 'Independent', 'General Government', 'Amanda Maxwell', 185),
('OFM', 'Office of Financial Management', 'Cabinet', 'General Government', 'Pat Sullivan', 265),
('AGO', 'Attorney General Office', 'Elected', 'General Government', 'Bob Ferguson', 1100);

-- Insert Budget Categories
INSERT INTO budget_categories (category_code, category_name, category_type, description, is_mandated) VALUES
('PERS', 'Personnel', 'Personnel', 'Salaries, wages, and benefits for state employees', TRUE),
('OPEX', 'Operations', 'Operations', 'Day-to-day operational expenses', FALSE),
('EQUIP', 'Equipment', 'Operations', 'Equipment purchases under $5,000', FALSE),
('TRAVEL', 'Travel', 'Operations', 'Official state business travel expenses', FALSE),
('CONTR', 'Contracts', 'Operations', 'Professional services and contracts', FALSE),
('MAINT', 'Maintenance', 'Operations', 'Facility and equipment maintenance', FALSE),
('CAP', 'Capital', 'Capital', 'Major construction and capital projects', FALSE),
('GRANT', 'Grants', 'Operations', 'Grants to local governments and nonprofits', TRUE),
('DEBT', 'Debt Service', 'Operations', 'Bond payments and debt service', TRUE),
('UTIL', 'Utilities', 'Operations', 'Electricity, water, telecommunications', FALSE);

-- Insert Fund Sources
INSERT INTO fund_sources (fund_code, fund_name, fund_type, revenue_source, restrictions, federal_cfda) VALUES
('001', 'General Fund-State', 'General', 'State taxes and general revenue', 'General government operations', NULL),
('001-F', 'General Fund-Federal', 'Federal', 'Federal grants and transfers', 'Federal program requirements', 'Various'),
('136', 'Puget Sound Ferry Operations Account', 'Dedicated', 'Ferry fares and vehicle fees', 'Ferry system operations only', NULL),
('207', 'Motor Vehicle Account', 'Dedicated', 'Gas tax and vehicle registration fees', 'Transportation purposes only', NULL),
('23P', 'Accident Account', 'Dedicated', 'Workers compensation premiums', 'Workers compensation benefits', NULL),
('588', 'University of Washington Building Account', 'Dedicated', 'Student fees and building funds', 'UW facilities only', NULL),
('02W', 'Waste Reduction/Recycling/Litter Control', 'Dedicated', 'Litter tax and fees', 'Environmental programs', NULL),
('176', 'Unemployment Compensation Administration', 'Federal', 'Federal unemployment grants', 'UI administration only', '17.225'),
('058', 'Real Estate Commission Account', 'Dedicated', 'Real estate license fees', 'Real estate regulation', NULL),
('766', 'Liquor Revolving Account', 'Dedicated', 'Liquor sales and taxes', 'Liquor control operations', NULL);

-- ===================================================================
-- SAMPLE BUDGET ALLOCATIONS (FY 2024)
-- Realistic budget amounts based on actual WA state budget patterns
-- ===================================================================

-- DSHS Budget Allocations (Largest state agency)
INSERT INTO budget_allocations (agency_id, category_id, fund_id, fy_id, budgeted_amount, allotment_amount, quarter_1_target, quarter_2_target, quarter_3_target, quarter_4_target, budget_notes) VALUES
-- DSHS Personnel (General Fund)
(1, 1, 1, 2, 1850000000, 1825000000, 456250000, 456250000, 456250000, 456250000, 'Personnel costs for 16,500 FTE'),
-- DSHS Operations (General Fund)
(1, 2, 1, 2, 450000000, 445000000, 111250000, 111250000, 111250000, 111250000, 'DSHS operational expenses'),
-- DSHS Federal Grants
(1, 8, 2, 2, 3200000000, 3200000000, 800000000, 800000000, 800000000, 800000000, 'Federal grants for social services'),
-- DSHS Contracts
(1, 5, 1, 2, 650000000, 640000000, 160000000, 160000000, 160000000, 160000000, 'Community mental health contracts');

-- DOT Budget Allocations (Transportation focus)
INSERT INTO budget_allocations (agency_id, category_id, fund_id, fy_id, budgeted_amount, allotment_amount, quarter_1_target, quarter_2_target, quarter_3_target, quarter_4_target, budget_notes) VALUES
-- DOT Personnel (Motor Vehicle Account)
(2, 1, 4, 2, 485000000, 480000000, 120000000, 120000000, 120000000, 120000000, 'Transportation personnel'),
-- DOT Ferry Operations
(2, 2, 3, 2, 125000000, 122000000, 30500000, 30500000, 30500000, 30500000, 'Ferry system operations'),
-- DOT Capital Projects
(2, 7, 4, 2, 850000000, 825000000, 150000000, 200000000, 250000000, 225000000, 'Highway and bridge construction'),
-- DOT Maintenance
(2, 6, 4, 2, 180000000, 175000000, 43750000, 43750000, 43750000, 43750000, 'Highway and facility maintenance');

-- DOR Budget Allocations (Revenue collection)
INSERT INTO budget_allocations (agency_id, category_id, fund_id, fy_id, budgeted_amount, allotment_amount, quarter_1_target, quarter_2_target, quarter_3_target, quarter_4_target, budget_notes) VALUES
-- DOR Personnel
(3, 1, 1, 2, 145000000, 143000000, 35750000, 35750000, 35750000, 35750000, 'Tax collection personnel'),
-- DOR Operations
(3, 2, 1, 2, 85000000, 83000000, 20750000, 20750000, 20750000, 20750000, 'Tax administration operations'),
-- DOR Equipment/Technology
(3, 3, 1, 2, 25000000, 24000000, 6000000, 6000000, 6000000, 6000000, 'IT systems and equipment');

-- Additional agencies (Commerce, Ecology, L&I)
INSERT INTO budget_allocations (agency_id, category_id, fund_id, fy_id, budgeted_amount, allotment_amount, quarter_1_target, quarter_2_target, quarter_3_target, quarter_4_target, budget_notes) VALUES
-- Commerce Personnel
(4, 1, 1, 2, 35000000, 34500000, 8625000, 8625000, 8625000, 8625000, 'Economic development staff'),
-- Commerce Grants
(4, 8, 1, 2, 125000000, 120000000, 25000000, 30000000, 32500000, 32500000, 'Community development grants'),
-- Ecology Personnel
(5, 1, 1, 2, 145000000, 142000000, 35500000, 35500000, 35500000, 35500000, 'Environmental protection staff'),
-- Ecology Operations (Dedicated fund)
(5, 2, 7, 2, 45000000, 44000000, 11000000, 11000000, 11000000, 11000000, 'Environmental programs'),
-- L&I Personnel (Accident Account)
(6, 1, 5, 2, 185000000, 182000000, 45500000, 45500000, 45500000, 45500000, 'Workers compensation personnel'),
-- L&I Operations
(6, 2, 5, 2, 65000000, 63000000, 15750000, 15750000, 15750000, 15750000, 'Industrial safety operations');

-- ===================================================================
-- SAMPLE ACTUAL EXPENDITURES (FY 2024)
-- Includes realistic variances and timing patterns
-- ===================================================================

-- Generate DSHS expenditures (some over budget, timing issues)
INSERT INTO actual_expenditures (agency_id, category_id, fund_id, fy_id, expenditure_date, amount, transaction_number, vendor_name, description) VALUES
-- DSHS Personnel - Q1 (slight overspend)
(1, 1, 1, 2, '2023-07-15', 152500000, 'TXN-2023-07-001', 'State Payroll System', 'July 2023 payroll'),
(1, 1, 1, 2, '2023-08-15', 153200000, 'TXN-2023-08-001', 'State Payroll System', 'August 2023 payroll'),
(1, 1, 1, 2, '2023-09-15', 154100000, 'TXN-2023-09-001', 'State Payroll System', 'September 2023 payroll'),
-- DSHS Operations - Q1 (under budget)
(1, 2, 1, 2, '2023-07-20', 35500000, 'TXN-2023-07-050', 'Various Vendors', 'Operational expenses July'),
(1, 2, 1, 2, '2023-08-20', 34800000, 'TXN-2023-08-050', 'Various Vendors', 'Operational expenses August'),
(1, 2, 1, 2, '2023-09-20', 36200000, 'TXN-2023-09-050', 'Various Vendors', 'Operational expenses September'),
-- DSHS Federal Grants - Q1 (on target)
(1, 8, 2, 2, '2023-07-25', 265000000, 'TXN-2023-07-100', 'Federal Reimbursement', 'Federal grants July'),
(1, 8, 2, 2, '2023-08-25', 268000000, 'TXN-2023-08-100', 'Federal Reimbursement', 'Federal grants August'),
(1, 8, 2, 2, '2023-09-25', 270000000, 'TXN-2023-09-100', 'Federal Reimbursement', 'Federal grants September');

-- DOT expenditures (capital projects behind schedule)
INSERT INTO actual_expenditures (agency_id, category_id, fund_id, fy_id, expenditure_date, amount, transaction_number, vendor_name, description) VALUES
-- DOT Personnel - Q1 (on budget)
(2, 1, 4, 2, '2023-07-15', 40200000, 'TXN-2023-07-200', 'State Payroll System', 'DOT July payroll'),
(2, 1, 4, 2, '2023-08-15', 39800000, 'TXN-2023-08-200', 'State Payroll System', 'DOT August payroll'),
(2, 1, 4, 2, '2023-09-15', 40500000, 'TXN-2023-09-200', 'State Payroll System', 'DOT September payroll'),
-- DOT Capital Projects - Q1 (significantly under budget - delays)
(2, 7, 4, 2, '2023-07-30', 45000000, 'TXN-2023-07-300', 'Skanska USA', 'I-5 Bridge Construction'),
(2, 7, 4, 2, '2023-08-15', 52000000, 'TXN-2023-08-300', 'Granite Construction', 'Highway 101 Improvement'),
(2, 7, 4, 2, '2023-09-20', 38000000, 'TXN-2023-09-300', 'Walsh Construction', 'SR-520 Project Payment'),
-- DOT Ferry Operations - Q1 (over budget due to fuel costs)
(2, 2, 3, 2, '2023-07-10', 11200000, 'TXN-2023-07-400', 'BP Energy', 'Ferry fuel costs'),
(2, 2, 3, 2, '2023-08-10', 10800000, 'TXN-2023-08-400', 'Various Ferry Operations', 'Ferry operational costs'),
(2, 2, 3, 2, '2023-09-10', 11500000, 'TXN-2023-09-400', 'Various Ferry Operations', 'Ferry operational costs');

-- DOR expenditures (technology overspend)
INSERT INTO actual_expenditures (agency_id, category_id, fund_id, fy_id, expenditure_date, amount, transaction_number, vendor_name, description) VALUES
-- DOR Personnel - Q1 (on budget)
(3, 1, 1, 2, '2023-07-15', 12100000, 'TXN-2023-07-500', 'State Payroll System', 'DOR July payroll'),
(3, 1, 1, 2, '2023-08-15', 11900000, 'TXN-2023-08-500', 'State Payroll System', 'DOR August payroll'),
(3, 1, 1, 2, '2023-09-15', 12200000, 'TXN-2023-09-500', 'State Payroll System', 'DOR September payroll'),
-- DOR Equipment/Technology - Q1 (significant overspend)
(3, 3, 1, 2, '2023-07-25', 8500000, 'TXN-2023-07-600', 'Microsoft Corporation', 'Cloud services and software'),
(3, 3, 1, 2, '2023-08-30', 9200000, 'TXN-2023-08-600', 'Accenture', 'Tax system modernization'),
(3, 3, 1, 2, '2023-09-15', 7800000, 'TXN-2023-09-600', 'Dell Technologies', 'Hardware upgrades');

-- Additional expenditures for other agencies
INSERT INTO actual_expenditures (agency_id, category_id, fund_id, fy_id, expenditure_date, amount, transaction_number, vendor_name, description) VALUES
-- Commerce Grant Spending (front-loaded)
(4, 8, 1, 2, '2023-07-01', 15000000, 'TXN-2023-07-700', 'Seattle Housing Authority', 'Affordable housing grant'),
(4, 8, 1, 2, '2023-08-15', 12500000, 'TXN-2023-08-700', 'Spokane Economic Development', 'Business development grant'),
(4, 8, 1, 2, '2023-09-20', 18000000, 'TXN-2023-09-700', 'Tacoma Community College', 'Workforce development grant'),
-- Ecology Personnel (understaffed - under budget)
(5, 1, 1, 2, '2023-07-15', 11800000, 'TXN-2023-07-800', 'State Payroll System', 'Ecology July payroll'),
(5, 1, 1, 2, '2023-08-15', 11600000, 'TXN-2023-08-800', 'State Payroll System', 'Ecology August payroll'),
(5, 1, 1, 2, '2023-09-15', 11900000, 'TXN-2023-09-800', 'State Payroll System', 'Ecology September payroll'),
-- L&I Operations (workers comp claims higher than expected)
(6, 2, 5, 2, '2023-07-30', 5800000, 'TXN-2023-07-900', 'Various Medical Providers', 'Workers comp medical payments'),
(6, 2, 5, 2, '2023-08-30', 6200000, 'TXN-2023-08-900', 'Various Medical Providers', 'Workers comp medical payments'),
(6, 2, 5, 2, '2023-09-30', 5900000, 'TXN-2023-09-900', 'Various Medical Providers', 'Workers comp medical payments');

-- ===================================================================
-- SAMPLE REVENUE COLLECTIONS (FY 2024)
-- Shows forecasting accuracy issues
-- ===================================================================

INSERT INTO revenue_collections (fund_id, fy_id, collection_date, amount, revenue_type, source_agency_id, forecasted_amount, notes) VALUES
-- General Fund revenue collections (some forecast misses)
(1, 2, '2023-07-15', 1250000000, 'Sales Tax', 3, 1200000000, 'Higher than forecasted due to consumer spending'),
(1, 2, '2023-08-15', 1180000000, 'Sales Tax', 3, 1200000000, 'Below forecast - economic slowdown'),
(1, 2, '2023-09-15', 1210000000, 'Sales Tax', 3, 1200000000, 'Recovery in retail sales'),
-- Motor Vehicle Account (transportation revenue)
(4, 2, '2023-07-20', 145000000, 'Gas Tax', 2, 150000000, 'Lower than forecast - fuel efficiency trends'),
(4, 2, '2023-08-20', 142000000, 'Gas Tax', 2, 150000000, 'Continued decline in gas tax revenue'),
(4, 2, '2023-09-20', 148000000, 'Gas Tax', 2, 150000000, 'Slight improvement'),
-- Federal grants (timing issues)
(2, 2, '2023-07-30', 285000000, 'Federal Grant', 1, 270000000, 'Federal reimbursement for DSHS programs'),
(2, 2, '2023-08-30', 265000000, 'Federal Grant', 1, 270000000, 'Delayed federal payments'),
(2, 2, '2023-09-30', 275000000, 'Federal Grant', 1, 270000000, 'Federal timing adjustment');

-- ===================================================================
-- DATA VALIDATION QUERIES
-- Run these to verify your data loaded correctly
-- ===================================================================

-- Verify table row counts
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

-- ===================================================================
-- NOTES FOR STUDENTS
-- ===================================================================

/*
This database represents realistic Washington State budget data with:

1. INTENTIONAL DATA QUALITY ISSUES:
   - Some agencies overspending in certain categories
   - Capital projects behind schedule (DOT)
   - Technology overspends (DOR)
   - Revenue forecasting misses
   - Timing issues with federal grants

2. REALISTIC PATTERNS:
   - DSHS as largest agency (social services)
   - DOT with dedicated transportation funds
   - Mix of General Fund and dedicated fund sources
   - Seasonal spending patterns
   - Federal grant reimbursement timing

3. ANALYSIS OPPORTUNITIES:
   - Budget variance analysis by agency/category
   - Fund source compliance and management
   - Revenue forecasting accuracy
   - Quarterly spending patterns
   - Cross-agency efficiency comparisons

4. SKILLS YOU'LL PRACTICE:
   - Complex JOINs across government data
   - Aggregation and variance calculations
   - Time-series analysis for trends
   - Data quality assessment
   - Performance metric development

Start with basic exploration queries, then build up to complex
variance analysis. Focus on questions a legislator might ask!
*/