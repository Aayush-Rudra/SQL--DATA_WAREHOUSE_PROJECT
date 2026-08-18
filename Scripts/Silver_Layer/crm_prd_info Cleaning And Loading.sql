----** crm_prd_info cleaning **----

-- Check the Inital Table Data
SELECT * FROM bronze.crm_prd_info;

-- Check Null in Primary key prd_id
SELECT * FROM bronze.crm_prd_info
WHERE prd_id IS NULL;
-- RESULT = NO NULL VALUE

-- Check Duplicates in Primary Key prd_id
SELECT prd_id,COUNT(*) FROM bronze.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) > 1;
-- RESULT = NO DUPLICATES VALUE


--REMOVE UNWANTED SPACE IF THEY EXITS
SELECT * FROM bronze.crm_prd_info; -- check 
-- RESULT = NO UNWANTED SPACES

--****************** Below queries Are Doing Derived Columns*************************************************

-- prd_key is made up of two parts prd_cat and prd_key
-- prd_cat verification can be done using bronze.erp_px_cat_g1v2 column name id
SELECT * FROM bronze.erp_px_cat_g1v2;

SELECT prd_id, prd_key FROM bronze.crm_prd_info;


--issue is in bronze.erp_px_cat_g1v2 column name id syntax uses "_" not "-"
SELECT 
prd_id, 
prd_key,
REPLACE(SUBSTRING(prd_key,1,5),'-','_') AS prd_cat
FROM bronze.crm_prd_info
WHERE REPLACE(SUBSTRING(prd_key,1,5),'-','_') 
NOT IN (SELECT id FROM bronze.erp_px_cat_g1v2); 
-- RESULT THERE ARE 7 VALUES which do not exists in erp_px_cat_g1v2

-- prd_key verification can be done using bronze.crm_sales_details column name sls_prd_key
SELECT * FROM bronze.crm_sales_details;

SELECT 
prd_id, 
prd_key,
REPLACE(SUBSTRING(prd_key,1,5),'-','_') AS prd_cat,
SUBSTRING(prd_key,7,LEN(prd_key)) AS prd__key
FROM bronze.crm_prd_info
WHERE SUBSTRING(prd_key,7,LEN(prd_key)) 
NOT IN (SELECT sls_prd_key FROM bronze.crm_sales_details); 
-- RESULT THERE ARE MANY VALUES which 
-- do not exists in bronze.crm_sales_details As they have no orders which is fine

--****** as result two new column are to be made for establishing two tables with crm_prd_info *******


-- Changes in product cost NULL to 0 by using ISNULL (two arguments)
-- or COALESCE(more than 2)
SELECT 
prd_id,
--ISNULL(prd_cost,0)
COALESCE(prd_cost,0)
FROM bronze.crm_prd_info

-- Data Standardization -> short form to full form of column prd_line

SELECT DISTINCT prd_line FROM bronze.crm_prd_info;

SELECT
prd_line,
CASE UPPER(TRIM(prd_line))
     WHEN 'M' THEN 'Mountain' 
     WHEN 'R' THEN 'Road'
     WHEN 'S' THEN 'Other Sales' 
     WHEN 'T' THEN 'Touring'
     ELSE  'N/A'
END AS prd___Line
FROM
bronze.crm_prd_info;

--******* Below Queries Are Doing DATA ENRICHMENT ******* -----
-- CHECK prd_start_dt and prd_end_dt Validate them--
-- Issues are
-- NULL
-- Invalid Dates ( prd_start_dt > prd_end_dt) which should be 

SELECT TOp 5* FROM bronze.crm_prd_info
WHERE prd_start_dt > prd_end_dt
Order by  prd_key; -- it should be corrected as end date cannot be less than start date

/*
Solutions
#1 Switch End Dates and Start Dates
   ISSUEs:-  The dates were overlapping 
             Each Records must have a Start Date

#2 Derive the end date from the  start date
   i.e END DATE  =  Start Date of the 'Next' Record - 1.
   --> LEAD() value fuction is used
   There Where no Issues 
*/
 
SELECT TOP 5 prd_id, prd_key, prd_nm, prd_cost, prd_line, prd_start_dt, prd_end_dt,
-- trick without use of DATEADD()
LEAD(prd_start_dt) OVER (PARTITION BY prd_key Order by prd_key )-1 AS prd_END_DATE, 
--using DATEADD()
DATEADD(DAY,-1,(LEAD(prd_start_dt) OVER (PARTITION BY prd_key Order by prd_key )))
FROM bronze.crm_prd_info
WHERE prd_start_dt > prd_end_dt
Order by  prd_key;

--Notice that is prd_end_dt and prd_start_dt both are using date only so we can change it
--from DATETIME to DATE using CAST()

 
SELECT TOP 5 prd_id, prd_key, prd_nm, prd_cost, prd_line, 
CAST(prd_start_dt AS DATE),
--prd_end_dt replaced b below,
-- trick without use of DATEADD()
CAST(LEAD(prd_start_dt) OVER (PARTITION BY prd_key Order by prd_key )-1 AS DATE) AS prd_end_dt 
--using DATEADD()
--DATEADD(DAY,-1,(LEAD(prd_start_dt) OVER (PARTITION BY prd_key Order by prd_key )))
FROM bronze.crm_prd_info
WHERE prd_start_dt > prd_end_dt
Order by  prd_key;

----------- COMPLILING ALL THE CLEANING QURIES INTO ONE ---------

-- WE are Droping older table because we made changes in the datatype and added columns 

IF OBJECT_ID('silver.crm_prd_info', 'U') IS NOT NULL
    DROP TABLE silver.crm_prd_info;
GO

CREATE TABLE silver.crm_prd_info (
    prd_id          INT,
    cat_id          NVARCHAR(50),
    prd_key         NVARCHAR(50),
    prd_nm          NVARCHAR(50),
    prd_cost        INT,
    prd_line        NVARCHAR(50),
    prd_start_dt    DATE,
    prd_end_dt      DATE,
);
GO


INSERT INTO silver.crm_prd_info(
    prd_id, 
    cat_id,
    prd_key,
    prd_nm,
    prd_cost, 
    prd_line,
    prd_start_dt,
    prd_end_dt 
)
SELECT 
prd_id, 
REPLACE(SUBSTRING(prd_key,1,5),'-','_') AS prd_cat,
SUBSTRING(prd_key,7,LEN(prd_key)) AS prd_key,
prd_nm,
ISNULL(prd_cost,0) AS prd_cost, 
CASE UPPER(TRIM(prd_line))
     WHEN 'M' THEN 'Mountain' 
     WHEN 'R' THEN 'Road'
     WHEN 'S' THEN 'Other Sales' 
     WHEN 'T' THEN 'Touring'
     ELSE  'N/A'
END AS prd_line,
CAST(prd_start_dt AS DATE) AS prd_start_dt,
CAST(LEAD(prd_start_dt) OVER (PARTITION BY prd_key Order by prd_key )-1 AS DATE) AS prd_end_dt 
FROM bronze.crm_prd_info;















