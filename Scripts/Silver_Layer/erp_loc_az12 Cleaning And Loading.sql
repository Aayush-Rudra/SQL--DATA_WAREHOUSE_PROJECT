---- cleaning erp_loc_a101 ---

SELECT * FROM bronze.erp_loc_a101;

--- format of cid is not same as cst_key in crm_cust_info
-- as both of the data is same info 

SELECT 
cid,
Replace(cid, '-', '') AS cid_new -- to replaace AW-00011000 to AW00011000
FROM bronze.erp_loc_a101;

---cntry column check
SELECT * FROM bronze.erp_loc_a101
where cntry IS NULL;
-- use case statements or nullif or coalesce
SELECT 
cid,
cntry,
ISNULL(cntry,'N/A')
FROM bronze.erp_loc_a101
where cntry IS NULL;

----DATA STANDARDIZATION AND CONSISTENCY
SELECT DISTINCT
cntry
FROM bronze.erp_loc_a101;

SELECT DISTINCT
cntry,
CASE  
    WHEN cntry IS NULL THEN 'N/A'
    WHEN TRIM(cntry) = 'DE' THEN 'Germany'
    WHEN TRIM(cntry) IN ('US', 'USA') THEN 'United States'
    WHEN TRIM(cntry) = '' THEN 'N/A'
    ELSE TRIM(cntry)
END AS cntry_new
FROM bronze.erp_loc_a101;


------------compiling all of them ----- 
INSERT INTO silver.erp_loc_a101(
cid,
cntry
)
SELECT 
Replace(cid, '-', '') AS cid,
CASE  
    WHEN cntry IS NULL THEN 'N/A'
    WHEN TRIM(cntry) = 'DE' THEN 'Germany'
    WHEN TRIM(cntry) IN ('US', 'USA') THEN 'United States'
    WHEN TRIM(cntry) = '' THEN 'N/A'
    ELSE TRIM(cntry)
END AS cntry
FROM bronze.erp_loc_a101;