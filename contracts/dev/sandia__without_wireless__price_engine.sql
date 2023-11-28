/**
*
* WESTWIND: Sandia Price Engine (EXCLUDING Wireless)
*
**/

/**
*
*   BEGIN PRICE ENGINE CONFIGURATION
*
**/
DECLARE @DestinationContractId AS INT;
SET @DestinationContractId = 60;

DECLARE @ContractNumber AS VARCHAR(100);
SET @ContractNumber = ''

DECLARE @ContractStartDate AS DATETIME;
SET @ContractStartDate = GETDATE();

DECLARE @ContractEndDate AS DATETIME;
SET @ContractEndDate = DATEADD(year, 1, GETDATE());


/** CLEAR TEMP TABLE **/
DELETE FROM [wwcp_pricing].[dbo].[ContractItem_temp];


/**
*
*   BEGIN PRICE ENGINE RULE SQL DEFINITIONS
*
**/


/** PRICE RULE ONE **/
BEGIN TRY
    DECLARE @PriceRuleDiscount AS FLOAT;
    SET @PriceRuleDiscount = '0.051'; -- Set Discount Percentage Here

    DECLARE @PriceRuleName AS VARCHAR(150);
    SET @PriceRuleName = 'HPE - SmartBUY - Entry Level Servers';

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
        WHERE (
            master_cat.etilizeCatId IN ('4873','5148','10154','10247','10282','11099','11748')
            OR master_cat.etilizeParentCatId IN ('4873','5148','10154','10247','10282','11099','11748')
        )
        AND master_cat.etilizeMfgId IN ('1063889','1063890','1063892','1063978','1043455','1046863','1046864','1054748','1054862')
        AND master_cat.search LIKE '% SBUY %'
        AND (
            master_cat.search NOT LIKE '%BLUETOOTH%'
            OR master_cat.search NOT LIKE '%WI-FI%'
            OR master_cat.search NOT LIKE '%WIFI%'
            OR master_cat.search NOT LIKE '%WIRELESS%'
            OR master_cat.search NOT LIKE '%LTE%'
            OR master_cat.search NOT LIKE '%REFURBISHED%'
            OR master_cat.search NOT LIKE '%IEEE 802.11%'
        )
        AND (
            master_cat.Description NOT LIKE '%BLUETOOTH%'
            OR master_cat.Description NOT LIKE '%WI-FI%'
            OR master_cat.Description NOT LIKE '%WIFI%'
            OR master_cat.Description NOT LIKE '%WIRELESS%'
            OR master_cat.Description NOT LIKE '%LTE%'
            OR master_cat.Description NOT LIKE '%REFURBISHED%'
            OR master_cat.Description NOT LIKE '%IEEE 802.11%'
        )
        AND (
            master_cat.ProductName NOT LIKE '%BLUETOOTH%'
            OR master_cat.ProductName NOT LIKE '%WI-FI%'
            OR master_cat.ProductName NOT LIKE '%WIFI%'
            OR master_cat.ProductName NOT LIKE '%WIRELESS%'
            OR master_cat.ProductName NOT LIKE '%LTE%'
            OR master_cat.ProductName NOT LIKE '%REFURBISHED%'
            OR master_cat.ProductName NOT LIKE '%IEEE 802.11%'
        )
        AND price_cat.Dist_ID = 20 -- Synnex
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
            target.CLIN = '',
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
                '',
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

/** PRICE RULE TWO **/
BEGIN TRY
--     DECLARE @PriceRuleDiscount AS FLOAT;
    SET @PriceRuleDiscount = '0.051'; -- Set Discount Percentage Here

--     DECLARE @PriceRuleName AS VARCHAR(150);
    SET @PriceRuleName = 'HPI - Level 2 - Non-CTO - Thin Client';

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
        WHERE (master_cat.etilizeCatId IN ('4830') OR master_cat.etilizeParentCatId IN ('4830')) AND master_cat.etilizeMfgId IN ('1063888','1063891','1063976','1063979','1042796','1043456','1046484') AND master_cat.search NOT LIKE '% SBUY %'
        AND (
            master_cat.search NOT LIKE '%BLUETOOTH%'
            OR master_cat.search NOT LIKE '%WI-FI%'
            OR master_cat.search NOT LIKE '%WIFI%'
            OR master_cat.search NOT LIKE '%WIRELESS%'
            OR master_cat.search NOT LIKE '%LTE%'
            OR master_cat.search NOT LIKE '%REFURBISHED%'
            OR master_cat.search NOT LIKE '%IEEE 802.11%'
        )
        AND (
            master_cat.Description NOT LIKE '%BLUETOOTH%'
            OR master_cat.Description NOT LIKE '%WI-FI%'
            OR master_cat.Description NOT LIKE '%WIFI%'
            OR master_cat.Description NOT LIKE '%WIRELESS%'
            OR master_cat.Description NOT LIKE '%LTE%'
            OR master_cat.Description NOT LIKE '%REFURBISHED%'
            OR master_cat.Description NOT LIKE '%IEEE 802.11%'
        )
        AND (
            master_cat.ProductName NOT LIKE '%BLUETOOTH%'
            OR master_cat.ProductName NOT LIKE '%WI-FI%'
            OR master_cat.ProductName NOT LIKE '%WIFI%'
            OR master_cat.ProductName NOT LIKE '%WIRELESS%'
            OR master_cat.ProductName NOT LIKE '%LTE%'
            OR master_cat.ProductName NOT LIKE '%REFURBISHED%'
            OR master_cat.ProductName NOT LIKE '%IEEE 802.11%'
        )
        AND price_cat.Dist_ID = 20 -- Synnex
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
            target.CLIN = '',
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
                '',
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
  END PRICE RULE TWO
**/


/** PRICE RULE THREE **/
BEGIN TRY
--     DECLARE @PriceRuleDiscount AS FLOAT;
    SET @PriceRuleDiscount = '0.295'; -- Set Discount Percentage Here

--     DECLARE @PriceRuleName AS VARCHAR(150);
    SET @PriceRuleName = 'HPI - Level 2 - CTO - Tablet';

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
        WHERE (master_cat.etilizeCatId IN ('10025') OR master_cat.etilizeParentCatId IN ('10025')) AND master_cat.etilizeMfgId IN ('1063888','1063891','1063976','1063979','1042796','1043456','1046484') AND master_cat.search NOT LIKE '% SBUY %' AND (
            master_cat.search NOT LIKE '%BLUETOOTH%'
            OR master_cat.search NOT LIKE '%WI-FI%'
            OR master_cat.search NOT LIKE '%WIFI%'
            OR master_cat.search NOT LIKE '%WIRELESS%'
            OR master_cat.search NOT LIKE '%LTE%'
            OR master_cat.search NOT LIKE '%REFURBISHED%'
            OR master_cat.search NOT LIKE '%IEEE 802.11%'
        )
        AND (
            master_cat.Description NOT LIKE '%BLUETOOTH%'
            OR master_cat.Description NOT LIKE '%WI-FI%'
            OR master_cat.Description NOT LIKE '%WIFI%'
            OR master_cat.Description NOT LIKE '%WIRELESS%'
            OR master_cat.Description NOT LIKE '%LTE%'
            OR master_cat.Description NOT LIKE '%REFURBISHED%'
            OR master_cat.Description NOT LIKE '%IEEE 802.11%'
        )
        AND (
            master_cat.ProductName NOT LIKE '%BLUETOOTH%'
            OR master_cat.ProductName NOT LIKE '%WI-FI%'
            OR master_cat.ProductName NOT LIKE '%WIFI%'
            OR master_cat.ProductName NOT LIKE '%WIRELESS%'
            OR master_cat.ProductName NOT LIKE '%LTE%'
            OR master_cat.ProductName NOT LIKE '%REFURBISHED%'
            OR master_cat.ProductName NOT LIKE '%IEEE 802.11%'
        )
        AND price_cat.Dist_ID = 20 -- Synnex
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
            target.CLIN = '',
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
                '',
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
  END PRICE RULE THREE
**/

/** PRICE RULE FOUR **/
BEGIN TRY
--     DECLARE @PriceRuleDiscount AS FLOAT;
    SET @PriceRuleDiscount = '0.1152'; -- Set Discount Percentage Here

