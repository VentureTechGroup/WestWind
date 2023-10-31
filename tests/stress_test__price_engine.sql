/**
*
* RELEASE: Price Engine Stress Test
*
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
        price_cat.Price,
        price_cat.Price * (1-@PriceRuleDiscount) as discounted_price, -- This Is Where The Discount Is Applied To price_cat.Price
        master_cat.*
        FROM [wwcp_pricing].[dbo].[PriceCatalog_temp] as price_cat
        JOIN [WWProjectCatalog].[dbo].[MasterCatalog] as master_cat
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
            -- target.Cost = source.Cost, -- TODO Review Cost Field
            target.Notes = + 'Updated by the Westwind Price Engine', -- Added note that it was created by the price engine
            target.CLIN = NULL,
            target.ContractNumber = @ContractNumber, -- References @ContractNumber
            target.StartDate = @ContractStartDate,
            target.EndDate = @ContractEndDate,
            target.ImageUrl = source.ImageURL,
            target.Weight = source.Weight,
            target.Retail_Price = source.discounted_price, -- References Discounted/Calculated Price
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
        INSERT (RecordID,
                GSAPrice,
                Price,
                ContractID,
                Vendor,
                VendorPartNumber,
                VendorPartNumberStripped,
                Description,
    --             Cost, -- TODO: Confirm Cost Field
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
                source.RecordID,
                source.discounted_price,
                source.discounted_price,
                @DestinationContractId,
                source.Vendor_Name,
                source.Vendor_Part_Number,
                source.Vendor_Part_Number_Stripped,
                source.Description,
    --             source.Cost, -- TODO: Confirm Cost Field
                NULL,
                NULL,
                @ContractNumber,
                @ContractStartDate,
                @ContractStartDate, -- Created Date
                @ContractEndDate,
                source.ImageURL,
                source.Weight,
                source.discounted_price,
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

    /** PRICE ENGINE MERGE **/
    MERGE INTO [wwcp].[dbo].[ContractItem] WITH (HOLDLOCK) AS target

    USING (
        SELECT
        *
        FROM [wwcp_pricing].[dbo].[ContractItem_temp]
        WHERE ContractID = @DestinationContractId
    ) AS source
    ON (target.Dist_ID = source.Dist_ID) -- Match ContractItem Records Using DIST_ID
    AND (target.Dist_PartNumber = source.Dist_PartNumber) -- AND DIST_PARTNUMBER
    AND (target.ContractID = @DestinationContractId) -- AND THE CONTRACT ID

    -- Update Existing Rows
    WHEN MATCHED THEN
        UPDATE SET
            target.Price = source.Price, -- References Discounted/Calculated Price
            target.GSAPrice = source.GSAPrice, -- References Discounted/Calculated Price
            target.ContractID = @DestinationContractId, -- References @DestinationContractId
            target.Vendor = source.Vendor,
            target.VendorPartNumber = source.VendorPartNumber,
            target.VendorPartNumberStripped = source.VendorPartNumberStripped,
            target.Description = source.Description,
            -- target.Cost = source.Cost, -- TODO Review Cost Field
            target.Notes = + source.Notes,
            target.CLIN = source.CLIN,
            target.ContractNumber = source.ContractNumber, -- References @ContractNumber
            target.StartDate = source.StartDate,
            target.EndDate = source.EndDate,
            target.ImageUrl = source.ImageURL,
            target.Weight = source.Weight,
            target.Retail_Price = source.Retail_Price, -- References Discounted/Calculated Price
            target.Show_On_Storesite = source.Show_On_Storesite, -- True
            target.EtilizeProductID = source.EtilizeProductID,
            target.ParentCategoryID = source.ParentCategoryID,
            target.CategoryID = source.CategoryID,
            target.ProductName = source.ProductName,
            target.Dist_ID = source.Dist_ID,
            target.Dist_PartNumber = source.Dist_PartNumber,
            target.Status = source.Status,
            target.GroupID = source.GroupID,
            target.IsBundle = source.IsBundle,
            target.Unit = source.Unit,
            target.Discount = source.Discount,
            target.Retail_PriceAutoCalculate = source.Retail_PriceAutoCalculate,
            target.Taxable = source.Taxable,
            target.GSAPrice_AutoCalculate = source.GSAPrice_AutoCalculate

    -- Insert New Rows
    WHEN NOT MATCHED BY TARGET THEN
        INSERT (RecordID,
                GSAPrice,
                Price,
                ContractID,
                Vendor,
                VendorPartNumber,
                VendorPartNumberStripped,
                Description,
    --             Cost, -- TODO: Confirm Cost Field
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
                source.RecordID,
                source.GSAPrice,
                source.Price,
                @DestinationContractId,
                source.Vendor,
                source.VendorPartNumber,
                source.VendorPartNumberStripped,
                source.Description,
    --             source.Cost, -- TODO: Confirm Cost Field
                source.Notes,
                source.CLIN,
                @ContractNumber,
                source.StartDate,
                source.DateCreated, -- Created Date
                source.EndDate,
                source.ImageURL,
                source.Weight,
                source.Retail_Price,
                source.Show_On_Storesite,
                source.EtilizeProductID,
                source.ParentCategoryID,
                source.CategoryID,
                source.ProductName,
                source.Dist_ID,
                source.Dist_PartNumber,
                source.Status, -- Status is 0
                source.GroupID,
                source.IsBundle,
                source.Unit,
                source.Discount,
                source.Retail_PriceAutoCalculate,
                source.Taxable,
                source.GSAPrice_AutoCalculate
                );

END TRY
BEGIN CATCH
    PRINT 'There was an error conducting the MERGE Statement from ContractItem_temp to ContractItems. No ContractItems created.';
END CATCH
