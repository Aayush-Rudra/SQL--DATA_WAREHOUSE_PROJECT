CREATE OR ALTER PROCEDURE bronze.test_bronze_data
    @table_choice INT
AS
BEGIN
    
    ---is a SQL Server statement that stops SQL Server from displaying messages like: (5 rows affected)
    SET NOCOUNT ON; 
    
    PRINT '==========================================';
    PRINT '       BRONZE LAYER TEST MENU';
    PRINT '==========================================';
    PRINT '1. CRM Customer Info';
    PRINT '2. CRM Product Info';
    PRINT '3. CRM Sales Details';
    PRINT '4. ERP Location';
    PRINT '5. ERP Customer';
    PRINT '6. ERP Product Category';
    PRINT '7. Show Top 5 From All Tables';
    PRINT '==========================================';

    ------------------------------------------------
    -- OPTION 1
    ------------------------------------------------
    IF @table_choice = 1
    BEGIN
        PRINT 'Showing Top 5 Rows: bronze.crm_cust_info';

        SELECT TOP 5 *
        FROM bronze.crm_cust_info;
    END

    ------------------------------------------------
    -- OPTION 2
    ------------------------------------------------
    ELSE IF @table_choice = 2
    BEGIN
        PRINT 'Showing Top 5 Rows: bronze.crm_prd_info';

        SELECT TOP 5 *
        FROM bronze.crm_prd_info;
    END

    ------------------------------------------------
    -- OPTION 3
    ------------------------------------------------
    ELSE IF @table_choice = 3
    BEGIN
        PRINT 'Showing Top 5 Rows: bronze.crm_sales_details';

        SELECT TOP 5 *
        FROM bronze.crm_sales_details;
    END

    ------------------------------------------------
    -- OPTION 4
    ------------------------------------------------
    ELSE IF @table_choice = 4
    BEGIN
        PRINT 'Showing Top 5 Rows: bronze.erp_loc_a101';

        SELECT TOP 5 *
        FROM bronze.erp_loc_a101;
    END

    ------------------------------------------------
    -- OPTION 5
    ------------------------------------------------
    ELSE IF @table_choice = 5
    BEGIN
        PRINT 'Showing Top 5 Rows: bronze.erp_cust_az12';

        SELECT TOP 5 *
        FROM bronze.erp_cust_az12;
    END

    ------------------------------------------------
    -- OPTION 6
    ------------------------------------------------
    ELSE IF @table_choice = 6
    BEGIN
        PRINT 'Showing Top 5 Rows: bronze.erp_px_cat_g1v2';

        SELECT TOP 5 *
        FROM bronze.erp_px_cat_g1v2;
    END

    ------------------------------------------------
    -- OPTION 7 - SHOW ALL TABLES
    ------------------------------------------------
    ELSE IF @table_choice = 7
    BEGIN
        PRINT '==========================================';
        PRINT 'TOP 5: bronze.crm_cust_info';
        PRINT '==========================================';

        SELECT TOP 5 *
        FROM bronze.crm_cust_info;


        PRINT '==========================================';
        PRINT 'TOP 5: bronze.crm_prd_info';
        PRINT '==========================================';

        SELECT TOP 5 *
        FROM bronze.crm_prd_info;


        PRINT '==========================================';
        PRINT 'TOP 5: bronze.crm_sales_details';
        PRINT '==========================================';

        SELECT TOP 5 *
        FROM bronze.crm_sales_details;


        PRINT '==========================================';
        PRINT 'TOP 5: bronze.erp_loc_a101';
        PRINT '==========================================';

        SELECT TOP 5 *
        FROM bronze.erp_loc_a101;


        PRINT '==========================================';
        PRINT 'TOP 5: bronze.erp_cust_az12';
        PRINT '==========================================';

        SELECT TOP 5 *
        FROM bronze.erp_cust_az12;


        PRINT '==========================================';
        PRINT 'TOP 5: bronze.erp_px_cat_g1v2';
        PRINT '==========================================';

        SELECT TOP 5 *
        FROM bronze.erp_px_cat_g1v2;
    END

    ------------------------------------------------
    -- INVALID INPUT
    ------------------------------------------------
    ELSE
    BEGIN
        PRINT 'ERROR: Invalid choice.';
        PRINT 'Please enter a number between 1 and 7.';
    END

END;
GO

/*
-- 1 = Customer Info
EXEC bronze.test_bronze_data @table_choice = 1;

-- 2 = Product Info
EXEC bronze.test_bronze_data @table_choice = 2;

-- 3 = Sales Details
EXEC bronze.test_bronze_data @table_choice = 3;

-- 4 = ERP Location
EXEC bronze.test_bronze_data @table_choice = 4;

-- 5 = ERP Customer
EXEC bronze.test_bronze_data @table_choice = 5;

-- 6 = ERP Product Category
EXEC bronze.test_bronze_data @table_choice = 6;

-- 7 = Show Top 5 records from ALL Bronze tables
EXEC bronze.test_bronze_data @table_choice = 7;
*/