--     DECLARE @PriceRuleName AS VARCHAR(150);
    SET @PriceRuleName = 'HPI - Level 2 - Non-CTO - Tablet';

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
        WHERE (master_cat.etilizeCatId IN ('10025') OR master_cat.etilizeParentCatId IN ('10025')) AND master_cat.etilizeMfgId IN ('1063888','1063891','1063976','1063979','1042796','1043456','1046484') AND master_cat.search LIKE '% SBUY %'
        AND (
            master_cat.search NOT LIKE '%BLUETOOTH%'
            OR master_cat.search NOT LIKE '%WI-FI%'
            OR master_cat.search NOT LIKE '%WIFI%'
            OR master_cat.search NOT LIKE '%WIRELESS%'
            OR master_cat.search NOT LIKE '%LTE%'
            OR master_cat.search NOT LIKE '%REFURBISHED%'
            OR master_cat.search NOT LIKE '%IEEE 802.11%'
        )
        AND (
            master_cat.Description NOT LIKE '%BLUETOOTH%'
            OR master_cat.Description NOT LIKE '%WI-FI%'
            OR master_cat.Description NOT LIKE '%WIFI%'
            OR master_cat.Description NOT LIKE '%WIRELESS%'
            OR master_cat.Description NOT LIKE '%LTE%'
            OR master_cat.Description NOT LIKE '%REFURBISHED%'
            OR master_cat.Description NOT LIKE '%IEEE 802.11%'
        )
        AND (
            master_cat.ProductName NOT LIKE '%BLUETOOTH%'
            OR master_cat.ProductName NOT LIKE '%WI-FI%'
            OR master_cat.ProductName NOT LIKE '%WIFI%'
            OR master_cat.ProductName NOT LIKE '%WIRELESS%'
            OR master_cat.ProductName NOT LIKE '%LTE%'
            OR master_cat.ProductName NOT LIKE '%REFURBISHED%'
            OR master_cat.ProductName NOT LIKE '%IEEE 802.11%'
        )
        AND price_cat.Dist_ID = 20 -- Synnex
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
            target.CLIN = '',
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
                '',
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
  END PRICE RULE FOUR
**/


/** PRICE RULE FIVE **/
BEGIN TRY
--     DECLARE @PriceRuleDiscount AS FLOAT;
    SET @PriceRuleDiscount = '0.34'; -- Set Discount Percentage Here

--     DECLARE @PriceRuleName AS VARCHAR(150);
    SET @PriceRuleName = 'HPI - Level 2 - CTO - Laptop';

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
        WHERE (master_cat.etilizeCatId  IN ('4876','10285','11925','4830') OR master_cat.etilizeParentCatId  IN ('4876','10285','11925','4830')) AND master_cat.etilizeMfgId IN ('1063888','1063891','1063976','1063979','1042796','1043456','1046484') AND master_cat.search NOT LIKE '% SBUY %'
        AND (
            master_cat.search NOT LIKE '%BLUETOOTH%'
            OR master_cat.search NOT LIKE '%WI-FI%'
            OR master_cat.search NOT LIKE '%WIFI%'
            OR master_cat.search NOT LIKE '%WIRELESS%'
            OR master_cat.search NOT LIKE '%LTE%'
            OR master_cat.search NOT LIKE '%REFURBISHED%'
            OR master_cat.search NOT LIKE '%IEEE 802.11%'
        )
        AND (
            master_cat.Description NOT LIKE '%BLUETOOTH%'
            OR master_cat.Description NOT LIKE '%WI-FI%'
            OR master_cat.Description NOT LIKE '%WIFI%'
            OR master_cat.Description NOT LIKE '%WIRELESS%'
            OR master_cat.Description NOT LIKE '%LTE%'
            OR master_cat.Description NOT LIKE '%REFURBISHED%'
            OR master_cat.Description NOT LIKE '%IEEE 802.11%'
        )
        AND (
            master_cat.ProductName NOT LIKE '%BLUETOOTH%'
            OR master_cat.ProductName NOT LIKE '%WI-FI%'
            OR master_cat.ProductName NOT LIKE '%WIFI%'
            OR master_cat.ProductName NOT LIKE '%WIRELESS%'
            OR master_cat.ProductName NOT LIKE '%LTE%'
            OR master_cat.ProductName NOT LIKE '%REFURBISHED%'
            OR master_cat.ProductName NOT LIKE '%IEEE 802.11%'
        )
        AND price_cat.Dist_ID = 20 -- Synnex
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
            target.CLIN = '',
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
                '',
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
  END PRICE RULE FIVE
**/

/** PRICE RULE SIX **/
BEGIN TRY
--     DECLARE @PriceRuleDiscount AS FLOAT;
    SET @PriceRuleDiscount = '0.0877'; -- Set Discount Percentage Here

--     DECLARE @PriceRuleName AS VARCHAR(150);
    SET @PriceRuleName = 'HPI - Level 2 - Non-CTO - Laptop';

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
        WHERE (master_cat.etilizeCatId IN ('4876','10285','11925','4830') OR master_cat.etilizeParentCatId IN ('4876','10285','11925','4830')) AND master_cat.etilizeMfgId IN ('1063888','1063891','1063976','1063979','1042796','1043456','1046484') AND master_cat.search LIKE '% SBUY %'
        AND (
            master_cat.search NOT LIKE '%BLUETOOTH%'
            OR master_cat.search NOT LIKE '%WI-FI%'
            OR master_cat.search NOT LIKE '%WIFI%'
            OR master_cat.search NOT LIKE '%WIRELESS%'
            OR master_cat.search NOT LIKE '%LTE%'
            OR master_cat.search NOT LIKE '%REFURBISHED%'
            OR master_cat.search NOT LIKE '%IEEE 802.11%'
        )
        AND (
            master_cat.Description NOT LIKE '%BLUETOOTH%'
            OR master_cat.Description NOT LIKE '%WI-FI%'
            OR master_cat.Description NOT LIKE '%WIFI%'
            OR master_cat.Description NOT LIKE '%WIRELESS%'
            OR master_cat.Description NOT LIKE '%LTE%'
            OR master_cat.Description NOT LIKE '%REFURBISHED%'
            OR master_cat.Description NOT LIKE '%IEEE 802.11%'
        )
        AND (
            master_cat.ProductName NOT LIKE '%BLUETOOTH%'
            OR master_cat.ProductName NOT LIKE '%WI-FI%'
            OR master_cat.ProductName NOT LIKE '%WIFI%'
            OR master_cat.ProductName NOT LIKE '%WIRELESS%'
            OR master_cat.ProductName NOT LIKE '%LTE%'
            OR master_cat.ProductName NOT LIKE '%REFURBISHED%'
            OR master_cat.ProductName NOT LIKE '%IEEE 802.11%'
        )
        AND price_cat.Dist_ID = 20 -- Synnex
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
            target.CLIN = '',
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
                '',
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
  END PRICE RULE SIX
**/


/** PRICE RULE SEVEN **/
BEGIN TRY
--     DECLARE @PriceRuleDiscount AS FLOAT;
    SET @PriceRuleDiscount = '0.29'; -- Set Discount Percentage Here

--     DECLARE @PriceRuleName AS VARCHAR(150);
    SET @PriceRuleName = 'HPI - Level 2 - CTO - Desktop';

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
        WHERE (master_cat.etilizeCatId IN ('4871') OR master_cat.etilizeParentCatId IN ('4871')) AND master_cat.etilizeMfgId IN ('1063888','1063891','1063976','1063979','1042796','1043456','1046484') AND master_cat.search NOT LIKE '% SBUY %'
        AND (
            master_cat.search NOT LIKE '%BLUETOOTH%'
            OR master_cat.search NOT LIKE '%WI-FI%'
            OR master_cat.search NOT LIKE '%WIFI%'
            OR master_cat.search NOT LIKE '%WIRELESS%'
            OR master_cat.search NOT LIKE '%LTE%'
            OR master_cat.search NOT LIKE '%REFURBISHED%'
            OR master_cat.search NOT LIKE '%IEEE 802.11%'
        )
        AND (
            master_cat.Description NOT LIKE '%BLUETOOTH%'
            OR master_cat.Description NOT LIKE '%WI-FI%'
            OR master_cat.Description NOT LIKE '%WIFI%'
            OR master_cat.Description NOT LIKE '%WIRELESS%'
            OR master_cat.Description NOT LIKE '%LTE%'
            OR master_cat.Description NOT LIKE '%REFURBISHED%'
            OR master_cat.Description NOT LIKE '%IEEE 802.11%'
        )
        AND (
            master_cat.ProductName NOT LIKE '%BLUETOOTH%'
            OR master_cat.ProductName NOT LIKE '%WI-FI%'
            OR master_cat.ProductName NOT LIKE '%WIFI%'
            OR master_cat.ProductName NOT LIKE '%WIRELESS%'
            OR master_cat.ProductName NOT LIKE '%LTE%'
            OR master_cat.ProductName NOT LIKE '%REFURBISHED%'
            OR master_cat.ProductName NOT LIKE '%IEEE 802.11%'
        )
        AND price_cat.Dist_ID = 20 -- Synnex
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
            target.CLIN = '',
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
                '',
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
  END PRICE RULE SEVEN
**/


/** PRICE RULE EIGHT **/
BEGIN TRY
--     DECLARE @PriceRuleDiscount AS FLOAT;
    SET @PriceRuleDiscount = '0.095'; -- Set Discount Percentage Here

