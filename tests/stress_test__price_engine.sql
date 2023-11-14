/**
*
* RELEASE: Price Engine Stress Test
* *
**/


/**
*
*   BEGIN PRICE ENGINE CONFIGURATION
*
**/
DECLARE @DestinationContractId AS INT;
SET @DestinationContractId = 55;

DECLARE @ContractNumber AS VARCHAR(100);
SET @ContractNumber = 'STRESS TEST'

DECLARE @ContractStartDate AS DATETIME;
SET @ContractStartDate = GETDATE();

DECLARE @ContractEndDate AS DATETIME;
SET @ContractEndDate = DATEADD(year, 1, GETDATE());

/**
*
*   BEGIN PRICE ENGINE RULE SQL DEFINITIONS
*
**/

/** CLEAR TEMP TABLE **/
DELETE FROM [wwcp_pricing].[dbo].[ContractItem_temp];

/**
*
* BEGIN PRICE RULE EXECUTION
*
*/

/** PRICE RULE ONE **/
BEGIN TRY
    DECLARE @PriceRuleDiscount AS FLOAT;
    SET @PriceRuleDiscount = '0.05'; -- Set Discount Percentage Here

    DECLARE @PriceRuleName AS VARCHAR(150);
    SET @PriceRuleName = 'STRESS TEST - PRICE RULE 1';

    /** PRICE ENGINE MERGE **/
    MERGE INTO [wwcp_pricing].[dbo].[ContractItem_temp] WITH (HOLDLOCK) AS target

    USING (
        SELECT
        price_cat.Cost,
        master_cat.Retail_Price,
        master_cat.Retail_Price * (1-@PriceRuleDiscount) as discounted_price, -- This Is Where The Discount Is Applied To price_cat.Price
        master_cat.Vendor_Name,
        master_cat.Vendor_Part_Number,
        master_cat.Vendor_Part_Number_Stripped,
        master_cat.Description,
        master_cat.ImageURL,
        master_cat.Weight,
        master_cat.EtilizeProductID,
        master_cat.EtilizeParentCatID,
        master_cat.EtilizeCatID,
        master_cat.ProductName,
        master_cat.Dist_ID,
        master_cat.Dist_Part_Number
        FROM [wwcp_pricing].[dbo].[PriceCatalog_temp] as price_cat
        JOIN [catservices].[dbo].[MasterCatalog] as master_cat
        ON price_cat.Dist_ID = master_cat.Dist_ID AND price_cat.Dist_Part_Number = master_cat.Dist_Part_Number
    ) AS source
    ON (target.Dist_ID = source.Dist_ID) -- Match ContractItem Records Using DIST_ID
    AND (target.Dist_PartNumber = source.Dist_Part_Number) -- AND DIST_PARTNUMBER
    AND (target.ContractID = @DestinationContractId) -- AND THE CONTRACT ID

    -- Update Existing Rows
    WHEN MATCHED THEN
        UPDATE SET
            target.Price = source.discounted_price, -- References Discounted/Calculated Price
            target.GSAPrice = source.discounted_price, -- References Discounted/Calculated Price
            target.ContractID = @DestinationContractId, -- References @DestinationContractId
            target.Vendor = source.Vendor_Name,
            target.VendorPartNumber = source.Vendor_Part_Number,
            target.VendorPartNumberStripped = source.Vendor_Part_Number_Stripped,
            target.Description = source.Description,
            target.Cost = source.Cost, -- TODO Review Cost Field
            target.Notes = + 'Updated by the Westwind Price Engine', -- Added note that it was created by the price engine
            target.CLIN = NULL,
            target.ContractNumber = @ContractNumber, -- References @ContractNumber
            target.StartDate = @ContractStartDate,
            target.EndDate = @ContractEndDate,
            target.ImageUrl = source.ImageURL,
            target.Weight = source.Weight,
            target.Retail_Price = source.Retail_Price, -- References Discounted/Calculated Price
            target.Show_On_Storesite = 1, -- True
            target.EtilizeProductID = source.EtilizeProductID,
            target.ParentCategoryID = source.EtilizeParentCatID,
            target.CategoryID = source.EtilizeCatID,
            target.ProductName = source.ProductName,
            target.Dist_ID = source.Dist_ID,
            target.Dist_PartNumber = source.Dist_Part_Number,
            target.Status = 0, -- Status hardcoded to 0
            target.GroupID = NULL,
            target.IsBundle = 0, -- False
            target.Unit = NULL,
            target.Discount = 0,
            target.Retail_PriceAutoCalculate = 0,
            target.Taxable = 1, -- True
            target.GSAPrice_AutoCalculate = 0

    -- Insert New Rows
    WHEN NOT MATCHED BY TARGET THEN
        INSERT (
                GSAPrice,
                Price,
                ContractID,
                Vendor,
                VendorPartNumber,
                VendorPartNumberStripped,
                Description,
                Cost, -- TODO: Confirm Cost Field
                Notes,
                CLIN,
                ContractNumber,
                StartDate,
                DateCreated,
                EndDate,
                ImageUrl,
                Weight,
                Retail_Price,
                Show_On_Storesite,
                EtilizeProductID,
                ParentCategoryID,
                CategoryID,
                ProductName,
                Dist_ID,
                Dist_PartNumber,
                Status,
                GroupID,
                IsBundle,
                Unit,
                Discount,
                Retail_PriceAutoCalculate,
                Taxable,
                GSAPrice_AutoCalculate
            )
        VALUES (
                source.discounted_price,
                source.discounted_price,
                @DestinationContractId,
                source.Vendor_Name,
                source.Vendor_Part_Number,
                source.Vendor_Part_Number_Stripped,
                source.Description,
                source.Cost, -- TODO: Confirm Cost Field
                NULL,
                NULL,
                @ContractNumber,
                @ContractStartDate,
                @ContractStartDate, -- Created Date
                @ContractEndDate,
                source.ImageURL,
                source.Weight,
                source.Retail_Price,
                1,
                source.EtilizeProductID,
                source.EtilizeParentCatID,
                source.EtilizeCatID,
                source.ProductName,
                source.Dist_ID,
                source.Dist_Part_Number,
                0, -- Status is 0
                NULL,
                0,
                NULL,
                0,
                0,
                1,
                0
                );

