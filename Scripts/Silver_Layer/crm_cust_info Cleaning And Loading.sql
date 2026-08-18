-- 1st Check : FOR NULLS AND DUPLICATES IN PRIMARY KEY --
-- Expectation: NO RESULT

-- DUPLICATES AND ITS DELETION
    -- Duplicates in primarkey can be deleted 
    -- acc. to cst_create_date as it shows us latest and older dates
    -- will be using row_number() function to create ranks for each record acc to cst_create_date 
    -- 1 representing latest and higher number representing older date as flag column

-- TABLE WHERE NO cst_id is duplicates
SELECT * FROM 
(
  SELECT *, ROW_NUMBER() OVER(PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag_last
  FROM bronze.crm_cust_info WHERE cst_id IS NOT NULL

)t WHERE flag_last = 1

-- Rough work
SELECT *,
       COUNT(cst_id) OVER (PARTITION BY cst_id) AS duplicate_count
FROM bronze.crm_cust_info
WHERE cst_id IN (
    SELECT cst_id
    FROM bronze.crm_cust_info
    GROUP BY cst_id
    HAVING COUNT(cst_id) > 1
);

--NULL IN PRIMARY KEY

SELECT * FROM bronze.crm_cust_info Where cst_id is null;

SELECT cst_id, count(*)
FROM bronze.crm_cust_info
GROUP BY cst_id
HAVING COUNT(cst_id) > 1
OR cst_id IS NULL;

-- 3rd quality check is to remove extra spaces from the table
SELECT * FROM 
(
  SELECT *, ROW_NUMBER() OVER(PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag_last
  FROM bronze.crm_cust_info WHERE cst_id IS NOT NULL

)t WHERE flag_last = 1

-- CHECK FOR UNWANTED SPACES TRIM() fuction is used
SELECT cst_firstname FROM bronze.crm_cust_info
WHERE cst_firstname != TRIM(cst_firstname);

-- DATA STANDARDIZATION AND CONSISTENCY (example with dont want to use abbrivation's)
SELECT DISTINCT cst_gndr
FROM bronze.crm_cust_info;

SELECT DISTINCT cst_marital_status
FROM bronze.crm_cust_info;
 
-- to replace these short forms to full forms you will be using 
-- CASE STATEMENTS
SELECT 
cst_gndr,
CASE
     WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'MALE' -- so that smaller case or unwanted space remove can also be included
     WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'FEMALE' -- so that smaller case or unwanted space remove can also be included
     ELSE 'N/A'
END AS "FULL FORMS OF GENDER"
FROM bronze.crm_cust_info;


SELECT * FROM bronze.crm_cust_info Where cst_lastname is null



/* 
============= COMPLILING ALL THE CLEANING QURIES INTO ONE===============================================
 CRM CUSTOMER INFORMATION CLEANING

 OBJECTIVE:
 Clean and standardize customer data before loading it from
 the Bronze layer into the Silver layer.

TRANSFORMATION STEPS:
-- 1. Remove records with NULL customer IDs.
-- 2. Remove duplicate customer records using ROW_NUMBER(),
      keeping the latest record based on cst_create_date.
-- 3. Remove unwanted spaces using TRIM().
-- 4. Data Standardize AND Consistency
      Convert abbreviated gender and marital status values
      into full descriptive values using CASE statements and 
      Upper() and Trim().
-- 5. Handle missing or invalid values where applicable.
-- ============================================================
*/

INSERT INTO silver.crm_cust_info
(
    cst_id,
	cst_key,
    cst_firstname,
    cst_lastname,
    cst_marital_status,
    cst_gndr,
	cst_create_date

)
SELECT 
	cst_id,
	cst_key,
    TRIM(cst_firstname), -- REMOVAL OF UNWANTED SPACES
    TRIM(cst_lastname),  -- REMOVAL OF UNWANTED SPACES
    CASE
        WHEN UPPER(TRIM(cst_gndr)) = 'S' THEN 'SINGLE' -- so that smaller case or unwanted space remove can also be included
        WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'MARRIED' -- so that smaller case or unwanted space remove can also be included
        ELSE 'N/A' -- to handle null values
    END AS cst_marital_status,
    CASE
        WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'MALE' -- so that smaller case or unwanted space remove can also be included
        WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'FEMALE' -- so that smaller case or unwanted space remove can also be included
        ELSE 'N/A' -- to handle null values
    END AS cst_gndr,
	cst_create_date

FROM 
(
  SELECT *, ROW_NUMBER() OVER(PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag_last
  FROM bronze.crm_cust_info WHERE cst_id IS NOT NULL -- REMOVED cst_id == NULL 

)t WHERE flag_last = 1 -- KEEP ONLY RECENT RECORDS OF CUSTOMER'S