--     DECLARE @PriceRuleName AS VARCHAR(150);
    SET @PriceRuleName = 'HPI - Level 2 - Non-CTO - Desktop';

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
        WHERE (master_cat.etilizeCatId IN ('4871') OR master_cat.etilizeParentCatId IN ('4871')) AND master_cat.etilizeMfgId IN ('1063888','1063891','1063976','1063979','1042796','1043456','1046484') AND master_cat.search LIKE '% SBUY %'
        AND (
            master_cat.search NOT LIKE '%BLUETOOTH%'
            OR master_cat.search NOT LIKE '%WI-FI%'
            OR master_cat.search NOT LIKE '%WIFI%'
            OR master_cat.search NOT LIKE '%WIRELESS%'
            OR master_cat.search NOT LIKE '%LTE%'
            OR master_cat.search NOT LIKE '%REFURBISHED%'
            OR master_cat.search NOT LIKE '%IEEE 802.11%'
        )
        AND (
            master_cat.Description NOT LIKE '%BLUETOOTH%'
            OR master_cat.Description NOT LIKE '%WI-FI%'
            OR master_cat.Description NOT LIKE '%WIFI%'
            OR master_cat.Description NOT LIKE '%WIRELESS%'
            OR master_cat.Description NOT LIKE '%LTE%'
            OR master_cat.Description NOT LIKE '%REFURBISHED%'
            OR master_cat.Description NOT LIKE '%IEEE 802.11%'
        )
        AND (
            master_cat.ProductName NOT LIKE '%BLUETOOTH%'
            OR master_cat.ProductName NOT LIKE '%WI-FI%'
            OR master_cat.ProductName NOT LIKE '%WIFI%'
            OR master_cat.ProductName NOT LIKE '%WIRELESS%'
            OR master_cat.ProductName NOT LIKE '%LTE%'
            OR master_cat.ProductName NOT LIKE '%REFURBISHED%'
            OR master_cat.ProductName NOT LIKE '%IEEE 802.11%'
        )
        AND price_cat.Dist_ID = 20 -- Synnex
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
            target.CLIN = '',
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
                '',
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
  END PRICE RULE EIGHT
**/


/** PRICE RULE NINE **/
BEGIN TRY
--     DECLARE @PriceRuleDiscount AS FLOAT;
    SET @PriceRuleDiscount = '0.34'; -- Set Discount Percentage Here

--     DECLARE @PriceRuleName AS VARCHAR(150);
    SET @PriceRuleName = 'HPI - Level 2 - Workstation';

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
        WHERE (master_cat.etilizeCatId IN ('4872') OR master_cat.etilizeParentCatId IN ('4872')) AND master_cat.etilizeMfgId IN ('1063888','1063891','1063976','1063979','1042796','1043456','1046484') AND master_cat.search NOT LIKE '% SBUY %'
        AND (
            master_cat.search NOT LIKE '%BLUETOOTH%'
            OR master_cat.search NOT LIKE '%WI-FI%'
            OR master_cat.search NOT LIKE '%WIFI%'
            OR master_cat.search NOT LIKE '%WIRELESS%'
            OR master_cat.search NOT LIKE '%LTE%'
            OR master_cat.search NOT LIKE '%REFURBISHED%'
            OR master_cat.search NOT LIKE '%IEEE 802.11%'
        )
        AND (
            master_cat.Description NOT LIKE '%BLUETOOTH%'
            OR master_cat.Description NOT LIKE '%WI-FI%'
            OR master_cat.Description NOT LIKE '%WIFI%'
            OR master_cat.Description NOT LIKE '%WIRELESS%'
            OR master_cat.Description NOT LIKE '%LTE%'
            OR master_cat.Description NOT LIKE '%REFURBISHED%'
            OR master_cat.Description NOT LIKE '%IEEE 802.11%'
        )
        AND (
            master_cat.ProductName NOT LIKE '%BLUETOOTH%'
            OR master_cat.ProductName NOT LIKE '%WI-FI%'
            OR master_cat.ProductName NOT LIKE '%WIFI%'
            OR master_cat.ProductName NOT LIKE '%WIRELESS%'
            OR master_cat.ProductName NOT LIKE '%LTE%'
            OR master_cat.ProductName NOT LIKE '%REFURBISHED%'
            OR master_cat.ProductName NOT LIKE '%IEEE 802.11%'
        )
        AND price_cat.Dist_ID = 20 -- Synnex
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
            target.CLIN = '',
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
                '',
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
  END PRICE RULE NINE
**/


/** PRICE RULE TEN **/
BEGIN TRY
--     DECLARE @PriceRuleDiscount AS FLOAT;
    SET @PriceRuleDiscount = '0.1243'; -- Set Discount Percentage Here

--     DECLARE @PriceRuleName AS VARCHAR(150);
    SET @PriceRuleName = 'HPI - Level 2 - Non-CTO - Workstation';

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
        WHERE (master_cat.etilizeCatId IN ('4872') OR master_cat.etilizeParentCatId IN ('4872')) AND master_cat.etilizeMfgId IN ('1063888','1063891','1063976','1063979','1042796','1043456','1046484') AND master_cat.search LIKE '% SBUY %'
        AND (
            master_cat.search NOT LIKE '%BLUETOOTH%'
            OR master_cat.search NOT LIKE '%WI-FI%'
            OR master_cat.search NOT LIKE '%WIFI%'
            OR master_cat.search NOT LIKE '%WIRELESS%'
            OR master_cat.search NOT LIKE '%LTE%'
            OR master_cat.search NOT LIKE '%REFURBISHED%'
            OR master_cat.search NOT LIKE '%IEEE 802.11%'
        )
        AND (
            master_cat.Description NOT LIKE '%BLUETOOTH%'
            OR master_cat.Description NOT LIKE '%WI-FI%'
            OR master_cat.Description NOT LIKE '%WIFI%'
            OR master_cat.Description NOT LIKE '%WIRELESS%'
            OR master_cat.Description NOT LIKE '%LTE%'
            OR master_cat.Description NOT LIKE '%REFURBISHED%'
            OR master_cat.Description NOT LIKE '%IEEE 802.11%'
        )
        AND (
            master_cat.ProductName NOT LIKE '%BLUETOOTH%'
            OR master_cat.ProductName NOT LIKE '%WI-FI%'
            OR master_cat.ProductName NOT LIKE '%WIFI%'
            OR master_cat.ProductName NOT LIKE '%WIRELESS%'
            OR master_cat.ProductName NOT LIKE '%LTE%'
            OR master_cat.ProductName NOT LIKE '%REFURBISHED%'
            OR master_cat.ProductName NOT LIKE '%IEEE 802.11%'
        )
        AND price_cat.Dist_ID = 20 -- Synnex
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
            target.CLIN = '',
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
                '',
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
  END PRICE RULE TEN
**/

/** PRICE RULE TEN **/
BEGIN TRY
--     DECLARE @PriceRuleDiscount AS FLOAT;
    SET @PriceRuleDiscount = '0.0715'; -- Set Discount Percentage Here

--     DECLARE @PriceRuleName AS VARCHAR(150);
    SET @PriceRuleName = 'HPI - Level 2 - Non-CTO - MONITORS';

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
        WHERE (master_cat.etilizeCatId IN ('4831','10165') OR master_cat.etilizeParentCatId IN ('4831','10165')) AND master_cat.etilizeMfgId IN ('1063888','1063891','1063976','1063979','1042796','1043456','1046484') AND master_cat.search NOT LIKE '% SBUY %'
        AND (
            master_cat.search NOT LIKE '%BLUETOOTH%'
            OR master_cat.search NOT LIKE '%WI-FI%'
            OR master_cat.search NOT LIKE '%WIFI%'
            OR master_cat.search NOT LIKE '%WIRELESS%'
            OR master_cat.search NOT LIKE '%LTE%'
            OR master_cat.search NOT LIKE '%REFURBISHED%'
            OR master_cat.search NOT LIKE '%IEEE 802.11%'
        )
        AND (
            master_cat.Description NOT LIKE '%BLUETOOTH%'
            OR master_cat.Description NOT LIKE '%WI-FI%'
            OR master_cat.Description NOT LIKE '%WIFI%'
            OR master_cat.Description NOT LIKE '%WIRELESS%'
            OR master_cat.Description NOT LIKE '%LTE%'
            OR master_cat.Description NOT LIKE '%REFURBISHED%'
            OR master_cat.Description NOT LIKE '%IEEE 802.11%'
        )
        AND (
            master_cat.ProductName NOT LIKE '%BLUETOOTH%'
            OR master_cat.ProductName NOT LIKE '%WI-FI%'
            OR master_cat.ProductName NOT LIKE '%WIFI%'
            OR master_cat.ProductName NOT LIKE '%WIRELESS%'
            OR master_cat.ProductName NOT LIKE '%LTE%'
            OR master_cat.ProductName NOT LIKE '%REFURBISHED%'
            OR master_cat.ProductName NOT LIKE '%IEEE 802.11%'
        )
        AND price_cat.Dist_ID = 20 -- Synnex
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
            target.CLIN = '',
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
                '',
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
  END PRICE RULE TEN
**/

    /** PRICE RULE TEN **/
BEGIN TRY
--     DECLARE @PriceRuleDiscount AS FLOAT;
    SET @PriceRuleDiscount = '0.23'; -- Set Discount Percentage Here

