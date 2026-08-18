-- Cleaning erp_px_cat_g1v2 --

SELECT 
id,  -- foreign key used as cat_id in crm_prd_info
cat, 
subcat, 
maintenance
FROM bronze.erp_px_cat_g1v2;

-- check for unwanted spaces
SELECT * FROM bronze.erp_px_cat_g1v2
WHERE cat != TRIM(cat) 
OR subcat != TRIM(subcat)
OR maintenance != TRIM(maintenance);
--- no record found

---- DATA STANDARDIZATION AND CONSISTENCY
SELECT DISTINCT
cat
FROM bronze.erp_px_cat_g1v2;

SELECT DISTINCT
subcat
FROM bronze.erp_px_cat_g1v2;

SELECT DISTINCT
maintenance
FROM bronze.erp_px_cat_g1v2;
--- no req. of transfomation

-------- compilation of all queries ------------
INSERT INTO silver.erp_px_cat_g1v2(
id,
cat,
subcat,
maintenance
)
SELECT 
id,  -- foreign key used as cat_id in crm_prd_info
cat, 
subcat, 
maintenance
FROM bronze.erp_px_cat_g1v2;