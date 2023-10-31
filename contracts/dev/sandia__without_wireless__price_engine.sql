/**
*
* WESTWIND: Sandia Price Engine (EXCLUDING Wireless)
*
**/

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
           