--     DECLARE @PriceRuleName AS VARCHAR(150);
    SET @PriceRuleName = 'HPI - Level 2 - Non-CTO - PRINTERS';

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
        WHERE (master_cat.etilizeCatId IN ('4805','4807','4810','4816','4820','4821','4822','10153','10294','10914','11655') OR master_cat.etilizeParentCatId IN ('4805','4807','4810','4816','4820','4821','4822','10153','10294','10914','11655')) AND master_cat.etilizeMfgId IN ('1063888','1063891','1063976','1063979','1042796','1043456','1046484') AND master_cat.search NOT LIKE '% SBUY %'
        AND (
            master_cat.search NOT LIKE '%BLUETOOTH%'
            OR master_cat.search NOT LIKE '%WI-FI%'
            OR master_cat.search NOT LIKE '%WIFI%'
            OR master_cat.search NOT LIKE '%WIRELESS%'
            OR master_cat.search NOT LIKE '%LTE%'
            OR master_cat.search NOT LIKE '%REFURBISHED%'
            OR master_cat.search NOT LIKE '%IEEE 802.11%'
        )
        AND (
            master_cat.Description NOT LIKE '%BLUETOOTH%'
            OR master_cat.Description NOT LIKE '%WI-FI%'
            OR master_cat.Description NOT LIKE '%WIFI%'
            OR master_cat.Description NOT LIKE '%WIRELESS%'
            OR master_cat.Description NOT LIKE '%LTE%'
            OR master_cat.Description NOT LIKE '%REFURBISHED%'
            OR master_cat.Description NOT LIKE '%IEEE 802.11%'
        )
        AND (
            master_cat.ProductName NOT LIKE '%BLUETOOTH%'
            OR master_cat.ProductName NOT LIKE '%WI-FI%'
            OR master_cat.ProductName NOT LIKE '%WIFI%'
            OR master_cat.ProductName NOT LIKE '%WIRELESS%'
            OR master_cat.ProductName NOT LIKE '%LTE%'
            OR master_cat.ProductName NOT LIKE '%REFURBISHED%'
            OR master_cat.ProductName NOT LIKE '%IEEE 802.11%'
        )
        AND price_cat.Dist_ID = 20 -- Synnex
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
            target.CLIN = '',
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
                '',
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
  END PRICE RULE TEN
**/

    /** PRICE RULE TEN **/
BEGIN TRY
--     DECLARE @PriceRuleDiscount AS FLOAT;
    SET @PriceRuleDiscount = '0.38'; -- Set Discount Percentage Here

--     DECLARE @PriceRuleName AS VARCHAR(150);
    SET @PriceRuleName = 'HPE - CTO - Networking Solution';

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
        WHERE (master_cat.etilizeCatId IN ('4813','4823','10040','10251','10291','10931','11099','11158','11164','11748','11752') OR master_cat.etilizeParentCatId IN ('4813','4823','10040','10251','10291','10931','11099','11158','11164','11748','11752')) AND master_cat.etilizeMfgId IN ('1063889','1063890','1063892','1063978','1043455','1046863','1046864','1054748','1054862') AND master_cat.search NOT LIKE '% SBUY %'
        AND (
            master_cat.search NOT LIKE '%BLUETOOTH%'
            OR master_cat.search NOT LIKE '%WI-FI%'
            OR master_cat.search NOT LIKE '%WIFI%'
            OR master_cat.search NOT LIKE '%WIRELESS%'
            OR master_cat.search NOT LIKE '%LTE%'
            OR master_cat.search NOT LIKE '%REFURBISHED%'
            OR master_cat.search NOT LIKE '%IEEE 802.11%'
        )
        AND (
            master_cat.Description NOT LIKE '%BLUETOOTH%'
            OR master_cat.Description NOT LIKE '%WI-FI%'
            OR master_cat.Description NOT LIKE '%WIFI%'
            OR master_cat.Description NOT LIKE '%WIRELESS%'
            OR master_cat.Description NOT LIKE '%LTE%'
            OR master_cat.Description NOT LIKE '%REFURBISHED%'
            OR master_cat.Description NOT LIKE '%IEEE 802.11%'
        )
        AND (
            master_cat.ProductName NOT LIKE '%BLUETOOTH%'
            OR master_cat.ProductName NOT LIKE '%WI-FI%'
            OR master_cat.ProductName NOT LIKE '%WIFI%'
            OR master_cat.ProductName NOT LIKE '%WIRELESS%'
            OR master_cat.ProductName NOT LIKE '%LTE%'
            OR master_cat.ProductName NOT LIKE '%REFURBISHED%'
            OR master_cat.ProductName NOT LIKE '%IEEE 802.11%'
        )
        AND price_cat.Dist_ID = 20 -- Synnex
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
            target.CLIN = '',
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
                '',
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
  END PRICE RULE TEN
**/

    /** PRICE RULE TEN **/
BEGIN TRY
--     DECLARE @PriceRuleDiscount AS FLOAT;
    SET @PriceRuleDiscount = '0.325'; -- Set Discount Percentage Here

--     DECLARE @PriceRuleName AS VARCHAR(150);
    SET @PriceRuleName = 'HPE - Non-CTO - Networking Solution';

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
        WHERE (master_cat.etilizeCatId IN ('4813','4823','10040','10251','10291','10931','11099','11158','11164','11748','11752') OR master_cat.etilizeParentCatId IN ('4813','4823','10040','10251','10291','10931','11099','11158','11164','11748','11752')) AND master_cat.etilizeMfgId IN ('1063889','1063890','1063892','1063978','1043455','1046863','1046864','1054748','1054862') AND master_cat.search LIKE '% SBUY %'
        AND (
            master_cat.search NOT LIKE '%BLUETOOTH%'
            OR master_cat.search NOT LIKE '%WI-FI%'
            OR master_cat.search NOT LIKE '%WIFI%'
            OR master_cat.search NOT LIKE '%WIRELESS%'
            OR master_cat.search NOT LIKE '%LTE%'
            OR master_cat.search NOT LIKE '%REFURBISHED%'
            OR master_cat.search NOT LIKE '%IEEE 802.11%'
        )
        AND (
            master_cat.Description NOT LIKE '%BLUETOOTH%'
            OR master_cat.Description NOT LIKE '%WI-FI%'
            OR master_cat.Description NOT LIKE '%WIFI%'
            OR master_cat.Description NOT LIKE '%WIRELESS%'
            OR master_cat.Description NOT LIKE '%LTE%'
            OR master_cat.Description NOT LIKE '%REFURBISHED%'
            OR master_cat.Description NOT LIKE '%IEEE 802.11%'
        )
        AND (
            master_cat.ProductName NOT LIKE '%BLUETOOTH%'
            OR master_cat.ProductName NOT LIKE '%WI-FI%'
            OR master_cat.ProductName NOT LIKE '%WIFI%'
            OR master_cat.ProductName NOT LIKE '%WIRELESS%'
            OR master_cat.ProductName NOT LIKE '%LTE%'
            OR master_cat.ProductName NOT LIKE '%REFURBISHED%'
            OR master_cat.ProductName NOT LIKE '%IEEE 802.11%'
        )
        AND price_cat.Dist_ID = 20 -- Synnex
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
            target.CLIN = '',
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
                '',
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
  END PRICE RULE TEN
**/


    /** PRICE RULE TEN **/
BEGIN TRY
--     DECLARE @PriceRuleDiscount AS FLOAT;
    SET @PriceRuleDiscount = '0.283'; -- Set Discount Percentage Here

--     DECLARE @PriceRuleName AS VARCHAR(150);
    SET @PriceRuleName = 'HPE - CTO and Non-CTO - Aruba Networking Solutions';

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
        WHERE master_cat.etilizeMfgId IN ('1063889','1063890','1063892','1063978','1043455','1046863','1046864','1054748','1054862') AND master_cat.Description LIKE '%Aruba%'
        AND (
            master_cat.search NOT LIKE '%BLUETOOTH%'
            OR master_cat.search NOT LIKE '%WI-FI%'
            OR master_cat.search NOT LIKE '%WIFI%'
            OR master_cat.search NOT LIKE '%WIRELESS%'
            OR master_cat.search NOT LIKE '%LTE%'
            OR master_cat.search NOT LIKE '%REFURBISHED%'
            OR master_cat.search NOT LIKE '%IEEE 802.11%'
        )
        AND (
            master_cat.Description NOT LIKE '%BLUETOOTH%'
            OR master_cat.Description NOT LIKE '%WI-FI%'
            OR master_cat.Description NOT LIKE '%WIFI%'
            OR master_cat.Description NOT LIKE '%WIRELESS%'
            OR master_cat.Description NOT LIKE '%LTE%'
            OR master_cat.Description NOT LIKE '%REFURBISHED%'
            OR master_cat.Description NOT LIKE '%IEEE 802.11%'
        )
        AND (
            master_cat.ProductName NOT LIKE '%BLUETOOTH%'
            OR master_cat.ProductName NOT LIKE '%WI-FI%'
            OR master_cat.ProductName NOT LIKE '%WIFI%'
            OR master_cat.ProductName NOT LIKE '%WIRELESS%'
            OR master_cat.ProductName NOT LIKE '%LTE%'
            OR master_cat.ProductName NOT LIKE '%REFURBISHED%'
            OR master_cat.ProductName NOT LIKE '%IEEE 802.11%'
        )
        AND price_cat.Dist_ID = 20 -- Synnex
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
            target.CLIN = '',
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
                '',
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
  END PRICE RULE TEN