END TRY
BEGIN CATCH
    PRINT 'There was an error conducting the MERGE Statement for ' + @PriceRuleName + '. No ContractItems created.';
END CATCH


/**
  END PRICE RULE ONE
**/


/**
*
* MERGE ContractItem_temp into ContractItem
*
*/
BEGIN TRY
    SET @PriceRuleDiscount = ''; -- Set Discount Percentage Here
    SET @PriceRuleName = '';


    INSERT INTO [192.168.80.162].[wwcp].[dbo].[ContractItem] (GSAPrice,
            Price,
            ContractID,
            Vendor,
            VendorPartNumber,
            VendorPartNumberStripped,
            Description,
            Cost, -- TODO: Confirm Cost Field
            Notes,
            CLIN,
            ContractNumber,
            StartDate,
            DateCreated,
            EndDate,
            ImageUrl,
            Weight,
            Retail_Price,
            Show_On_Storesite,
            EtilizeProductID,
            ParentCategoryID,
            CategoryID,
            ProductName,
            Dist_ID,
            Dist_PartNumber,
            Status,
            GroupID,
            IsBundle,
            Unit,
            Discount,
            Retail_PriceAutoCalculate,
            Taxable,
            GSAPrice_AutoCalculate)
    SELECT  GSAPrice,
            Price,
            @DestinationContractId,
            Vendor,
            VendorPartNumber,
            VendorPartNumberStripped,
            Description,
            Cost, -- TODO: Confirm Cost Field
            Notes,
            CLIN,
            @ContractNumber,
            StartDate,
            DateCreated, -- Created Date
            EndDate,
            ImageURL,
            Weight,
            Retail_Price,
            Show_On_Storesite,
            EtilizeProductID,
            ParentCategoryID,
            CategoryID,
            ProductName,
            Dist_ID,
            Dist_PartNumber,
            Status, -- Status is 0
            GroupID,
            IsBundle,
            Unit,
            Discount,
            Retail_PriceAutoCalculate,
            Taxable,
            GSAPrice_AutoCalculate
    FROM [wwcp_pricing].[dbo].[ContractItem_temp]
    WHERE ContractID = @DestinationContractId

END TRY
BEGIN CATCH
    PRINT 'There was an error conducting the MERGE Statement from ContractItem_temp to ContractItems. No ContractItems created.';
END CATCH
