-- Object Creation i.e Product In Gold Layer--
SELECT TOP 5* FROM silver.crm_prd_info;--master table
SELECT TOP 5* FROM silver.erp_px_cat_g1v2;-- Slave table


-- Remove all the Old history Keep only current prducts info --

SELECT 
pr.prd_id,
pr.cat_id,
pr.prd_key,
pr.prd_nm,
pr.prd_cost,
pr.prd_line,	
pr.prd_start_dt
FROM silver.crm_prd_info pr
WHERE pr.prd_end_dt IS NULL; -- FILTER OUT THE OLD HOSTORICAL DATA OF PRODUCTS


-- JOINING TWO TABLE By using Left Join as inner Join might lead to oass of data 
-- for unmatched data in mamster data
SELECT 
pr.prd_id,
pr.cat_id,
pr.prd_key,
pr.prd_nm,
pr.prd_cost,
pr.prd_line,
pr.prd_start_dt,
ct.cat,
ct.subcat,
ct.maintenance
FROM silver.crm_prd_info AS pr
LEFT JOIN silver.erp_px_cat_g1v2 AS ct
ON pr.cat_id = ct.id
WHERE pr.prd_end_dt IS NULL; -- FILTER OUT THE OLD HOSTORICAL DATA OF PRODUCTS


-- test if duplication arised due to join
SELECT DISTINCT
prd_id , COUNT(*) AS Flag_of_duplicates
FROM(
SELECT 
pr.prd_id,
pr.cat_id,
pr.prd_key,
pr.prd_nm,
pr.prd_cost,
pr.prd_line,
pr.prd_start_dt,
ct.cat,
ct.subcat,
ct.maintenance
FROM silver.crm_prd_info AS pr
LEFT JOIN silver.erp_px_cat_g1v2 AS ct
ON pr.cat_id = ct.id
WHERE pr.prd_end_dt IS NULL -- FILTER OUT THE OLD HOSTORICAL DATA OF PRODUCTS
)t
GROUP BY prd_id
HAVING COUNT(*)>1;
--- No RECORDS ---

SELECT 
pr.prd_id,
pr.prd_key,
pr.prd_nm,
pr.cat_id,
ct.cat,
ct.subcat,
ct.maintenance,
pr.prd_cost,
pr.prd_line,
pr.prd_start_dt
FROM silver.crm_prd_info AS pr
LEFT JOIN silver.erp_px_cat_g1v2 AS ct
ON pr.cat_id = ct.id
WHERE pr.prd_end_dt IS NULL -- FILTER OUT THE OLD HOSTORICAL DATA OF PRODUCTS

--- Now Create the object to store this queri data -> use view  ----
IF OBJECT_ID('gold.dim_products', 'V') IS NOT NULL
    DROP VIEW gold.dim_products;
GO

CREATE VIEW gold.dim_products AS
SELECT
    ROW_NUMBER() OVER (ORDER BY pr.prd_start_dt, pr.prd_key) AS product_key, -- Surrogate key
    pr.prd_id       AS product_id,
    pr.prd_key      AS product_number,
    pr.prd_nm       AS product_name,
    pr.cat_id       AS category_id,
    ct.cat          AS category,
    ct.subcat       AS subcategory,
    ct.maintenance  AS maintenance,
    pr.prd_cost     AS cost,
    pr.prd_line     AS product_line,
    pr.prd_start_dt AS start_date
FROM silver.crm_prd_info pr
LEFT JOIN silver.erp_px_cat_g1v2 ct
    ON pr.cat_id = ct.id
WHERE pr.prd_end_dt IS NULL -- FILTER OUT THE OLD HOSTORICAL DATA OF PRODUCTS
GO