**/


    /** PRICE RULE TEN **/
BEGIN TRY
--     DECLARE @PriceRuleDiscount AS FLOAT;
    SET @PriceRuleDiscount = '0.1216'; -- Set Discount Percentage Here

--     DECLARE @PriceRuleName AS VARCHAR(150);
    SET @PriceRuleName = 'HPE - SBUY - Entry, Mid, and High Level Servers';

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
        WHERE (master_cat.etilizeCatId IN ('4873','5148','10154','10247','10282','11099','11748') OR master_cat.etilizeParentCatId IN ('4873','5148','10154','10247','10282','11099','11748')) AND master_cat.etilizeMfgId IN ('1063889','1063890','1063892','1063978','1043455','1046863','1046864','1054748','1054862')
        AND (
            master_cat.search NOT LIKE '%BLUETOOTH%'
            OR master_cat.search NOT LIKE '%WI-FI%'
            OR master_cat.search NOT LIKE '%WIFI%'
            OR master_cat.search NOT LIKE '%WIRELESS%'
            OR master_cat.search NOT LIKE '%LTE%'
            OR master_cat.search NOT LIKE '%REFURBISHED%'
            OR master_cat.search NOT LIKE '%IEEE 802.11%'
        )
        AND (
            master_cat.Description NOT LIKE '%BLUETOOTH%'
            OR master_cat.Description NOT LIKE '%WI-FI%'
            OR master_cat.Description NOT LIKE '%WIFI%'
            OR master_cat.Description NOT LIKE '%WIRELESS%'
            OR master_cat.Description NOT LIKE '%LTE%'
            OR master_cat.Description NOT LIKE '%REFURBISHED%'
            OR master_cat.Description NOT LIKE '%IEEE 802.11%'
        )
        AND (
            master_cat.ProductName NOT LIKE '%BLUETOOTH%'
            OR master_cat.ProductName NOT LIKE '%WI-FI%'
            OR master_cat.ProductName NOT LIKE '%WIFI%'
            OR master_cat.ProductName NOT LIKE '%WIRELESS%'
            OR master_cat.ProductName NOT LIKE '%LTE%'
            OR master_cat.ProductName NOT LIKE '%REFURBISHED%'
            OR master_cat.ProductName NOT LIKE '%IEEE 802.11%'
        )
        AND price_cat.Dist_ID = 20 -- Synnex
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
            target.CLIN = '',
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
                '',
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
  END PRICE RULE TEN
**/

    /** PRICE RULE TEN **/
BEGIN TRY
--     DECLARE @PriceRuleDiscount AS FLOAT;
    SET @PriceRuleDiscount = '0.26'; -- Set Discount Percentage Here

--     DECLARE @PriceRuleName AS VARCHAR(150);
    SET @PriceRuleName = 'HP - Storage Devices (HSD)';

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
        WHERE (master_cat.etilizeCatId IN ('4907','5167','10061','1010','10154','10465','10468','10692','10808','10931','11493','11611') OR master_cat.etilizeParentCatId IN ('4907','5167','10061','1010','10154','10465','10468','10692','10808','10931','11493','11611')) AND master_cat.etilizeMfgId IN ('1063889','1063890','1063892','1063978','1043455','1046863','1046864','1054748','1054862','1063888','1063891','1063976','1063979','1042796','1043456','1046484')
        AND (
            master_cat.search NOT LIKE '%BLUETOOTH%'
            OR master_cat.search NOT LIKE '%WI-FI%'
            OR master_cat.search NOT LIKE '%WIFI%'
            OR master_cat.search NOT LIKE '%WIRELESS%'
            OR master_cat.search NOT LIKE '%LTE%'
            OR master_cat.search NOT LIKE '%REFURBISHED%'
            OR master_cat.search NOT LIKE '%IEEE 802.11%'
        )
        AND (
            master_cat.Description NOT LIKE '%BLUETOOTH%'
            OR master_cat.Description NOT LIKE '%WI-FI%'
            OR master_cat.Description NOT LIKE '%WIFI%'
            OR master_cat.Description NOT LIKE '%WIRELESS%'
            OR master_cat.Description NOT LIKE '%LTE%'
            OR master_cat.Description NOT LIKE '%REFURBISHED%'
            OR master_cat.Description NOT LIKE '%IEEE 802.11%'
        )
        AND (
            master_cat.ProductName NOT LIKE '%BLUETOOTH%'
            OR master_cat.ProductName NOT LIKE '%WI-FI%'
            OR master_cat.ProductName NOT LIKE '%WIFI%'
            OR master_cat.ProductName NOT LIKE '%WIRELESS%'
            OR master_cat.ProductName NOT LIKE '%LTE%'
            OR master_cat.ProductName NOT LIKE '%REFURBISHED%'
            OR master_cat.ProductName NOT LIKE '%IEEE 802.11%'
        )
        AND price_cat.Dist_ID = 20 -- Synnex
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
            target.CLIN = '',
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
                '',
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
  END PRICE RULE TEN
**/

    /** PRICE RULE TEN **/
BEGIN TRY
--     DECLARE @PriceRuleDiscount AS FLOAT;
    SET @PriceRuleDiscount = '0.26'; -- Set Discount Percentage Here

--     DECLARE @PriceRuleName AS VARCHAR(150);
    SET @PriceRuleName = 'NOT HP - Storage Devices (HSD)';

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
        WHERE (master_cat.etilizeCatId IN ('4907','5167','10061','1010','10154','10465','10468','10692','10808','10931','11493','11611') OR master_cat.etilizeParentCatId IN ('4907','5167','10061','1010','10154','10465','10468','10692','10808','10931','11493','11611')) AND master_cat.etilizeMfgId IN ('102251','101210','10237','10220','10406','10418','102304','10563','10353','1020570','1030062','10227','1036611','10322','10301','10227','10943','1023145','1026045','1029114','1032356','1035747','1044946','1045024','1046866','1020376','1029553','1030008','1025881','1036136','1039004','101950','1034465','1026916')
        AND (
            master_cat.search NOT LIKE '%BLUETOOTH%'
            OR master_cat.search NOT LIKE '%WI-FI%'
            OR master_cat.search NOT LIKE '%WIFI%'
            OR master_cat.search NOT LIKE '%WIRELESS%'
            OR master_cat.search NOT LIKE '%LTE%'
            OR master_cat.search NOT LIKE '%REFURBISHED%'
            OR master_cat.search NOT LIKE '%IEEE 802.11%'
        )
        AND (
            master_cat.Description NOT LIKE '%BLUETOOTH%'
            OR master_cat.Description NOT LIKE '%WI-FI%'
            OR master_cat.Description NOT LIKE '%WIFI%'
            OR master_cat.Description NOT LIKE '%WIRELESS%'
            OR master_cat.Description NOT LIKE '%LTE%'
            OR master_cat.Description NOT LIKE '%REFURBISHED%'
            OR master_cat.Description NOT LIKE '%IEEE 802.11%'
        )
        AND (
            master_cat.ProductName NOT LIKE '%BLUETOOTH%'
            OR master_cat.ProductName NOT LIKE '%WI-FI%'
            OR master_cat.ProductName NOT LIKE '%WIFI%'
            OR master_cat.ProductName NOT LIKE '%WIRELESS%'
            OR master_cat.ProductName NOT LIKE '%LTE%'
            OR master_cat.ProductName NOT LIKE '%REFURBISHED%'
            OR master_cat.ProductName NOT LIKE '%IEEE 802.11%'
        )
        AND price_cat.Dist_ID = 20 -- Synnex
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
            target.CLIN = '',
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
                '',
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
  END PRICE RULE TEN
**/


    /** PRICE RULE TEN **/
BEGIN TRY
--     DECLARE @PriceRuleDiscount AS FLOAT;
    SET @PriceRuleDiscount = '0.31'; -- Set Discount Percentage Here

