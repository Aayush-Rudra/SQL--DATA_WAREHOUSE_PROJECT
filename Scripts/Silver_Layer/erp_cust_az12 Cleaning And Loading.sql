-- Cleaning and Loading silver.erp_cust_az12 From bronze.erp_cust_az12--

-- Check the table
SELECT 
cid, -- foreign key as used in crm_cust_info
bdate,
gen 
FROM bronze.erp_cust_az12;

-- Since its bday records so we can say that cid will not be duplicate as 
-- one person cannot have two bday
SELECT 
cid, 
COUNT(*)
FROM bronze.erp_cust_az12
GROUP BY cid
HAVING COUNT(*)>2;
-- NO DUPLICATED RECORDS

-- cid IS NULL
SELECT 
cid
FROM bronze.erp_cust_az12
WHERE cid IS NULL;
-- NO NULL RECORDS

--Since foreign key exists so we check te formats of keys
SELECT 
cid
FROM bronze.erp_cust_az12;

SELECT cst_key FROM silver.crm_cust_info; 

--observation is cid starts from NAS WHERE AS cst_key starts from A
SELECT cst_key FROM silver.crm_cust_info
WHERE cst_key = 'NASAW00011000';  -- NO RECORDS FOUND

SELECT cst_key FROM silver.crm_cust_info
WHERE cst_key = 'AW00011000';  -- RECORD FOUND

-- OBSERVATION HOLDS TRUE
-- Therefore we need to change the format
SELECT 
cid,
CASE 
     WHEN cid Like 'NAS%' THEN SUBSTRING(cid,4,LEN(cid)) 
     ELSE cid    
END AS correct_cid
FROM bronze.erp_cust_az12;

--- NOW CHECK WHAT RECORDS EXITS ONLY IN erp_cust_az12 and Delete those
SELECT 
cid,
CASE 
     WHEN cid Like 'NAS%' THEN SUBSTRING(cid,4,LEN(cid)) 
     ELSE cid    
END AS correct_cid
FROM bronze.erp_cust_az12
WHERE 
CASE  WHEN cid Like 'NAS%' THEN SUBSTRING(cid,4,LEN(cid)) 
      ELSE cid  
END NOT IN (SELECT cst_key FROM silver.crm_cust_info);
-- NO records Found


--Indentify bdate that are out of range using boundary
SELECT
bdate
FROM
bronze.erp_cust_az12
WHERE bdate < '1926-01-01' --100+ year's old customers 
OR bdate > GETDATE(); --customers that are not even born future bdates
-- remove these records 35 in total from silver layer when loading
SELECT
bdate,
CASE
    WHEN bdate > GETDATE() THEN NULL -- only removed future dates
    WHEN bdate < '1926-01-01' THEN NULL -- 100+ year's old customers  REMOVED
    ELSE bdate
END AS bdate_corrected
FROM bronze.erp_cust_az12
WHERE bdate < '1926-01-01' --100+ year's old customers 
OR bdate > GETDATE()



--DATA Standardizationa nd consistency
SELECT DISTINCT
gen
FROM
bronze.erp_cust_az12;
-- values can be male , female and N/A
-- use case statements
SELECT DISTINCT
gen,
CASE UPPER(TRIM(gen))
     WHEN 'M' THEN 'Male'
     WHEN 'Male' THEN 'Male'
     WHEN 'Female' THEN 'Female'
     WHEN 'F' THEN 'Female'
     ELSE 'N/A'
END AS gen_corrected
FROM
bronze.erp_cust_az12;

---------------- Compile all the queries into one  ------------------
INSERT INTO silver.erp_cust_az12(
  cid,
  bdate,
  gen

)
SELECT 
CASE 
     WHEN cid Like 'NAS%' THEN SUBSTRING(cid,4,LEN(cid)) 
     ELSE cid    
END AS correct_cid,
CASE
    WHEN bdate > GETDATE() THEN NULL -- only removed future dates
    ELSE bdate
END AS bdate,
CASE UPPER(TRIM(gen))
     WHEN 'M' THEN 'Male'
     WHEN 'Male' THEN 'Male'
     WHEN 'Female' THEN 'Female'
     WHEN 'F' THEN 'Female'
     ELSE 'N/A'
END AS gen
FROM bronze.erp_cust_az12;



