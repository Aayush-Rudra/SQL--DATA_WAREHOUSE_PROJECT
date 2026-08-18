----** crm_sales_details cleaning **----

-- Check enitre table
SELECT
sls_ord_num,
sls_prd_key, --foreign key connect with crm_prd_info
sls_cust_id, --foreign key conncet with crm_cust_info
sls_order_dt,    
sls_ship_dt,   
sls_due_dt,      
sls_sales,     
sls_quantity,    
sls_price       
FROM bronze.crm_sales_details;

--sls_order_num IS NULL VALUE EXITS -> NO 
SELECT
sls_ord_num
FROM bronze.crm_sales_details
WHERE sls_ord_num IS NULL

SELECT
sls_cust_id
FROM bronze.crm_sales_details
WHERE sls_cust_id IS NULL

SELECT
sls_prd_key
FROM bronze.crm_sales_details
WHERE sls_prd_key IS NULL

--Duplication is allowed as it is not a primary key
SELECT
sls_ord_num, COUNT(*) 
FROM bronze.crm_sales_details
GROUP BY sls_ord_num
HAVING COUNT(*)  > 2
--The sls_order_num is the same for one customer orders placed in a single transaction
-- same goes for sls_prd_key and sls_cust_id duplication will exits

--UNWANTED SPACE ALSO DOES NOT EXITS IN ALL THREE COLUMNS

-- Check that there is no mismatched/umwanted data sls_prd_key 
-- which is not in crm_pd_info as they are connected
SELECT * FROM bronze.crm_sales_details
WHERE  sls_prd_key NOT IN (SELECT prd_key FROM silver.crm_prd_info);
-- expected result was NO which is TRUE

-- Check that there is no mismatched/umwanted data sls_cust_id
-- which is not in crm_cust_info as they are connected
SELECT * FROM bronze.crm_sales_details
WHERE sls_cust_id NOT IN (SELECT  cst_id  FROM silver.crm_cust_info);
-- Expected result was NO which is TRUE




-- Checking datatype of sls_order_dt
SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'bronze'
  AND TABLE_NAME = 'crm_sales_details'
  AND COLUMN_NAME = 'sls_order_dt';

-- Invalid dates are also to be handled
SELECT
NULLIF(sls_order_dt,0)-- handled 0 dates  
FROM bronze.crm_sales_details
WHERE sls_order_dt <= 0 -- negative dates --result was 0 records
OR LEN(sls_order_dt)!=8; -- check for invalid dates if length is less then 8
-- OR boundary condition of date like minimim date which will be when business was opened
-- and maximum date ex no future values of date

-- SOLUTION 
SELECT
sls_order_dt,
CASE
     WHEN sls_order_dt <= 0 OR LEN(sls_order_dt)!=8 THEN NULL
     -- Dates datatype needs to be changed from int to date
     ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE)  
END AS sls_order_dt
FROM bronze.crm_sales_details;
--apply this on all dates column
SELECT
sls_ship_dt,
CASE
     WHEN sls_ship_dt <= 0 OR LEN(sls_ship_dt)!=8 THEN NULL
     -- Dates datatype needs to be changed from int to date
     ELSE CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE)  
END AS sls_ship_dt
FROM bronze.crm_sales_details;

SELECT
sls_due_dt,
CASE
     WHEN sls_due_dt <= 0 OR LEN(sls_due_dt)!=8 THEN NULL
     -- Dates datatype needs to be changed from int to date
     ELSE CAST(CAST(sls_due_dt AS VARCHAR) AS DATE)  
END AS sls_due_dt
FROM bronze.crm_sales_details;

-- Invalid dates if Order date > shiping date and order date > due date
SELECT * FROM bronze.crm_sales_details
WHERE sls_order_dt > sls_ship_dt OR sls_order_dt > sls_due_dt;
-- ans no records so no need of transformation


---- ** CHECKING DATA CONSISTENCY BETWEEN SALES, QUANTITY AND PRICE ** --------
-->> sls_sales =  sls quantity * sls_price 
-->> VALUES of these Column must not be NULL, Zero, OR Negative