--     DECLARE @PriceRuleName AS VARCHAR(150);
    SET @PriceRuleName = 'HP - System Components';

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
        WHERE (master_cat.etilizeCatId IN ('5181') OR master_cat.etilizeParentCatId IN ('5181')) AND master_cat.etilizeMfgId IN ('1063889','1063890','1063892','1063978','1043455','1046863','1046864','1054748','1054862','1063888','1063891','1063976','1063979','1042796','1043456','1046484')
        AND (
            master_cat.search NOT LIKE '%BLUETOOTH%'
            OR master_cat.search NOT LIKE '%WI-FI%'
            OR master_cat.search NOT LIKE '%WIFI%'
            OR master_cat.search NOT LIKE '%WIRELESS%'
            OR master_cat.search NOT LIKE '%LTE%'
            OR master_cat.search NOT LIKE '%REFURBISHED%'
            OR master_cat.search NOT LIKE '%IEEE 802.11%'
        )
        AND (
            master_cat.Description NOT LIKE '%BLUETOOTH%'
            OR master_cat.Description NOT LIKE '%WI-FI%'
            OR master_cat.Description NOT LIKE '%WIFI%'
            OR master_cat.Description NOT LIKE '%WIRELESS%'
            OR master_cat.Description NOT LIKE '%LTE%'
            OR master_cat.Description NOT LIKE '%REFURBISHED%'
            OR master_cat.Description NOT LIKE '%IEEE 802.11%'
        )
        AND (
            master_cat.ProductName NOT LIKE '%BLUETOOTH%'
            OR master_cat.ProductName NOT LIKE '%WI-FI%'
            OR master_cat.ProductName NOT LIKE '%WIFI%'
            OR master_cat.ProductName NOT LIKE '%WIRELESS%'
            OR master_cat.ProductName NOT LIKE '%LTE%'
            OR master_cat.ProductName NOT LIKE '%REFURBISHED%'
            OR master_cat.ProductName NOT LIKE '%IEEE 802.11%'
        )
        AND price_cat.Dist_ID = 20 -- Synnex
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
            target.CLIN = '',
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
                '',
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
  END PRICE RULE TEN
**/

    /** PRICE RULE TEN **/
BEGIN TRY
--     DECLARE @PriceRuleDiscount AS FLOAT;
    SET @PriceRuleDiscount = '0.21'; -- Set Discount Percentage Here

--     DECLARE @PriceRuleName AS VARCHAR(150);
    SET @PriceRuleName = 'Not HP - System Components';

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
        WHERE (master_cat.etilizeCatId IN ('5181') OR master_cat.etilizeParentCatId IN ('5181')) AND master_cat.etilizeMfgId IN ('102251','101210','10237','10220','10406','10418','102304','10563','10353','1020570','1030062','10227','1036611','10322','10301','10227','10943','1023145','1026045','1029114','1032356','1035747','1044946','1045024','1046866','1020376','1029553','1030008','1025881','1036136','1039004','101950','1034465','1026916')
        AND (
            master_cat.search NOT LIKE '%BLUETOOTH%'
            OR master_cat.search NOT LIKE '%WI-FI%'
            OR master_cat.search NOT LIKE '%WIFI%'
            OR master_cat.search NOT LIKE '%WIRELESS%'
            OR master_cat.search NOT LIKE '%LTE%'
            OR master_cat.search NOT LIKE '%REFURBISHED%'
            OR master_cat.search NOT LIKE '%IEEE 802.11%'
        )
        AND (
            master_cat.Description NOT LIKE '%BLUETOOTH%'
            OR master_cat.Description NOT LIKE '%WI-FI%'
            OR master_cat.Description NOT LIKE '%WIFI%'
            OR master_cat.Description NOT LIKE '%WIRELESS%'
            OR master_cat.Description NOT LIKE '%LTE%'
            OR master_cat.Description NOT LIKE '%REFURBISHED%'
            OR master_cat.Description NOT LIKE '%IEEE 802.11%'
        )
        AND (
            master_cat.ProductName NOT LIKE '%BLUETOOTH%'
            OR master_cat.ProductName NOT LIKE '%WI-FI%'
            OR master_cat.ProductName NOT LIKE '%WIFI%'
            OR master_cat.ProductName NOT LIKE '%WIRELESS%'
            OR master_cat.ProductName NOT LIKE '%LTE%'
            OR master_cat.ProductName NOT LIKE '%REFURBISHED%'
            OR master_cat.ProductName NOT LIKE '%IEEE 802.11%'
        )
        AND price_cat.Dist_ID = 20 -- Synnex
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
            target.CLIN = '',
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
                '',
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
  END PRICE RULE TEN
**/

    /** PRICE RULE TEN **/
BEGIN TRY
--     DECLARE @PriceRuleDiscount AS FLOAT;
    SET @PriceRuleDiscount = '0.36'; -- Set Discount Percentage Here

--     DECLARE @PriceRuleName AS VARCHAR(150);
    SET @PriceRuleName = 'HP - Printer Supplies';

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
        WHERE (master_cat.etilizeCatId IN ('11040') OR master_cat.etilizeParentCatId IN ('11040')) AND master_cat.etilizeMfgId IN ('1063889','1063890','1063892','1063978','1043455','1046863','1046864','1054748','1054862','1063888','1063891','1063976','1063979','1042796','1043456','1046484')
        AND (
            master_cat.search NOT LIKE '%BLUETOOTH%'
            OR master_cat.search NOT LIKE '%WI-FI%'
            OR master_cat.search NOT LIKE '%WIFI%'
            OR master_cat.search NOT LIKE '%WIRELESS%'
            OR master_cat.search NOT LIKE '%LTE%'
            OR master_cat.search NOT LIKE '%REFURBISHED%'
            OR master_cat.search NOT LIKE '%IEEE 802.11%'
        )
        AND (
            master_cat.Description NOT LIKE '%BLUETOOTH%'
            OR master_cat.Description NOT LIKE '%WI-FI%'
            OR master_cat.Description NOT LIKE '%WIFI%'
            OR master_cat.Description NOT LIKE '%WIRELESS%'
            OR master_cat.Description NOT LIKE '%LTE%'
            OR master_cat.Description NOT LIKE '%REFURBISHED%'
            OR master_cat.Description NOT LIKE '%IEEE 802.11%'
        )
        AND (
            master_cat.ProductName NOT LIKE '%BLUETOOTH%'
            OR master_cat.ProductName NOT LIKE '%WI-FI%'
            OR master_cat.ProductName NOT LIKE '%WIFI%'
            OR master_cat.ProductName NOT LIKE '%WIRELESS%'
            OR master_cat.ProductName NOT LIKE '%LTE%'
            OR master_cat.ProductName NOT LIKE '%REFURBISHED%'
            OR master_cat.ProductName NOT LIKE '%IEEE 802.11%'
        )
        AND price_cat.Dist_ID = 20 -- Synnex
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
            target.CLIN = '',
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
                '',
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
  END PRICE RULE TEN
**/

    /** PRICE RULE TEN **/
BEGIN TRY
--     DECLARE @PriceRuleDiscount AS FLOAT;
    SET @PriceRuleDiscount = '0.36'; -- Set Discount Percentage Here

--     DECLARE @PriceRuleName AS VARCHAR(150);
    SET @PriceRuleName = 'Not HP - Printer Supplies (Not Ink)';

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
        WHERE (master_cat.etilizeCatId IN ('11040') OR master_cat.etilizeParentCatId IN ('11040')) AND master_cat.etilizeMfgId IN ('102251','101210','10237','10220','10406','10418','102304','10563','10353','1020570','1030062','10227','1036611','10322','10301','10227','10943','1023145','1026045','1029114','1032356','1035747','1044946','1045024','1046866','1020376','1029553','1030008','1025881','1036136','1039004','101950','1034465','1026916')
        AND (
            master_cat.search NOT LIKE '%BLUETOOTH%'
            OR master_cat.search NOT LIKE '%WI-FI%'
            OR master_cat.search NOT LIKE '%WIFI%'
            OR master_cat.search NOT LIKE '%WIRELESS%'
            OR master_cat.search NOT LIKE '%LTE%'
            OR master_cat.search NOT LIKE '%REFURBISHED%'
            OR master_cat.search NOT LIKE '%IEEE 802.11%'
        )
        AND (
            master_cat.Description NOT LIKE '%BLUETOOTH%'
            OR master_cat.Description NOT LIKE '%WI-FI%'
            OR master_cat.Description NOT LIKE '%WIFI%'
            OR master_cat.Description NOT LIKE '%WIRELESS%'
            OR master_cat.Description NOT LIKE '%LTE%'
            OR master_cat.Description NOT LIKE '%REFURBISHED%'
            OR master_cat.Description NOT LIKE '%IEEE 802.11%'
        )
        AND (
            master_cat.ProductName NOT LIKE '%BLUETOOTH%'
            OR master_cat.ProductName NOT LIKE '%WI-FI%'
            OR master_cat.ProductName NOT LIKE '%WIFI%'
            OR master_cat.ProductName NOT LIKE '%WIRELESS%'
            OR master_cat.ProductName NOT LIKE '%LTE%'
            OR master_cat.ProductName NOT LIKE '%REFURBISHED%'
            OR master_cat.ProductName NOT LIKE '%IEEE 802.11%'
        )
        AND price_cat.Dist_ID = 20 -- Synnex
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
            target.CLIN = '',
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
                '',
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
  END PRICE RULE TEN
**/


    /** PRICE RULE TEN **/
BEGIN TRY
--     DECLARE @PriceRuleDiscount AS FLOAT;
    SET @PriceRuleDiscount = '0.21'; -- Set Discount Percentage Here

