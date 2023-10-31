/**
*
* WESTWIND: Sandia Price Engine (EXCLUDING Wireless)
*
**/

-- TEMP TABLE: [wwcp_pricing].[dbo].[ContractItem_temp]
-- FINAL TABLE: [wwcp].[dbo].[ContractItem]

/**
*
*   BEGIN PRICE ENGINE CONFIGURATION
*
**/
DECLARE @DestinationContractId AS INT;
SET @DestinationContractId = 55;

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
        price_cat.Price,
        price_cat.Price * (1-@PriceRuleDiscount) as discounted_price, -- This Is Where The Discount Is Applied To price_cat.Price
        master_cat.*
        FROM [wwcp_pricing].[dbo].[PriceCatalog_temp] as price_cat
        JOIN [WWProjectCatalog].[dbo].[MasterCatalog] as master_cat
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
        )
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

    


/*
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

/** ADDITIONAL RULES
"HPI - Level 2 - Non-CTO - Thin Client" - 0.051
SELECT
        price_cat.Price,
        price_cat.Price * (1-@PriceRuleDiscount) as discounted_price, -- This Is Where The Discount Is Applied To price_cat.Price
        master_cat.*
        FROM [wwcp_pricing].[dbo].[PriceCatalog_temp] as price_cat
        JOIN [WWProjectCatalog].[dbo].[MasterCatalog] as master_cat
        ON price_cat.Dist_ID = master_cat.Dist_ID AND price_cat.Dist_Part_Number = master_cat.Dist_Part_Number
        WHERE (master_cat.etilizeCatId IN ('4830') OR master_cat.etilizeParentCatId IN ('4830')) AND master_cat.etilizeMfgId IN ('1063888','1063891','1063976','1063979','1042796','1043456','1046484') AND master_cat.search NOT LIKE '% SBUY %' AND (master_cat.search NOT LIKE '%BLUETOOTH%' OR master_cat.search NOT LIKE '%WI-FI%' OR master_cat.search NOT LIKE '%WIFI%' OR master_cat.search NOT LIKE '%WIRELESS%' OR master_cat.search NOT LIKE '%LTE%')


"HPI - Level 2 - CTO - Tablet" - 0.295
  SELECT
        price_cat.Price,
        price_cat.Price * (1-@PriceRuleDiscount) as discounted_price, -- This Is Where The Discount Is Applied To price_cat.Price
        master_cat.*
        FROM [wwcp_pricing].[dbo].[PriceCatalog_temp] as price_cat
        JOIN [WWProjectCatalog].[dbo].[MasterCatalog] as master_cat
        ON price_cat.Dist_ID = master_cat.Dist_ID AND price_cat.Dist_Part_Number = master_cat.Dist_Part_Number
        WHERE (master_cat.etilizeCatId IN ('10025') OR master_cat.etilizeParentCatId IN ('10025')) AND master_cat.etilizeMfgId IN ('1063888','1063891','1063976','1063979','1042796','1043456','1046484') AND master_cat.search NOT LIKE '% SBUY %' AND (master_cat.search NOT LIKE '%BLUETOOTH%' OR master_cat.search NOT LIKE '%WI-FI%' OR master_cat.search NOT LIKE '%WIFI%' OR master_cat.search NOT LIKE '%WIRELESS%' OR master_cat.search NOT LIKE '%LTE%')

  "HPI - Level 2 - NON-CTO - Tablet" - 0.1152
WHERE (master_cat.etilizeCatId IN ('10025') OR master_cat.etilizeParentCatId IN ('10025')) AND master_cat.etilizeMfgId IN ('1063888','1063891','1063976','1063979','1042796','1043456','1046484') AND master_cat.search LIKE '% SBUY %' AND (master_cat.search NOT LIKE '%BLUETOOTH%' OR master_cat.search NOT LIKE '%WI-FI%' OR master_cat.search NOT LIKE '%WIFI%' OR master_cat.search NOT LIKE '%WIRELESS%' OR master_cat.search NOT LIKE '%LTE%')

  
  "HPI - Level 2 - CTO - LAPTOP" - 0.34
  WHERE (master_cat.etilizeCatId  IN ('4876','10285','11925','4830') OR master_cat.etilizeParentCatId  IN ('4876','10285','11925','4830')) AND master_cat.etilizeMfgId IN ('1063888','1063891','1063976','1063979','1042796','1043456','1046484') AND master_cat.search NOT LIKE '% SBUY %' AND (master_cat.search NOT LIKE '%BLUETOOTH%' OR master_cat.search NOT LIKE '%WI-FI%' OR master_cat.search NOT LIKE '%WIFI%' OR master_cat.search NOT LIKE '%WIRELESS%' OR master_cat.search NOT LIKE '%LTE%')

"HPI - Level 2 - NON-CTO - LAPTOP" - 0.0877
WHERE (master_cat.etilizeCatId IN ('4876','10285','11925','4830') OR master_cat.etilizeParentCatId IN ('4876','10285','11925','4830')) AND master_cat.etilizeMfgId IN ('1063888','1063891','1063976','1063979','1042796','1043456','1046484') AND master_cat.search LIKE '% SBUY %' AND (master_cat.search NOT LIKE '%BLUETOOTH%' OR master_cat.search NOT LIKE '%WI-FI%' OR master_cat.search NOT LIKE '%WIFI%' OR master_cat.search NOT LIKE '%WIRELESS%' OR master_cat.search NOT LIKE '%LTE%')
           
"HPI - Level 2 - CTO - DEKSTOP" - 0.29
WHERE (master_cat.etilizeCatId IN ('4871') OR master_cat.etilizeParentCatId IN ('4871')) AND master_cat.etilizeMfgId IN ('1063888','1063891','1063976','1063979','1042796','1043456','1046484') AND master_cat.search NOT LIKE '% SBUY %' AND (master_cat.search NOT LIKE '%BLUETOOTH%' OR master_cat.search NOT LIKE '%WI-FI%' OR master_cat.search NOT LIKE '%WIFI%' OR master_cat.search NOT LIKE '%WIRELESS%' OR master_cat.search NOT LIKE '%LTE%')
            

  "HPI - Level 2 - NON-CTO - DESKTOP" - 0.0952
WHERE (master_cat.etilizeCatId IN ('4871') OR master_cat.etilizeParentCatId IN ('4871')) AND master_cat.etilizeMfgId IN ('1063888','1063891','1063976','1063979','1042796','1043456','1046484') AND master_cat.search LIKE '% SBUY %' AND (master_cat.search NOT LIKE '%BLUETOOTH%' OR master_cat.search NOT LIKE '%WI-FI%' OR master_cat.search NOT LIKE '%WIFI%' OR master_cat.search NOT LIKE '%WIRELESS%' OR master_cat.search NOT LIKE '%LTE%')

  "HPI - Level 2 - CTO - WORKSTATION" - 0.34
  WHERE (master_cat.etilizeCatId IN ('4872') OR master_cat.etilizeParentCatId IN ('4872')) AND master_cat.etilizeMfgId IN ('1063888','1063891','1063976','1063979','1042796','1043456','1046484') AND master_cat.search NOT LIKE '% SBUY %' AND (master_cat.search NOT LIKE '%BLUETOOTH%' OR master_cat.search NOT LIKE '%WI-FI%' OR master_cat.search NOT LIKE '%WIFI%' OR master_cat.search NOT LIKE '%WIRELESS%' OR master_cat.search NOT LIKE '%LTE%')
            
 "HPI - Level 2 - NON-CTO - WORKSTATION" - 0.1243
WHERE (master_cat.etilizeCatId IN ('4872') OR master_cat.etilizeParentCatId IN ('4872')) AND master_cat.etilizeMfgId IN ('1063888','1063891','1063976','1063979','1042796','1043456','1046484') AND master_cat.search LIKE '% SBUY %' AND (master_cat.search NOT LIKE '%BLUETOOTH%' OR master_cat.search NOT LIKE '%WI-FI%' OR master_cat.search NOT LIKE '%WIFI%' OR master_cat.search NOT LIKE '%WIRELESS%' OR master_cat.search NOT LIKE '%LTE%')

  "HPI - Level 2 - Non-CTO - MONITORS" - 0.0715
WHERE (master_cat.etilizeCatId IN ('4831','10165') OR master_cat.etilizeParentCatId IN ('4831','10165')) AND master_cat.etilizeMfgId IN ('1063888','1063891','1063976','1063979','1042796','1043456','1046484') AND master_cat.search NOT LIKE '% SBUY %' AND (master_cat.search NOT LIKE '%BLUETOOTH%' OR master_cat.search NOT LIKE '%WI-FI%' OR master_cat.search NOT LIKE '%WIFI%' OR master_cat.search NOT LIKE '%WIRELESS%' OR master_cat.search NOT LIKE '%LTE%')
           
"HPI - Level 2 - Non-CTO - PRINTERS" - 0.23
WHERE (master_cat.etilizeCatId IN ('4805','4807','4810','4816','4820','4821','4822','10153','10294','10914','11655') OR master_cat.etilizeParentCatId IN ('4805','4807','4810','4816','4820','4821','4822','10153','10294','10914','11655')) AND master_cat.etilizeMfgId IN ('1063888','1063891','1063976','1063979','1042796','1043456','1046484') AND master_cat.search NOT LIKE '% SBUY %' AND (master_cat.search NOT LIKE '%BLUETOOTH%' OR master_cat.search NOT LIKE '%WI-FI%' OR master_cat.search NOT LIKE '%WIFI%' OR master_cat.search NOT LIKE '%WIRELESS%' OR master_cat.search NOT LIKE '%LTE%')

  "HPE - CTO - Networking Solution" - 0.38
WHERE (master_cat.etilizeCatId IN ('4813','4823','10040','10251','10291','10931','11099','11158','11164','11748','11752') OR master_cat.etilizeParentCatId IN ('4813','4823','10040','10251','10291','10931','11099','11158','11164','11748','11752')) AND master_cat.etilizeMfgId IN ('1063889','1063890','1063892','1063978','1043455','1046863','1046864','1054748','1054862') AND master_cat.search NOT LIKE '% SBUY %' AND (master_cat.search NOT LIKE '%BLUETOOTH%' OR master_cat.search NOT LIKE '%WI-FI%' OR master_cat.search NOT LIKE '%WIFI%' OR master_cat.search NOT LIKE '%WIRELESS%' OR master_cat.search NOT LIKE '%LTE%')
           
"HPE - Non-CTO - Networking Solution" - 0.325
WHERE (master_cat.etilizeCatId IN ('4813','4823','10040','10251','10291','10931','11099','11158','11164','11748','11752') OR master_cat.etilizeParentCatId IN ('4813','4823','10040','10251','10291','10931','11099','11158','11164','11748','11752')) AND master_cat.etilizeMfgId IN ('1063889','1063890','1063892','1063978','1043455','1046863','1046864','1054748','1054862') AND master_cat.search LIKE '% SBUY %' AND (master_cat.search NOT LIKE '%BLUETOOTH%' OR master_cat.search NOT LIKE '%WI-FI%' OR master_cat.search NOT LIKE '%WIFI%' OR master_cat.search NOT LIKE '%WIRELESS%' OR master_cat.search NOT LIKE '%LTE%')

  "HPE - CTO and Non-CTO - Aruba Networking Solutions" - 0.283
WHERE master_cat.etilizeMfgId IN ('1063889','1063890','1063892','1063978','1043455','1046863','1046864','1054748','1054862') AND master_cat.Description LIKE '%Aruba%' AND (master_cat.search NOT LIKE '%BLUETOOTH%' OR master_cat.search NOT LIKE '%WI-FI%' OR master_cat.search NOT LIKE '%WIFI%' OR master_cat.search NOT LIKE '%WIRELESS%' OR master_cat.search NOT LIKE '%LTE%')

"HPE - SBUY - Entry, Mid, and High Level Servers" - 0.1216
  WHERE (master_cat.etilizeCatId IN ('4873','5148','10154','10247','10282','11099','11748') OR master_cat.etilizeParentCatId IN ('4873','5148','10154','10247','10282','11099','11748')) AND master_cat.etilizeMfgId IN ('1063889','1063890','1063892','1063978','1043455','1046863','1046864','1054748','1054862') AND (master_cat.search NOT LIKE '%BLUETOOTH%' OR master_cat.search NOT LIKE '%WI-FI%' OR master_cat.search NOT LIKE '%WIFI%' OR master_cat.search NOT LIKE '%WIRELESS%' OR master_cat.search NOT LIKE '%LTE%')

  "HP - Storage Devices (HSD)" - 0.26
            WHERE (master_cat.etilizeCatId IN ('4907','5167','10061','1010','10154','10465','10468','10692','10808','10931','11493','11611') OR master_cat.etilizeParentCatId IN ('4907','5167','10061','1010','10154','10465','10468','10692','10808','10931','11493','11611')) AND master_cat.etilizeMfgId IN ('1063889','1063890','1063892','1063978','1043455','1046863','1046864','1054748','1054862','1063888','1063891','1063976','1063979','1042796','1043456','1046484') AND (master_cat.search NOT LIKE '%BLUETOOTH%' OR master_cat.search NOT LIKE '%WI-FI%' OR master_cat.search NOT LIKE '%WIFI%' OR master_cat.search NOT LIKE '%WIRELESS%' OR master_cat.search NOT LIKE '%LTE%')

  "NOT HP - Storage Devices (HSD)" - 0.26
            WHERE (master_cat.etilizeCatId IN ('4907','5167','10061','1010','10154','10465','10468','10692','10808','10931','11493','11611') OR master_cat.etilizeParentCatId IN ('4907','5167','10061','1010','10154','10465','10468','10692','10808','10931','11493','11611')) AND master_cat.etilizeMfgId IN ('102251','101210','10237','10220','10406','10418','102304','10563','10353','1020570','1030062','10227','1036611','10322','10301','10227','10943','1023145','1026045','1029114','1032356','1035747','1044946','1045024','1046866','1020376','1029553','1030008','1025881','1036136','1039004','101950','1034465','1026916') AND (master_cat.search NOT LIKE '%BLUETOOTH%' OR master_cat.search NOT LIKE '%WI-FI%' OR master_cat.search NOT LIKE '%WIFI%' OR master_cat.search NOT LIKE '%WIRELESS%' OR master_cat.search NOT LIKE '%LTE%')
           
  "HP - System Components (HSC)" - 0.31
            WHERE (master_cat.etilizeCatId IN ('5181') OR master_cat.etilizeParentCatId IN ('5181')) AND master_cat.etilizeMfgId IN ('1063889','1063890','1063892','1063978','1043455','1046863','1046864','1054748','1054862','1063888','1063891','1063976','1063979','1042796','1043456','1046484') AND (master_cat.search NOT LIKE '%BLUETOOTH%' OR master_cat.search NOT LIKE '%WI-FI%' OR master_cat.search NOT LIKE '%WIFI%' OR master_cat.search NOT LIKE '%WIRELESS%' OR master_cat.search NOT LIKE '%LTE%')
         
  "Not HP - System Components (HSC)" - 0.21
            WHERE (master_cat.etilizeCatId IN ('5181') OR master_cat.etilizeParentCatId IN ('5181')) AND master_cat.etilizeMfgId IN ('102251','101210','10237','10220','10406','10418','102304','10563','10353','1020570','1030062','10227','1036611','10322','10301','10227','10943','1023145','1026045','1029114','1032356','1035747','1044946','1045024','1046866','1020376','1029553','1030008','1025881','1036136','1039004','101950','1034465','1026916') AND (master_cat.search NOT LIKE '%BLUETOOTH%' OR master_cat.search NOT LIKE '%WI-FI%' OR master_cat.search NOT LIKE '%WIFI%' OR master_cat.search NOT LIKE '%WIRELESS%' OR master_cat.search NOT LIKE '%LTE%')
            
"HP - Printer Supplies (HPS) - Not Ink" - 0.36
            WHERE (master_cat.etilizeCatId IN ('11040') OR master_cat.etilizeParentCatId IN ('11040')) AND master_cat.etilizeMfgId IN ('1063889','1063890','1063892','1063978','1043455','1046863','1046864','1054748','1054862','1063888','1063891','1063976','1063979','1042796','1043456','1046484') AND (master_cat.search NOT LIKE '%BLUETOOTH%' OR master_cat.search NOT LIKE '%WI-FI%' OR master_cat.search NOT LIKE '%WIFI%' OR master_cat.search NOT LIKE '%WIRELESS%' OR master_cat.search NOT LIKE '%LTE%')
          
  "Not HP - Printer Supplies (HPS) - Not Ink" - 0.36
            WHERE (master_cat.etilizeCatId IN ('11040') OR master_cat.etilizeParentCatId IN ('11040')) AND master_cat.etilizeMfgId IN ('102251','101210','10237','10220','10406','10418','102304','10563','10353','1020570','1030062','10227','1036611','10322','10301','10227','10943','1023145','1026045','1029114','1032356','1035747','1044946','1045024','1046866','1020376','1029553','1030008','1025881','1036136','1039004','101950','1034465','1026916') AND (master_cat.search NOT LIKE '%BLUETOOTH%' OR master_cat.search NOT LIKE '%WI-FI%' OR master_cat.search NOT LIKE '%WIFI%' OR master_cat.search NOT LIKE '%WIRELESS%' OR master_cat.search NOT LIKE '%LTE%')
           
  "HP - 3rd Party Software (H3SW)" - 0.21
            WHERE (master_cat.etilizeCatId IN ('5160','10007','10052','10114') OR master_cat.etilizeParentCatId IN ('5160','10007','10052','10114')) AND master_cat.etilizeMfgId IN ('1063889','1063890','1063892','1063978','1043455','1046863','1046864','1054748','1054862','1063888','1063891','1063976','1063979','1042796','1043456','1046484') AND (master_cat.search NOT LIKE '%BLUETOOTH%' OR master_cat.search NOT LIKE '%WI-FI%' OR master_cat.search NOT LIKE '%WIFI%' OR master_cat.search NOT LIKE '%WIRELESS%' OR master_cat.search NOT LIKE '%LTE%')
           
  "HP - Cables (HC)" - 0.41
            WHERE (master_cat.etilizeCatId IN ('5153') OR master_cat.etilizeParentCatId IN ('5153')) AND master_cat.etilizeMfgId IN ('1063889','1063890','1063892','1063978','1043455','1046863','1046864','1054748','1054862','1063888','1063891','1063976','1063979','1042796','1043456','1046484') AND (master_cat.search NOT LIKE '%BLUETOOTH%' OR master_cat.search NOT LIKE '%WI-FI%' OR master_cat.search NOT LIKE '%WIFI%' OR master_cat.search NOT LIKE '%WIRELESS%' OR master_cat.search NOT LIKE '%LTE%')
  
  "NOT HP - Cables (HC)" - 0.21
            WHERE (master_cat.etilizeCatId IN ('5153') OR master_cat.etilizeParentCatId IN ('5153')) AND master_cat.etilizeMfgId IN ('102251','101210','10237','10220','10406','10418','102304','10563','10353','1020570','1030062','10227','1036611','10322','10301','10227','10943','1023145','1026045','1029114','1032356','1035747','1044946','1045024','1046866','1020376','1029553','1030008','1025881','1036136','1039004','101950','1034465','1026916') AND (master_cat.search NOT LIKE '%BLUETOOTH%' OR master_cat.search NOT LIKE '%WI-FI%' OR master_cat.search NOT LIKE '%WIFI%' OR master_cat.search NOT LIKE '%WIRELESS%' OR master_cat.search NOT LIKE '%LTE%')
        

  "HP - Large Format Printer (HLP)" 0.22
          
  "HP - Ink & Toner (HIT)" - 0.37
            WHERE (master_cat.etilizeCatId IN ('10015') OR master_cat.etilizeParentCatId IN ('10015')) AND master_cat.etilizeMfgId IN ('1063889','1063890','1063892','1063978','1043455','1046863','1046864','1054748','1054862','1063888','1063891','1063976','1063979','1042796','1043456','1046484') AND (master_cat.search NOT LIKE '%BLUETOOTH%' OR master_cat.search NOT LIKE '%WI-FI%' OR master_cat.search NOT LIKE '%WIFI%' OR master_cat.search NOT LIKE '%WIRELESS%' OR master_cat.search NOT LIKE '%LTE%')
  
  "HP - Imaging Devices (HID)" - 0.22
            WHERE (master_cat.etilizeCatId IN ('4911','4912','5123','10167','10333','10663','10910','11757') OR master_cat.etilizeParentCatId IN ('4911','4912','5123','10167','10333','10663','10910','11757')) AND master_cat.etilizeMfgId IN ('1063889','1063890','1063892','1063978','1043455','1046863','1046864','1054748','1054862','1063888','1063891','1063976','1063979','1042796','1043456','1046484') AND (master_cat.search NOT LIKE '%BLUETOOTH%' OR master_cat.search NOT LIKE '%WI-FI%' OR master_cat.search NOT LIKE '%WIFI%' OR master_cat.search NOT LIKE '%WIRELESS%' OR master_cat.search NOT LIKE '%LTE%')
            
  "Not HP - Imaging Devices (HID)" 0.22
            WHERE (master_cat.etilizeCatId IN ('4911','4912','5123','10167','10333','10663','10910','11757') OR master_cat.etilizeParentCatId IN ('4911','4912','5123','10167','10333','10663','10910','11757')) AND master_cat.etilizeMfgId IN ('102251','101210','10237','10220','10406','10418','102304','10563','10353','1020570','1030062','10227','1036611','10322','10301','10227','10943','1023145','1026045','1029114','1032356','1035747','1044946','1045024','1046866','1020376','1029553','1030008','1025881','1036136','1039004','101950','1034465','1026916') AND (master_cat.search NOT LIKE '%BLUETOOTH%' OR master_cat.search NOT LIKE '%WI-FI%' OR master_cat.search NOT LIKE '%WIFI%' OR master_cat.search NOT LIKE '%WIRELESS%' OR master_cat.search NOT LIKE '%LTE%')
           
*/ 
