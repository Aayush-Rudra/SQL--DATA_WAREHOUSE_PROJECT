--- GOLD LAYER ---
SELECT * FROM silver.crm_cust_info; -- Master Table
SELECT * FROM silver.erp_cust_az12; -- Slave Table
SELECT * FROM silver.erp_loc_a101; -- Slave Table

-- ABOVE TABLE DATA NEEDS TO BE COMBINED AND VIEW NEEDS TO BE MADE
-- We are using left join on the table because 
-- inner join -> the data of customer might get lost
-- as for some customers there will be no data in slave table
SELECT 
ci.cst_id, 
ci.cst_key, 
ci.cst_firstname, 
ci.cst_lastname, 
ci.cst_marital_status, 
ci.cst_gndr,
ci.cst_create_date,
bd.bdate,
bd.gen,
loc.cntry
FROM silver.crm_cust_info ci
LEFT JOIN silver.erp_cust_az12 bd 
-- ( SELECT * FROM silver.erp_cust_az12 ) 
-- It becomes useful when you want to filter, transform, or aggregate data before joining.
ON ci.cst_key = bd.cid
LEFT JOIN silver.erp_loc_a101 loc 
ON ci.cst_key = loc.cid;

-- Check due to Join Duplicates have not occured 
-- i.e there are no duplicates of cst_id after left join
SELECT cst_key, Count(*) as Flag_of_duplicates
FROM(
SELECT 
ci.cst_id, 
ci.cst_key, 
ci.cst_firstname, 
ci.cst_lastname, 
ci.cst_marital_status, 
ci.cst_gndr,
ci.cst_create_date,
bd.bdate,
bd.gen,
loc.cntry
FROM silver.crm_cust_info ci
LEFT JOIN silver.erp_cust_az12 bd 
ON ci.cst_key = bd.cid
LEFT JOIN silver.erp_loc_a101 loc 
ON ci.cst_key = loc.cid
)t
GROUP BY cst_key
HAVING COUNT(*) > 1;

--- Issue After Joining Is two Column of same info i,e gender 
-- column name cst_gndr and gen
SELECT DISTINCT
ci.cst_gndr, -- column 1
bd.gen -- column 2
FROM silver.crm_cust_info ci
LEFT JOIN silver.erp_cust_az12 bd 
ON ci.cst_key = bd.cid
LEFT JOIN silver.erp_loc_a101 loc 
ON ci.cst_key = loc.cid
ORDER BY 1,2;
/*Issues
#1 cst_gen from silver.crm_cust_info and gen from silver.erp_cust_az12 is mismatched
   then use master data (suppose here it is crm).
#2 if cst_gen from silver.crm_cust_info is null then use data from 
   gen from silver.erp_cust_az12.
#3 if both of them is n/a or null(arised due to join) then make the final data also N/A 
*/
--Solution is 
SELECT DISTINCT
ci.cst_gndr, -- column 1
bd.gen, -- column 2
CASE
     WHEN ci.cst_gndr  != 'N/A' THEN ci.cst_gndr -- master data is prefered
     ELSE UPPER(COALESCE(bd.gen,'N/A')) -- ci.cst_gndr is N/A or null then use bd.gen 
                                 -- and if bd.gen is also n/a or null then the value be N/A
END AS aggregated_gender_data
FROM silver.crm_cust_info ci
LEFT JOIN silver.erp_cust_az12 bd 
ON ci.cst_key = bd.cid
LEFT JOIN silver.erp_loc_a101 loc 
ON ci.cst_key = loc.cid
ORDER BY 1,2;

---- final compiled qurie ----
SELECT 
ci.cst_id, 
ci.cst_key, 
ci.cst_firstname, 
ci.cst_lastname, 
ci.cst_marital_status, 
CASE
     WHEN ci.cst_gndr  != 'N/A' THEN ci.cst_gndr -- master data is prefered
     ELSE UPPER(COALESCE(bd.gen,'N/A')) -- ci.cst_gndr is N/A or null then use bd.gen 
                                 -- and if bd.gen is also n/a or null then the value be N/A
END AS cst_gender,
ci.cst_create_date,
bd.bdate,
loc.cntry
FROM silver.crm_cust_info ci
LEFT JOIN silver.erp_cust_az12 bd 
ON ci.cst_key = bd.cid
LEFT JOIN silver.erp_loc_a101 loc 
ON ci.cst_key = loc.cid;
GO

--- Now Create the object to store this queri data -> use view  ----
IF OBJECT_ID('gold.dim_customers', 'V') IS NOT NULL
    DROP VIEW gold.dim_customers;
GO

CREATE VIEW gold.dim_customers AS 
(   SELECT 
    -- Since its a dimension not a fact therefore 
    -- we need to create a surrogate key
    ROW_NUMBER() OVER (ORDER BY ci.cst_id) AS customer_key,
    ci.cst_id AS customer_id, 
    ci.cst_key AS customer_number, 
    ci.cst_firstname AS first_name, 
    ci.cst_lastname AS  last_name,
    loc.cntry AS country,
    ci.cst_marital_status AS marital_status, 
    CASE
         WHEN ci.cst_gndr  != 'N/A' THEN ci.cst_gndr -- master data is prefered
         ELSE UPPER(COALESCE(bd.gen,'N/A')) -- ci.cst_gndr is N/A or null then use bd.gen 
                                            -- and if bd.gen is also n/a or null then the value be N/A
    END AS gender,
    bd.bdate AS birthdate,
    ci.cst_create_date AS create_date
    FROM silver.crm_cust_info ci
    LEFT JOIN silver.erp_cust_az12 bd 
    ON ci.cst_key = bd.cid
    LEFT JOIN silver.erp_loc_a101 loc 
    ON ci.cst_key = loc.cid
);