--     DECLARE @PriceRuleName AS VARCHAR(150);
    SET @PriceRuleName = 'HP - 3rd Party Software';

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
        WHERE (master_cat.etilizeCatId IN ('5160','10007','10052','10114') OR master_cat.etilizeParentCatId IN ('5160','10007','10052','10114')) AND master_cat.etilizeMfgId IN ('1063889','1063890','1063892','1063978','1043455','1046863','1046864','1054748','1054862','1063888','1063891','1063976','1063979','1042796','1043456','1046484')
        AND (
            master_cat.search NOT LIKE '%BLUETOOTH%'
            OR master_cat.search NOT LIKE '%WI-FI%'
            OR master_cat.search NOT LIKE '%WIFI%'
            OR master_cat.search NOT LIKE '%WIRELESS%'
            OR master_cat.search NOT LIKE '%LTE%'
            OR master_cat.search NOT LIKE '%REFURBISHED%'
            OR master_cat.search NOT LIKE '%IEEE 802.11%'
        )
        AND (
            master_cat.Description NOT LIKE '%BLUETOOTH%'
            OR master_cat.Description NOT LIKE '%WI-FI%'
            OR master_cat.Description NOT LIKE '%WIFI%'
            OR master_cat.Description NOT LIKE '%WIRELESS%'
            OR master_cat.Description NOT LIKE '%LTE%'
            OR master_cat.Description NOT LIKE '%REFURBISHED%'
            OR master_cat.Description NOT LIKE '%IEEE 802.11%'
        )
        AND (
            master_cat.ProductName NOT LIKE '%BLUETOOTH%'
            OR master_cat.ProductName NOT LIKE '%WI-FI%'
            OR master_cat.ProductName NOT LIKE '%WIFI%'
            OR master_cat.ProductName NOT LIKE '%WIRELESS%'
            OR master_cat.ProductName NOT LIKE '%LTE%'
            OR master_cat.ProductName NOT LIKE '%REFURBISHED%'
            OR master_cat.ProductName NOT LIKE '%IEEE 802.11%'
        )
        AND price_cat.Dist_ID = 20 -- Synnex
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
            target.CLIN = '',
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
                '',
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
  END PRICE RULE TEN
**/

    /** PRICE RULE TEN **/
BEGIN TRY
--     DECLARE @PriceRuleDiscount AS FLOAT;
    SET @PriceRuleDiscount = '0.41'; -- Set Discount Percentage Here

--     DECLARE @PriceRuleName AS VARCHAR(150);
    SET @PriceRuleName = 'HP - Cables';

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
        WHERE (master_cat.etilizeCatId IN ('5153') OR master_cat.etilizeParentCatId IN ('5153')) AND master_cat.etilizeMfgId IN ('1063889','1063890','1063892','1063978','1043455','1046863','1046864','1054748','1054862','1063888','1063891','1063976','1063979','1042796','1043456','1046484')
        AND (
            master_cat.search NOT LIKE '%BLUETOOTH%'
            OR master_cat.search NOT LIKE '%WI-FI%'
            OR master_cat.search NOT LIKE '%WIFI%'
            OR master_cat.search NOT LIKE '%WIRELESS%'
            OR master_cat.search NOT LIKE '%LTE%'
            OR master_cat.search NOT LIKE '%REFURBISHED%'
            OR master_cat.search NOT LIKE '%IEEE 802.11%'
        )
        AND (
            master_cat.Description NOT LIKE '%BLUETOOTH%'
            OR master_cat.Description NOT LIKE '%WI-FI%'
            OR master_cat.Description NOT LIKE '%WIFI%'
            OR master_cat.Description NOT LIKE '%WIRELESS%'
            OR master_cat.Description NOT LIKE '%LTE%'
            OR master_cat.Description NOT LIKE '%REFURBISHED%'
            OR master_cat.Description NOT LIKE '%IEEE 802.11%'
        )
        AND (
            master_cat.ProductName NOT LIKE '%BLUETOOTH%'
            OR master_cat.ProductName NOT LIKE '%WI-FI%'
            OR master_cat.ProductName NOT LIKE '%WIFI%'
            OR master_cat.ProductName NOT LIKE '%WIRELESS%'
            OR master_cat.ProductName NOT LIKE '%LTE%'
            OR master_cat.ProductName NOT LIKE '%REFURBISHED%'
            OR master_cat.ProductName NOT LIKE '%IEEE 802.11%'
        )
        AND price_cat.Dist_ID = 20 -- Synnex
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
            target.CLIN = '',
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
                '',
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
  END PRICE RULE TEN
**/

    /** PRICE RULE TEN **/
BEGIN TRY
--     DECLARE @PriceRuleDiscount AS FLOAT;
    SET @PriceRuleDiscount = '0.21'; -- Set Discount Percentage Here

--     DECLARE @PriceRuleName AS VARCHAR(150);
    SET @PriceRuleName = 'Not HP - Cables';

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
        WHERE (master_cat.etilizeCatId IN ('5153') OR master_cat.etilizeParentCatId IN ('5153')) AND master_cat.etilizeMfgId IN ('102251','101210','10237','10220','10406','10418','102304','10563','10353','1020570','1030062','10227','1036611','10322','10301','10227','10943','1023145','1026045','1029114','1032356','1035747','1044946','1045024','1046866','1020376','1029553','1030008','1025881','1036136','1039004','101950','1034465','1026916')
        AND (
            master_cat.search NOT LIKE '%BLUETOOTH%'
            OR master_cat.search NOT LIKE '%WI-FI%'
            OR master_cat.search NOT LIKE '%WIFI%'
            OR master_cat.search NOT LIKE '%WIRELESS%'
            OR master_cat.search NOT LIKE '%LTE%'
            OR master_cat.search NOT LIKE '%REFURBISHED%'
            OR master_cat.search NOT LIKE '%IEEE 802.11%'
        )
        AND (
            master_cat.Description NOT LIKE '%BLUETOOTH%'
            OR master_cat.Description NOT LIKE '%WI-FI%'
            OR master_cat.Description NOT LIKE '%WIFI%'
            OR master_cat.Description NOT LIKE '%WIRELESS%'
            OR master_cat.Description NOT LIKE '%LTE%'
            OR master_cat.Description NOT LIKE '%REFURBISHED%'
            OR master_cat.Description NOT LIKE '%IEEE 802.11%'
        )
        AND (
            master_cat.ProductName NOT LIKE '%BLUETOOTH%'
            OR master_cat.ProductName NOT LIKE '%WI-FI%'
            OR master_cat.ProductName NOT LIKE '%WIFI%'
            OR master_cat.ProductName NOT LIKE '%WIRELESS%'
            OR master_cat.ProductName NOT LIKE '%LTE%'
            OR master_cat.ProductName NOT LIKE '%REFURBISHED%'
            OR master_cat.ProductName NOT LIKE '%IEEE 802.11%'
        )
        AND price_cat.Dist_ID = 20 -- Synnex
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
            target.CLIN = '',
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
                '',
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
  END PRICE RULE TEN
**/

    /** PRICE RULE TEN **/
BEGIN TRY
--     DECLARE @PriceRuleDiscount AS FLOAT;
    SET @PriceRuleDiscount = '0.22'; -- Set Discount Percentage Here

--     DECLARE @PriceRuleName AS VARCHAR(150);
    SET @PriceRuleName = 'HP - Large Format Printer (HLP)';

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
        WHERE (master_cat.etilizeCatId IN ('4822') OR master_cat.etilizeParentCatId IN ('4822')) AND master_cat.etilizeMfgId IN ('1063889','1063890','1063892','1063978','1043455','1046863','1046864','1054748','1054862','1063888','1063891','1063976','1063979','1042796','1043456','1046484')
        AND (
            master_cat.search NOT LIKE '%BLUETOOTH%'
            OR master_cat.search NOT LIKE '%WI-FI%'
            OR master_cat.search NOT LIKE '%WIFI%'
            OR master_cat.search NOT LIKE '%WIRELESS%'
            OR master_cat.search NOT LIKE '%LTE%'
            OR master_cat.search NOT LIKE '%REFURBISHED%'
            OR master_cat.search NOT LIKE '%IEEE 802.11%'
        )
        AND (
            master_cat.Description NOT LIKE '%BLUETOOTH%'
            OR master_cat.Description NOT LIKE '%WI-FI%'
            OR master_cat.Description NOT LIKE '%WIFI%'
            OR master_cat.Description NOT LIKE '%WIRELESS%'
            OR master_cat.Description NOT LIKE '%LTE%'
            OR master_cat.Description NOT LIKE '%REFURBISHED%'
            OR master_cat.Description NOT LIKE '%IEEE 802.11%'
        )
        AND (
            master_cat.ProductName NOT LIKE '%BLUETOOTH%'
            OR master_cat.ProductName NOT LIKE '%WI-FI%'
            OR master_cat.ProductName NOT LIKE '%WIFI%'
            OR master_cat.ProductName NOT LIKE '%WIRELESS%'
            OR master_cat.ProductName NOT LIKE '%LTE%'
            OR master_cat.ProductName NOT LIKE '%REFURBISHED%'
            OR master_cat.ProductName NOT LIKE '%IEEE 802.11%'
        )
        AND price_cat.Dist_ID = 20 -- Synnex
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
            target.CLIN = '',
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
                '',
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
  END PRICE RULE TEN