/*
If you use DISTINCT, you're asking:
"What are the different types/combinations of bad values?"
Without DISTINCT, you're asking:
"Which actual rows have bad values?"
*/

SELECT DISTINCT
sls_sales,
sls_quantity,
sls_price
FROM bronze.crm_sales_details
WHERE sls_price IS NULL 
OR  sls_sales IS NULL 
OR sls_price IS NULL
OR sls_sales != sls_price * sls_quantity
OR sls_price <0 OR  sls_sales < 0  OR sls_price < 0;
--issue in sls_sales and sls_price 
-- no issue with sls_quantity

-- BUSINESS RULES FOR CORRECTION
--#1 Sales is Negative,zero or null derive it using quantity and price
--#2 if price is zero or null, calculate it using sales and quantity
--#3 if price is negative, convert it to a positive value

SELECT 
sls_sales,
CASE 
    WHEN sls_sales <= 0 OR sls_sales IS NULL OR sls_price != sls_quantity * ABS(sls_price) 
    THEN  ABS(sls_price) * sls_quantity
    ELSE sls_sales
END AS sls_sales_correctd, 
sls_quantity, 
sls_price,
CASE 
    WHEN sls_price = 0 OR sls_price IS NULL THEN  ABS(sls_sales) / sls_quantity
    WHEN sls_price < 0 THEN ABS(sls_price)
    ELSE sls_price
END AS sls_price_correctd
FROM bronze.crm_sales_details
WHERE sls_price IS NULL 
OR  sls_sales IS NULL 
OR sls_price IS NULL
OR sls_sales != sls_price * sls_quantity
OR sls_price <0 OR  sls_sales < 0  OR sls_price < 0;

----------- COMPLILING ALL THE CLEANING QURIES INTO ONE ---------

-- Befor inserting check the data tyes of column 
-- if changed then drop the old table craete new table with req.modification in data types
INSERT INTO silver.crm_sales_details(
    sls_ord_num,     
    sls_prd_key,    
    sls_cust_id,   
    sls_order_dt,    
    sls_ship_dt,     
    sls_due_dt,      
    sls_sales,       
    sls_quantity,    
    sls_price
)
SELECT 
sls_ord_num,
sls_prd_key, --foreign key connect with crm_prd_info
sls_cust_id, --foreign key conncet with crm_cust_info
CASE
     WHEN sls_order_dt <= 0 OR LEN(sls_order_dt)!=8 THEN NULL
     -- Dates datatype needs to be changed from int to date
     ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE)  
END AS sls_order_dt,
CASE
     WHEN sls_ship_dt <= 0 OR LEN(sls_ship_dt)!=8 THEN NULL
     -- Dates datatype needs to be changed from int to date
     ELSE CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE)  
END AS sls_ship_dt,
CASE
     WHEN sls_due_dt <= 0 OR LEN(sls_due_dt)!=8 THEN NULL
     -- Dates datatype needs to be changed from int to date
     ELSE CAST(CAST(sls_due_dt AS VARCHAR) AS DATE)  
END AS sls_due_dt,
-- BUSINESS RULES FOR CORRECTION
--#1 Sales is Negative,zero or null derive it using quantity and price
--#2 if price is zero or null, calculate it using sales and quantity
--#3 if price is negative, convert it to a positive value
CASE 
    WHEN sls_sales <= 0 OR sls_sales IS NULL OR sls_price != sls_quantity * ABS(sls_price) 
    THEN  ABS(sls_price) * sls_quantity
    ELSE sls_sales
END AS sls_sales, 
sls_quantity, -- No records with Issues were found
CASE 
    WHEN sls_price = 0 OR sls_price IS NULL THEN  ABS(sls_sales) / NULLIF(sls_quantity,0)
    WHEN sls_price < 0 THEN ABS(sls_price)
    ELSE sls_price
END AS sls_price_
FROM bronze.crm_sales_details;