**/


    /** PRICE RULE TEN **/
BEGIN TRY
--     DECLARE @PriceRuleDiscount AS FLOAT;
    SET @PriceRuleDiscount = '0.37'; -- Set Discount Percentage Here

--     DECLARE @PriceRuleName AS VARCHAR(150);
    SET @PriceRuleName = 'HP - Ink & Toner';

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
        WHERE (master_cat.etilizeCatId IN ('10015') OR master_cat.etilizeParentCatId IN ('10015')) AND master_cat.etilizeMfgId IN ('1063889','1063890','1063892','1063978','1043455','1046863','1046864','1054748','1054862','1063888','1063891','1063976','1063979','1042796','1043456','1046484')
        AND (
            master_cat.search NOT LIKE '%BLUETOOTH%'
            OR master_cat.search NOT LIKE '%WI-FI%'
            OR master_cat.search NOT LIKE '%WIFI%'
            OR master_cat.search NOT LIKE '%WIRELESS%'
            OR master_cat.search NOT LIKE '%LTE%'
            OR master_cat.search NOT LIKE '%REFURBISHED%'
            OR master_cat.search NOT LIKE '%IEEE 802.11%'
        )
        AND (
            master_cat.Description NOT LIKE '%BLUETOOTH%'
            OR master_cat.Description NOT LIKE '%WI-FI%'
            OR master_cat.Description NOT LIKE '%WIFI%'
            OR master_cat.Description NOT LIKE '%WIRELESS%'
            OR master_cat.Description NOT LIKE '%LTE%'
            OR master_cat.Description NOT LIKE '%REFURBISHED%'
            OR master_cat.Description NOT LIKE '%IEEE 802.11%'
        )
        AND (
            master_cat.ProductName NOT LIKE '%BLUETOOTH%'
            OR master_cat.ProductName NOT LIKE '%WI-FI%'
            OR master_cat.ProductName NOT LIKE '%WIFI%'
            OR master_cat.ProductName NOT LIKE '%WIRELESS%'
            OR master_cat.ProductName NOT LIKE '%LTE%'
            OR master_cat.ProductName NOT LIKE '%REFURBISHED%'
            OR master_cat.ProductName NOT LIKE '%IEEE 802.11%'
        )
        AND price_cat.Dist_ID = 20 -- Synnex
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
            target.CLIN = '',
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
                '',
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
  END PRICE RULE TEN
**/


    /** PRICE RULE TEN **/
BEGIN TRY
--     DECLARE @PriceRuleDiscount AS FLOAT;
    SET @PriceRuleDiscount = '0.22'; -- Set Discount Percentage Here

--     DECLARE @PriceRuleName AS VARCHAR(150);
    SET @PriceRuleName = 'HP - Imaging Devices (HID)';

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
        WHERE (master_cat.etilizeCatId IN ('4911','4912','5123','10167','10333','10663','10910','11757') OR master_cat.etilizeParentCatId IN ('4911','4912','5123','10167','10333','10663','10910','11757')) AND master_cat.etilizeMfgId IN ('1063889','1063890','1063892','1063978','1043455','1046863','1046864','1054748','1054862','1063888','1063891','1063976','1063979','1042796','1043456','1046484')
        AND (
            master_cat.search NOT LIKE '%BLUETOOTH%'
            OR master_cat.search NOT LIKE '%WI-FI%'
            OR master_cat.search NOT LIKE '%WIFI%'
            OR master_cat.search NOT LIKE '%WIRELESS%'
            OR master_cat.search NOT LIKE '%LTE%'
            OR master_cat.search NOT LIKE '%REFURBISHED%'
            OR master_cat.search NOT LIKE '%IEEE 802.11%'
        )
        AND (
            master_cat.Description NOT LIKE '%BLUETOOTH%'
            OR master_cat.Description NOT LIKE '%WI-FI%'
            OR master_cat.Description NOT LIKE '%WIFI%'
            OR master_cat.Description NOT LIKE '%WIRELESS%'
            OR master_cat.Description NOT LIKE '%LTE%'
            OR master_cat.Description NOT LIKE '%REFURBISHED%'
            OR master_cat.Description NOT LIKE '%IEEE 802.11%'
        )
        AND (
            master_cat.ProductName NOT LIKE '%BLUETOOTH%'
            OR master_cat.ProductName NOT LIKE '%WI-FI%'
            OR master_cat.ProductName NOT LIKE '%WIFI%'
            OR master_cat.ProductName NOT LIKE '%WIRELESS%'
            OR master_cat.ProductName NOT LIKE '%LTE%'
            OR master_cat.ProductName NOT LIKE '%REFURBISHED%'
            OR master_cat.ProductName NOT LIKE '%IEEE 802.11%'
        )
        AND price_cat.Dist_ID = 20 -- Synnex
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
            target.CLIN = '',
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
                '',
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
  END PRICE RULE TEN
**/



    /** PRICE RULE TEN **/
BEGIN TRY
--     DECLARE @PriceRuleDiscount AS FLOAT;
    SET @PriceRuleDiscount = '0.22'; -- Set Discount Percentage Here

--     DECLARE @PriceRuleName AS VARCHAR(150);
    SET @PriceRuleName = 'Non-HP Imaging Devices';

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
        WHERE (master_cat.etilizeCatId IN ('4911','4912','5123','10167','10333','10663','10910','11757') OR master_cat.etilizeParentCatId IN ('4911','4912','5123','10167','10333','10663','10910','11757')) AND master_cat.etilizeMfgId IN ('102251','101210','10237','10220','10406','10418','102304','10563','10353','1020570','1030062','10227','1036611','10322','10301','10227','10943','1023145','1026045','1029114','1032356','1035747','1044946','1045024','1046866','1020376','1029553','1030008','1025881','1036136','1039004','101950','1034465','1026916')
        AND (
            master_cat.search NOT LIKE '%BLUETOOTH%'
            OR master_cat.search NOT LIKE '%WI-FI%'
            OR master_cat.search NOT LIKE '%WIFI%'
            OR master_cat.search NOT LIKE '%WIRELESS%'
            OR master_cat.search NOT LIKE '%LTE%'
            OR master_cat.search NOT LIKE '%REFURBISHED%'
            OR master_cat.search NOT LIKE '%IEEE 802.11%'
        )
        AND (
            master_cat.Description NOT LIKE '%BLUETOOTH%'
            OR master_cat.Description NOT LIKE '%WI-FI%'
            OR master_cat.Description NOT LIKE '%WIFI%'
            OR master_cat.Description NOT LIKE '%WIRELESS%'
            OR master_cat.Description NOT LIKE '%LTE%'
            OR master_cat.Description NOT LIKE '%REFURBISHED%'
            OR master_cat.Description NOT LIKE '%IEEE 802.11%'
        )
        AND (
            master_cat.ProductName NOT LIKE '%BLUETOOTH%'
            OR master_cat.ProductName NOT LIKE '%WI-FI%'
            OR master_cat.ProductName NOT LIKE '%WIFI%'
            OR master_cat.ProductName NOT LIKE '%WIRELESS%'
            OR master_cat.ProductName NOT LIKE '%LTE%'
            OR master_cat.ProductName NOT LIKE '%REFURBISHED%'
            OR master_cat.ProductName NOT LIKE '%IEEE 802.11%'
        )
        AND price_cat.Dist_ID = 20 -- Synnex
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
            target.CLIN = '',
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
                '',
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
  END PRICE RULE TEN
**/

-- Remove All $0 or Null Prices
DELETE FROM [wwcp_pricing].[dbo].[ContractItem_temp]
WHERE Price <= 0
OR Price IS NULL;

-- Ensure Price Always Has At Least 5% Gross Margin
UPDATE [wwcp_pricing].[dbo].[ContractItem_temp]
SET Price = Cost / 0.95
WHERE ((Price - Cost) / Price) * 100 < 5;

-- Double Remove The Wireless Keywords
DELETE FROM [wwcp_pricing].[dbo].[ContractItem_temp]
WHERE (
        Description LIKE '%BLUETOOTH%'
        OR Description LIKE '%WI-FI%'
        OR Description LIKE '%WIFI%'
        OR Description LIKE '%WIRELESS%'
        OR Description LIKE '%LTE%'
        OR Description LIKE '%REFURBISHED%'
        OR Description LIKE '%IEEE 802.11%'
    )
    AND (
        ProductName LIKE '%BLUETOOTH%'
        OR ProductName LIKE '%WI-FI%'
        OR ProductName LIKE '%WIFI%'
        OR ProductName LIKE '%WIRELESS%'
        OR ProductName LIKE '%LTE%'
        OR ProductName LIKE '%REFURBISHED%'
        OR ProductName LIKE '%IEEE 802.11%'
    );

/*
*
* MERGE ContractItem_temp into ContractItem
*/

BEGIN TRY

/** DELETE ContractItems created during prior runs (FILTERED to single ContractId) **/
DELETE FROM [192.168.80.162].[wwcp].[dbo].[ContractItem] WHERE ContractID = @DestinationContractId;

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
SELECT GSAPrice,
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


